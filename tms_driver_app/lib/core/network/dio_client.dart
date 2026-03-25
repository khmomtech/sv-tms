// 📁 lib/core/network/dio_client.dart
import 'dart:async';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';
import '../security/certificate_pinning_config.dart';
import 'api_constants.dart';
import 'api_response.dart';

class DioClient {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;

  DioClient._internal() {
    final BaseOptions options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: ApiConstants.defaultHeaders,
      // responseType: ResponseType.json,
      // Allow the app to handle 4xx/5xx responses itself so we can
      // convert them into ApiResponse.failure with server message.
      // NOTE: Treat 401/403 as errors so the auth interceptor can refresh tokens.
      validateStatus: (status) =>
          status != null && status < 500 && status != 401 && status != 403,
    );

    dio = Dio(options);

    // Configure HTTP client to be more resilient (avoid stale keep-alive connections,
    // low max connections, and shorter idle timeouts which can help avoid intermittent
    // "connection reset" / "closed before full header" errors when the network is
    // unstable or when calling local dev servers.
    //
    // NOTE: This is a workaround for intermittent socket failures that are often
    // caused by the underlying OS or emulator/network stack closing sockets unexpectedly.
    // Use the Dio IOHttpClientAdapter entrypoint for configuring the underlying
    // dart:io HttpClient. `onHttpClientCreate` is deprecated in Dio 5.x; use
    // `createHttpClient` instead.
    final ioAdapter = dio.httpClientAdapter as IOHttpClientAdapter;
    ioAdapter.createHttpClient = () {
      final client = HttpClient();
      client.maxConnectionsPerHost = 4;
      client.idleTimeout = const Duration(seconds: 10);
      client.connectionTimeout = const Duration(seconds: 10);
      return client;
    };

    // Configure certificate pinning for security
    CertificatePinningConfig.configureDio(dio);

    // Interceptors
    dio.interceptors.add(_AuthInterceptor(dio));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        responseBody: true,
        requestBody: true,
        requestHeader: true,
        responseHeader: false,
      ));
    }
  }

  // Normalize a request path to avoid doubling the `/api` segment when the
  // Dio instance already has a baseUrl that ends with `/api` and callers pass
  // a path that also begins with `/api`. If `path` is an absolute URL it is
  // returned unchanged.
  String _resolveRequestPath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = dio.options.baseUrl;
    if (base.endsWith('/api') && path.startsWith('/api')) {
      // remove the `/api` suffix from base and join with provided path
      final trimmedBase = base.substring(0, base.length - 4);
      return '$trimmedBase$path';
    }
    return path;
  }

  // ---------------------------------------------------------------------------
  // Public HTTP helpers: preserve your ApiResponse<T> facade
  // ---------------------------------------------------------------------------
  String resolvePath(String path) => _resolveRequestPath(path);

  static const int _maxRetries = 2;
  static const Duration _baseRetryDelay = Duration(milliseconds: 400);

  bool _shouldRetry(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return true;
    }

    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode ?? 0;
      return statusCode == 502 || statusCode == 503 || statusCode == 504;
    }

    return false;
  }

  Future<Response<dynamic>> _executeWithRetry(
    Future<Response<dynamic>> Function() requestFn,
  ) async {
    int attempt = 0;
    while (true) {
      try {
        return await requestFn();
      } on DioException catch (e) {
        if (attempt >= _maxRetries || !_shouldRetry(e)) rethrow;

        final delay = _baseRetryDelay * (1 << attempt);
        Logger.warning(
          'Request transient error, will retry in ${delay.inMilliseconds}ms (attempt ${attempt + 1}/$_maxRetries): ${e.message}',
          tag: 'DioClient',
        );
        await Future.delayed(delay);
        attempt++;
      }
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? converter,
  }) async {
    try {
      final res = await _executeWithRetry(
        () => dio.get(_resolveRequestPath(path), queryParameters: queryParameters),
      );
      // Treat HTTP 2xx as success; otherwise surface as failure with body
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return ApiResponse.failure(
          // prefer server-provided message if available
          (res.data is Map && res.data['message'] is String)
              ? res.data['message'] as String
              : 'Server error: $status',
          statusCode: status,
          errorData: res.data,
        );
      }
      final converted = converter != null ? converter(res.data) : res.data;
      return ApiResponse.success(converted);
    } on DioException catch (e) {
      final msg = _extractMessage(e);
      return ApiResponse.failure(
        msg,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
    } catch (_) {
      return ApiResponse.failure('Unexpected error occurred');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
    T Function(dynamic data)? converter,
    required Map<String, dynamic> Function(dynamic raw) parser,
  }) async {
    try {
      final res = await _executeWithRetry(
        () => dio.post(
          _resolveRequestPath(path),
          data: data,
          options: headers == null ? null : Options(headers: headers),
        ),
      );
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return ApiResponse.failure(
          (res.data is Map && res.data['message'] is String)
              ? res.data['message'] as String
              : 'Server error: $status',
          statusCode: status,
          errorData: res.data,
        );
      }
      final converted = converter != null ? converter(res.data) : res.data;
      return ApiResponse.success(converted);
    } on DioException catch (e) {
      final msg = _extractMessage(e);
      return ApiResponse.failure(
        msg,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
    } catch (_) {
      return ApiResponse.failure('Unexpected error occurred');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? converter,
  }) async {
    try {
      final res = await _executeWithRetry(
        () => dio.put(_resolveRequestPath(path), data: data),
      );
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return ApiResponse.failure(
          (res.data is Map && res.data['message'] is String)
              ? res.data['message'] as String
              : 'Server error: $status',
          statusCode: status,
          errorData: res.data,
        );
      }
      final converted = converter != null ? converter(res.data) : res.data;
      return ApiResponse.success(converted);
    } on DioException catch (e) {
      final msg = _extractMessage(e);
      return ApiResponse.failure(
        msg,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
    } catch (_) {
      return ApiResponse.failure('Unexpected error occurred');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? converter,
    required Map<String, dynamic> Function(dynamic raw) parser,
  }) async {
    try {
      final res = await _executeWithRetry(
        () => dio.patch(_resolveRequestPath(path), data: data),
      );
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return ApiResponse.failure(
          (res.data is Map && res.data['message'] is String)
              ? res.data['message'] as String
              : 'Server error: $status',
          statusCode: status,
          errorData: res.data,
        );
      }
      final converted = converter != null ? converter(res.data) : res.data;
      return ApiResponse.success(converted);
    } on DioException catch (e) {
      final msg = _extractMessage(e);
      return ApiResponse.failure(
        msg,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
    } catch (_) {
      return ApiResponse.failure('Unexpected error occurred');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? converter,
  }) async {
    try {
      final res = await _executeWithRetry(
        () => dio.delete(_resolveRequestPath(path), data: data),
      );
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return ApiResponse.failure(
          (res.data is Map && res.data['message'] is String)
              ? res.data['message'] as String
              : 'Server error: $status',
          statusCode: status,
          errorData: res.data,
        );
      }
      final converted = converter != null ? converter(res.data) : res.data;
      return ApiResponse.success(converted);
    } on DioException catch (e) {
      final msg = _extractMessage(e);
      return ApiResponse.failure(
        msg,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
    } catch (_) {
      return ApiResponse.failure('Unexpected error occurred');
    }
  }

  String _extractMessage(DioException e) {
    Logger.error(' Dio Error: ${e.message}', tag: 'DioClient');

    final code = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    String? serverMessage;
    if (data is Map && data['message'] is String) {
      serverMessage = data['message'] as String;
    } else if (data is String && data.isNotEmpty) {
      serverMessage = data;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        return serverMessage ?? 'Server error: $code';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.badCertificate:
        return 'Bad certificate';
      case DioExceptionType.connectionError:
        return _connectionErrorMessage(e) ?? 'No internet connection';
      case DioExceptionType.unknown:
        return serverMessage ?? 'Something went wrong';
    }
  }

  String? _connectionErrorMessage(DioException e) {
    final err = e.error;
    if (err is SocketException) {
      final detail = err.osError?.message ?? err.message;
      final lower = detail.toLowerCase();
      if (lower.contains('connection refused')) {
        return 'Unable to reach the backend. Ensure the server is running at ${ApiConstants.baseUrl}.';
      }
      if (lower.contains('host is down') ||
          lower.contains('hostunreachable') ||
          lower.contains('network is unreachable')) {
        return 'Network unreachable. Check your connection.';
      }
      if (lower.contains('timed out')) {
        return 'Connection attempt timed out. Please try again.';
      }
    }
    return null;
  }
}

/// Internal auth/refresh interceptor with:
/// - Header injection
/// - BaseUrl sync with ApiConstants
/// - Single refresh in flight + queued request replay
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);
  final Dio _dio;

  bool _isRefreshing = false;
  final List<_QueuedRequest> _queue = [];

  bool _isAuthPath(String path) {
    final p = path.toLowerCase();
    return p.contains('/auth/driver/login') ||
        p.contains('/auth/registerdriver') ||
        p.contains('/auth/refresh');
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      if (_isAuthPath(options.path)) {
        return handler.next(options);
      }
      // Keep baseUrl in sync in case env changed at runtime
      if (_dio.options.baseUrl != ApiConstants.baseUrl) {
        _dio.options = _dio.options.copyWith(baseUrl: ApiConstants.baseUrl);
      }
      // Inject headers (includes bearer, may pre-refresh if expiring soon)
      final headers = await ApiConstants.getHeaders();
      // For multipart requests, do NOT override content-type (boundary set by Dio)
      final isMultipart = options.data is FormData ||
          (options.contentType != null &&
              options.contentType!
                  .toLowerCase()
                  .contains('multipart/form-data'));
      if (isMultipart) {
        headers.removeWhere((key, value) =>
            key.toLowerCase() == 'content-type'); // let Dio set boundary
        // Ensure request contentType remains multipart
        options.contentType = 'multipart/form-data';
      }
      options.headers.addAll(headers);
      if (kDebugMode) {
        debugPrint('[DioClient] Request: ${options.method} ${options.uri}');
      }
    } catch (e) {
      Logger.warning('Failed to attach auth headers: $e', tag: 'DioClient');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final req = err.requestOptions;

    // Only act on 401, and never on the refresh endpoint itself
    if (status == 401 && !_isAuthPath(req.path)) {
      if (_isRefreshing) {
        // Another refresh is in progress — enqueue and replay later
        final completer = Completer<Response>();
        _queue.add(_QueuedRequest(req, completer));
        try {
          final response = await completer.future;
          return handler.resolve(response);
        } catch (e) {
          return handler.reject(e as DioException);
        }
      }

      _isRefreshing = true;
      try {
        final newAccess = await ApiConstants.refreshAccessToken();
        if (newAccess == null || newAccess.isEmpty) {
          // Refresh failed — reject original & queued
          for (final q in _queue) {
            q.completer.completeError(err);
          }
          _queue.clear();
          return handler.reject(err);
        }

        // Retry the original request with fresh header
        final retried = await _retry(req);
        // Replay queued
        for (final q in _queue) {
          _retry(q.request)
              .then(q.completer.complete)
              .catchError(q.completer.completeError);
        }
        _queue.clear();

        return handler.resolve(retried);
      } catch (e) {
        // Any exception -> reject chain
        for (final q in _queue) {
          q.completer.completeError(err);
        }
        _queue.clear();
        return handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    }

    // Any other error -> pass through
    handler.next(err);
  }

  Future<Response<dynamic>> _retry(RequestOptions ro) async {
    // Build request options without touching interceptors stack
    final options = Options(
      method: ro.method,
      headers: ro.headers, // headers will be re-added by onRequest anyway
      responseType: ro.responseType,
      contentType: ro.contentType,
      sendTimeout: ro.sendTimeout,
      receiveTimeout: ro.receiveTimeout,
      followRedirects: ro.followRedirects,
      listFormat: ro.listFormat,
    );

    return _dio.request<dynamic>(
      ro.path,
      data: ro.data,
      queryParameters: ro.queryParameters,
      cancelToken: ro.cancelToken,
      onReceiveProgress: ro.onReceiveProgress,
      onSendProgress: ro.onSendProgress,
      options: options,
    );
  }
}

class _QueuedRequest {
  _QueuedRequest(this.request, this.completer);
  final RequestOptions request;
  final Completer<Response> completer;
}
