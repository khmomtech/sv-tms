// 📁 lib/core/services/error_handler_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../utils/logger.dart';

/// Centralized error handling service
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// Handle and report errors
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    final errorContext = context ?? 'Unknown';
    
    // Log locally
    Logger.error(
      'Error in $errorContext: ${error.toString()}',
      tag: 'ErrorHandler',
    );

    // Send to Sentry in production
    if (kReleaseMode) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace ?? StackTrace.current,
        withScope: (scope) {
          scope.setContexts('error_context', {
            'location': errorContext,
            if (extras != null) ...extras,
          });

          // Set fingerprint for better grouping
          if (error is AppException) {
            scope.fingerprint = [
              error.runtimeType.toString(),
              error.code ?? 'no_code',
            ];
          }
        },
      );
    }

    // Handle specific exception types
    if (error is AppException) {
      _handleAppException(error);
    }
  }

  void _handleAppException(AppException exception) {
    // Add specific handling logic for different exception types
    if (exception is AuthException) {
      // Could trigger logout or re-authentication flow
      Logger.warning('Auth error occurred: ${exception.message}');
    } else if (exception is NetworkException) {
      // Could show connectivity warning
      Logger.warning('Network error occurred: ${exception.message}');
    } else if (exception is ServerException) {
      // Could show server maintenance message
      Logger.warning('Server error occurred: ${exception.message}');
    }
  }

  /// Format user-friendly error message
  String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    } else if (error is FormatException) {
      return 'Invalid data format';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An unexpected error occurred';
    }
  }
}
