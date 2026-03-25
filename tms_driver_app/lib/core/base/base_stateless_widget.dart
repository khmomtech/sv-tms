// 📁 lib/core/base/base_stateless_widget.dart

import 'package:flutter/material.dart';
import 'package:tms_driver_app/core/di/service_locator.dart';
import 'package:tms_driver_app/core/errors/error_handler.dart';

/// Base stateless widget with dependency injection support
/// 
/// Provides:
/// - Access to service locator
/// - Error handling utilities
/// - Common widget helpers
abstract class BaseStatelessWidget extends StatelessWidget {
  const BaseStatelessWidget({super.key});

  /// Get dependency from service locator
  @protected
  T getIt<T extends Object>() => sl<T>();

  /// Get error handler
  @protected
  ErrorHandler get errorHandler => getIt<ErrorHandler>();

  /// Show error message
  @protected
  void showError(BuildContext context, dynamic error) {
    final message = errorHandler.getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success message
  @protected
  void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info message
  @protected
  void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
