// 📁 lib/core/base/base_stateful_widget.dart

import 'package:flutter/material.dart';
import 'package:tms_driver_app/core/di/service_locator.dart';
import 'package:tms_driver_app/core/errors/error_handler.dart';

/// Base stateful widget with dependency injection support
/// 
/// Provides:
/// - Access to service locator
/// - Error handling utilities
/// - Loading state management
/// - Common widget helpers
abstract class BaseStatefulWidget extends StatefulWidget {
  const BaseStatefulWidget({super.key});
}

abstract class BaseState<T extends BaseStatefulWidget> extends State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  /// Get dependency from service locator
  @protected
  S getIt<S extends Object>() => sl<S>();

  /// Get error handler
  @protected
  ErrorHandler get errorHandler => getIt<ErrorHandler>();

  /// Loading state getter
  @protected
  bool get isLoading => _isLoading;

  /// Error message getter
  @protected
  String? get errorMessage => _errorMessage;

  /// Set loading state
  @protected
  void setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoading = loading);
    }
  }

  /// Set error message
  @protected
  void setError(String? error) {
    if (mounted) {
      setState(() => _errorMessage = error);
    }
  }

  /// Clear error
  @protected
  void clearError() {
    if (mounted) {
      setState(() => _errorMessage = null);
    }
  }

  /// Execute async operation with loading state and error handling
  @protected
  Future<void> executeAsync(
    Future<void> Function() operation, {
    bool showLoading = true,
    void Function(dynamic error)? onError,
  }) async {
    try {
      if (showLoading) setLoading(true);
      clearError();

      await operation();
    } catch (e, stack) {
      final message = errorHandler.handleAndLog(
        e,
        stackTrace: stack,
        context: runtimeType.toString(),
      );

      if (!mounted) {
        return;
      }

      setError(message);

      if (onError != null) {
        onError(e);
      } else {
        showError(context, e);
      }
    } finally {
      if (showLoading) setLoading(false);
    }
  }

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

  /// Show loading indicator
  @protected
  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Show error widget
  @protected
  Widget buildError(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show empty state widget
  @protected
  Widget buildEmpty({
    String message = 'No data available',
    IconData icon = Icons.inbox_outlined,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
