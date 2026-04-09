import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Integration test for driver dispatch APIs using a real driver token.
/// Guarded by env flag to avoid accidental backend hits.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // allow real HTTP

  final env = Platform.environment;
  final baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: env['API_BASE_URL'] ?? 'http://localhost:8080/api');
  final driverUsername = env['DISPATCH_USERNAME'] ?? 'testdriver';
  final driverPassword = env['DISPATCH_PASSWORD'] ?? 'password';
  final driverId = int.tryParse(env['DISPATCH_DRIVER_ID'] ?? '') ?? 79; // default from docs
  final deviceId = env['DISPATCH_DEVICE_ID'] ?? 'driver-dispatch-int-device';

  final shouldRun = Platform.environment['RUN_DISPATCH_TEST'] == '1';
  if (!shouldRun) {
    test('skipped: set RUN_DISPATCH_TEST=1 to run dispatch API integration', () {
      expect(true, isTrue);
    });
    return;
  }

  test('driver can login and list dispatches', () async {
    final adminToken = await _loginAdmin(baseUrl);
    expect(adminToken, isNotEmpty, reason: 'Admin login failed');

    try {
      await _ensureDeviceApproved(
        baseUrl,
        adminToken: adminToken,
        driverId: driverId,
        deviceId: deviceId,
      );
    } on _SkipTest catch (e) {
      // Device endpoints may be permission-restricted in some environments.
      print('SKIP: ${e.message}');
      return;
    }

    final driverAuth = await _loginDriver(
      baseUrl,
      username: driverUsername,
      password: driverPassword,
      deviceId: deviceId,
    );
    expect(driverAuth.accessToken, isNotEmpty, reason: 'Driver login failed');

    final listRes = await http.get(
      Uri.parse('$baseUrl/driver/dispatches/driver/$driverId'),
      headers: {'Authorization': 'Bearer ${driverAuth.accessToken}'},
    );
    expect(listRes.statusCode, 200);
    final listBody = jsonDecode(listRes.body);
    expect(listBody is Map, true);
    expect(listBody.containsKey('content'), true,
        reason: 'Dispatch page response missing content key');

    // Status-filtered endpoint should also be reachable.
    final statusRes = await http.get(
      Uri.parse('$baseUrl/driver/dispatches/driver/$driverId/status?status=ASSIGNED'),
      headers: {'Authorization': 'Bearer ${driverAuth.accessToken}'},
    );
    expect(statusRes.statusCode, 200);
  });
}

/// ----- Helpers -----

Future<String> _loginAdmin(String baseUrl) async {
  final resp = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': 'admin', 'password': 'admin123'}),
  );
  if (resp.statusCode != 200) return '';
  final data = jsonDecode(resp.body);
  final Map body = data['data'] is Map ? data['data'] as Map : data as Map;
  return (body['token'] ?? body['accessToken'] ?? '') as String? ?? '';
}

class _DriverAuth {
  _DriverAuth(this.accessToken, this.refreshToken);
  final String accessToken;
  final String refreshToken;
}

Future<_DriverAuth> _loginDriver(
  String baseUrl, {
  required String username,
  required String password,
  required String deviceId,
}) async {
  final resp = await http.post(
    Uri.parse('$baseUrl/auth/driver/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': username,
      'password': password,
      'deviceId': deviceId,
    }),
  );
  if (resp.statusCode != 200) {
    throw Exception('Driver login failed: ${resp.statusCode} ${resp.body}');
  }
  final data = jsonDecode(resp.body);
  final Map body = data['data'] is Map ? data['data'] as Map : data as Map;
  final access = (body['token'] ?? body['accessToken'] ?? '') as String? ?? '';
  final refresh = (body['refreshToken'] ?? '') as String? ?? '';
  if (access.isEmpty) {
    throw Exception('Driver login missing access token: ${resp.body}');
  }
  return _DriverAuth(access, refresh);
}

Future<void> _ensureDeviceApproved(
  String baseUrl, {
  required String adminToken,
  required int driverId,
  required String deviceId,
}) async {
  final headers = {
    'Authorization': 'Bearer $adminToken',
    'Content-Type': 'application/json',
  };

  // First, see if device already exists.
  final listResp = await http.get(Uri.parse('$baseUrl/driver/device/all'), headers: headers);
  int? devicePk;
  String? status;
  if (listResp.statusCode == 200) {
    final data = jsonDecode(listResp.body);
    if (data is Map && data['data'] is List) {
      for (final item in data['data'] as List) {
        if (item is Map &&
            item['deviceId'] == deviceId &&
            (item['driverId']?.toString() == driverId.toString())) {
          devicePk = item['id'] as int?;
          status = item['status'] as String?;
          break;
        }
      }
    }
  } else if (listResp.statusCode == 403) {
    throw _SkipTest('Device list endpoint forbidden for admin token.');
  }

  if (devicePk == null) {
    // Create device with APPROVED status.
    final createResp = await http.post(
      Uri.parse('$baseUrl/driver/device/create'),
      headers: headers,
      body: jsonEncode({
        'driverId': driverId,
        'deviceId': deviceId,
        'deviceName': 'driver-dispatch-int',
        'os': 'android',
        'version': '1.0.0',
        'status': 'APPROVED',
      }),
    );
    if (createResp.statusCode == 200) {
      final data = jsonDecode(createResp.body);
      final created = (data is Map && data['data'] is Map) ? data['data'] as Map : <String, dynamic>{};
      devicePk = created['id'] as int?;
      status = created['status'] as String?;
    } else if (createResp.statusCode == 403) {
      throw _SkipTest('Device create endpoint forbidden for admin token.');
    } else {
      throw Exception('Failed to create device: ${createResp.statusCode} ${createResp.body}');
    }
  }

  // Approve if not already approved.
  if (devicePk != null && status != 'APPROVED') {
    final approveResp = await http.put(
      Uri.parse('$baseUrl/driver/device/approve/$devicePk'),
      headers: headers,
    );
    if (approveResp.statusCode == 403) {
      throw _SkipTest('Device approve endpoint forbidden for admin token.');
    }
    if (approveResp.statusCode != 200) {
      throw Exception('Failed to approve device $devicePk: ${approveResp.statusCode} ${approveResp.body}');
    }
  }
}

class _SkipTest implements Exception {
  _SkipTest(this.message);
  final String message;
}
