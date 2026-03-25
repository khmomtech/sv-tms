import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/screens/shipment/trips_screen.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';

/// Fake DispatchProvider that returns in-progress trips without hitting network.

import 'package:tms_driver_app/core/repositories/dispatch_repository.dart';

import 'package:mockito/mockito.dart';

class _FakeDispatchRepository extends Mock implements DispatchRepository {}

class FakeDispatchProvider extends DispatchProvider {
  final List<Map<String, dynamic>> sample;
  FakeDispatchProvider(this.sample)
      : super(dispatchRepository: _FakeDispatchRepository());

  @override
  List<Map<String, dynamic>> get inProgressDispatches => sample;

  @override
  bool get isLoadingInProgress => false;

  @override
  Future<void> fetchInProgressDispatches({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
    bool force = false,
  }) async {
    // no-op for tests
  }
}

/// Fake DriverProvider to supply a driverId and skip network.
class FakeDriverProvider extends DriverProvider {
  final String fakeId;
  FakeDriverProvider(this.fakeId);

  @override
  String? get driverId => fakeId;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  const bool runWidgetTests =
      bool.fromEnvironment('RUN_WIDGET_TESTS', defaultValue: false);

  testWidgets('TripsScreen shows in-progress trip and navigates to detail',
      (tester) async {
    final trips = [
      {
        'id': 9906,
        'status': 'IN_TRANSIT',
        'routeCode': 'T-2025-12-000001',
        'orderReference': '2025352-00001',
        'startTime': '2025-12-18T16:45:14Z',
        'stops': [
          {
            'type': 'PICKUP',
            'address': {'code': 'KHB', 'name': 'Phnom Penh'}
          },
          {
            'type': 'DROP',
            'address': {'code': 'BTB', 'name': 'Battambang'}
          }
        ],
        'transportOrder': {
          'customerName': 'KHB',
        },
      }
    ];

    Object? receivedArgs;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<DispatchProvider>(
              create: (_) => FakeDispatchProvider(trips),
            ),
            ChangeNotifierProvider<DriverProvider>(
              create: (_) => FakeDriverProvider('72'),
            ),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              routes: {
                '/dispatchDetail': (ctx) {
                  receivedArgs = ModalRoute.of(ctx)?.settings.arguments;
                  return const Scaffold(body: Text('detail'));
                },
              },
              home: const TripsScreen(),
            ),
          ),
        ),
      ),
    );

    // Let initState complete.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Trip card renders with id and route code.
    expect(find.text('#9906 (2)'), findsOneWidget);
    expect(find.text('T-2025-12-000001'), findsOneWidget);
    expect(find.text('2025352-00001'), findsOneWidget);

    // Tap the View Detail button.
    await tester.tap(find.text('View Detail'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(receivedArgs, isA<Map>());
    expect((receivedArgs as Map)['dispatchId'].toString(), '9906');
  }, skip: !runWidgetTests);
}
