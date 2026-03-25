// 📁 lib/core/utils/result.dart

/// A Result type for handling success and failure cases with better type safety
/// than nullable values or throwing exceptions
sealed class Result<T> {
  const Result();

  /// Transform the success value if present
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(value: final v) => Success(transform(v)),
      Failure(error: final e) => Failure(e),
    };
  }

  /// Execute different callbacks based on success or failure
  R when<R>({
    required R Function(T value) success,
    required R Function(dynamic error) failure,
  }) {
    return switch (this) {
      Success(value: final v) => success(v),
      Failure(error: final e) => failure(e),
    };
  }

  /// Check if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Check if this is a failure result
  bool get isFailure => this is Failure<T>;

  /// Get the value if success, otherwise return null
  T? get valueOrNull => switch (this) {
        Success(value: final v) => v,
        Failure() => null,
      };

  /// Get the value if success, otherwise return default
  T getOrElse(T defaultValue) => switch (this) {
        Success(value: final v) => v,
        Failure() => defaultValue,
      };
}

/// Successful result with value
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Failed result with error
final class Failure<T> extends Result<T> {
  final dynamic error;
  final StackTrace? stackTrace;

  const Failure(this.error, [this.stackTrace]);

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => error.hashCode;
}
