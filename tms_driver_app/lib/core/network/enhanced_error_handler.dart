// lib/core/network/enhanced_error_handler.dart
import 'package:flutter/foundation.dart';

/// 🔍 Enhanced error handling and response parsing for consistent API communication
class EnhancedErrorHandler {
  
  /// Parse error response from API and extract structured information
  static ErrorInfo parseApiError(dynamic responseData, int statusCode) {
    debugPrint('🔍 Enhanced Error Parsing:');
    debugPrint('  Status Code: $statusCode');
    debugPrint('  Response Data: $responseData');
    
    if (responseData is Map<String, dynamic>) {
      // Try multiple possible error code locations
      String? code = responseData['code']?.toString() ?? 
                    responseData['error_code']?.toString() ?? 
                    responseData['errorCode']?.toString() ??
                    responseData['errors']?.toString();
      
      final String? message = responseData['message']?.toString() ?? 
                       responseData['error']?.toString() ?? 
                       responseData['detail']?.toString();
      
      // Enhanced device error detection from message if no code
      if (code == null && message != null) {
        code = _detectErrorCodeFromMessage(message);
        debugPrint('  Detected Code from Message: $code');
      }
      
      return ErrorInfo(
        code: code ?? _getDefaultErrorCode(statusCode),
        message: message ?? _getDefaultMessage(statusCode),
        statusCode: statusCode,
        timestamp: DateTime.now(),
        showApprovalButton: _shouldShowApprovalButton(code, message),
      );
    }
    
    return ErrorInfo.fromStatusCode(statusCode);
  }
  
  /// Detect error codes from message content using enhanced pattern matching
  static String? _detectErrorCodeFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    final patterns = {
      'DEVICE_NOT_REGISTERED': [
        'device not registered',
        'register your device',
        'device registration required',
        'device needs registration'
      ],
      'DEVICE_PENDING_APPROVAL': [
        'pending admin approval',
        'pending approval',
        'device is pending',
        'awaiting approval',
        'waiting for approval'
      ],
      'DEVICE_REJECTED': [
        'device was rejected',
        'device rejected',
        'device blocked',
        'device denied'
      ],
      'DEVICE_ACTIVE_ON_OTHER_PHONE': [
        'active on another phone',
        'used in other phone',
        'already active on another device',
        'use the approved phone'
      ],
      'DEVICE_BLOCKED': [
        'device is blocked',
        'blocked device'
      ],
      'DEVICE_NOT_APPROVED': [
        'not approved',
        'device not approved',
        'device approval required'
      ],
      'INVALID_CREDENTIALS': [
        'invalid username',
        'invalid password',
        'invalid credentials',
        'authentication failed',
        'login failed'
      ],
      'USER_NOT_FOUND': [
        'user not found',
        'username not found',
        'account not found'
      ],
      'USER_DISABLED': [
        'user disabled',
        'account disabled',
        'user suspended'
      ],
      'USER_LOCKED': [
        'user locked',
        'account locked',
        'temporarily locked'
      ]
    };
    
    for (final entry in patterns.entries) {
      for (final pattern in entry.value) {
        if (lowerMessage.contains(pattern)) {
          return entry.key;
        }
      }
    }
    
    return null;
  }
  
  /// Determine if approval button should be shown based on error code and message
  static bool _shouldShowApprovalButton(String? code, String? message) {
    if (code != null) {
      return ['DEVICE_NOT_REGISTERED', 'DEVICE_PENDING_APPROVAL', 'DEVICE_REJECTED', 'DEVICE_NOT_APPROVED']
          .contains(code);
    }
    
    if (message != null) {
      final lowerMessage = message.toLowerCase();
      return lowerMessage.contains('device not registered') ||
             lowerMessage.contains('pending approval') ||
             lowerMessage.contains('device rejected') ||
             lowerMessage.contains('not approved');
    }
    
    return false;
  }
  
  /// Get default error code based on HTTP status code
  static String _getDefaultErrorCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 422:
        return 'VALIDATION_ERROR';
      case 500:
        return 'INTERNAL_SERVER_ERROR';
      case 502:
        return 'BAD_GATEWAY';
      case 503:
        return 'SERVICE_UNAVAILABLE';
      default:
        return 'UNKNOWN_ERROR';
    }
  }
  
  /// Get default error message based on HTTP status code
  static String _getDefaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication failed. Please check your credentials.';
      case 403:
        return 'Access denied. You don\'t have permission to access this resource.';
      case 404:
        return 'The requested resource was not found.';
      case 422:
        return 'Validation error. Please check your input data.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Server is temporarily unavailable. Please try again.';
      case 503:
        return 'Service is currently unavailable. Please try again later.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

/// Enhanced error information with comprehensive details
class ErrorInfo {
  final String code;
  final String message;
  final int statusCode;
  final DateTime timestamp;
  final bool showApprovalButton;
  
  const ErrorInfo({
    required this.code,
    required this.message,
    required this.statusCode,
    required this.timestamp,
    this.showApprovalButton = false,
  });
  
  factory ErrorInfo.fromStatusCode(int statusCode) {
    return ErrorInfo(
      code: EnhancedErrorHandler._getDefaultErrorCode(statusCode),
      message: EnhancedErrorHandler._getDefaultMessage(statusCode),
      statusCode: statusCode,
      timestamp: DateTime.now(),
      showApprovalButton: false,
    );
  }
  
  @override
  String toString() => 'ErrorInfo(code: $code, message: $message, status: $statusCode)';
}
