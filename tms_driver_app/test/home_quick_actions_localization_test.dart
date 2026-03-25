import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/quick_actions_section.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildApp() {
    return EasyLocalization(
      supportedLocales: const <Locale>[Locale('en'), Locale('km')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickActionsSection(onTap: (_) {}),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders English labels', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Incident'), findsOneWidget);
  });

  testWidgets('renders Khmer labels after locale switch', (tester) async {
    await tester.pumpWidget(buildApp());
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

    expect(find.text('សកម្មភាពរហ័ស'), findsOneWidget);
    expect(find.text('ជើងដឹករបស់ខ្ញុំ'), findsOneWidget);
    expect(find.text('រាយការណ៍អំពើហេតុ'), findsOneWidget);
  });
}
