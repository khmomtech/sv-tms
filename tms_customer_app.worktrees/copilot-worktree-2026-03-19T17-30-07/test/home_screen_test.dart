import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tms_customer_app/screens/home/home_screen.dart';
import 'package:tms_customer_app/providers/auth_provider.dart';
import 'package:tms_customer_app/providers/notification_provider.dart';
import 'package:tms_customer_app/services/auth_service.dart';
import 'package:tms_customer_app/services/local_storage.dart';
import 'package:tms_customer_app/models/auth_models.dart' as auth_models;
import 'package:easy_localization/easy_localization.dart';

// Minimal test implementation of AuthService to satisfy AuthProvider
class TestLocalStorage extends LocalStorage {
  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> clearToken() async {}

  @override
  Future<void> saveRefreshToken(String token) async {}

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> clearRefreshToken() async {}

  @override
  Future<void> saveUserInfo(userInfo) async {}

  @override
  @override
  Future<auth_models.UserInfo?> getUserInfo() async => null;

  @override
  Future<void> clearUserInfo() async {}
}

// Lightweight subclass of the real NotificationProvider that avoids network
// activity during widget tests. It uses the test AuthService (which returns
// no token) so the provider won't attempt to connect.
class TestNotificationProvider extends NotificationProvider {
  TestNotificationProvider({required AuthService authService})
      : super(authService: authService, baseUrl: 'http://localhost:8080');

  @override
  Future<void> connectWebSocket(String customerId) async {
    // no-op in tests
  }

  @override
  void disconnectWebSocket() {
    // no-op in tests
  }

  @override
  void markAsRead(int id) {
    // no-op in tests
  }
}

/// Minimal AssetLoader for tests that returns a small translations map so
/// `tr()` calls don't emit warnings during widget tests.
class TestAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {
      'myOrders': 'My Orders',
      'logout': 'Logout',
      'active_shipments': 'Active Shipments',
      'no_orders_title': 'No orders yet',
      'no_orders_message': 'You have no active shipments',
      'app_title': 'SV',
      'hi_user': 'Hi, {name}!',
      'home_subtitle': 'Welcome back',
      'promo_title': 'Promo',
      'promo_subtitle': 'Get 10% off',
      'book_now': 'Book now',
      'book_shipment': 'Book shipment',
      'track_order': 'Track order',
      'payments': 'Payments',
      'history': 'History',
      'services_pricing_title': 'Services & Pricing',
      'view_full': 'View full',
      'small_package': 'Small package',
      'medium_package': 'Medium package',
      'large_package': 'Large package',
      'phnom_penh': 'Phnom Penh',
    };
  }
}

void main() {
  testWidgets('HomeScreen builds without exceptions',
      (WidgetTester tester) async {
    // initialize EasyLocalization for tests
    await EasyLocalization.ensureInitialized();
    final testStorage = TestLocalStorage();
    final authService = AuthService(storage: testStorage);
    final authProvider = AuthProvider(authService: authService);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/lang',
        assetLoader: TestAssetLoader(),
        child: MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              // provide a lightweight test notification provider
              ChangeNotifierProvider<NotificationProvider>(
                  create: (_) =>
                      TestNotificationProvider(authService: authService)),
            ],
            child: const HomeScreen(),
          ),
        ),
      ),
    );

    // allow a frame and a short follow-up pump; avoid waiting indefinitely in CI
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // ensure no build exceptions were thrown
    expect(tester.takeException(), isNull);
  });

  test('NumberFormat.simpleCurrency produces two-decimal output', () {
    final fmt = NumberFormat.simpleCurrency(locale: 'en_US');
    final out = fmt.format(1.5);
    expect(RegExp(r"\d+\.\d{2}").hasMatch(out), isTrue);
  });
}
