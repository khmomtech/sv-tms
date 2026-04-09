// 📁 lib/core/errors/error_handler.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Centralized error handling service
/// 
/// Provides:
/// - Consistent error message formatting
/// - Error logging and reporting
/// - User-friendly error messages
/// - Error analytics tracking
class ErrorHandler {
  /// Convert any error to user-friendly message
  String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is AppException) {
      return error.message;
    } else if (error is String) {
      return error;
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle Dio/HTTP errors
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response);
      
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      
      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please contact support.';
      
      case DioExceptionType.unknown:
        return 'Network error. Please try again.';
    }
  }

  /// Handle HTTP response errors
  String _handleHttpError(Response? response) {
    if (response == null) {
      return 'Server error. Please try again later.';
    }

    final statusCode = response.statusCode ?? 0;
    
    // Try to extract error message from response body
    String? serverMessage;
    if (response.data is Map<String, dynamic>) {
      serverMessage = response.data['message'] as String?;
    }

    switch (statusCode) {
      case 400:
        return serverMessage ?? 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'Resource not found.';
      case 409:
        return serverMessage ?? 'Conflict error. Resource already exists.';
      case 422:
        return serverMessage ?? 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server error. Please try again later.';
      default:
        return serverMessage ?? 'Request failed. Please try again.';
    }
  }

  /// Log error for debugging and analytics
  void logError(dynamic error, {StackTrace? stackTrace, String? context}) {
    if (kDebugMode) {
      debugPrint('🔴 ERROR ${context != null ? '[$context]' : ''}: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }
    
    // TODO: Send to analytics/crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // Example:
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, context: context);
  }

  /// Handle and log error, then return user-friendly message
  String handleAndLog(dynamic error, {StackTrace? stackTrace, String? context}) {
    logError(error, stackTrace: stackTrace, context: context);
    return getErrorMessage(error);
  }
}

/// Base class for custom application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Authentication/Authorization exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  
  const ValidationException(super.message, {this.fieldErrors, super.code});
}

/// Server error exceptions
class ServerException extends AppException {
  final int? statusCode;
  
  const ServerException(super.message, {this.statusCode, super.code});
}

/// Cache/Storage exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}
