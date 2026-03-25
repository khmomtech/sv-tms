Map<String, dynamic> asMap(dynamic input) {
  if (input is Map<String, dynamic>) return input;
  if (input is Map) {
    return input.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

Map<String, dynamic> unwrapData(dynamic body) {
  final map = asMap(body);
  final inner = map['data'];
  if (inner is Map<String, dynamic>) return inner;
  if (inner is Map) {
    return inner.map((key, value) => MapEntry(key.toString(), value));
  }
  return map;
}

List<Map<String, dynamic>> unwrapDataList(dynamic body) {
  final map = asMap(body);
  final raw = map['data'] is List ? map['data'] : body;
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}

int? asInt(dynamic value) {
  if (value is int) return value;
  if (value == null) return null;
  return int.tryParse(value.toString());
}
