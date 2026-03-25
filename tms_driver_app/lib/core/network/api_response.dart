// lib/core/network/api_response.dart

/// A generic wrapper for API results with status, message and optional metadata.
class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;
  final int? statusCode;
  final dynamic errorData; // raw error payload when available

  ApiResponse({this.data, this.message, required this.success, this.statusCode, this.errorData});

  /// Construct a successful response
  factory ApiResponse.success(T data) => ApiResponse(data: data, success: true);

  /// Construct a failure response with a message
    factory ApiResponse.failure(String message, {int? statusCode, dynamic errorData}) =>
      ApiResponse(message: message, success: false, statusCode: statusCode, errorData: errorData);

  /// Helpful check for status
  bool get hasData => success && data != null;
}
