import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:svtms_safety_check/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app loads to login screen', (WidgetTester tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.textContaining('Login', findRichText: true).evaluate().isNotEmpty ||
        find.textContaining('ចូល', findRichText: true).evaluate().isNotEmpty, isTrue);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
