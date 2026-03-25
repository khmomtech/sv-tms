import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/screens/shipment/profile_screen_modern.dart';

import '_http_overrides.dart';

class _FakeDriverProvider extends DriverProvider {
  final Map<String, dynamic>? _profile;
  final Map<String, dynamic>? _monthly;
  final String? _id;
  final bool _loading;
  bool updateCalled = false;
  String? updatedFirstName;
  String? updatedLastName;
  String? updatedPhone;
  final bool updateResult;

  _FakeDriverProvider({
    Map<String, dynamic>? profile,
    Map<String, dynamic>? monthly,
    String? driverId,
    bool isLoading = false,
    this.updateResult = true,
  })  : _profile = profile,
        _monthly = monthly,
        _id = driverId,
        _loading = isLoading;

  @override
  Map<String, dynamic>? get driverProfile => _profile;

  @override
  Map<String, dynamic>? get currentMonthPerformance => _monthly;

  @override
  String? get driverId => _id;

  @override
  bool get isLoading => _loading;

  @override
  Future<void> initializeDriverSession() async {}

  @override
  Future<void> fetchDriverProfile({int retryCount = 0}) async {}

  @override
  Future<void> fetchCurrentMonthPerformance() async {}

  @override
  Future<void> fetchCurrentAssignment() async {}

  @override
  Future<bool> updateBasicProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    updateCalled = true;
    updatedFirstName = firstName;
    updatedLastName = lastName;
    updatedPhone = phoneNumber;
    return updateResult;
  }
}

Widget _buildApp({
  required Locale locale,
  required DriverProvider provider,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('km')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    child: Builder(
      builder: (context) {
        return ChangeNotifierProvider<DriverProvider>.value(
          value: provider,
          child: MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const ProfileScreenModern(),
          ),
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = AllowHttpOverrides();
    ApiConstants.skipSecureStorageForTests = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'accessToken': 'test-access-token',
      'refreshToken': 'test-refresh-token',
    });
  });

  testWidgets('Profile screen renders English labels', (tester) async {
    final provider = _FakeDriverProvider(
      driverId: '889210',
      profile: <String, dynamic>{
        'id': 889210,
        'firstName': 'John',
        'lastName': 'Doe',
        'companyName': 'Global Logistics',
      },
      monthly: <String, dynamic>{
        'onTimePercent': 95,
        'safetyScore': 'Excellent',
        'totalDistanceMiles': 12500,
      },
    );

    await tester
        .pumpWidget(_buildApp(locale: const Locale('en'), provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Driver Profile'), findsOneWidget);
    expect(find.text('Performance Stats'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Share ID'), findsOneWidget);
  });

  testWidgets('Profile screen renders Khmer labels', (tester) async {
    final provider = _FakeDriverProvider(
      driverId: '889210',
      profile: <String, dynamic>{
        'id': 889210,
        'firstName': 'John',
        'lastName': 'Doe',
        'companyName': 'Global Logistics',
      },
      monthly: <String, dynamic>{
        'onTimePercent': 95,
        'safetyScore': 'Excellent',
        'totalDistanceMiles': 12500,
      },
    );

    await tester
        .pumpWidget(_buildApp(locale: const Locale('en'), provider: provider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(MaterialApp));

    // runAsync executes in a real async context (outside the fake-async zone)
    // so easy_localization's microtask/SharedPreferences chain drains fully.
    await tester.runAsync(() async {
      await EasyLocalization.of(context)!.setLocale(const Locale('km'));
    });

    // Back in the fake zone — pump explicitly to propagate the locale rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ប្រវត្តិអ្នកបើកបរ'), findsOneWidget);
    expect(find.text('ស្ថិតិប្រតិបត្តិការ'), findsOneWidget);
    expect(find.text('កែប្រែប្រវត្តិ'), findsOneWidget);
    expect(find.text('ចែករំលែក ID'), findsOneWidget);
  });
}
