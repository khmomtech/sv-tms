// lib/core/utils/request_helper.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 🔧 Request Helper utilities for enhanced API communication
class RequestHelper {
  
  /// Check if an error should trigger a retry
  static bool shouldRetry(dynamic error, int attemptCount, int maxRetries) {
    if (attemptCount >= maxRetries) return false;
    
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error.toString().toLowerCase().contains('timeout')) return true;
    if (error.toString().toLowerCase().contains('connection')) return true;
    
    return false;
  }
  
  /// Get exponential backoff delay
  static Duration getBackoffDelay(int attempt) {
    final baseDelay = 1000; // 1 second base
    final delay = baseDelay * (1 << attempt); // 2^attempt
    return Duration(milliseconds: delay.clamp(1000, 10000)); // Max 10 seconds
  }
  
  /// Get timeout based on network conditions
  static Duration getAdaptiveTimeout({bool isSlowNetwork = false}) {
    if (isSlowNetwork) {
      return const Duration(seconds: 45);
    }
    return const Duration(seconds: 30);
  }
  
  /// Sanitize data for logging (hide sensitive info)
  static String sanitizeForLogging(dynamic data) {
    if (data == null) return 'null';
    
    final str = data.toString();
    final lowerStr = str.toLowerCase();
    
    // Hide sensitive data
    if (lowerStr.contains('password') || 
        lowerStr.contains('token') || 
        lowerStr.contains('authorization') ||
        lowerStr.contains('secret')) {
      return '[SENSITIVE DATA HIDDEN]';
    }
    
    // Truncate long responses for readability
    if (str.length > 500) {
      return '${str.substring(0, 500)}... [TRUNCATED]';
    }
    
    return str;
  }
  
  /// Enhanced error message extraction
  static String extractErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error occurred';
    
    if (error is Map<String, dynamic>) {
      return error['message']?.toString() ?? 
             error['error']?.toString() ?? 
             error['detail']?.toString() ?? 
             'Server returned an error';
    }
    
    if (error is SocketException) {
      return 'Network connection failed. Please check your internet connection.';
    }
    
    if (error is HttpException) {
      return 'HTTP request failed: ${error.message}';
    }
    
    final errorStr = error.toString();
    if (errorStr.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    return errorStr;
  }
  
  /// Generate unique request ID for tracking
  static String generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }
  
  /// Log request details
  static void logRequest(String method, String url, Map<String, dynamic>? data) {
    if (!kDebugMode) return;
    
    debugPrint('🌐 $method $url');
    if (data != null) {
      debugPrint('📤 Request: ${sanitizeForLogging(data)}');
    }
  }
  
  /// Log response details
  static void logResponse(int statusCode, dynamic data, {String? requestId}) {
    if (!kDebugMode) return;
    
    final prefix = requestId != null ? '[$requestId]' : '';
    debugPrint('$prefix Response $statusCode: ${sanitizeForLogging(data)}');
  }
  
  /// Log error details
  static void logError(dynamic error, {String? requestId}) {
    if (!kDebugMode) return;
    
    final prefix = requestId != null ? '[$requestId]' : '';
    debugPrint('$prefix Error: ${sanitizeForLogging(error)}');
  }
}