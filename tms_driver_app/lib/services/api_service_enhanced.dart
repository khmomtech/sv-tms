// lib/services/api_service_enhanced.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

/// 🚀 Enhanced API Service with comprehensive error handling, retry logic, and performance optimizations
class ApiServiceEnhanced {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _shortTimeout = Duration(seconds: 15);
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 1000);

  // Enhanced Dio client with connection pooling and interceptors
  static late final Dio _dio;
  static bool _initialized = false;

  static String _resolveLocalDirectAuthEndpoint(String endpoint) {
    try {
      final baseUri = Uri.parse(ApiConstants.baseUrl);
      final host = baseUri.host.trim();
      if (host.isEmpty) return endpoint;

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

      if (!(isLocalHost || isPrivateIpv4)) return endpoint;
      if (currentPort != 8080 && currentPort != 8086) return endpoint;

      return baseUri
          .replace(
            port: 8080,
            path: '/api$endpoint',
            query: null,
            fragment: null,
          )
          .toString();
    } catch (_) {
      return endpoint;
    }
  }

  /// Initialize the enhanced API service
  static Future<void> initialize() async {
    if (_initialized) return;

    await ApiConstants.ensureInitialized();

    final baseOptions = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: _defaultTimeout,
      receiveTimeout: _defaultTimeout,
      sendTimeout: _defaultTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'SV-TMS-Driver-App/1.0',
        'Cache-Control': 'no-cache',
      },
      validateStatus: (status) => true, // Handle all status codes manually
    );

    _dio = Dio(baseOptions);

    // Add authentication interceptor
    _dio.interceptors.add(_AuthInterceptor());
    // Add retry interceptor
    _dio.interceptors.add(_RetryInterceptor());

    // Add performance monitoring interceptor
    _dio.interceptors.add(_PerformanceInterceptor());

    // Add debug logging in development
    if (kDebugMode) {
      _dio.interceptors.add(_DebugLogInterceptor());
    }

    _initialized = true;
    debugPrint('🚀 Enhanced API Service initialized');
  }

  /// Make authenticated request with retry logic and comprehensive error handling
  static Future<EnhancedApiResponse<T>> request<T>({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    int? retries,
    bool requiresAuth = true,
    T Function(dynamic)? parser,
  }) async {
    if (!_initialized) await initialize();

    final requestId = _generateRequestId();
    debugPrint('🌐 [$requestId] Starting $method $endpoint');

    try {
      final options = Options(
        method: method.toUpperCase(),
        headers: headers,
        sendTimeout: timeout ?? _defaultTimeout,
        receiveTimeout: timeout ?? _defaultTimeout,
      );

      // Add authentication if required
      if (requiresAuth) {
        await _ensureValidToken();
        final token = await ApiConstants.getAccessToken();
        if (token != null) {
          options.headers = {...?options.headers, 'Authorization': 'Bearer $token'};
        }
      }

      final response = await _dio.request<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _parseResponse<T>(response, parser, requestId);
    } catch (e) {
      debugPrint('[$requestId] Request failed: $e');
      return _handleError<T>(e, requestId);
    }
  }

  /// Convenient methods for common HTTP verbs
  static Future<EnhancedApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    bool requiresAuth = true,
    T Function(dynamic)? parser,
  }) =>
      request<T>(
        method: 'GET',
        endpoint: endpoint,
        queryParameters: queryParameters,
        headers: headers,
        timeout: timeout,
        requiresAuth: requiresAuth,
        parser: parser,
      );

  static Future<EnhancedApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    Duration? timeout,
    bool requiresAuth = true,
    T Function(dynamic)? parser,
  }) =>
      request<T>(
        method: 'POST',
        endpoint: endpoint,
        data: data,
        headers: headers,
        timeout: timeout,
        requiresAuth: requiresAuth,
        parser: parser,
      );

  static Future<EnhancedApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    Duration? timeout,
    bool requiresAuth = true,
    T Function(dynamic)? parser,
  }) =>
      request<T>(
        method: 'PUT',
        endpoint: endpoint,
        data: data,
        headers: headers,
        timeout: timeout,
        requiresAuth: requiresAuth,
        parser: parser,
      );

  static Future<EnhancedApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    bool requiresAuth = true,
    T Function(dynamic)? parser,
  }) =>
      request<T>(
        method: 'DELETE',
        endpoint: endpoint,
        headers: headers,
        timeout: timeout,
        requiresAuth: requiresAuth,
        parser: parser,
      );

  /// Enhanced device approval with proper error handling
  static Future<DeviceApprovalResult> requestDeviceApproval({
    required String username,
    required String password,
    required Map<String, String> deviceInfo,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        _resolveLocalDirectAuthEndpoint('/driver/device/request-approval'),
        data: {
          'username': username,
          'password': password,
          ...deviceInfo,
        },
        requiresAuth: false,
        timeout: _shortTimeout,
      );

      if (response.success) {
        return DeviceApprovalResult.success(
          message: response.message ?? 'Device approval request submitted successfully',
        );
      } else {
        return DeviceApprovalResult.failure(
          code: response.errorCode ?? 'REQUEST_FAILED',
          message: response.message ?? 'Failed to submit device approval request',
        );
      }
    } catch (e) {
      return DeviceApprovalResult.failure(
        code: 'NETWORK_ERROR',
        message: 'Network error occurred. Please check your connection and try again.',
      );
    }
  }

  /// Enhanced driver login with comprehensive error handling
  static Future<LoginResult> driverLogin({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        _resolveLocalDirectAuthEndpoint('/auth/driver/login'),
        data: {
          'username': username,
          'password': password,
          'deviceId': deviceId,
        },
        requiresAuth: false,
        timeout: _shortTimeout,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final code = data['code']?.toString();

        if (code == 'LOGIN_SUCCESS') {
          return LoginResult.success(
            data: data,
            message: 'Login successful',
          );
        } else {
          return LoginResult.failure(
            code: code ?? 'LOGIN_FAILED',
            message: data['message']?.toString() ?? 'Login failed',
          );
        }
      } else {
        return LoginResult.failure(
          code: response.errorCode ?? 'LOGIN_ERROR',
          message: response.message ?? 'Authentication failed',
        );
      }
    } catch (e) {
      return LoginResult.failure(
        code: 'NETWORK_ERROR',
        message: 'Network error during login. Please try again.',
      );
    }
  }

  // Internal helper methods

  static String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }

  static Future<void> _ensureValidToken() async {
    try {
      if (await ApiConstants.isTokenExpired(leewaySeconds: 300)) { // 5 min buffer
        debugPrint('🔑 Token expiring soon, attempting refresh...');
        final newToken = await ApiConstants.refreshAccessToken();
        if (newToken == null) {
          debugPrint(
            'Token refresh unavailable - keeping existing credentials until backend confirms invalid session',
          );
        } else {
          debugPrint('Token refreshed successfully');
        }
      }
    } catch (e) {
      debugPrint('Token validation error: $e');
    }
  }

  static EnhancedApiResponse<T> _parseResponse<T>(
    Response<dynamic> response,
    T Function(dynamic)? parser,
    String requestId,
  ) {
    final statusCode = response.statusCode ?? 0;
    final isSuccess = statusCode >= 200 && statusCode < 300;

    debugPrint('[$requestId] Response: $statusCode');

    try {
      final responseData = response.data;

      if (isSuccess) {
        // Parse successful response
        T? parsedData;
        if (parser != null && responseData != null) {
          parsedData = parser(responseData);
        } else if (responseData is Map<String, dynamic>) {
          parsedData = responseData as T?;
        }

        return EnhancedApiResponse<T>.success(
          data: parsedData,
          message: _extractMessage(responseData),
          statusCode: statusCode,
        );
      } else {
        // Parse error response
        return EnhancedApiResponse<T>.failure(
          message: _extractMessage(responseData) ?? 'Request failed',
          statusCode: statusCode,
          errorCode: _extractErrorCode(responseData),
          errorData: responseData,
        );
      }
    } catch (e) {
      debugPrint('[$requestId] Response parsing error: $e');
      return EnhancedApiResponse<T>.failure(
        message: 'Failed to parse server response',
        statusCode: statusCode,
        errorCode: 'PARSE_ERROR',
      );
    }
  }

  static EnhancedApiResponse<T> _handleError<T>(dynamic error, String requestId) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return EnhancedApiResponse<T>.failure(
            message: 'Request timeout. Please check your connection and try again.',
            errorCode: 'TIMEOUT_ERROR',
            statusCode: 0,
          );

        case DioExceptionType.connectionError:
          return EnhancedApiResponse<T>.failure(
            message: 'Connection failed. Please check your internet connection.',
            errorCode: 'CONNECTION_ERROR',
            statusCode: 0,
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          final responseData = error.response?.data;
          return EnhancedApiResponse<T>.failure(
            message: _extractMessage(responseData) ?? 'Server error occurred',
            statusCode: statusCode,
            errorCode: _extractErrorCode(responseData) ?? 'SERVER_ERROR',
            errorData: responseData,
          );

        default:
          return EnhancedApiResponse<T>.failure(
            message: 'An unexpected error occurred. Please try again.',
            errorCode: 'UNKNOWN_ERROR',
            statusCode: 0,
          );
      }
    }

    return EnhancedApiResponse<T>.failure(
      message: 'Unexpected error: ${error.toString()}',
      errorCode: 'UNEXPECTED_ERROR',
      statusCode: 0,
    );
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
             data['error']?.toString() ??
             data['detail']?.toString();
    }
    return null;
  }

  static String? _extractErrorCode(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['code']?.toString() ??
             data['errorCode']?.toString() ??
             data['error_code']?.toString();
    }
    return null;
  }
}

// Enhanced API Response class
class EnhancedApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;
  final String? errorCode;
  final dynamic errorData;
  final DateTime timestamp;

  const EnhancedApiResponse._(
    this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errorCode,
    this.errorData,
    this.timestamp,
  );

  factory EnhancedApiResponse.success({
    T? data,
    String? message,
    int statusCode = 200,
  }) {
    return EnhancedApiResponse._(
      true,
      data,
      message,
      statusCode,
      null,
      null,
      DateTime.now(),
    );
  }

  factory EnhancedApiResponse.failure({
    required String message,
    int statusCode = 0,
    String? errorCode,
    dynamic errorData,
  }) {
    return EnhancedApiResponse._(
      false,
      null,
      message,
      statusCode,
      errorCode,
      errorData,
      DateTime.now(),
    );
  }
}

// Result classes for specific operations
class DeviceApprovalResult {
  final bool success;
  final String? code;
  final String message;

  const DeviceApprovalResult._(this.success, this.code, this.message);

  factory DeviceApprovalResult.success({required String message}) {
    return DeviceApprovalResult._(true, null, message);
  }

  factory DeviceApprovalResult.failure({required String code, required String message}) {
    return DeviceApprovalResult._(false, code, message);
  }
}

class LoginResult {
  final bool success;
  final String? code;
  final String message;
  final Map<String, dynamic>? data;

  const LoginResult._(this.success, this.code, this.message, this.data);

  factory LoginResult.success({required Map<String, dynamic> data, String? message}) {
    return LoginResult._(true, null, message ?? 'Success', data);
  }

  factory LoginResult.failure({required String code, required String message}) {
    return LoginResult._(false, code, message, null);
  }
}

// Interceptors for enhanced functionality

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add authorization header if available and not already present
    if (!options.headers.containsKey('Authorization')) {
      final token = await ApiConstants.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Add request timestamp for analytics
    options.headers['X-Request-Time'] = DateTime.now().toIso8601String();

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle token expiration
    if (err.response?.statusCode == 401) {
      debugPrint('🔑 Received 401 - attempting token refresh');

      final newToken = await ApiConstants.refreshAccessToken();
      if (newToken != null) {
        // Retry the original request with new token
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';

        try {
          final response = await ApiServiceEnhanced._dio.fetch(options);
          handler.resolve(response);
          return;
        } catch (e) {
          debugPrint('Retry after token refresh failed: $e');
        }
      }
    }

    super.onError(err, handler);
  }
}

class _RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retry_count'] as int? ?? 0;

      if (retryCount < ApiServiceEnhanced._maxRetries) {
        debugPrint('Retrying request (attempt ${retryCount + 1})');

        // Exponential backoff
        await Future.delayed(Duration(
          milliseconds: ApiServiceEnhanced._baseDelay.inMilliseconds * (1 << retryCount),
        ));

        // Retry the request
        err.requestOptions.extra['retry_count'] = retryCount + 1;

        try {
          final response = await ApiServiceEnhanced._dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          debugPrint('Retry attempt failed: $e');
        }
      }
    }

    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        // Retry on server errors (5xx) but not client errors (4xx)
        final statusCode = err.response?.statusCode;
        return statusCode != null && statusCode >= 500;
      default:
        return false;
    }
  }
}

class _PerformanceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['start_time'] = DateTime.now().millisecondsSinceEpoch;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _trackPerformance(response.requestOptions, response.statusCode);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _trackPerformance(err.requestOptions, err.response?.statusCode ?? 0, hasError: true);
    super.onError(err, handler);
  }

  void _trackPerformance(RequestOptions options, int? statusCode, {bool hasError = false}) {
    final startTime = options.extra['start_time'] as int?;
    if (startTime != null) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      final endpoint = '${options.method} ${options.path}';

      debugPrint('📊 Performance: $endpoint → ${statusCode ?? 0} (${duration}ms)');

      if (duration > 5000) {
        debugPrint('Slow request detected: $endpoint took ${duration}ms');
      }
    }
  }
}

class _DebugLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🌐 ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('📤 Request Data: ${_sanitizeData(options.data)}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('Response ${response.statusCode}: ${_sanitizeData(response.data)}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('Error ${err.response?.statusCode}: ${err.message}');
    super.onError(err, handler);
  }

  String _sanitizeData(dynamic data) {
    if (data == null) return 'null';

    final str = data.toString();
    // Don't log sensitive information
    if (str.toLowerCase().contains('password')) {
      return '[SENSITIVE DATA HIDDEN]';
    }

    return str.length > 500 ? '${str.substring(0, 500)}...' : str;
  }
}
