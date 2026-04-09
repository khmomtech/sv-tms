// 📁 lib/providers/driver_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';
import 'package:tms_driver_app/services/location_service.dart'; // LocationUpdate
import 'package:tms_driver_app/services/native_service_bridge.dart';
import 'package:tms_driver_app/services/session_manager.dart';
import 'package:tms_driver_app/services/web_socket_service.dart';
import 'package:tms_driver_app/services/driver_api_service.dart';

class DriverProvider with ChangeNotifier {
  // -------- Core session / status --------
  String? _driverId;
  bool _isOnline = false;
  Position? _currentPosition;
  Position? _lastSentPosition;
  bool _isTracking = false;
  bool _isLoading = false;
  int _notificationCount = 0;

  Map<String, dynamic>? _driverProfile;
  Timer? _pollingTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  StompUnsubscribe?
      _assignmentSubscription; // Track assignment topic subscription

  // WebSocket singleton
  final WebSocketService _ws = WebSocketService.instance;
  final DioClient _dio = DioClient();
  final DriverApiService _driverApiService = DriverApiService();

  // Session lifecycle flags
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _authBlocked = false;
  DateTime? _profileFetchBackoffUntil;
  DateTime? _notificationsFetchBackoffUntil;
  int? _lastProfileFetchStatusCode;
  String? _lastProfileFetchError;

  // -------- Assigned Vehicles state --------
  List<Map<String, dynamic>> _assignedVehicles = [];
  bool _isLoadingAssignedVehicles = false;

  // -------- Current Assignment (effective vehicle) --------
  Map<String, dynamic>?
      _currentAssignment; // holds permanentVehicle, temporaryVehicle, effectiveVehicle, temporaryExpiry
  /// Public setter for testing
  set currentAssignment(Map<String, dynamic>? assignment) {
    _currentAssignment = assignment;
    notifyListeners();
  }

  bool _isLoadingCurrentAssignment = false;
  String? _assignmentError;

  // -------- Monthly Performance --------
  Map<String, dynamic>? _currentMonthPerformance;
  List<Map<String, dynamic>> _performanceHistory = [];
  bool _isLoadingPerformance = false;

  // -------- Getters --------
  String? get driverId => _driverId;
  bool get isOnline => _isOnline;
  Position? get currentPosition => _currentPosition;
  Map<String, dynamic>? get driverProfile => _driverProfile;
  bool get isLoading => _isLoading;
  int get notificationCount => _notificationCount;
  int? get lastProfileFetchStatusCode => _lastProfileFetchStatusCode;
  String? get lastProfileFetchError => _lastProfileFetchError;

  List<Map<String, dynamic>> get assignedVehicles => _assignedVehicles;
  bool get isLoadingAssignedVehicles => _isLoadingAssignedVehicles;
  Map<String, dynamic>? get currentAssignment => _currentAssignment;
  Map<String, dynamic>? get effectiveVehicle => _currentAssignment == null
      ? null
      : _currentAssignment!['effectiveVehicle'] as Map<String, dynamic>?;
  bool get isLoadingCurrentAssignment => _isLoadingCurrentAssignment;
  String? get assignmentError => _assignmentError;

  Map<String, dynamic>? get vehicleCardData {
    final Map<String, dynamic>? effective = effectiveVehicle;
    if (effective != null && effective.isNotEmpty) {
      return _enrichVehicleMap(effective);
    }
    final Map<String, dynamic>? assignedFromProfile = _driverProfile == null
        ? null
        : (_driverProfile!['assignedVehicle'] as Map<String, dynamic>?);
    if (assignedFromProfile != null && assignedFromProfile.isNotEmpty) {
      return _enrichVehicleMap(assignedFromProfile);
    }
    return null;
  }

  // Monthly performance getters
  Map<String, dynamic>? get currentMonthPerformance => _currentMonthPerformance;
  List<Map<String, dynamic>> get performanceHistory => _performanceHistory;
  bool get isLoadingPerformance => _isLoadingPerformance;

  // -------- Setters --------
  set isOnline(bool value) {
    _isOnline = value;
    value ? startLiveLocationUpdates() : stopLocationUpdates();
    notifyListeners();
  }

  // ============================================================
  // Session bootstrap
  // ============================================================
  Future<void> initializeDriverSession() async {
    if (_isInitialized || _isDisposed) {
      debugPrint('[DriverProvider] Session already initialized or disposed');
      return;
    }

    await loadLoggedInDriverId();
    if (_driverId == null || _driverId!.trim().isEmpty) {
      debugPrint(
          '[DriverProvider] No driver ID found; cannot initialize session');
      return;
    }

    final token = await ApiConstants.ensureFreshTrackingToken() ??
        await ApiConstants.ensureFreshAccessToken();
    if (token == null || token.isEmpty) {
      _authBlocked = true;
      SessionManager.instance
          .markAuthInvalid(reason: 'driver_provider_init_missing_token');
      return;
    }

    _authBlocked = false;
    _isInitialized = true;

    _isOnline = true;
    _currentPosition = await _getStoredLocation();
    notifyListeners();

    // Start native location service
    await NativeServiceBridge.startServiceOnce();

    // WebSocket connect (now requires tokenProvider)
    // Connect WS only if token available
    try {
      await _ws.connect(
        tokenProvider: () async =>
            await ApiConstants.ensureFreshTrackingToken() ??
            await ApiConstants.ensureFreshAccessToken(),
      );
      _ws.onLocationReceived = _handleIncomingSocketMessage;

      // Subscribe to driver assignment updates -> refresh current assignment
      await _subscribeToAssignmentUpdates();
    } catch (e) {
      debugPrint('[DriverProvider] WebSocket connection failed: $e');
      // Continue initialization even if WebSocket fails (REST fallback available)
    }

    // Foreground (Dart) stream
    await startLiveLocationUpdates();

    // UI polling fallback
    _startPolling();

    await fetchDriverProfile();
    await fetchNotifications();
    // fetchAssignedVehicles() removed - uses admin endpoint that returns 403 for drivers
    // Vehicle data is already available via fetchCurrentAssignment()
    await fetchCurrentAssignment(); // new effective assignment
  }

  // ============================================================
  // WebSocket Assignment Subscription Management
  // ============================================================
  Future<void> _subscribeToAssignmentUpdates() async {
    if (_driverId == null || _isDisposed) return;

    // Clean up existing subscription first
    _assignmentSubscription?.call();
    _assignmentSubscription = null;

    try {
      final topic = '/topic/assignments/driver/$_driverId';
      _assignmentSubscription = _ws.subscribe(topic, (frame) async {
        if (_isDisposed || frame.body == null) return;

        try {
          final event = json.decode(frame.body!) as Map<String, dynamic>;
          final did = event['driverId']?.toString();

          // Only process if event matches current driver
          if (did == _driverId) {
            debugPrint(
                '[DriverProvider] Assignment update received for driver $_driverId');
            await fetchCurrentAssignment();
          }
        } catch (e) {
          debugPrint('[DriverProvider] Failed to parse assignment update: $e');
        }
      });

      if (_assignmentSubscription != null) {
        debugPrint(
            '[DriverProvider] Successfully subscribed to assignment updates');
      }
    } catch (e) {
      debugPrint('[DriverProvider] WS subscribe error: $e');
    }
  }

  // ============================================================
  // Profile & Notifications
  // ============================================================
  Future<void> fetchDriverProfile({int retryCount = 0}) async {
    if (_driverId == null || _isDisposed) {
      debugPrint(
          '[DriverProvider] Cannot fetch profile: driverId=$_driverId, disposed=$_isDisposed');
      _lastProfileFetchError = 'profile_fetch_skipped';
      return;
    }

    final now = DateTime.now();
    if (retryCount == 0 &&
        _profileFetchBackoffUntil != null &&
        now.isBefore(_profileFetchBackoffUntil!)) {
      _lastProfileFetchError = 'profile_fetch_backoff';
      return;
    }

    final headers = await _getAuthHeaders();
    if (headers == null) {
      debugPrint('[DriverProvider] No auth headers available');
      _lastProfileFetchError = 'missing_auth_headers';
      return;
    }

    if (!await _hasInternet()) {
      _hydrateProfileFromStoredUser();
      debugPrint('[DriverProvider] No internet connection');
      _lastProfileFetchError = 'no_internet';
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      http.Response response;
      // Prefer self profile endpoint when available, then fallback to id endpoint.
      final selfUrl = '${ApiConstants.baseUrl}/driver/me/profile';
      final idUrl = '${ApiConstants.baseUrl}/driver/$_driverId';
      debugPrint('[DriverProvider] Fetching profile (self): $selfUrl');
      response = await http
          .get(
            Uri.parse(selfUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 404 || response.statusCode == 405) {
        debugPrint(
            '[DriverProvider] Self profile unavailable (${response.statusCode}), fallback: $idUrl');
        response = await http
            .get(
              Uri.parse(idUrl),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
      }

      debugPrint('[DriverProvider] Profile response: ${response.statusCode}');
      _lastProfileFetchStatusCode = response.statusCode;

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        _profileFetchBackoffUntil = null;
        _lastProfileFetchError = null;
        final body = json.decode(response.body) as Map<String, dynamic>;
        final data = _extractDriverProfileData(body);

        if (data != null) {
          _mergeNestedUserFields(data);
          _mergeStoredUserFields(data);
          _normalizeDriverIdentity(data);
          final name =
              '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          debugPrint('[DriverProvider] Profile loaded: $name (ID: $_driverId)');

          // Build absolute URL for profile picture and normalize localhost URLs
          final pic = data['profilePicture'];
          if (pic is String && pic.isNotEmpty) {
            final imageUrl = ApiConstants.image(pic);
            data['profilePictureUrl'] = imageUrl;
            debugPrint('[DriverProvider] Profile picture URL: $imageUrl');
          }

          // Parse array-form timestamp to DateTime
          data['lastLocationAtParsed'] =
              _asDateFromArray(data['lastLocationAt']);

          final idCardMap = await _fetchMyIdCard(headers);
          if (idCardMap != null) {
            data.addAll(idCardMap);
          }
          _driverProfile = data;
        } else {
          debugPrint('[DriverProvider] No data field in response');
          _lastProfileFetchError = 'empty_data';
          _hydrateProfileFromStoredUser();
        }
      } else if (response.statusCode == 403) {
        debugPrint(
            '[DriverProvider] Access denied (403) - Check user permissions');
        _lastProfileFetchError = 'forbidden';
        _hydrateProfileFromStoredUser();
      } else if (response.statusCode == 404) {
        debugPrint('[DriverProvider] Driver not found (404) - ID: $_driverId');
        _lastProfileFetchError = 'not_found';
        _hydrateProfileFromStoredUser();
      } else if (response.statusCode >= 500) {
        // Prevent repeated storm of the same failing call across multiple screens.
        _profileFetchBackoffUntil =
            DateTime.now().add(const Duration(seconds: 30));
        debugPrint(
            '[DriverProvider] Server error ${response.statusCode}, applying 30s backoff');
        _lastProfileFetchError = 'server_${response.statusCode}';
        _hydrateProfileFromStoredUser();
      } else {
        final preview = response.body.length > 100
            ? response.body.substring(0, 100)
            : response.body;
        debugPrint(
            '[DriverProvider] Unexpected response ${response.statusCode}: $preview');
        _lastProfileFetchError = 'unexpected_${response.statusCode}';
        _hydrateProfileFromStoredUser();
      }
    } on TimeoutException catch (e) {
      debugPrint('[DriverProvider] ⏱️ Profile fetch timeout: $e');
      _profileFetchBackoffUntil =
          DateTime.now().add(const Duration(seconds: 30));
      debugPrint(
          '[DriverProvider] Timeout on profile fetch, applying 30s backoff');
      _lastProfileFetchError = 'timeout';
      _hydrateProfileFromStoredUser();
    } on FormatException catch (e) {
      debugPrint('[DriverProvider] JSON parse error: $e');
      _lastProfileFetchError = 'format_error';
      _hydrateProfileFromStoredUser();
    } catch (e, stackTrace) {
      debugPrint('[DriverProvider] Profile fetch error: $e');
      _lastProfileFetchError = 'exception';
      _hydrateProfileFromStoredUser();
      if (retryCount == 0) {
        debugPrint('Stack trace: $stackTrace');
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchNotifications() async {
    if (_driverId == null || _isDisposed) return;
    final now = DateTime.now();
    if (_notificationsFetchBackoffUntil != null &&
        now.isBefore(_notificationsFetchBackoffUntil!)) {
      return;
    }
    final headers = await _getAuthHeaders();
    if (headers == null || !await _hasInternet()) return;

    try {
      // Prefer unified notifications API; keep legacy fallback for older servers.
      final primaryUri = Uri.parse(
        '${ApiConstants.baseUrl}/notifications/driver/$_driverId'
        '?order=unreadFirst&unreadOnly=false&page=0&size=100',
      );
      final legacyUri = Uri.parse(
        '${ApiConstants.baseUrl}/driver/$_driverId/notifications?page=0&size=100',
      );

      http.Response response;
      response = await http
          .get(primaryUri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await http
            .get(legacyUri, headers: headers)
            .timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        _notificationsFetchBackoffUntil = null;
        final jsonBody = json.decode(response.body) as Map<String, dynamic>;
        final data = (jsonBody['data'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final content =
            (data['content'] as List<dynamic>? ?? const <dynamic>[]);
        final unreadCountFromServer = data['unreadCount'];
        final unreadCount = unreadCountFromServer is num
            ? unreadCountFromServer.toInt()
            : content.where((n) => (n as Map)['read'] == false).length;

        if (!_isDisposed) {
          _notificationCount = unreadCount;
          notifyListeners();
        }
      } else if (response.statusCode >= 500) {
        _notificationsFetchBackoffUntil =
            DateTime.now().add(const Duration(seconds: 60));
      }
    } on TimeoutException catch (e) {
      debugPrint('[DriverProvider] Notification fetch timeout: $e');
    } catch (e) {
      debugPrint('[DriverProvider] Notification fetch error: $e');
    }
  }

  void _hydrateProfileFromStoredUser() {
    final cached = _driverProfile;
    if (cached != null && cached.isNotEmpty) return;
    ApiConstants.getUser().then((user) {
      if (_isDisposed || user == null || user.isEmpty) return;

      final firstName = (user['firstName'] ?? '').toString();
      final lastName = (user['lastName'] ?? '').toString();
      final username = (user['username'] ?? '').toString();
      final phone = (user['phoneNumber'] ?? user['phone'] ?? '').toString();
      final id = user['driverId'] ?? _driverId;

      _driverProfile = <String, dynamic>{
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'displayName': user['displayName'],
        'name': '$firstName $lastName'.trim().isEmpty
            ? ((user['displayName'] ?? username).toString())
            : '$firstName $lastName'.trim(),
        'username': username,
        'phoneNumber': phone,
        'phone': phone,
        'status': user['status'],
        'employmentStatus': user['employmentStatus'],
      };
      if (!_isDisposed) notifyListeners();
    }).catchError((_) {});
  }

  Future<bool> updateBasicProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    if (_driverId == null || _isDisposed) return false;
    final headers = await _getAuthHeaders();
    if (headers == null || !await _hasInternet()) return false;

    final existing = _driverProfile ?? const <String, dynamic>{};
    final rating = double.tryParse('${existing['rating'] ?? ''}') ?? 0.0;
    final isActive =
        existing['isActive'] is bool ? existing['isActive'] as bool : true;
    final vehicleType = (existing['vehicleType'] ?? 'TRUCK').toString();

    final selfPayload = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phoneNumber': phoneNumber.trim(),
    };

    final legacyPayload = <String, dynamic>{
      'name': '${firstName.trim()} ${lastName.trim()}'.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'rating': rating,
      'isActive': isActive,
      'vehicleType': vehicleType,
      if (existing['licenseNumber'] != null)
        'licenseNumber': '${existing['licenseNumber']}',
      if (existing['licenseClass'] != null)
        'licenseClass': '${existing['licenseClass']}',
      if (existing['zone'] != null) 'zone': '${existing['zone']}',
      if (existing['status'] != null) 'status': '${existing['status']}',
      if (existing['employmentStatus'] != null)
        'employmentStatus': '${existing['employmentStatus']}',
      if (existing['idCardExpiry'] != null)
        'idCardExpiry': '${existing['idCardExpiry']}',
      if (existing['profilePicture'] != null)
        'profilePicture': '${existing['profilePicture']}',
    };

    try {
      final selfUrl = '${ApiConstants.baseUrl}/driver/me/profile';
      final selfResponse = await http
          .put(
            Uri.parse(selfUrl),
            headers: headers,
            body: jsonEncode(selfPayload),
          )
          .timeout(const Duration(seconds: 15));

      if (selfResponse.statusCode == 200) {
        await fetchDriverProfile();
        return true;
      }

      // Backward compatibility fallback for older backends.
      if (selfResponse.statusCode == 404 || selfResponse.statusCode == 403) {
        final legacyUrl = '${ApiConstants.baseUrl}/driver/update/$_driverId';
        final legacyResponse = await http
            .put(
              Uri.parse(legacyUrl),
              headers: headers,
              body: jsonEncode(legacyPayload),
            )
            .timeout(const Duration(seconds: 15));

        if (legacyResponse.statusCode == 200) {
          await fetchDriverProfile();
          return true;
        }

        debugPrint(
            '[DriverProvider] updateBasicProfile legacy failed: ${legacyResponse.statusCode} ${legacyResponse.body}');
        return false;
      }

      debugPrint(
          '[DriverProvider] updateBasicProfile failed: ${selfResponse.statusCode} ${selfResponse.body}');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('[DriverProvider] updateBasicProfile timeout: $e');
      return false;
    } catch (e) {
      debugPrint('[DriverProvider] updateBasicProfile error: $e');
      return false;
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    if (_driverId == null) return;
    try {
      if (!await _hasInternet()) return;

      final path =
          ApiConstants.endpoint('/driver/$_driverId/upload-profile').path;
      final form = FormData.fromMap({
        'profilePicture': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final res = await _dio.dio.post(
        path,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (res.statusCode == 200) {
        await fetchDriverProfile();
        return;
      }

      debugPrint(
          '[DriverProvider] Upload failed: ${res.statusCode} ${res.data}');
    } catch (e) {
      debugPrint('[DriverProvider] Upload failed: $e');
    }
  }

  // ============================================================
  // Live Location (WS + REST fallback)
  // ============================================================
  Future<void> startLiveLocationUpdates() async {
    if (_driverId == null || _isTracking || _isDisposed) return;
    if (!await _checkLocationPermission()) {
      debugPrint('[DriverProvider] Location permission denied');
      return;
    }

    _isTracking = true;
    await _positionStreamSubscription?.cancel();

    try {
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // meters
        ),
      ).listen(
        (position) async {
          if (_isDisposed) return;

          _currentPosition = position;
          if (!_isDisposed) notifyListeners();

          await _saveLocationToStorage(position);

          if (_shouldSendLocation(position) && !_isDisposed) {
            final update = LocationUpdate(
              position: position,
              batteryLevel: -1, // unknown in Dart layer
              timestamp: DateTime.now().toUtc(),
              isBatterySaver: false,
              isReducedAccuracy: position.isMocked,
            );
            await LocationService().queueUpdate(update);

            _lastSentPosition = position;
          }
        },
        onError: (error) {
          debugPrint('[DriverProvider] Location stream error: $error');
          _isTracking = false;
        },
        cancelOnError: false, // Keep stream active despite errors
      );
    } catch (e) {
      debugPrint('[DriverProvider] Failed to start location stream: $e');
      _isTracking = false;
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    if (_isDisposed) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!_isDisposed) {
        await fetchDriverLocation();
      }
    });
  }

  bool _shouldSendLocation(Position pos) {
    if (_lastSentPosition == null) return true;
    const threshold = 0.00001; // ~1.1 m lat delta
    return (pos.latitude - _lastSentPosition!.latitude).abs() > threshold ||
        (pos.longitude - _lastSentPosition!.longitude).abs() > threshold;
  }

  void stopLocationUpdates() {
    _isTracking = false;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void _handleIncomingSocketMessage(Map<String, dynamic> data) {
    final idStr = data['driverId']?.toString();
    if (idStr == null || idStr != _driverId) return;

    final lat = _asDouble(data['latitude']);
    final lng = _asDouble(data['longitude']);

    // Avoid overwriting with invalid/zero coordinates
    if (lat.isNaN || lng.isNaN || (lat.abs() < 1e-9 && lng.abs() < 1e-9)) {
      return;
    }

    _currentPosition = Position(
      latitude: lat,
      longitude: lng,
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      timestamp: DateTime.now(),
    );
    notifyListeners();
  }

  // ============================================================
  // Assigned Vehicles
  // ============================================================
  // DEPRECATED: This method is no longer needed as we use currentAssignment
  // which provides the effective vehicle assignment for the driver
  Future<void> fetchAssignedVehicles() async {
    await fetchDriverVehicles();
  }

  Future<void> fetchDriverVehicles() async {
    if (_isDisposed) return;

    // Vehicle data is already populated by fetchCurrentAssignment.
    // If we have a cached assignment, extract vehicles from it directly.
    if (_currentAssignment != null) {
      _isLoadingAssignedVehicles = true;
      notifyListeners();
      try {
        final vehicles = <Map<String, dynamic>>[];
        final permanent = _asStringKeyMap(_currentAssignment!['permanentVehicle']);
        final temporary = _asStringKeyMap(_currentAssignment!['temporaryVehicle']);
        if (permanent != null) vehicles.add(_enrichVehicleMap(permanent));
        if (temporary != null && temporary['id'] != permanent?['id']) {
          vehicles.add(_enrichVehicleMap(temporary));
        }
        if (vehicles.isNotEmpty && !_isDisposed) _assignedVehicles = vehicles;
      } finally {
        if (!_isDisposed) {
          _isLoadingAssignedVehicles = false;
          notifyListeners();
        }
      }
      return;
    }

    // No cached assignment — fetch from server.
    await fetchCurrentAssignment();
  }

  Future<void> fetchCurrentAssignment() async {
    if (_isDisposed) return;
    if (_driverId == null || _driverId!.trim().isEmpty) {
      await loadLoggedInDriverId();
    }
    final headers = await _getAuthHeaders();
    if (headers == null || !await _hasInternet()) return;

    _isLoadingCurrentAssignment = true;
    _assignmentError = null;
    if (!_isDisposed) notifyListeners();

    debugPrint('[DriverProvider] Fetching current assignment...');

    try {
      final assignmentData = await _driverApiService.getCurrentAssignment(
        driverId: _driverId!,
        headers: headers,
      );

      if (!_isDisposed) {
        if (assignmentData != null) {
          final tmpExp = assignmentData['temporaryExpiry'];
          if (tmpExp is List && tmpExp.length >= 6) {
            try {
              assignmentData['temporaryExpiryParsed'] = DateTime(
                tmpExp[0] as int,
                tmpExp[1] as int,
                tmpExp[2] as int,
                tmpExp[3] as int,
                tmpExp[4] as int,
                tmpExp[5] as int,
              );
            } catch (_) {}
          } else if (tmpExp is String && tmpExp.isNotEmpty) {
            final parsed = DateTime.tryParse(tmpExp);
            if (parsed != null) {
              assignmentData['temporaryExpiryParsed'] = parsed;
            }
          }

          assignmentData['effectiveVehicle'] ??=
              assignmentData['temporaryVehicle'] ??
                  assignmentData['permanentVehicle'];
          _currentAssignment = assignmentData;
          _syncProfileWithEffectiveVehicle(
            _asStringKeyMap(assignmentData['effectiveVehicle']),
          );
          // Populate vehicle list from assignment data to avoid a separate API call.
          final vehicles = <Map<String, dynamic>>[];
          final permanent = _asStringKeyMap(assignmentData['permanentVehicle']);
          final temporary = _asStringKeyMap(assignmentData['temporaryVehicle']);
          if (permanent != null) vehicles.add(_enrichVehicleMap(permanent));
          if (temporary != null && temporary['id'] != permanent?['id']) {
            vehicles.add(_enrichVehicleMap(temporary));
          }
          if (vehicles.isNotEmpty) _assignedVehicles = vehicles;
        } else {
          debugPrint(
              '[DriverProvider] fetchCurrentAssignment completed with no data, using fallback from local state.');
          _currentAssignment = _buildFallbackAssignmentFromLocalState();
          _syncProfileWithEffectiveVehicle(
            _asStringKeyMap(_currentAssignment?['effectiveVehicle']),
          );
        }
      }
    } on TimeoutException catch (e) {
      _assignmentError =
          'Could not connect to the server. Please try again later.';
      debugPrint('[DriverProvider] fetchCurrentAssignment timeout: $e');
    } catch (e) {
      _assignmentError = 'An unexpected error occurred. Please try again.';
      debugPrint('[DriverProvider] fetchCurrentAssignment error: $e');
    } finally {
      _isLoadingCurrentAssignment = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> fetchAvailableVehicles() async {
    debugPrint(
        '[DriverProvider] fetchAvailableVehicles skipped: no driver-facing endpoint integrated');
    return [];
  }

  Future<bool> assignVehicleToSelf(int vehicleId) async {
    debugPrint(
        '[DriverProvider] assignVehicleToSelf skipped for vehicleId=$vehicleId: no driver-facing endpoint integrated');
    return false;
  }

  // ============================================================
  // Server-side position polling (UI sync)
  // ============================================================
  Future<void> fetchDriverLocation() async {
    final headers = await _getAuthHeaders();
    if (headers == null || _driverId == null || !await _hasInternet()) return;

    try {
      final data = await _driverApiService.getDriverLocation(
        driverId: _driverId!,
        headers: headers,
      );

      if (data != null) {
        final lat = _asDouble(data['latitude'] ?? data['lat']);
        final lng = _asDouble(data['longitude'] ?? data['lng']);

        // Do not overwrite with invalid or origin coordinates
        if (lat.isNaN || lng.isNaN || (lat.abs() < 1e-9 && lng.abs() < 1e-9)) {
          return;
        }

        _currentPosition = Position(
          latitude: lat,
          longitude: lng,
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
          timestamp: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[DriverProvider] Driver location fetch failed: $e');
    }
  }

  // ============================================================
  // Auth / Headers / Connectivity
  // ============================================================
  Future<Map<String, String>?> _getAuthHeaders() async {
    if (_authBlocked || _isDisposed) return null;
    final token = await ApiConstants.ensureFreshAccessToken() ??
        await ApiConstants.ensureFreshTrackingToken();
    if (token == null || token.isEmpty) {
      _authBlocked = true;
      debugPrint('[DriverProvider] Unauthorized: Please login again');
      SessionManager.instance
          .markAuthInvalid(reason: 'driver_provider_missing_token');
      return null;
    }
    _authBlocked = false;
    return {
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
  }

  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    // connectivity_plus 6.x+ returns List<ConnectivityResult>
    return !result.contains(ConnectivityResult.none);
  }

  // ============================================================
  // Storage helpers
  // ============================================================
  Future<void> _saveLocationToStorage(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', position.latitude);
    await prefs.setDouble('longitude', position.longitude);
  }

  Future<Position?> _getStoredLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('latitude');
    final lng = prefs.getDouble('longitude');
    if (lat != null && lng != null) {
      return Position(
        latitude: lat,
        longitude: lng,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  // ============================================================
  // Permissions
  // ============================================================
  Future<bool> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ============================================================
  // Session save/load
  // ============================================================
  Future<void> saveLoggedInDriverId(String driverId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverId', driverId);
    await prefs.setString('token', token); // kept for BC; not used for sends
    _driverId = driverId;
    _authBlocked = false;
    notifyListeners();
  }

  Future<void> loadLoggedInDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    _driverId = prefs.getString('driverId');
    if (_driverId != null && _driverId!.trim().isEmpty) {
      _driverId = null;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------
  // Helpers: parsing
  // ------------------------------------------------------------
  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? double.nan;
  }

  DateTime? _asDateFromArray(dynamic v) {
    if (v is List && v.length >= 6) {
      final y = v[0];
      final mo = v[1];
      final d = v[2];
      final h = v[3];
      final mi = v[4];
      final s = v[5];
      if ([y, mo, d, h, mi, s].every((e) => e is int)) {
        return DateTime(
            y as int, mo as int, d as int, h as int, mi as int, s as int);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchMyIdCard(
      Map<String, String> headers) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/driver/me/id-card');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.body.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final data = decoded['data'];
      if (data is! Map) {
        return null;
      }
      final idCard = data.cast<String, dynamic>();
      return {
        'idCardNumber': idCard['idCardNumber'],
        'idCardIssuedDate': idCard['issuedDate'],
        'idCardExpiry': idCard['expiryDate'],
        'idCardStatus': idCard['status'],
      };
    } catch (e) {
      debugPrint('[DriverProvider] fetchMyIdCard fallback skipped: $e');
      return null;
    }
  }

  Map<String, dynamic> _enrichVehicleMap(Map<String, dynamic> base) {
    final Map<String, dynamic> enriched = Map<String, dynamic>.from(base);
    final normalizedPlate = enriched['licensePlate'] ??
        enriched['plate'] ??
        enriched['plateNumber'] ??
        enriched['truckNumber'] ??
        enriched['vehiclePlate'];
    if (normalizedPlate != null &&
        normalizedPlate.toString().trim().isNotEmpty) {
      final plateText = normalizedPlate.toString().trim();
      enriched['licensePlate'] ??= plateText;
      enriched['plate'] ??= plateText;
      enriched['plateNumber'] ??= plateText;
      enriched['truckNumber'] ??= plateText;
      enriched['vehiclePlate'] ??= plateText;
    }
    enriched['model'] ??= enriched['vehicleModel'] ?? 'Unknown Model';
    enriched['type'] ??= enriched['vehicleType'];
    enriched['vehicleType'] ??= enriched['type'];
    enriched['vin'] ??= enriched['chassisNumber'] ?? enriched['chassisNo'];
    enriched['status'] ??= 'UNKNOWN';

    final rawVehicleDrivers =
        enriched['vehicle_drivers'] ?? enriched['vehicleDrivers'];
    if (rawVehicleDrivers is List) {
      final normalizedDrivers = rawVehicleDrivers
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
      enriched['vehicle_drivers'] = normalizedDrivers;
      enriched['vehicleDrivers'] = normalizedDrivers;

      if (normalizedDrivers.isNotEmpty) {
        final activeRelation =
            normalizedDrivers.cast<Map<String, dynamic>>().firstWhere(
                  (entry) =>
                      entry['endedAt'] == null &&
                      entry['endDate'] == null &&
                      entry['inactiveAt'] == null,
                  orElse: () => normalizedDrivers.first.cast<String, dynamic>(),
                );
        final relationDriver = _asStringKeyMap(activeRelation['driver']);
        if (relationDriver != null && relationDriver.isNotEmpty) {
          enriched['assignedDriver'] ??= relationDriver;
        }
        enriched['assignedAt'] ??= activeRelation['assignedAt'] ??
            activeRelation['startDate'] ??
            activeRelation['createdAt'];
      }
    }

    return enriched;
  }

  void _normalizeDriverIdentity(Map<String, dynamic> profile) {
    final displayName = (profile['displayName'] ?? profile['name'])?.toString();
    final firstName = profile['firstName']?.toString().trim() ?? '';
    final lastName = profile['lastName']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final username = profile['username']?.toString().trim();

    final resolvedName = [
      fullName,
      displayName?.trim() ?? '',
      username ?? '',
    ].firstWhere((value) => value.isNotEmpty, orElse: () => 'Driver');

    profile['name'] = resolvedName;
    profile['displayName'] = resolvedName;
    profile['phoneNumber'] ??= profile['phone'];
    profile['phone'] ??= profile['phoneNumber'];
    profile['companyName'] ??= profile['company'];
    profile['company'] ??= profile['companyName'];
  }

  Map<String, dynamic>? _extractDriverProfileData(Map<String, dynamic> body) {
    final dynamic wrapped = body['data'];
    if (wrapped is Map<String, dynamic>) {
      return Map<String, dynamic>.from(wrapped);
    }
    if (wrapped is Map) {
      return wrapped.map((k, v) => MapEntry(k.toString(), v));
    }

    // Fallback for servers returning driver fields at root (without ApiResponse envelope)
    if (body.containsKey('id') ||
        body.containsKey('firstName') ||
        body.containsKey('lastName') ||
        body.containsKey('user')) {
      return Map<String, dynamic>.from(body);
    }
    return null;
  }

  void _mergeNestedUserFields(Map<String, dynamic> profile) {
    final dynamic rawUser = profile['user'];
    if (rawUser is! Map) return;
    final user = rawUser.map((k, v) => MapEntry(k.toString(), v));

    profile['username'] ??= user['username'] ?? user['userName'];
    profile['email'] ??= user['email'];

    final first = profile['firstName']?.toString().trim() ?? '';
    final last = profile['lastName']?.toString().trim() ?? '';
    if (first.isEmpty &&
        (user['firstName']?.toString().trim().isNotEmpty ?? false)) {
      profile['firstName'] = user['firstName'];
    }
    if (last.isEmpty &&
        (user['lastName']?.toString().trim().isNotEmpty ?? false)) {
      profile['lastName'] = user['lastName'];
    }
    profile['phone'] ??= user['phone'] ?? user['phoneNumber'];
    profile['phoneNumber'] ??= profile['phone'];
    profile['driverId'] ??= user['driverId'];
    profile['zone'] ??= user['zone'];
    profile['vehicleType'] ??= user['vehicleType'];
    profile['status'] ??= user['status'];
  }

  void _mergeStoredUserFields(Map<String, dynamic> profile) {
    ApiConstants.getUser().then((user) {
      if (_isDisposed || user == null || user.isEmpty) return;

      profile['username'] ??= user['username'] ?? user['userName'];
      profile['email'] ??= user['email'];
      profile['driverId'] ??= user['driverId'];
      profile['zone'] ??= user['zone'];
      profile['vehicleType'] ??= user['vehicleType'];
      profile['status'] ??= user['status'];
      profile['firstName'] ??= user['firstName'];
      profile['lastName'] ??= user['lastName'];
      profile['phone'] ??= user['phone'] ?? user['phoneNumber'];
      profile['phoneNumber'] ??= profile['phone'];
      profile['companyName'] ??= user['companyName'] ?? user['company'];
      profile['company'] ??= profile['companyName'];
    }).catchError((_) {});
  }

  Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  void _syncProfileWithEffectiveVehicle(Map<String, dynamic>? vehicle) {
    if (_driverProfile == null) return;

    final profile = Map<String, dynamic>.from(_driverProfile!);
    if (vehicle == null || vehicle.isEmpty) {
      profile.remove('assignedVehicle');
      profile.remove('assignedVehiclePlate');
      _driverProfile = profile;
      return;
    }

    final normalized = _enrichVehicleMap(vehicle);
    profile['assignedVehicle'] = normalized;
    profile['assignedVehiclePlate'] = normalized['licensePlate'] ??
        normalized['plate'] ??
        normalized['plateNumber'] ??
        normalized['truckNumber'] ??
        normalized['vehiclePlate'];
    _driverProfile = profile;
  }

  /// Attempt to build a fallback assignment from locally cached state
  /// Returns a map shaped like the server assignment payload or null.
  Map<String, dynamic>? _buildFallbackAssignmentFromLocalState() {
    // Prefer assigned vehicle present on the cached profile
    try {
      final assignedFromProfile = _driverProfile == null
          ? null
          : (_driverProfile!['assignedVehicle'] as Map<String, dynamic>?);
      if (assignedFromProfile != null && assignedFromProfile.isNotEmpty) {
        final effective = _enrichVehicleMap(assignedFromProfile);
        return {
          'effectiveVehicle': effective,
          'permanentVehicle': assignedFromProfile,
        };
      }

      // Next, try any assigned vehicles list
      if (_assignedVehicles.isNotEmpty) {
        final first = _assignedVehicles.first;
        final effective = _enrichVehicleMap(first);
        return {
          'effectiveVehicle': effective,
          'permanentVehicle': first,
        };
      }
    } catch (e) {
      debugPrint(
          '[DriverProvider] _buildFallbackAssignmentFromLocalState error: $e');
    }
    return null;
  }

  // ============================================================
  // Cleanup
  // ============================================================
  void disposeDriverProvider() {
    if (_isDisposed) return;
    _isDisposed = true;

    debugPrint('[DriverProvider] Disposing provider resources');

    // Stop location tracking
    _isTracking = false;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    // Stop polling
    _pollingTimer?.cancel();
    _pollingTimer = null;

    // Unsubscribe from assignment updates
    _assignmentSubscription?.call();
    _assignmentSubscription = null;

    // Disconnect WebSocket
    try {
      _ws.disconnect();
    } catch (e) {
      debugPrint('[DriverProvider] Error disconnecting WebSocket: $e');
    }

    // Clear state
    _currentPosition = null;
    _lastSentPosition = null;
    _driverProfile = null;
    _authBlocked = false;
    _assignedVehicles = [];
    _currentAssignment = null;
    _currentMonthPerformance = null;
    _performanceHistory = [];
    _isInitialized = false;
  }

  // ============================================================
  // Monthly Performance Methods
  // ============================================================

  /// Fetch current month performance metrics
  Future<void> fetchCurrentMonthPerformance() async {
    if (_driverId == null) return;

    final headers = await _getAuthHeaders();
    if (headers == null) return;

    _isLoadingPerformance = true;
    notifyListeners();

    try {
      final url = '${ApiConstants.baseUrl}/driver/performance/current';
      debugPrint('[DriverProvider] 📊 Fetching current month performance...');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final data = (body['data'] as Map?)?.cast<String, dynamic>();
        if (data != null) {
          _currentMonthPerformance = data;
          debugPrint('[DriverProvider] Current month performance loaded');
        }
      } else if (response.statusCode == 404) {
        debugPrint('[DriverProvider] Performance endpoint not available (404) — feature not yet deployed');
      } else {
        debugPrint('[DriverProvider] fetchCurrentMonthPerformance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
          '[DriverProvider] Failed to fetch current month performance: $e');
    } finally {
      if (!_isDisposed) {
        _isLoadingPerformance = false;
        notifyListeners();
      }
    }
  }

  /// Fetch performance history (last N months)
  Future<void> fetchPerformanceHistory({int months = 6}) async {
    if (_driverId == null) return;

    final headers = await _getAuthHeaders();
    if (headers == null) return;

    _isLoadingPerformance = true;
    notifyListeners();

    try {
      final url =
          '${ApiConstants.baseUrl}/driver/performance/history?months=$months';
      debugPrint(
          '[DriverProvider] 📈 Fetching performance history ($months months)...');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final data = (body['data'] as List?)?.cast<Map<String, dynamic>>();
        if (data != null) {
          _performanceHistory =
              data.map((e) => e.cast<String, dynamic>()).toList();
          debugPrint(
              '[DriverProvider] Performance history loaded: ${_performanceHistory.length} months');
        }
      } else if (response.statusCode == 404) {
        debugPrint('[DriverProvider] Performance history endpoint not available (404) — feature not yet deployed');
      } else {
        debugPrint('[DriverProvider] fetchPerformanceHistory: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DriverProvider] Failed to fetch performance history: $e');
    } finally {
      if (!_isDisposed) {
        _isLoadingPerformance = false;
        notifyListeners();
      }
    }
  }

  /// Get performance trend (improving/declining)
  String getPerformanceTrend() {
    if (_performanceHistory.length < 2) return 'stable';

    final current = _performanceHistory[0]['performanceScore'] as int? ?? 0;
    final previous = _performanceHistory[1]['performanceScore'] as int? ?? 0;

    if (current > previous + 5) {
      return 'improving';
    }
    if (current < previous - 5) {
      return 'declining';
    }
    return 'stable';
  }

  /// Get month-over-month change
  int getPerformanceChange() {
    if (_performanceHistory.length < 2) return 0;

    final current = _performanceHistory[0]['performanceScore'] as int? ?? 0;
    final previous = _performanceHistory[1]['performanceScore'] as int? ?? 0;

    return current - previous;
  }

  @override
  void dispose() {
    disposeDriverProvider();
    super.dispose();
  }
}
