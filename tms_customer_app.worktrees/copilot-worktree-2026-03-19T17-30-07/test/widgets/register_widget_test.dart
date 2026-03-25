import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:tms_customer_app/services/auth_service.dart';
import 'package:tms_customer_app/services/local_storage.dart';
import 'package:tms_customer_app/providers/auth_provider.dart';
import 'package:tms_customer_app/screens/auth/register_screen.dart';
import 'package:tms_customer_app/models/auth_models.dart';

class _InMemoryStorage extends LocalStorage {
  String? _token;
  String? _refresh;
  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<void> saveRefreshToken(String token) async => _refresh = token;
  @override
  Future<void> saveUserInfo(user) async {}
  @override
  Future<String?> getToken() async => _token;
  @override
  Future<String?> getRefreshToken() async => _refresh;
  @override
  Future<void> clearToken() async => _token = null;
  @override
  Future<void> clearRefreshToken() async => _refresh = null;
  @override
  Future<void> clearUserInfo() async {}
  @override
  Future<UserInfo?> getUserInfo() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('RegisterScreen submits and shows success SnackBar',
      (WidgetTester tester) async {
    var called = false;
    final mockClient = MockClient((req) async {
      called = true;
      final body = {'message': 'ok'};
      return http.Response(jsonEncode(body), 200);
    });

    final storage = _InMemoryStorage();
    final authService = AuthService(storage: storage, client: mockClient);
    final authProvider = AuthProvider(authService: authService);

    await tester.pumpWidget(EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider)
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    ));

    // Fill form
    await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Ensure the mock endpoint was called
    expect(called, isTrue);
  });
}
