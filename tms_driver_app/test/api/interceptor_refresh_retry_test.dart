import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';

/// This test verifies that the Dio auth interceptor automatically refreshes
/// an expired/invalid access token and retries the original request.
///
/// Requirements to run:
/// - Backend running on http://localhost:8080 with admin credentials
/// - flutter_secure_storage available in test environment (run as integration)
/// - Set env RUN_REFRESH_TEST=1 to enable
void main() {
  // Ensure Flutter bindings are available for shared_preferences/secure_storage.
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  // Allow real HTTP calls inside widget test binding (needed for integration-style test).
  HttpOverrides.global = null;

  final shouldRun = Platform.environment['RUN_REFRESH_TEST'] == '1';
  if (!shouldRun) {
    // Skip gracefully when not explicitly enabled
    test('skipped: enable by setting RUN_REFRESH_TEST=1', () {
      expect(true, true);
    });
    return;
  }

  const String base = 'http://localhost:8080/api';
  final raw = Dio(BaseOptions(baseUrl: base));

  late String refreshToken;

  setUpAll(() async {
    // Point ApiConstants to local backend
    await ApiConstants.setBaseUrlOverride('http://localhost:8080/api');

    // Login to obtain a valid refresh token
    final resp = await raw.post('/auth/login',
        data: jsonEncode({
          'username': 'admin',
          'password': 'admin123',
        }),
        options: Options(headers: {'Content-Type': 'application/json'}));
    expect(resp.statusCode, 200);
    final data = resp.data is Map
        ? resp.data as Map
        : jsonDecode(resp.data as String) as Map;
    final body = data['data'] is Map ? data['data'] as Map : data;
    refreshToken = body['refreshToken'] as String;

    // Seed secure storage with an invalid access token + valid refresh token
    await ApiConstants.saveTokens(accessToken: 'invalid-token', refreshToken: refreshToken);
  });

  test('401 triggers refresh + retry via interceptor', () async {
    final client = DioClient();
    final res = await client.dio.get('/notifications/admin/count');
    expect(res.statusCode, 200);
    // Basic shape assertions
    if (res.data is Map) {
      final m = res.data as Map;
      if (m.containsKey('success')) {
        expect(m['success'], true);
      }
    }
  });
}
