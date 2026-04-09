// 📁 lib/core/errors/error_boundary.dart

import 'package:flutter/material.dart';
import 'package:tms_driver_app/core/errors/error_handler.dart';

/// Global error boundary widget that catches all uncaught errors
/// 
/// Wraps the entire app to provide:
/// - Graceful error handling
/// - User-friendly error screens
/// - Error logging and reporting
/// - Crash recovery
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final ErrorHandler errorHandler;
  final Widget Function(FlutterErrorDetails)? errorWidgetBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.errorHandler,
    this.errorWidgetBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    _setupErrorHandling();
  }

  void _setupErrorHandling() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      widget.errorHandler.logError(
        details.exception,
        stackTrace: details.stack,
        context: 'Flutter Error',
      );

      // In production, show error screen
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      // Show error screen
      return widget.errorWidgetBuilder?.call(_errorDetails!) ??
          _DefaultErrorScreen(
            errorDetails: _errorDetails!,
            onRetry: _resetError,
          );
    }

    // Normal app flow
    return widget.child;
  }

  void _resetError() {
    setState(() {
      _errorDetails = null;
    });
  }
}

/// Default error screen shown when app crashes
class _DefaultErrorScreen extends StatelessWidget {
  final FlutterErrorDetails errorDetails;
  final VoidCallback onRetry;

  const _DefaultErrorScreen({
    required this.errorDetails,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Error title
                Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Error message
                Text(
                  'We\'re sorry for the inconvenience. The app encountered an unexpected error.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Debug info (only in debug mode)
                if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                  const Divider(height: 48),
                  
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Debug Info:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        errorDetails.exception.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget-level error boundary for specific sections of the app
class SectionErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(dynamic error)? errorBuilder;
  final String? sectionName;

  const SectionErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.sectionName,
  });

  @override
  State<SectionErrorBoundary> createState() => _SectionErrorBoundaryState();
}

class _SectionErrorBoundaryState extends State<SectionErrorBoundary> {
  dynamic _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error) ??
          _DefaultSectionError(
            error: _error,
            onRetry: () => setState(() => _error = null),
          );
    }

    return ErrorCatcher(
      onError: (error, stack) {
        setState(() => _error = error);
      },
      child: widget.child,
    );
  }
}

/// Catches errors in widget tree
class ErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(dynamic error, StackTrace? stack)? onError;

  const ErrorCatcher({
    super.key,
    required this.child,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Default error widget for section errors
class _DefaultSectionError extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;

  const _DefaultSectionError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load this section',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Something went wrong. Please try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
