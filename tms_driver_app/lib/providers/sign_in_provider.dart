import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/config/app_config.dart' as env_app_config;
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/network/api_response.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';
import 'package:tms_driver_app/core/network/enhanced_error_handler.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/services/location_service.dart';
import 'package:tms_driver_app/services/native_service_bridge.dart';
import 'package:tms_driver_app/services/session_manager.dart';
import 'package:tms_driver_app/services/tracking_session_manager.dart';
import 'package:tms_driver_app/services/topic_subscription_service.dart';
import 'package:tms_driver_app/utils/error_handler.dart';

import 'app_bootstrap_provider.dart';
import 'user_provider.dart';

class SignInProvider with ChangeNotifier {
  final DioClient _client = DioClient();
  // ----------------------------------------------------------------------------
  // State
  // ----------------------------------------------------------------------------
  bool _isLoading = false;
  String _errorMessage = '';
  bool _inFlight = false; // prevent double-submits
  bool _showRequestApproval = false;
  String? _requestApprovalMessage;
  final bool _enableDeviceApprovalFlow =
      env_app_config.AppConfig.requireApprovedDevice;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get showRequestApproval => _showRequestApproval;
  String? get requestApprovalMessage => _requestApprovalMessage;

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void setShowRequestApproval(bool value) {
    if (_showRequestApproval == value) return;
    _showRequestApproval = value;
    notifyListeners();
  }

  // ----------------------------------------------------------------------------
  // Secure “remember me”
  // ----------------------------------------------------------------------------
  Future<void> saveCredentials(String username, String password) async {
    await _secureStorage.write(key: 'remember_username', value: username);
    await _secureStorage.write(key: 'remember_password', value: password);
  }

  Future<Map<String, String?>> loadSavedCredentials() async {
    final username = await _secureStorage.read(key: 'remember_username');
    final password = await _secureStorage.read(key: 'remember_password');
    return {'username': username, 'password': password};
  }

  Future<void> clearSavedCredentials() async {
    await _secureStorage.delete(key: 'remember_username');
    await _secureStorage.delete(key: 'remember_password');
  }

  // ----------------------------------------------------------------------------
  // Device info (best-effort location)
  // ----------------------------------------------------------------------------
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final fallbackDeviceId = await _getOrCreateDeviceId(null);

    Future<Position?> _tryGetPosition() async {
      try {
        if (!await Geolocator.isLocationServiceEnabled()) return null;
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          return null;
        }
        return await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 2),
        );
      } catch (_) {
        return null;
      }
    }

    final pos = await _tryGetPosition();
    final locString =
        (pos != null) ? '${pos.latitude},${pos.longitude}' : 'unknown';

    if (Platform.isAndroid) {
      final ai = await deviceInfo.androidInfo;
      final deviceId = await _getOrCreateDeviceId(ai.id);
      return {
        'deviceId': deviceId,
        'deviceName': '${ai.brand} ${ai.model}',
        'manufacturer': ai.manufacturer,
        'model': ai.device,
        'os': 'Android',
        'version': ai.version.release,
        'appVersion': packageInfo.version,
        'location': locString,
      };
    } else if (Platform.isIOS) {
      final ii = await deviceInfo.iosInfo;
      final deviceId = await _getOrCreateDeviceId(ii.identifierForVendor);
      return {
        'deviceId': deviceId,
        'deviceName': '${ii.name} ${ii.model}',
        'manufacturer': 'Apple',
        'model': ii.utsname.machine,
        'os': 'iOS',
        'version': ii.systemVersion,
        'appVersion': packageInfo.version,
        'location': locString,
      };
    }

    return {
      'deviceId': fallbackDeviceId,
      'deviceName': 'unknown',
      'manufacturer': 'unknown',
      'model': 'unknown',
      'os': Platform.operatingSystem,
      'version': 'unknown',
      'appVersion': packageInfo.version,
      'location': locString,
    };
  }

  Future<String> _getOrCreateDeviceId(String? rawId) async {
    final trimmed = rawId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('deviceId');
    if (stored != null && stored.trim().isNotEmpty) return stored.trim();

    final rand = Random();
    final generated =
        'drv-${DateTime.now().millisecondsSinceEpoch}-${rand.nextInt(1 << 32)}';
    await prefs.setString('deviceId', generated);
    return generated;
  }

  // ----------------------------------------------------------------------------
  // Small HTTP helper via DioClient
  // ----------------------------------------------------------------------------
  Future<ApiResponse<Map<String, dynamic>>> _postJsonDio(
    String path,
    Map<String, dynamic> body,
    {Map<String, dynamic>? headers}
  ) async {
    return _client.post<Map<String, dynamic>>(
      path,
      data: body,
      headers: headers,
      parser: (raw) =>
          (raw as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> _deviceHeaders(Map<String, String> info) {
    final headers = <String, dynamic>{};

    void put(String key, String? value) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) {
        headers[key] = text;
      }
    }

    put('X-Device-Id', info['deviceId']);
    put('X-Device-Name', info['deviceName']);
    put('X-Device-Os', info['os']);
    put('X-Device-Os-Version', info['version']);
    put('X-App-Version', info['appVersion']);
    put('X-Device-Manufacturer', info['manufacturer']);
    put('X-Device-Model', info['model']);
    return headers;
  }

  String _resolveLocalDirectAuthPath(String apiPath) {
    final defaultPath = ApiConstants.endpoint(apiPath).path;
    try {
      final baseUri = Uri.parse(ApiConstants.baseApiUrl);
      final host = baseUri.host.trim();
      if (host.isEmpty) return defaultPath;

      final isLocalHost = host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '10.0.2.2' ||
          host == '::1';
      final isPrivateIpv4 = RegExp(
        r'^(10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(1[6-9]|2\d|3[0-1])\.\d+\.\d+)$',
      ).hasMatch(host);
      final currentPort = baseUri.hasPort
          ? baseUri.port
          : (baseUri.scheme == 'https' ? 443 : 80);

      if (!(isLocalHost || isPrivateIpv4)) return defaultPath;
      if (currentPort != 8080 && currentPort != 8086) return defaultPath;

      final directAuthUri = baseUri.replace(
        port: 8080,
        path: '/api$apiPath',
        query: null,
        fragment: null,
      );
      return directAuthUri.toString();
    } catch (_) {
      return defaultPath;
    }
  }

  String _extractDriverIdFromLoginPayload(Map<String, dynamic> payload) {
    final candidates = <dynamic>[
      payload['driverId'],
      payload['driver_id'],
      payload['id'],
      payload['driverCode'],
      (payload['driver'] as Map?)?['id'],
      (payload['driver'] as Map?)?['driverId'],
      (payload['data'] as Map?)?['driverId'],
    ];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  Future<String> _resolveDriverIdFromServerFallback(
    String currentDriverId,
  ) async {
    if (currentDriverId.trim().isNotEmpty) return currentDriverId.trim();
    try {
      final path = ApiConstants.endpoint('/driver/current-assignment').path;
      final resp = await _client.get<Map<String, dynamic>>(
        path,
        converter: (raw) =>
            (raw as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      );
      if (!resp.success || resp.data == null) return '';
      final root = resp.data!;
      final data = (root['data'] as Map?)?.cast<String, dynamic>() ?? root;
      final candidates = <dynamic>[
        data['driverId'],
        data['driver_id'],
        root['driverId'],
        root['driver_id'],
      ];
      for (final value in candidates) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
      }
    } catch (_) {
      // best-effort fallback only
    }
    return '';
  }

  // ----------------------------------------------------------------------------
  // Device approval & register
  // ----------------------------------------------------------------------------
  Future<bool> requestDeviceApproval(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    await ApiConstants.ensureInitialized();
    final info = await getDeviceInfo();
    try {
      final path =
          _resolveLocalDirectAuthPath('/driver/device/request-approval');
      final resp = await _postJsonDio(path, {
        'username': username,
        'password': password,
        ...info,
      });

      debugPrint(
          '📩 Request approval: ${resp.statusCode} - Success: ${resp.success}');
      debugPrint('📩 Response: ${resp.message}');

      if (resp.success) {
        _errorMessage =
            'Device approval request sent successfully! Please wait for admin approval.';
        setShowRequestApproval(false);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = resp.message ?? 'Failed to send approval request';
      }
    } catch (e) {
      debugPrint('Request approval failed: $e');
      _errorMessage = 'Network error. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> _refreshNativeTrackingService({
    required String accessToken,
    required String driverId,
  }) async {
    final trackingToken = await ApiConstants.getTrackingToken();
    final trackingSessionId = await ApiConstants.getTrackingSessionId();
    final refreshToken = await ApiConstants.getRefreshToken();

    final updated = await NativeServiceBridge.notifyTokenUpdated(
      token: accessToken,
      trackingToken: trackingToken,
      trackingSessionId: trackingSessionId,
      refreshToken: refreshToken,
    );

    if (updated) {
      debugPrint(
          '[SignIn] Native service updated with fresh access/tracking tokens');
      return;
    }

    final restarted = await NativeServiceBridge.startNativeLocationService(
      token: accessToken,
      driverId: driverId,
    );
    debugPrint(
        '[SignIn] Native service ${restarted ? "restarted" : "failed to restart"} with fresh tokens');
  }

  Future<void> _registerDevice(String driverId) async {
    await ApiConstants.ensureInitialized();
    final info = await getDeviceInfo();

    try {
      final path = ApiConstants.endpoint('/driver/device/register').path;
      final resp = await _postJsonDio(path, {
        'driverId': driverId,
        ...info,
      });
      if (resp.success) {
        debugPrint('📲 Register device: success');
      } else {
        debugPrint(
            '📲 Register device failed: ${resp.statusCode} ${resp.message}');
      }
    } catch (e) {
      debugPrint('Register device error: $e');
    }
  }

  Future<bool> _startTrackingSessionOrHandleFailure(String deviceId) async {
    await ApiConstants.clearTrackingSession();
    final started = await TrackingSessionManager.instance
        .startTrackingSession(deviceIdOverride: deviceId);
    if (started) {
      return true;
    }
    if (!_enableDeviceApprovalFlow) {
      return true;
    }

    _requestApprovalMessage =
        'Unable to start secure tracking for this device. Please confirm the device is approved and try again.';
    _errorMessage = _requestApprovalMessage!;
    setShowRequestApproval(true);
    await ApiConstants.clearTrackingSession();
    await ApiConstants.clearTokens();
    await ApiConstants.clearUser();
    return false;
  }

  // ----------------------------------------------------------------------------
  // Sign-in
  // ----------------------------------------------------------------------------
  Future<bool> signIn(
    BuildContext context,
    String username,
    String password, {
    bool rememberMe = false,
    String? deviceId,
  }) async {
    if (_inFlight) return false;
    _inFlight = true;
    _isLoading = true;
    _errorMessage = '';
    setShowRequestApproval(false);
    notifyListeners();

    await ApiConstants.ensureInitialized();

    // Quick connectivity sanity: resolve the actual API host
    try {
      final host = Uri.parse(ApiConstants.baseApiUrl).host;
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
      if (result.isEmpty || result.first.rawAddress.isEmpty) {
        _errorMessage = 'error.no_internet'.tr();
        return false;
      }
    } on SocketException {
      _errorMessage = 'error.no_internet'.tr();
      return false;
    } catch (_) {
      // continue; server might still be reachable
    }

    final info = await getDeviceInfo();
    final resolvedDeviceId = (deviceId ?? info['deviceId'] ?? '').trim();
    if (!context.mounted) return false;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bootstrapProvider =
        Provider.of<AppBootstrapProvider>(context, listen: false);

    try {
      final path = _resolveLocalDirectAuthPath('/auth/driver/login');
      final ApiResponse<Map<String, dynamic>> resp = await _postJsonDio(
        path,
        {
          'username': username,
          'password': password,
        },
        headers: _deviceHeaders(info),
      );

      final Map<String, dynamic>? data = resp.data;

      if (resp.success && data != null) {
        // Extract the actual login data from the nested structure
        final Map<String, dynamic>? loginData =
            data['data'] as Map<String, dynamic>?;
        if (loginData == null) {
          _errorMessage = 'error.api_malformed'.tr();
          return false;
        }

        final code = loginData['code']?.toString();
        if (code != 'LOGIN_SUCCESS') {
          _setErrorFromServerCode(code, loginData['message']?.toString());
          return false;
        }

        // Persist via ApiConstants (single source of truth)
        debugPrint(
            '[SignIn] About to persist login response. loginData keys: ${loginData.keys.toList()}');
        debugPrint('[SignIn] loginData type: ${loginData.runtimeType}');
        debugPrint('[SignIn] loginData content: $loginData');
        await ApiConstants.persistLoginResponse(loginData);
        final trackingReady =
            await _startTrackingSessionOrHandleFailure(resolvedDeviceId);
        if (!trackingReady) {
          return false;
        }

        // Extract user snapshot for your local providers/UI
        final user = _extractUserMap(loginData);
        final accessToken = await ApiConstants.getAccessToken();
        if ((accessToken == null || accessToken.isEmpty) || user.isEmpty) {
          _errorMessage = 'error.api_malformed'.tr();
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        var resolvedDriverId = _resolveDriverId(user);
        if (resolvedDriverId.isEmpty) {
          resolvedDriverId = _extractDriverIdFromLoginPayload(loginData);
        }
        resolvedDriverId =
            await _resolveDriverIdFromServerFallback(resolvedDriverId);

        final String userId = resolvedDriverId.isNotEmpty
            ? resolvedDriverId
            : _resolveUserId(user);
        final String usernameValue = _resolveUsername(user);
        final String email = (user['email'] ?? '').toString();
        final String driverId = resolvedDriverId;
        final String? zone = user['zone']?.toString();
        final String? status = user['status']?.toString();
        final String? vehicleType = user['vehicleType']?.toString();
        final List<String> roles =
            (user['roles'] as List? ?? []).map((e) => e.toString()).toList();

        await prefs.setString('userId', userId);
        await prefs.setString('email', email);
        await prefs.setString('driverId', driverId);
        if (zone != null) await prefs.setString('driverZone', zone);
        if (vehicleType != null) {
          await prefs.setString('vehicleType', vehicleType);
        }
        await prefs.setStringList('roles', roles);

        // Optional secure cache of token (if used elsewhere)
        // await _secureStorage.write(key: 'token', value: accessToken); // Removed - handled by ApiConstants.persistLoginResponse()

        if (rememberMe) {
          await saveCredentials(username, password);
        } else {
          await clearSavedCredentials();
        }

        if (!context.mounted) return false;

        // Guard widget lifecycle before any context-dependent operations
        if (!context.mounted) return false;
        await userProvider.login(
          userId,
          usernameValue,
          accessToken,
          roles,
          displayName: _resolveDisplayName(user),
          email: email,
          driverId: driverId,
          zone: zone,
          vehicleType: vehicleType,
          status: status,
          refreshToken: await ApiConstants.getRefreshToken(),
        );
        SessionManager.instance.reset();
        if (driverId.isNotEmpty) {
          final driverProvider =
              Provider.of<DriverProvider>(context, listen: false);
          await driverProvider.saveLoggedInDriverId(driverId, accessToken);
        }

        // 🚀 Start background GPS tracking service
        try {
          await _refreshNativeTrackingService(
            accessToken: accessToken,
            driverId: driverId,
          );
        } catch (e) {
          debugPrint('[SignIn] Failed to start GPS service: $e');
          // Continue login even if service fails - user can start manually
        }

        await TopicSubscriptionService().subscribeToDynamicTopics();
        await _registerDevice(driverId);
        try {
          await bootstrapProvider.refreshFromServer(force: true);
        } catch (_) {}

        setShowRequestApproval(false);
        if (!context.mounted) return true;
        return true;
      }

      // Enhanced error parsing using new error handler
      debugPrint('🔍 Processing login failure with enhanced error handler');

      final errorInfo = EnhancedErrorHandler.parseApiError(
        resp.errorData ?? {'message': resp.message},
        resp.statusCode ?? 0,
      );

      // If the server complains about device registration/ID but the app
      // is configured to bypass enterprise approval flows, try a retry
      // without sending a deviceId so public users and App Store reviewers
      // can still sign in when the server isn't enforcing device locks.
      if (!_enableDeviceApprovalFlow &&
          [
            'DEVICE_ID_REQUIRED',
            'DEVICE_NOT_REGISTERED',
            'DEVICE_NOT_APPROVED',
            'DEVICE_PENDING_APPROVAL'
          ].contains(errorInfo.code)) {
        try {
          debugPrint(
              '🔁 Retrying login without deviceId to bypass device lock for public flow');
          final retryResp = await _postJsonDio(
            path,
            {
              'username': username,
              'password': password,
              // omit deviceId intentionally
            },
            headers: _deviceHeaders(info),
          );
          if (retryResp.success && retryResp.data != null) {
            final Map<String, dynamic>? retryData =
                retryResp.data!['data'] as Map<String, dynamic>?;
            if (retryData != null &&
                retryData['code']?.toString() == 'LOGIN_SUCCESS') {
              await ApiConstants.persistLoginResponse(retryData);
              final trackingReady =
                  await _startTrackingSessionOrHandleFailure(resolvedDeviceId);
              if (!trackingReady) {
                return false;
              }
              final user = _extractUserMap(retryData);
              final accessToken = await ApiConstants.getAccessToken();
              if ((accessToken == null || accessToken.isEmpty) ||
                  user.isEmpty) {
                _errorMessage = 'error.api_malformed'.tr();
                return false;
              }
              final prefs = await SharedPreferences.getInstance();
              var resolvedDriverId = _resolveDriverId(user);
              if (resolvedDriverId.isEmpty) {
                resolvedDriverId = _extractDriverIdFromLoginPayload(retryData);
              }
              resolvedDriverId =
                  await _resolveDriverIdFromServerFallback(resolvedDriverId);

              final String userId = resolvedDriverId.isNotEmpty
                  ? resolvedDriverId
                  : _resolveUserId(user);
              final String usernameValue = _resolveUsername(user);
              final String email = (user['email'] ?? '').toString();
              final String driverId = resolvedDriverId;
              final String? zone = user['zone']?.toString();
              final String? status = user['status']?.toString();
              final String? vehicleType = user['vehicleType']?.toString();
              final List<String> roles = (user['roles'] as List? ?? [])
                  .map((e) => e.toString())
                  .toList();
              await prefs.setString('userId', userId);
              await prefs.setString('email', email);
              await prefs.setString('driverId', driverId);
              if (zone != null) await prefs.setString('driverZone', zone);
              if (vehicleType != null) {
                await prefs.setString('vehicleType', vehicleType);
              }
              await prefs.setStringList('roles', roles);
              if (rememberMe) await saveCredentials(username, password);
              await userProvider.login(
                userId,
                usernameValue,
                accessToken,
                roles,
                displayName: _resolveDisplayName(user),
                email: email,
                driverId: driverId,
                zone: zone,
                vehicleType: vehicleType,
                status: status,
                refreshToken: await ApiConstants.getRefreshToken(),
              );
              SessionManager.instance.reset();
              if (driverId.isNotEmpty) {
                final driverProvider =
                    Provider.of<DriverProvider>(context, listen: false);
                await driverProvider.saveLoggedInDriverId(
                    driverId, accessToken);
              }

              // 🚀 Start background GPS tracking service (retry path)
              try {
                await _refreshNativeTrackingService(
                  accessToken: accessToken,
                  driverId: driverId,
                );
              } catch (e) {
                debugPrint('[SignIn] Failed to start GPS service (retry): $e');
              }

              await TopicSubscriptionService().subscribeToDynamicTopics();
              try {
                await bootstrapProvider.refreshFromServer(force: true);
              } catch (_) {}
              // Do not register device in this path
              setShowRequestApproval(false);
              if (!context.mounted) return false;
              return true;
            }
          }
        } catch (e) {
          debugPrint('Retry without deviceId failed: $e');
        }
      }

      debugPrint('Enhanced Error Analysis Complete:');
      debugPrint('  Code: ${errorInfo.code}');
      debugPrint('  Message: ${errorInfo.message}');
      debugPrint('  Show Approval Button: ${errorInfo.showApprovalButton}');

      // Set error state based on enhanced parsing
      _setErrorFromServerCode(errorInfo.code, errorInfo.message);

      // Override approval button state from enhanced analysis only when
      // device-approval flow is enabled. By default we keep it disabled so
      // login is not blocked by enterprise device/admin approval requirements.
      if (_enableDeviceApprovalFlow && errorInfo.showApprovalButton) {
        debugPrint('🔘 Enhanced handler recommends showing approval button');
        setShowRequestApproval(true);
      }
      return false;
    } catch (e) {
      _errorMessage = ErrorHandler.getFriendlyMessage(e);
      return false;
    } finally {
      _isLoading = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------------------------
  // Public self-registration (simple helper)
  // ----------------------------------------------------------------------------
  Future<bool> registerAccount({
    required String username,
    required String password,
    String? email,
    String? name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await ApiConstants.ensureInitialized();
      final path = _resolveLocalDirectAuthPath('/auth/registerdriver');
      // Production APIs may reject unexpected fields (older deployed servers).
      // Avoid sending `name` by default to be compatible with deployed backends.
      final resp = await _postJsonDio(path, {
        'username': username,
        'password': password,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      });

      if (resp.success) {
        // registration accepted; backend may still require approval
        return true;
      }

      _errorMessage = resp.message ?? 'Registration failed';
      return false;
    } catch (e) {
      debugPrint('registerAccount error: $e');
      _errorMessage = 'Network error. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setErrorFromServerCode(String? code, String? serverMessage) {
    final tail = (serverMessage == null || serverMessage.isEmpty)
        ? ''
        : ' — $serverMessage';
    switch (code) {
      case 'USER_NOT_FOUND':
        _errorMessage = "🙅 ${'signin.error_user_not_found'.tr()}$tail";
        break;
      case 'USER_DISABLED':
        _errorMessage = "🚫 ${'signin.error_user_disabled'.tr()}$tail";
        break;
      case 'USER_LOCKED':
        _errorMessage = "${'signin.error_user_locked'.tr()}$tail";
        break;
      case 'NOT_DRIVER':
        _errorMessage = "${'signin.error_not_driver'.tr()}$tail";
        break;
      case 'DRIVER_NOT_FOUND':
        _errorMessage = "🧍 ${'signin.error_driver_not_found'.tr()}$tail";
        break;
      case 'DEVICE_ID_REQUIRED':
        _errorMessage = "📱 ${'signin.error_device_id_required'.tr()}$tail";
        break;
      case 'DEVICE_NOT_REGISTERED':
      case 'DEVICE_REJECTED':
      case 'DEVICE_NOT_APPROVED':
      case 'DEVICE_PENDING_APPROVAL':
      case 'DEVICE_BLOCKED':
        // Prefer the server message for clarity; surface it to the UI
        _requestApprovalMessage = (serverMessage?.isNotEmpty == true)
            ? serverMessage!
            : 'signin.error_device_not_approved'.tr();
        _errorMessage = _requestApprovalMessage!;
        // Only show the approval UI when the device-approval flow is enabled.
        if (_enableDeviceApprovalFlow) setShowRequestApproval(true);
        break;
      case 'DEVICE_ACTIVE_ON_OTHER_PHONE':
        _requestApprovalMessage = (serverMessage?.isNotEmpty == true)
            ? serverMessage!
            : 'This account is already active on another phone.';
        _errorMessage = _requestApprovalMessage!;
        setShowRequestApproval(false);
        break;
      case 'INVALID_CREDENTIALS':
        _errorMessage = "🔑 ${'signin.error_invalid_credentials'.tr()}$tail";
        break;
      default:
        _errorMessage = (serverMessage?.isNotEmpty == true)
            ? serverMessage!
            : 'error.unexpected'.tr();
    }
  }

  // ----------------------------------------------------------------------------
  // Sign-out
  // ----------------------------------------------------------------------------
  Future<void> signOut(BuildContext context) async {
    try {
      final bootstrapProvider =
          Provider.of<AppBootstrapProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await _performSignOutCleanup(
        userProvider: userProvider,
        bootstrapProvider: bootstrapProvider,
      );

      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.signin, (_) => false);
    } catch (e) {
      debugPrint('signOut error: $e');
    }
  }

  Future<void> forceSignOut({
    UserProvider? userProvider,
    AppBootstrapProvider? bootstrapProvider,
  }) async {
    try {
      await _performSignOutCleanup(
        userProvider: userProvider,
        bootstrapProvider: bootstrapProvider,
      );
    } catch (e) {
      debugPrint('forceSignOut error: $e');
    }
  }

  Future<void> _performSignOutCleanup({
    UserProvider? userProvider,
    AppBootstrapProvider? bootstrapProvider,
  }) async {
    await NativeServiceBridge.stopNativeLocationService();
    await LocationService().stop();
    await TrackingSessionManager.instance.stopTrackingSession();
    await ApiConstants.clearTokens();
    await ApiConstants.clearUser();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('email');
    await prefs.remove('driverId');
    await prefs.remove('driverZone');
    await prefs.remove('vehicleType');
    await prefs.remove('roles');
    await prefs.remove('displayName');

    await TopicSubscriptionService().unsubscribeFromAllTopics();
    await bootstrapProvider?.clear();
    await userProvider?.logout();
  }

  String _resolveDisplayName(Map<String, dynamic> user) {
    final candidates = <String?>[
      user['displayName']?.toString(),
      user['name']?.toString(),
      _joinNameParts(user['firstName'], user['lastName']),
      user['username']?.toString(),
    ];
    for (final candidate in candidates) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return 'Driver';
  }

  Map<String, dynamic> _extractUserMap(Map<String, dynamic> payload) {
    final dynamic rawUser = payload['user'];
    if (rawUser is Map<String, dynamic>) return rawUser;
    if (rawUser is Map) {
      return rawUser.map((key, value) => MapEntry(key.toString(), value));
    }
    final dynamic altUser = payload['driver'];
    if (altUser is Map<String, dynamic>) return altUser;
    if (altUser is Map) {
      return altUser.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  String _resolveDriverId(Map<String, dynamic> user) {
    final candidates = <dynamic>[
      user['driverId'],
      user['driver_id'],
      user['id'],
      user['driverCode'],
    ];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  String _resolveUsername(Map<String, dynamic> user) {
    final candidates = <dynamic>[
      user['username'],
      user['userName'],
      user['email'],
    ];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  String _resolveUserId(Map<String, dynamic> user) {
    final driverId = _resolveDriverId(user);
    if (driverId.isNotEmpty) return driverId;
    final username = _resolveUsername(user);
    if (username.isNotEmpty) return username;
    return '';
  }

  String? _joinNameParts(dynamic firstName, dynamic lastName) {
    final first = firstName?.toString().trim() ?? '';
    final last = lastName?.toString().trim() ?? '';
    final fullName = '$first $last'.trim();
    return fullName.isEmpty ? null : fullName;
  }
}
