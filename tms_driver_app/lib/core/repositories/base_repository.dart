// 📁 lib/core/repositories/base_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Base repository providing common data operations and error handling
///
/// All repositories should extend this class to benefit from:
/// - Standardized error handling
/// - Network timeout configurations
/// - Retry logic with exponential backoff
/// - Cache invalidation helpers
abstract class BaseRepository {
  final Dio dio;

  BaseRepository({required this.dio}) {
    _configureDio();
  }

  void _configureDio() {
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);
    dio.options.sendTimeout = const Duration(seconds: 60);
  }

  /// Execute an API call with automatic retry logic
  ///
  /// - [maxRetries]: Maximum number of retry attempts (default: 2)
  /// - [backoffMultiplier]: Exponential backoff multiplier in milliseconds (default: 400ms)
  /// - [label]: Optional label for logging purposes
  @protected
  Future<T> executeWithRetry<T>(
    Future<T> Function() apiCall, {
    int maxRetries = 2,
    int backoffMultiplier = 400,
    String? label,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        return await apiCall();
      } catch (e) {
        if (attempt >= maxRetries) {
          _logError(
              '${label ?? 'API call'} failed after ${attempt + 1} attempts', e);
          rethrow;
        }

        final backoffDuration = Duration(
          milliseconds: backoffMultiplier * (1 << attempt),
        );

        _logRetry(label ?? 'API call', attempt + 1, backoffDuration, e);
        await Future.delayed(backoffDuration);
        attempt++;
      }
    }
  }

  /// Handle API errors and convert to user-friendly messages
  @protected
  String handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return 'Session expired. Please login again.';
          } else if (statusCode == 403) {
            return 'Access denied. You don\'t have permission.';
          } else if (statusCode == 404) {
            return 'Resource not found.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }
          return error.response?.data['message'] ?? 'Request failed.';

        case DioExceptionType.cancel:
          return 'Request cancelled.';

        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';

        default:
          return 'An unexpected error occurred. Please try again.';
      }
    }

    return error.toString();
  }

  /// Log debug information (only in debug mode)
  @protected
  void log(String message) {
    if (kDebugMode) {
      debugPrint('[${runtimeType.toString()}] $message');
    }
  }

  /// Log retry attempts
  void _logRetry(
      String operation, int attempt, Duration backoff, dynamic error) {
    log('Retry attempt $attempt for $operation after $backoff - Error: $error');
  }

  /// Log errors
  void _logError(String message, dynamic error) {
    log('ERROR: $message - $error');
  }
}
