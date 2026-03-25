import 'dart:convert';

Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length < 2) return <String, dynamic>{};
  try {
    final normalized = base64Url.normalize(parts[1]);
    final payload = utf8.decode(base64Url.decode(normalized));
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {
    return <String, dynamic>{};
  }
  return <String, dynamic>{};
}

Set<String> extractRoleClaims(Map<String, dynamic> claims) {
  final roles = <String>{};
  final knownKeys = ['roles', 'authorities', 'scope', 'scopes'];
  for (final key in knownKeys) {
    final value = claims[key];
    if (value is List) {
      for (final role in value) {
        final normalized = _normalizeRole(role?.toString());
        if (normalized != null) roles.add(normalized);
      }
    } else if (value is String) {
      for (final raw in value.split(RegExp(r'[,\s]+'))) {
        final normalized = _normalizeRole(raw);
        if (normalized != null) roles.add(normalized);
      }
    }
  }
  return roles;
}

String? _normalizeRole(String? input) {
  if (input == null) return null;
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('ROLE_')) return trimmed;
  return 'ROLE_$trimmed';
}
