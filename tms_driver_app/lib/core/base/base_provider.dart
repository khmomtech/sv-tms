// 📁 lib/core/base/base_provider.dart

import 'package:flutter/foundation.dart';
import 'package:tms_driver_app/core/errors/error_handler.dart';

/// Base provider with common functionality
/// 
/// Provides:
/// - Loading state management
/// - Error handling
/// - Safe state updates
/// - Async operation handling
abstract class BaseProvider with ChangeNotifier {
  final ErrorHandler errorHandler;

  BaseProvider({required this.errorHandler});

  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  /// Loading state getter
  bool get isLoading => _isLoading;

  /// Error message getter
  String? get errorMessage => _errorMessage;

  /// Set loading state with safe state update
  @protected
  void setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message with safe state update
  @protected
  void setError(String? error) {
    if (_isDisposed) return;
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error
  @protected
  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Safe notify listeners (checks if disposed)
  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Execute async operation with automatic loading state and error handling
  @protected
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
    String? context,
  }) async {
    try {
      if (showLoading) setLoading(true);
      clearError();
      
      final result = await operation();
      return result;
    } catch (e, stack) {
      final message = errorHandler.handleAndLog(
        e,
        stackTrace: stack,
        context: context ?? runtimeType.toString(),
      );
      
      setError(message);
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  /// Log debug message
  @protected
  void log(String message) {
    if (kDebugMode) {
      debugPrint('[${runtimeType.toString()}] $message');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
