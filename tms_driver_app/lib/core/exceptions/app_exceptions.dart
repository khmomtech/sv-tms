// 📁 lib/core/exceptions/app_exceptions.dart

/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message ${code != null ? '(code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication/Authorization exceptions
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Server-side exceptions (4xx, 5xx)
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() =>
      'ServerException: $message ${statusCode != null ? '(status: $statusCode)' : ''} ${code != null ? '(code: $code)' : ''}';
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Cache/Storage exceptions
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Location service exceptions
class LocationException extends AppException {
  const LocationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Generic unexpected exceptions
class UnexpectedException extends AppException {
  const UnexpectedException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}
