/// Utility helpers for unwrapping generated ApiResponse* types.
/// The generated models typically expose a `data` field containing the payload.
/// We keep this generic to avoid tight coupling with individual response classes.

T? unwrapData<T>(dynamic apiResponse) {
  if (apiResponse == null) return null;
  try {
    // Common pattern: class has a `data` getter or field
    final value = (apiResponse as dynamic).data;
    return value is T ? value : value as T?;
  } catch (_) {
    return apiResponse as T?; // fallback if structure differs
  }
}

List<E>? unwrapList<E>(dynamic apiResponse) {
  final data = unwrapData<List<dynamic>>(apiResponse);
  if (data == null) return null;
  return data.map((e) => e as E).toList();
}

/// Attempt to read a `message` field if present.
String? unwrapMessage(dynamic apiResponse) {
  if (apiResponse == null) return null;
  try {
    final msg = (apiResponse as dynamic).message;
    if (msg is String) return msg;
  } catch (_) {}
  return null;
}
