import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

class AuthService {
  AuthService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 25),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio;

  Future<void> login(String username, String password) async {
    Response response;
    try {
      response = await _dio.post(
        '/api/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        throw Exception(body['message'].toString());
      }
      throw Exception(e.message ?? 'Login failed');
    }

    final Map<String, dynamic> body = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    if (body['success'] == false) {
      throw Exception((body['message'] ?? 'Login failed').toString());
    }
    // Backend wraps payload in ApiResponse { success, message, code, data: {...} }
    final Map<String, dynamic> payload = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : body;

    final token = (payload['token'] ?? payload['accessToken'])?.toString();
    final refreshToken = payload['refreshToken']?.toString();
    final user = payload['user'] is Map
        ? Map<String, dynamic>.from(payload['user'])
        : null;
    final tokenClaims = _decodeJwtPayload(token);
    final userId = (payload['userId'] ??
            user?['id'] ??
            tokenClaims?['userId'] ??
            tokenClaims?['id'])
        ?.toString();
    final fullName =
        (payload['fullName'] ?? user?['fullName'] ?? user?['name'])?.toString();

    // Roles may come from data.roles or data.user.roles
    final roles = (payload['roles'] as List?) ??
        (payload['user'] is Map ? (payload['user']['roles'] as List?) : null) ??
        <String>[];
    final roleStrings = roles.map((r) => r.toString()).toList();

    if (token == null || token.isEmpty) {
      final message = payload['message'] ??
          body['message'] ??
          'Missing token from login response';
      throw Exception(message.toString());
    }

    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'refreshToken', value: refreshToken);
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'roles', value: roleStrings.join(','));
    if (userId != null) {
      await _storage.write(key: 'userId', value: userId);
    }
    if (fullName != null) {
      await _storage.write(key: 'fullName', value: fullName);
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() => _storage.read(key: 'token');
  Future<String?> getUsername() => _storage.read(key: 'username');
  Future<String?> getUserId() => _storage.read(key: 'userId');
  Future<String?> getFullName() => _storage.read(key: 'fullName');

  Future<List<String>> getRoles() async {
    final raw = await _storage.read(key: 'roles');
    if (raw == null || raw.isEmpty) return <String>[];
    return raw.split(',').where((e) => e.isNotEmpty).toList();
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // --- Simple PIN storage for quick unlock (stored in secure storage) ---
  static const _pinKey = 'login_pin';

  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<bool> isPinSet() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored == pin;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }

  Map<String, dynamic>? _decodeJwtPayload(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final parsed = jsonDecode(payload);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
      return null;
    } catch (_) {
      return null;
    }
  }
}
