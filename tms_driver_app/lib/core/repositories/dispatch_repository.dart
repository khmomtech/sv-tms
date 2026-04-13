// 📁 lib/core/repositories/dispatch_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/repositories/base_repository.dart';

/// Repository for dispatch/job-related data operations
///
/// Handles:
/// - Fetching dispatches by status
/// - Job acceptance/rejection
/// - Status updates
/// - Proof of delivery uploads
class DispatchRepository extends BaseRepository {
  static const int _defaultPageSize = 100;
  static const int _maxPageFetches = 50;
  static const Set<String> _pendingStatusSet = {
    'PLANNED',
    'PENDING',
    'SCHEDULED',
    'ASSIGNED',
  };
  static const Set<String> _inProgressStatusSet = {
    'DRIVER_CONFIRMED',
    'APPROVED',
    'ARRIVED_LOADING',
    'SAFETY_FAILED',
    'IN_QUEUE',
    'LOADING',
    'LOADED',
    'AT_HUB',
    'HUB_LOADING',
    'IN_TRANSIT',
    'IN_TRANSIT_BREAKDOWN',
    'PENDING_INVESTIGATION',
    'ARRIVED_UNLOADING',
    'UNLOADING',
    'UNLOADED',
    'SAFETY_PASSED',
  };
  static const Set<String> _completedStatusSet = {
    'DELIVERED',
    'FINANCIAL_LOCKED',
    'CLOSED',
    'COMPLETED',
    'CANCELLED',
    'REJECTED',
  };

  Future<List<Map<String, dynamic>>> _fetchAllDispatchPages(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final all = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    var page = 0;
    var totalPages = 1;
    var guard = 0;

    while (page < totalPages && guard < _maxPageFetches) {
      guard++;
      final qp = <String, dynamic>{
        ...?queryParameters,
        'page': page,
        'size': _defaultPageSize,
      };

      final response = await dio.get(
        ApiConstants.endpoint(path).toString(),
        queryParameters: qp,
        options: Options(responseType: ResponseType.plain),
      );

      final responseData = _decodeResponseBody(response.data);
      if (response.statusCode != 200 || response.data == null) {
        break;
      }

      final dispatches = _extractDispatches(responseData);
      for (final dispatch in dispatches) {
        final idCandidate = dispatch['id'] ??
            dispatch['dispatchId'] ??
            dispatch['dispatch_id'] ??
            '${dispatch.hashCode}';
        final id = idCandidate.toString();
        if (seenIds.add(id)) {
          all.add(dispatch);
        }
      }

      final Map<dynamic, dynamic>? payload =
          (responseData is Map && responseData['data'] is Map)
              ? responseData['data']
              : (responseData is Map ? responseData : null);

      if (payload != null) {
        final tp = payload['totalPages'];
        if (tp is num) {
          totalPages = tp.toInt().clamp(1, _maxPageFetches);
        } else if (payload['last'] == true ||
            dispatches.length < _defaultPageSize) {
          totalPages = page + 1;
        }
      } else {
        totalPages = page + 1;
      }

      page++;
    }

    return all;
  }

  dynamic _decodeResponseBody(dynamic data) {
    if (data is! String) {
      return data;
    }

    final body = data.trim();
    if (body.isEmpty) {
      return null;
    }

    final first = body[0];
    final looksLikeJson = first == '{' || first == '[';
    if (!looksLikeJson) {
      return data;
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      return data;
    }
  }

  /// Fetch processing (not completed/cancelled) dispatches
  Future<List<Map<String, dynamic>>> getProcessingDispatches(
      String driverId) async {
    return executeWithRetry(
      () async {
        final dispatches = await _fetchAllDispatchPages(
          '/driver/dispatches/driver/$driverId/processing',
          queryParameters: {'sort': 'startTime,DESC'},
        );
        await _cacheDispatches(_inProgressCacheKey, dispatches);
        return dispatches;
      },
      label: 'getProcessingDispatches',
    );
  }

  final SharedPreferences _prefs;

  static const String _pendingCacheKey = 'cached_pending_dispatches';
  static const String _inProgressCacheKey = 'cached_in_progress_dispatches';
  static const String _completedCacheKey = 'cached_completed_dispatches';

  DispatchRepository({
    required Dio dio,
    required SharedPreferences prefs,
  })  : _prefs = prefs,
        super(dio: dio);

  // ============================================================
  // Fetch Dispatches by Status
  // ============================================================

  /// Fetch pending dispatches for the authenticated driver
  /// (pending bucket statuses managed by backend)
  /// Sorted by startTime DESC - managed on backend
  Future<List<Map<String, dynamic>>> getMyPendingDispatches() async {
    return executeWithRetry(
      () async {
        List<Map<String, dynamic>> dispatches;
        try {
          dispatches = await _fetchAllDispatchPages(
            '/driver/dispatches/me/pending',
            queryParameters: {'sort': 'startTime,DESC'},
          );
        } catch (e) {
          if (!_shouldFallbackToLegacyDispatchLookup(e)) rethrow;
          dispatches = await _fallbackDispatchesFromDriverId(
            statusFilter: _pendingStatusSet,
          );
        }
        if (dispatches.isEmpty) {
          dispatches = await _fallbackDispatchesFromDriverId(
            statusFilter: _pendingStatusSet,
          );
        }
        await _cacheDispatches(_pendingCacheKey, dispatches);
        return dispatches;
      },
      label: 'getMyPendingDispatches',
    );
  }

  /// Fetch in-progress dispatches for the authenticated driver
  /// (in-progress bucket statuses managed by backend)
  /// Sorted by startTime ASC - managed on backend
  Future<List<Map<String, dynamic>>> getMyInProgressDispatches() async {
    return executeWithRetry(
      () async {
        List<Map<String, dynamic>> dispatches;
        try {
          dispatches = await _fetchAllDispatchPages(
            '/driver/dispatches/me/in-progress',
            queryParameters: {'sort': 'startTime,DESC'},
          );
        } catch (e) {
          if (!_shouldFallbackToLegacyDispatchLookup(e)) rethrow;
          dispatches = await _fallbackDispatchesFromDriverId(
            pathSuffix: '/processing',
            statusFilter: _inProgressStatusSet,
          );
        }
        if (dispatches.isEmpty) {
          dispatches = await _fallbackDispatchesFromDriverId(
            pathSuffix: '/processing',
            statusFilter: _inProgressStatusSet,
          );
        }
        await _cacheDispatches(_inProgressCacheKey, dispatches);
        return dispatches;
      },
      label: 'getMyInProgressDispatches',
    );
  }

  /// Fetch completed dispatches for the authenticated driver
  /// (completed bucket statuses managed by backend)
  /// Sorted by endTime DESC - managed on backend
  Future<List<Map<String, dynamic>>> getMyCompletedDispatches() async {
    return executeWithRetry(
      () async {
        List<Map<String, dynamic>> dispatches;
        try {
          dispatches = await _fetchAllDispatchPages(
            '/driver/dispatches/me/completed',
            queryParameters: {'sort': 'endTime,DESC'},
          );
        } catch (_) {
          dispatches = <Map<String, dynamic>>[];
        }
        if (dispatches.isEmpty) {
          dispatches = await _fallbackDispatchesFromDriverId(
            statusFilter: _completedStatusSet,
          );
        }
        await _cacheDispatches(_completedCacheKey, dispatches);
        return dispatches;
      },
      label: 'getMyCompletedDispatches',
    );
  }

  Future<List<Map<String, dynamic>>> _fallbackDispatchesFromDriverId({
    String pathSuffix = '',
    Set<String>? statusFilter,
  }) async {
    final driverId = await ApiConstants.getDriverId();
    if (driverId == null) {
      return <Map<String, dynamic>>[];
    }

    final dispatches = await _fetchAllDispatchPages(
      '/driver/dispatches/driver/$driverId$pathSuffix',
      queryParameters: {'sort': 'startTime,DESC'},
    );
    if (statusFilter == null || statusFilter.isEmpty) {
      return dispatches;
    }
    return dispatches.where((dispatch) {
      final status = (dispatch['status'] ?? '').toString().toUpperCase().trim();
      return statusFilter.contains(status);
    }).toList();
  }

  bool _shouldFallbackToLegacyDispatchLookup(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
        return true;
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return true;
      }
    }
    final text = error.toString().toLowerCase();
    return text.contains('504') ||
        text.contains('gateway') ||
        text.contains('driver-app-api:8084') ||
        text.contains('connection refused') ||
        text.contains('timed out');
  }

  /// Extract dispatch list from paginated response
  List<Map<String, dynamic>> _extractDispatches(dynamic data) {
    final payload =
        (data is Map && data.containsKey('data')) ? data['data'] : data;
    if (payload is Map<String, dynamic> && payload.containsKey('content')) {
      return List<Map<String, dynamic>>.from(payload['content'] ?? []);
    } else if (payload is List) {
      return List<Map<String, dynamic>>.from(payload);
    }
    return [];
  }

  // ============================================================
  // Dispatch Actions
  // ============================================================

  /// Accept a dispatch
  Future<Map<String, dynamic>?> acceptDispatch(int dispatchId) async {
    return executeWithRetry(
      () async {
        final response = await dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.dispatchEndpoints['accept']!.replaceAll('{id}', dispatchId.toString())}',
        );

        if (response.statusCode == 200 && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
        return null;
      },
      label: 'acceptDispatch',
    );
  }

  /// Reject a dispatch with reason
  Future<Map<String, dynamic>?> rejectDispatch({
    required int dispatchId,
    required String reason,
  }) async {
    return executeWithRetry(
      () async {
        final response = await dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.dispatchEndpoints['reject']!.replaceAll('{id}', dispatchId.toString())}',
          data: {'reason': reason},
        );

        if (response.statusCode == 200 && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
        return null;
      },
      label: 'rejectDispatch',
    );
  }

  /// Update dispatch status (START, ARRIVE, COMPLETE)
  Future<Map<String, dynamic>?> updateDispatchStatus({
    required int dispatchId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    return executeWithRetry(
      () async {
        final endpoint = ApiConstants.dispatchEndpoints['status-update']!
            .replaceAll('{id}', dispatchId.toString());
        final response = await dio.patch(
          '${ApiConstants.baseUrl}$endpoint',
          data: {
            'status': status,
            ...?additionalData,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
        return null;
      },
      label: 'updateDispatchStatus',
    );
  }

  // ============================================================
  // File Uploads (Proof of Delivery, etc.)
  // ============================================================

  /// Upload proof of delivery files
  Future<Map<String, dynamic>?> uploadProofOfDelivery({
    required int dispatchId,
    required List<File> files,
    String? notes,
    Function(int, int)? onProgress,
  }) async {
    return executeWithRetry(
      () async {
        final formData = FormData();

        // Backend expects unload proof images under multipart field name `images`.
        for (var file in files) {
          final fileName = file.path.split('/').last;
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(file.path, filename: fileName),
            ),
          );
        }

        // Backend expects optional remarks field.
        if (notes != null && notes.isNotEmpty) {
          formData.fields.add(MapEntry('remarks', notes));
        }

        final response = await dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.dispatchEndpoints['upload-proof']!.replaceAll('{id}', dispatchId.toString())}',
          data: formData,
          onSendProgress: (sent, total) {
            if (onProgress != null) {
              onProgress(sent, total);
            }
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
        return null;
      },
      label: 'uploadProofOfDelivery',
      maxRetries: 1, // Don't retry file uploads too much
    );
  }

  // ============================================================
  // Finance / Odometer
  // ============================================================

  Future<Map<String, dynamic>?> submitOdometer({
    required int dispatchId,
    double? startKm,
    double? endKm,
    String? recordedAt,
  }) async {
    return executeWithRetry(
      () async {
        final endpoint = ApiConstants.dispatchEndpoints['odometer']!
            .replaceAll('{id}', dispatchId.toString());
        final response = await dio.post(
          '${ApiConstants.baseUrl}$endpoint',
          data: {
            'startKm': startKm,
            'endKm': endKm,
            'recordedAt': recordedAt,
          },
        );
        if (response.statusCode == 200 && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
        return null;
      },
      label: 'submitOdometer',
    );
  }

  Future<Map<String, dynamic>?> submitFuelRequest({
    required int dispatchId,
    double? amount,
    double? liters,
    String? station,
    String? receiptPaths,
  }) async {
    return executeWithRetry(
      () async {
        final endpoint = ApiConstants.dispatchEndpoints['fuel-request']!
            .replaceAll('{id}', dispatchId.toString());
        final response = await dio.post(
          '${ApiConstants.baseUrl}$endpoint',
          data: {
            'amount': amount,
            'liters': liters,
            'station': station,
            'receiptPaths': receiptPaths,
          },
        );
        if (response.statusCode == 200 && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
        return null;
      },
      label: 'submitFuelRequest',
    );
  }

  Future<Map<String, dynamic>?> submitCodSettlement({
    required int dispatchId,
    double? amount,
    String? currency,
    String? collectedAt,
  }) async {
    return executeWithRetry(
      () async {
        final endpoint = ApiConstants.dispatchEndpoints['cod-settlement']!
            .replaceAll('{id}', dispatchId.toString());
        final response = await dio.post(
          '${ApiConstants.baseUrl}$endpoint',
          data: {
            'amount': amount,
            'currency': currency,
            'collectedAt': collectedAt,
          },
        );
        if (response.statusCode == 200 && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
        return null;
      },
      label: 'submitCodSettlement',
    );
  }

  // ============================================================
  // Cache Management
  // ============================================================

  Future<void> _cacheDispatches(
      String cacheKey, List<Map<String, dynamic>> dispatches) async {
    try {
      await _prefs.setString(cacheKey, jsonEncode(dispatches));
    } catch (e) {
      log('Error caching dispatches: $e');
    }
  }

  /// Get cached dispatches for offline support
  Future<List<Map<String, dynamic>>> getCachedDispatches(
      String cacheKey) async {
    try {
      final cached = _prefs.getString(cacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
    } catch (e) {
      log('Error reading cached dispatches: $e');
    }
    return [];
  }

  /// Clear all dispatch cache
  Future<void> clearCache() async {
    await Future.wait([
      _prefs.remove(_pendingCacheKey),
      _prefs.remove(_inProgressCacheKey),
      _prefs.remove(_completedCacheKey),
    ]);
  }
}
