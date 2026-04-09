import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simple API smoke test against a running backend on localhost:8080.
///
/// Pre-req: Backend up (docker compose or Spring Boot), DB seeded with admin user.
void main() {
  const bool runSmoke = bool.fromEnvironment('RUN_SMOKE_TESTS', defaultValue: false);
  const String base = 'http://localhost:8080/api';
  final dio = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 10)));

  String? token;
  String? refreshToken;

  test('Login as admin returns token + refreshToken', () async {
    final resp = await dio.post('/auth/login',
        data: jsonEncode({
          'username': 'admin',
          'password': 'admin123',
        }),
        options: Options(headers: {'Content-Type': 'application/json'}));

    expect(resp.statusCode, 200);
    final data = resp.data is Map ? resp.data as Map : jsonDecode(resp.data as String) as Map;
    // Accept either wrapped or flat response shapes
    final body = data['data'] is Map ? data['data'] as Map : data;

    token = body['token'] as String?;
    refreshToken = body['refreshToken'] as String?;

    expect(token, isNotNull, reason: 'token should be present');
    expect(token!.length > 20, true, reason: 'token appears non-empty');
    expect(refreshToken, isNotNull, reason: 'refreshToken should be present');
  }, skip: !runSmoke);

  test('Admin can access unread notifications count', () async {
    expect(token, isNotNull, reason: 'login must run first');
    final resp = await dio.get('/notifications/admin/count',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    expect(resp.statusCode, 200);
    final data = resp.data is Map ? resp.data as Map : jsonDecode(resp.data as String) as Map;
    // ApiResponse shape: { success: true, data: <num>, ... }
    if (data.containsKey('success')) {
      expect(data['success'], true);
      expect(data.containsKey('data'), true);
    } else {
      // Fallback: expect numeric body or count field
      expect(data['count'] ?? data['data'], isNotNull);
    }
  }, skip: !runSmoke);

  test('Refresh token endpoint returns new accessToken', () async {
    expect(refreshToken, isNotNull, reason: 'login must run first');
    // Backend expects refresh token in Authorization header (Bearer <refresh>)
    final resp = await dio.post(
      '/auth/refresh',
      options: Options(headers: {
        'Authorization': 'Bearer $refreshToken',
        'Accept': 'application/json',
      }),
    );
    expect(resp.statusCode, 200);
    final data = resp.data is Map ? resp.data as Map : jsonDecode(resp.data as String) as Map;
    final body = data['data'] is Map ? data['data'] as Map : data;
    final newToken = body['accessToken'] ?? body['token'];
    expect(newToken, isNotNull);
  }, skip: !runSmoke);
}
