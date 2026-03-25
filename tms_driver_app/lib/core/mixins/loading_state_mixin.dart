// 📁 lib/core/mixins/loading_state_mixin.dart

import 'package:flutter/material.dart';

/// Mixin to add loading state management to providers
mixin LoadingStateMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Execute an async operation with automatic loading state management
  Future<T?> executeWithLoading<T>(
    Future<T> Function() operation, {
    void Function(String error)? onError,
    bool silent = false,
  }) async {
    if (!silent) setLoading(true);
    clearError();

    try {
      final result = await operation();
      return result;
    } catch (e) {
      final errorMsg = e.toString();
      setError(errorMsg);
      onError?.call(errorMsg);
      return null;
    } finally {
      if (!silent) setLoading(false);
    }
  }
}
