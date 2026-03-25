import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; //  Add for cache
import 'package:tms_driver_app/constants/dispatch_constants.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/network/api_response.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';

import 'package:tms_driver_app/core/repositories/dispatch_repository.dart';
import 'package:tms_driver_app/models/dispatch_action_metadata.dart';

class DispatchProvider with ChangeNotifier {
  final DioClient _dio = DioClient();
  final DispatchRepository dispatchRepository;

  DispatchProvider({required this.dispatchRepository});

  // ---- Networking helpers (timeouts + retries) ----
  static const int _maxRetries = 2; // total tries = 1 + _maxRetries

  Future<T> _retry<T>(Future<T> Function() run, {String? label}) async {
    int attempt = 0;
    while (true) {
      try {
        return await run();
      } catch (e) {
        if (attempt >= _maxRetries) rethrow;
        final backoff = Duration(milliseconds: 400 * (1 << attempt));
        _log(
            '[retry] ${label ?? ''} attempt=${attempt + 1} error=$e -> delay=$backoff');
        await Future.delayed(backoff);
        attempt++;
      }
    }
  }

  void _log(String msg) {
    // Toggle this to false if you want to silence provider logs
    const bool enable = true;
    if (enable) debugPrint('DispatchProvider: $msg');
  }

  String _proofUploadErrorMessage(
    dynamic responseData, {
    int? statusCode,
    required String fallback,
  }) {
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
      final errors = responseData['errors'];
      if (errors is Map) {
        final firstError = errors.values
            .map((e) => e?.toString().trim() ?? '')
            .firstWhere((e) => e.isNotEmpty, orElse: () => '');
        if (firstError.isNotEmpty) {
          return firstError;
        }
      }
    }
    return statusCode == null ? fallback : '$fallback ($statusCode)';
  }

  // Note: JSON endpoints use DioClient; only multipart uses http.Client

  List<Map<String, dynamic>> _dispatches = [];

  // Separate lists for each status group
  List<Map<String, dynamic>> _pendingDispatches = [];
  List<Map<String, dynamic>> _inProgressDispatches = [];
  List<Map<String, dynamic>> _completedDispatches = [];

  String? _cacheDriverId;

  // Status constants - aligned with backend dispatch lifecycle.
  static const Set<String> _pendingStatusSet = {
    DispatchStatus.pending,
    DispatchStatus.scheduled,
    DispatchStatus.assigned,
  };
  static const Set<String> _inProgressStatusSet = {
    DispatchStatus.driverConfirmed,
    DispatchStatus.arrivedLoading,
    DispatchStatus.inQueue,
    DispatchStatus.loading,
    DispatchStatus.loaded,
    DispatchStatus.atHub,
    DispatchStatus.hubLoading,
    DispatchStatus.inTransit,
    DispatchStatus.inTransitBreakdown,
    DispatchStatus.pendingInvestigation,
    DispatchStatus.arrivedUnloading,
    DispatchStatus.unloading,
    DispatchStatus.unloaded,
    DispatchStatus.approved,
    DispatchStatus.safetyPassed,
    DispatchStatus.safetyFailed,
  };
  static const Set<String> _terminalStatusSet = {
    DispatchStatus.delivered,
    DispatchStatus.financialLocked,
    DispatchStatus.closed,
    DispatchStatus.completed,
    DispatchStatus.cancelled,
    DispatchStatus.rejected,
  };
  static const Set<String> _completedStatusSet = _terminalStatusSet;

  // Loading states for each tab
  bool _isLoadingPending = false;
  bool _isLoadingInProgress = false;
  bool _isLoadingCompleted = false;
  DateTime? _lastPendingFetchAt;
  DateTime? _lastInProgressFetchAt;
  static const Duration _homeFetchCooldown = Duration(seconds: 20);

  // Cache for available actions with TTL
  final Map<String, _CachedActions> _availableActionsCache = {};
  static const Duration _availableActionsTTL = Duration(seconds: 30);
  DispatchActionsResponse? _lastActionsResponse;
  String? _lastActionsDispatchId;

  List<Map<String, dynamic>> get dispatches => _dispatches;
  List<Map<String, dynamic>> get pendingDispatches => _pendingDispatches;
  List<Map<String, dynamic>> get inProgressDispatches => _inProgressDispatches;
  List<Map<String, dynamic>> get completedDispatches => _completedDispatches;

  bool get isLoadingPending => _isLoadingPending;
  bool get isLoadingInProgress => _isLoadingInProgress;
  bool get isLoadingCompleted => _isLoadingCompleted;
  DispatchActionsResponse? get lastActionsResponse => _lastActionsResponse;
  String? get lastActionsDispatchId => _lastActionsDispatchId;

  static const String _cacheKeyBase =
      'cached_dispatches'; // Local cache key base
  static const String _pendingCacheKeyBase = 'cached_pending_dispatches';
  static const String _inProgressCacheKeyBase = 'cached_in_progress_dispatches';
  static const String _completedCacheKeyBase = 'cached_completed_dispatches';

  String _keyFor(String base, String driverId) => '${base}_$driverId';

  String _fileNameOf(File f) {
    final p = f.path;
    final i = p.lastIndexOf('/');
    return (i >= 0) ? p.substring(i + 1) : p;
  }

  String _buildIdempotencyKey(String proofType, String dispatchId) {
    final random = Random.secure();
    final suffix = List.generate(
      8,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return '$proofType-$dispatchId-${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }

  // ---- Image compression helpers ----
  static const int _compressThresholdBytes = 400 * 1024; // compress if > 400KB
  static const int _targetQuality = 80; // 0-100
  static const int _minWidth = 1280; // keep reasonably large for clear proof

  Future<File> _compressIfNeeded(File original) async {
    try {
      final length = await original.length();
      if (length <= _compressThresholdBytes) return original; // small enough

      final tmpDir = Directory.systemTemp;
      final outPath =
          '${tmpDir.path}/dp_${DateTime.now().millisecondsSinceEpoch}_${_fileNameOf(original)}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        original.absolute.path,
        outPath,
        quality: _targetQuality,
        minWidth: _minWidth,
        format: CompressFormat.jpeg,
      );

      if (result == null) return original; // fallback if compression failed
      final outFile = File(result.path);
      _log(
          'Compressed ${_fileNameOf(original)}: ${length}B -> ${await outFile.length()}B');
      return outFile;
    } catch (e) {
      _log('Compression failed for ${_fileNameOf(original)}: $e');
      return original; // fail open
    }
  }

  /// Fetch dispatches (with fallback to local cache if API fails)
  Future<void> fetchDispatches({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final now = DateTime.now();
      startDate ??= DateTime(now.year, now.month, 1);
      endDate ??= DateTime(now.year, now.month + 1, 0);

      final from = DateFormat('yyyy-MM-dd').format(startDate);
      final to = DateFormat('yyyy-MM-dd').format(endDate);

      final path =
          ApiConstants.endpoint('/driver/dispatches/driver/$driverId').path;
      final ApiResponse<Map<String, dynamic>> res =
          await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'from': from,
          'to': to,
          'page': page.toString(),
          'size': size.toString(),
        },
        converter: (data) => (data as Map).cast<String, dynamic>(),
      );

      if (res.success) {
        final decoded = res.data!;
        _dispatches = List<Map<String, dynamic>>.from(decoded['content'] ?? []);
        _cacheDriverId = driverId;
        _categorizeDispatches(rebuildCaches: true);
        notifyListeners();
      } else {
        debugPrint(' API failed ${res.statusCode}, loading cache...');
        await _loadFromCache(driverId);
      }
    } catch (e) {
      debugPrint(' Error fetching dispatches: $e, loading cache...');
      await _loadFromCache(driverId);
    }
  }

  /// Save dispatch list to local storage
  Future<void> _saveToCache(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _keyFor(_cacheKeyBase, driverId), jsonEncode(_dispatches));
    } catch (e) {
      debugPrint(' Error saving cache: $e');
    }
  }

  /// Save pending dispatch list to local storage
  Future<void> _savePendingToCache(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(_pendingCacheKeyBase, driverId),
          jsonEncode(_pendingDispatches));
    } catch (e) {
      debugPrint(' Error saving pending cache: $e');
    }
  }

  /// Save in-progress dispatch list to local storage
  Future<void> _saveInProgressToCache(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(_inProgressCacheKeyBase, driverId),
          jsonEncode(_inProgressDispatches));
    } catch (e) {
      debugPrint(' Error saving in-progress cache: $e');
    }
  }

  /// Save completed dispatch list to local storage
  Future<void> _saveCompletedToCache(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(_completedCacheKeyBase, driverId),
          jsonEncode(_completedDispatches));
    } catch (e) {
      debugPrint(' Error saving completed cache: $e');
    }
  }

  /// Load dispatch list from local storage
  Future<void> _loadFromCache(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyFor(_cacheKeyBase, driverId));

      if (cachedData != null) {
        final List<dynamic> data = jsonDecode(cachedData);
        _dispatches = data.map((e) => Map<String, dynamic>.from(e)).toList();
        _cacheDriverId = driverId;
        _categorizeDispatches();
        notifyListeners();
        debugPrint(' Loaded dispatches from cache');
      } else {
        _dispatches = [];
        debugPrint(' No cached dispatches available');
      }
    } catch (e) {
      debugPrint(' Error loading cache: $e');
    }
  }

  /// Load pending dispatch list from local storage
  Future<void> _loadPendingFromCache(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData =
          prefs.getString(_keyFor(_pendingCacheKeyBase, driverId));

      if (cachedData != null) {
        final List<dynamic> data = jsonDecode(cachedData);
        _pendingDispatches =
            data.map((e) => Map<String, dynamic>.from(e)).toList();
        notifyListeners();
        debugPrint(' Loaded pending dispatches from cache');
      } else {
        _pendingDispatches = [];
        debugPrint(' No cached pending dispatches available');
      }
    } catch (e) {
      debugPrint(' Error loading pending cache: $e');
    }
  }

  /// Load in-progress dispatch list from local storage
  Future<void> _loadInProgressFromCache(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData =
          prefs.getString(_keyFor(_inProgressCacheKeyBase, driverId));

      if (cachedData != null) {
        final List<dynamic> data = jsonDecode(cachedData);
        _inProgressDispatches =
            data.map((e) => Map<String, dynamic>.from(e)).toList();
        notifyListeners();
        debugPrint(' Loaded in-progress dispatches from cache');
      } else {
        _inProgressDispatches = [];
        debugPrint(' No cached in-progress dispatches available');
      }
    } catch (e) {
      debugPrint(' Error loading in-progress cache: $e');
    }
  }

  /// Load completed dispatch list from local storage
  Future<void> _loadCompletedFromCache(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData =
          prefs.getString(_keyFor(_completedCacheKeyBase, driverId));

      if (cachedData != null) {
        final List<dynamic> data = jsonDecode(cachedData);
        _completedDispatches =
            data.map((e) => Map<String, dynamic>.from(e)).toList();
        notifyListeners();
        debugPrint(' Loaded completed dispatches from cache');
      } else {
        _completedDispatches = [];
        debugPrint(' No cached completed dispatches available');
      }
    } catch (e) {
      debugPrint(' Error loading completed cache: $e');
    }
  }

  String? _dispatchIdFromMap(Map<String, dynamic> dispatch) {
    final idCandidate = dispatch['id'] ??
        dispatch['dispatchId'] ??
        dispatch['dispatch_id'] ??
        dispatch['dispatchID'];
    return idCandidate?.toString();
  }

  String _dispatchStatus(Map<String, dynamic> dispatch) {
    return (dispatch['status'] ?? '').toString().toUpperCase().trim();
  }

  bool _isPendingDispatch(Map<String, dynamic> dispatch) {
    return _pendingStatusSet.contains(_dispatchStatus(dispatch));
  }

  bool _isInProgressDispatch(Map<String, dynamic> dispatch) {
    return _inProgressStatusSet.contains(_dispatchStatus(dispatch));
  }

  bool _isCompletedDispatch(Map<String, dynamic> dispatch) {
    return _completedStatusSet.contains(_dispatchStatus(dispatch));
  }

  Map<String, dynamic>? _unwrapMapPayload(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final nested = payload['data'];
      if (nested is Map<String, dynamic>) return nested;
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return payload;
    }
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final nested = map['data'];
      if (nested is Map<String, dynamic>) return nested;
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return map;
    }
    return null;
  }

  void _categorizeDispatches({bool rebuildCaches = false}) {
    _pendingDispatches = [];
    _inProgressDispatches = [];
    _completedDispatches = [];

    for (final dispatch in _dispatches) {
      if (_isPendingDispatch(dispatch)) {
        _pendingDispatches.add(dispatch);
      } else if (_isInProgressDispatch(dispatch)) {
        _inProgressDispatches.add(dispatch);
      } else if (_isCompletedDispatch(dispatch)) {
        _completedDispatches.add(dispatch);
      }
    }

    if (rebuildCaches && _cacheDriverId != null) {
      final driverId = _cacheDriverId!;
      unawaited(_saveToCache(driverId));
      unawaited(_savePendingToCache(driverId));
      unawaited(_saveInProgressToCache(driverId));
      unawaited(_saveCompletedToCache(driverId));
    }
  }

  Future<Map<String, dynamic>?> getDispatchById(String dispatchId) async {
    try {
      final ApiResponse<Map<String, dynamic>> res =
          await _dio.get<Map<String, dynamic>>(
        ApiConstants.endpoint('/driver/dispatches/$dispatchId').path,
        converter: (data) => (data as Map).cast<String, dynamic>(),
      );

      if (res.success) {
        return _unwrapMapPayload(res.data);
      } else {
        _log('Failed to fetch dispatch by ID: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      _log('Error fetching dispatch by ID: $e');
      return null;
    }
  }

  /// Fetch available action metadata for a dispatch (dynamic workflow)
  /// Returns DispatchActionsResponse with full action metadata from backend
  /// Uses caching with 30-second TTL to avoid excessive API calls
  Future<DispatchActionsResponse?> getAvailableActions(
      String dispatchId) async {
    // Check cache first
    final cached = _availableActionsCache[dispatchId];
    if (cached != null && cached.isValid) {
      _log(
          'Returning cached available actions for $dispatchId: ${cached.response.availableActions.length} actions');
      return cached.response;
    }

    try {
      final ApiResponse<Map<String, dynamic>> res =
          await _dio.get<Map<String, dynamic>>(
        ApiConstants.endpoint(
                '/driver/dispatches/$dispatchId/available-actions')
            .path,
        converter: (data) => (data as Map).cast<String, dynamic>(),
      );

      if (res.success && res.data != null) {
        final data = _unwrapMapPayload(res.data);
        if (data != null) {
          final response = DispatchActionsResponse.fromJson(data);
          // Cache the result
          _availableActionsCache[dispatchId] =
              _CachedActions(response: response, cachedAt: DateTime.now());
          _lastActionsDispatchId = dispatchId;
          _lastActionsResponse = response;
          _log(
              'Fetched ${response.availableActions.length} available actions for $dispatchId');
          return response;
        }
      }
      _log('Failed to fetch available actions: ${res.statusCode}');
      return null;
    } catch (e) {
      _log('Error fetching available actions: $e');
      return null;
    }
  }

  /// Fetch dispatch by transport order id (driver-scoped).
  /// Backend must expose /driver/dispatches/by-order/{orderId}
  Future<Map<String, dynamic>?> getDispatchByOrderId(String orderId) async {
    try {
      final ApiResponse<Map<String, dynamic>> res =
          await _dio.get<Map<String, dynamic>>(
        ApiConstants.endpoint('/driver/dispatches/by-order/$orderId').path,
        converter: (data) => (data as Map).cast<String, dynamic>(),
      );

      if (res.success) {
        return _unwrapMapPayload(res.data);
      } else {
        _log('Failed to fetch dispatch by orderId: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      _log('Error fetching dispatch by orderId: $e');
      return null;
    }
  }

  @protected
  Future<ApiResponse<Map<String, dynamic>>> patchDispatchStatusRequest(
    String dispatchId,
    Map<String, dynamic> body,
  ) {
    return _dio.patch<Map<String, dynamic>>(
      ApiConstants.endpoint('/driver/dispatches/$dispatchId/status').path,
      data: body,
      converter: (data) => (data as Map).cast<String, dynamic>(),
      parser: (raw) => (raw as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  Future<void> updateDispatchStatus(
    String dispatchId,
    String newStatus, {
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final payload = <String, dynamic>{'status': newStatus};
      if (reason != null && reason.trim().isNotEmpty) {
        payload['reason'] = reason.trim();
      }
      if (metadata != null && metadata.isNotEmpty) {
        payload['metadata'] = metadata;
      }
      final ApiResponse<Map<String, dynamic>> res =
          await patchDispatchStatusRequest(dispatchId, payload);

      if (res.success) {
        final updated = _castResponsePayload(res.data?['data']);
        if (updated != null) {
          _replaceDispatchData(updated);
        } else {
          _applyStatusLocally(dispatchId, newStatus);
        }
        // Clear cache after successful status update
        clearAvailableActionsCache(dispatchId);
      } else {
        throw Exception(
            'Failed to update status: ${res.statusCode ?? 0} ${res.message ?? ''}'
                .trim());
      }
    } catch (e) {
      _log('Error updating status: $e');
      rethrow;
    }
  }

  Future<void> acceptDispatch(String dispatchId) async {
    try {
      final ApiResponse<Map<String, dynamic>> res =
          await _dio.post<Map<String, dynamic>>(
        ApiConstants.endpoint('/driver/dispatches/$dispatchId/accept').path,
        data: null,
        converter: (data) => (data as Map).cast<String, dynamic>(),
        parser: (raw) => (raw as Map?)?.cast<String, dynamic>() ?? {},
      );

      if (res.success) {
        final updated = _castResponsePayload(res.data?['data']);
        if (updated != null) {
          _replaceDispatchData(updated);
        } else {
          _applyStatusLocally(dispatchId, 'DRIVER_CONFIRMED');
        }
        // Clear cache after successful accept
        clearAvailableActionsCache(dispatchId);
      } else {
        throw Exception(' Failed to accept dispatch: ${res.statusCode}');
      }
    } catch (e) {
      _log('Error accepting dispatch: $e');
      rethrow;
    }
  }

  Future<void> rejectDispatch(String dispatchId, String reason) async {
    try {
      final String path = ApiConstants.endpoint(
              '/driver/dispatches/$dispatchId/reject?reason=${Uri.encodeComponent(reason)}')
          .path;
      final ApiResponse<Map<String, dynamic>> res =
          await _dio.post<Map<String, dynamic>>(
        path,
        data: null,
        converter: (data) => (data as Map).cast<String, dynamic>(),
        parser: (raw) => (raw as Map?)?.cast<String, dynamic>() ?? {},
      );

      if (res.success) {
        final updated = _castResponsePayload(res.data?['data']);
        if (updated != null) {
          _replaceDispatchData(updated);
        } else {
          _applyStatusLocally(dispatchId, 'REJECTED');
        }
        // Clear cache after successful rejection
        clearAvailableActionsCache(dispatchId);
      } else {
        throw Exception(' Failed to reject dispatch: ${res.statusCode}');
      }
    } catch (e) {
      _log('Error rejecting dispatch: $e');
      rethrow;
    }
  }

  /// Reports a vehicle breakdown during transit.
  /// Calls POST /api/driver/dispatches/{id}/breakdown
  Future<void> reportBreakdown(
    String dispatchId, {
    String? location,
    String? description,
    double? lat,
    double? lng,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (location != null && location.trim().isNotEmpty) {
        payload['location'] = location.trim();
      }
      if (description != null && description.trim().isNotEmpty) {
        payload['description'] = description.trim();
      }
      if (lat != null) payload['lat'] = lat;
      if (lng != null) payload['lng'] = lng;

      final ApiResponse<Map<String, dynamic>> res =
          await _dio.post<Map<String, dynamic>>(
        ApiConstants.endpoint('/driver/dispatches/$dispatchId/breakdown').path,
        data: payload,
        converter: (data) => (data as Map).cast<String, dynamic>(),
        parser: (raw) => (raw as Map?)?.cast<String, dynamic>() ?? {},
      );

      if (res.success) {
        final updated = _castResponsePayload(res.data?['data']);
        if (updated != null) {
          _replaceDispatchData(updated);
        } else {
          _applyStatusLocally(dispatchId, DispatchStatus.inTransitBreakdown);
        }
        clearAvailableActionsCache(dispatchId);
      } else {
        throw Exception(
            'Failed to report breakdown: ${res.statusCode ?? 0} ${res.message ?? ''}'
                .trim());
      }
    } catch (e) {
      _log('Error reporting breakdown: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? _castResponsePayload(dynamic payload) {
    if (payload == null) return null;
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return null;
  }

  void _replaceDispatchData(Map<String, dynamic> updated) {
    final updatedId = _dispatchIdFromMap(updated);
    if (updatedId == null) return;

    final index = _dispatches
        .indexWhere((dispatch) => _dispatchIdFromMap(dispatch) == updatedId);

    if (index >= 0) {
      _dispatches[index] = updated;
    } else {
      _dispatches.add(updated);
    }

    _categorizeDispatches(rebuildCaches: _cacheDriverId != null);
    notifyListeners();
  }

  void _applyStatusLocally(String dispatchId, String newStatus) {
    final index = _dispatches
        .indexWhere((dispatch) => _dispatchIdFromMap(dispatch) == dispatchId);
    if (index < 0) return;

    final updated = Map<String, dynamic>.from(_dispatches[index]);
    updated['status'] = newStatus;
    _dispatches[index] = updated;

    _categorizeDispatches(rebuildCaches: _cacheDriverId != null);
    notifyListeners();
  }

  Future<void> fetchDispatchesByDriver(
    String driverId, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    await fetchDispatches(
      driverId: driverId,
      startDate: fromDate,
      endDate: toDate,
    );
  }

  /// Fetch pending dispatches (PENDING, ASSIGNED)
  Future<void> fetchPendingDispatches({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
    bool force = false,
  }) async {
    final now = DateTime.now();
    final recentPending = _lastPendingFetchAt != null &&
        now.difference(_lastPendingFetchAt!) < _homeFetchCooldown;
    if (!force && recentPending && _pendingDispatches.isNotEmpty) {
      return;
    }

    _isLoadingPending = true;
    notifyListeners();

    try {
      final dispatches = await dispatchRepository.getMyPendingDispatches();
      // Backend filters pending bucket statuses; keep as-is and cache.
      _pendingDispatches = dispatches;
      _lastPendingFetchAt = DateTime.now();
      await _savePendingToCache(driverId);
      notifyListeners();
    } catch (e) {
      debugPrint(' Error fetching pending dispatches: $e, loading cache...');
      await _loadPendingFromCache(driverId);
    } finally {
      _isLoadingPending = false;
      notifyListeners();
    }
  }

  /// Fetch processing (not completed/cancelled) dispatches
  Future<void> fetchInProgressDispatches({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
    bool force = false,
  }) async {
    final now = DateTime.now();
    final recentInProgress = _lastInProgressFetchAt != null &&
        now.difference(_lastInProgressFetchAt!) < _homeFetchCooldown;
    if (!force && recentInProgress && _inProgressDispatches.isNotEmpty) {
      return;
    }

    _isLoadingInProgress = true;
    notifyListeners();

    try {
      final dispatches = await dispatchRepository.getMyInProgressDispatches();
      // Backend filters in-progress bucket statuses; keep as-is and cache.
      _inProgressDispatches = dispatches;
      _lastInProgressFetchAt = DateTime.now();
      await _saveInProgressToCache(driverId);
      notifyListeners();
    } catch (e) {
      debugPrint(
          ' Error fetching in-progress dispatches: $e, loading cache...');
      await _loadInProgressFromCache(driverId);
    } finally {
      _isLoadingInProgress = false;
      notifyListeners();
    }
  }

  /// Fetch completed dispatches (DELIVERED, CLOSED, CANCELLED)
  Future<void> fetchCompletedDispatches({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoadingCompleted = true;
    notifyListeners();

    try {
      final dispatches = await dispatchRepository.getMyCompletedDispatches();
      // Backend filters completed bucket statuses; keep as-is and cache.
      _completedDispatches = dispatches;
      await _saveCompletedToCache(driverId);
      notifyListeners();
    } catch (e) {
      debugPrint(' Error fetching completed dispatches: $e, loading cache...');
      await _loadCompletedFromCache(driverId);
    } finally {
      _isLoadingCompleted = false;
      notifyListeners();
    }
  }

  /// Fetch completed dispatches (DELIVERED, CANCELLED)
  Future<void> fetchCompletedDispatchesByDateToDate({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoadingCompleted = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      startDate ??= DateTime(now.year, now.month, 1);
      endDate ??= DateTime(now.year, now.month + 1, 0);

      final from = DateFormat('yyyy-MM-dd').format(startDate);
      final to = DateFormat('yyyy-MM-dd').format(endDate);

      final path =
          ApiConstants.endpoint('/driver/dispatches/driver/$driverId/status')
              .path;
      final ApiResponse<Map<String, dynamic>> res =
          await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'from': from,
          'to': to,
          'status': 'DELIVERED,CANCELLED',
          'sort': 'startTime,DESC',
        },
        converter: (data) => (data as Map).cast<String, dynamic>(),
      );

      if (res.success) {
        final decoded = res.data!;
        final items = List<Map<String, dynamic>>.from(decoded['content'] ?? []);
        // Backend already filters for completed statuses - no need to re-filter
        _completedDispatches = items;
        await _saveCompletedToCache(driverId);
        notifyListeners();
      } else {
        debugPrint(' API failed ${res.statusCode}, loading cache...');
        await _loadCompletedFromCache(driverId);
      }
    } catch (e) {
      debugPrint(' Error fetching completed dispatches: $e, loading cache...');
      await _loadCompletedFromCache(driverId);
    } finally {
      _isLoadingCompleted = false;
      notifyListeners();
    }
  }

  Future<void> uploadLoadProof(String dispatchId, File file) async {
    File? tempToDelete;
    try {
      final toSend = await _compressIfNeeded(file);
      if (!identical(toSend, file)) tempToDelete = toSend; // mark for cleanup

      final String path =
          ApiConstants.endpoint('/driver/dispatches/$dispatchId/load').path;

      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          toSend.path,
          filename: _fileNameOf(toSend),
        ),
      });

      final resolvedPath = _dio.resolvePath(path);
      final res = await _retry(
        () => _dio.dio.post(resolvedPath,
            data: form, options: Options(contentType: 'multipart/form-data')),
        label: 'uploadLoadProof',
      );

      if (res.statusCode != 200) {
        throw Exception(' Upload failed: ${res.statusCode}');
      }
    } catch (e) {
      _log('Error uploading load proof: $e');
      rethrow;
    } finally {
      if (tempToDelete != null && await tempToDelete.exists()) {
        try {
          await tempToDelete.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> markAsLoaded(String dispatchId) async {
    try {
      await updateDispatchStatus(dispatchId, 'LOADED');
    } catch (e) {
      _log('Error marking as loaded: $e');
      rethrow;
    }
  }

  Future<void> submitLoadProof({
    required String dispatchId,
    required List<File> images,
    File? signature,
    String? remarks,
  }) async {
    final String path =
        ApiConstants.endpoint('/driver/dispatches/$dispatchId/load').path;

    final List<File> temps = [];
    try {
      final compressedImages = await Future.wait(images.map((f) async {
        final c = await _compressIfNeeded(f);
        if (!identical(c, f)) temps.add(c);
        return c;
      }));
      final File? compressedSig =
          signature == null ? null : await _compressIfNeeded(signature);
      if (compressedSig != null && !identical(compressedSig, signature)) {
        temps.add(compressedSig);
      }

      final form = FormData();
      final idempotencyKey = _buildIdempotencyKey('POL', dispatchId);
      form.fields.add(MapEntry('idempotencyKey', idempotencyKey));
      if (remarks != null) form.fields.add(MapEntry('remarks', remarks));
      // images
      for (final img in compressedImages) {
        form.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(img.path, filename: _fileNameOf(img)),
        ));
      }
      // signature
      if (compressedSig != null) {
        form.files.add(MapEntry(
          'signature',
          await MultipartFile.fromFile(
            compressedSig.path,
            filename: _fileNameOf(compressedSig),
          ),
        ));
      }

      final resolvedPath = _dio.resolvePath(path);
      final res = await _retry(
        () => _dio.dio.post(resolvedPath,
            data: form,
            options: Options(
              contentType: 'multipart/form-data',
              headers: {'X-Idempotency-Key': idempotencyKey},
            )),
        label: 'submitLoadProof',
      );

      if (res.statusCode != 200) {
        throw Exception(_proofUploadErrorMessage(
          res.data,
          statusCode: res.statusCode,
          fallback: 'Failed to submit load proof',
        ));
      }
      // Proof submission can advance workflow status server-side.
      // Clear action cache so next available-actions fetch is fresh.
      clearAvailableActionsCache(dispatchId);
    } catch (e) {
      _log('Error uploading load proof: $e');
      rethrow;
    } finally {
      for (final f in temps) {
        try {
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> submitUnloadProof({
    required String dispatchId,
    required List<File> images,
    File? signature,
    String? remarks,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final String path =
        ApiConstants.endpoint('/driver/dispatches/$dispatchId/unload').path;

    final List<File> temps = [];
    try {
      final compressedImages = await Future.wait(images.map((f) async {
        final c = await _compressIfNeeded(f);
        if (!identical(c, f)) temps.add(c);
        return c;
      }));
      final File? compressedSig =
          signature == null ? null : await _compressIfNeeded(signature);
      if (compressedSig != null && !identical(compressedSig, signature)) {
        temps.add(compressedSig);
      }

      final form = FormData();
      final idempotencyKey = _buildIdempotencyKey('POD', dispatchId);
      form.fields.add(MapEntry('idempotencyKey', idempotencyKey));
      if (remarks != null) form.fields.add(MapEntry('remarks', remarks));
      if (address != null) form.fields.add(MapEntry('address', address));
      if (latitude != null) {
        form.fields.add(MapEntry('latitude', latitude.toString()));
      }
      if (longitude != null) {
        form.fields.add(MapEntry('longitude', longitude.toString()));
      }
      for (final img in compressedImages) {
        form.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(img.path, filename: _fileNameOf(img)),
        ));
      }
      if (compressedSig != null) {
        form.files.add(MapEntry(
          'signature',
          await MultipartFile.fromFile(
            compressedSig.path,
            filename: _fileNameOf(compressedSig),
          ),
        ));
      }

      final resolvedPath = _dio.resolvePath(path);
      final res = await _retry(
        () => _dio.dio.post(resolvedPath,
            data: form,
            options: Options(
              contentType: 'multipart/form-data',
              headers: {'X-Idempotency-Key': idempotencyKey},
            )),
        label: 'submitUnloadProof',
      );

      if (res.statusCode != 200) {
        throw Exception(_proofUploadErrorMessage(
          res.data,
          statusCode: res.statusCode,
          fallback: 'Failed to submit unload proof',
        ));
      }
      // Unload proof advances status server-side (typically to UNLOADED).
      // Clear action cache so detail screen does not reuse stale actions.
      clearAvailableActionsCache(dispatchId);
    } catch (e) {
      _log('Error uploading unload proof: $e');
      rethrow;
    } finally {
      for (final f in temps) {
        try {
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  // ============================================================
  // Finance / Odometer
  // ============================================================

  Future<Map<String, dynamic>?> submitOdometer({
    required int dispatchId,
    double? startKm,
    double? endKm,
    DateTime? recordedAt,
  }) async {
    return dispatchRepository.submitOdometer(
      dispatchId: dispatchId,
      startKm: startKm,
      endKm: endKm,
      recordedAt: recordedAt?.toIso8601String(),
    );
  }

  Future<Map<String, dynamic>?> submitFuelRequest({
    required int dispatchId,
    double? amount,
    double? liters,
    String? station,
    String? receiptPaths,
  }) async {
    return dispatchRepository.submitFuelRequest(
      dispatchId: dispatchId,
      amount: amount,
      liters: liters,
      station: station,
      receiptPaths: receiptPaths,
    );
  }

  Future<Map<String, dynamic>?> submitCodSettlement({
    required int dispatchId,
    double? amount,
    String? currency,
    DateTime? collectedAt,
  }) async {
    return dispatchRepository.submitCodSettlement(
      dispatchId: dispatchId,
      amount: amount,
      currency: currency,
      collectedAt: collectedAt?.toIso8601String(),
    );
  }

  /// Clear cached available actions for a specific dispatch
  /// Called after status updates to ensure fresh data on next query
  void clearAvailableActionsCache(String dispatchId) {
    _availableActionsCache.remove(dispatchId);
  }
}

/// Helper class for caching available actions with TTL
class _CachedActions {
  final DispatchActionsResponse response;
  final DateTime cachedAt;

  _CachedActions({required this.response, required this.cachedAt});

  /// Check if cache is still valid (within TTL)
  bool get isValid =>
      DateTime.now().difference(cachedAt) <
      DispatchProvider._availableActionsTTL;
}
