import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tms_customer_app/services/auth_service.dart';
import 'package:tms_customer_app/services/local_storage.dart';
import 'package:tms_customer_app/models/auth_models.dart';

class _InMemoryStorage extends LocalStorage {
  String? _token;
  String? _refresh;
  UserInfo? _user;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _refresh = token;
  }

  @override
  Future<void> saveUserInfo(UserInfo? user) async {
    _user = user;
  }

  @override
  Future<String?> getToken() async => _token;
  @override
  Future<String?> getRefreshToken() async => _refresh;
  @override
  Future<UserInfo?> getUserInfo() async => _user;
  @override
  Future<void> clearToken() async {
    _token = null;
  }

  @override
  Future<void> clearRefreshToken() async {
    _refresh = null;
  }

  @override
  Future<void> clearUserInfo() async {
    _user = null;
  }
}

void main() {
  group('AuthService', () {
    test('login success saves token and user', () async {
      final storage = _InMemoryStorage();
      final mockClient = MockClient((req) async {
        final body = {
          'code': 'LOGIN_SUCCESS',
          'message': 'ok',
          'token': 'abc123',
          'refreshToken': 'ref123',
          'user': {
            'username': 'test',
            'email': 'test@example.com',
            'roles': ['CUSTOMER'],
            'permissions': []
          }
        };
        return http.Response(jsonEncode(body), 200);
      });

      final service = AuthService(storage: storage, client: mockClient);
      final resp = await service.login('test', 'pass');
      // verify storage was updated
      final savedToken = await storage.getToken();
      final savedRefresh = await storage.getRefreshToken();
      final savedUser = await storage.getUserInfo();

      expect(resp.code, equals('LOGIN_SUCCESS'));
      expect(savedToken, equals('abc123'));
      expect(savedRefresh, equals('ref123'));
      expect(savedUser?.username, equals('test'));
    });
  });
}
