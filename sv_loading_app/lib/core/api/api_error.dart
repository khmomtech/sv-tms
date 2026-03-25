import 'package:dio/dio.dart';

class ApiError {
  final int? statusCode;
  final String message;
  final String? requestId;
  final Map<String, String> fieldErrors;
  final bool isNetworkError;

  const ApiError({
    required this.message,
    this.statusCode,
    this.requestId,
    this.fieldErrors = const {},
    this.isNetworkError = false,
  });
}

ApiError parseApiError(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        (error.message ?? '').toLowerCase().contains('failed host lookup')) {
      return const ApiError(
        message: 'Network error. Check your connection and API host.',
        isNetworkError: true,
      );
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorsRaw = data['errors'];
      final fieldErrors = <String, String>{};
      if (errorsRaw is Map) {
        for (final entry in errorsRaw.entries) {
          fieldErrors[entry.key.toString()] =
              entry.value?.toString() ?? 'Invalid value';
        }
      }

      final status =
          statusCode ?? (data['status'] is int ? data['status'] as int : null);
      final message = data['message']?.toString() ??
          data['error']?.toString() ??
          'Request failed with status ${status ?? 'unknown'}.';
      return ApiError(
        message: message,
        statusCode: status,
        requestId: data['requestId']?.toString(),
        fieldErrors: fieldErrors,
      );
    }

    return ApiError(
      message: error.message ?? 'Request failed.',
      statusCode: statusCode,
    );
  }

  return ApiError(message: error.toString());
}
