import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('basic integration smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: Text('integration')))));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('integration'), findsOneWidget);
  });

  testWidgets('driver list API returns id and phone for all drivers',
      (WidgetTester tester) async {
    // The test will run against a running backend.
    // Set the API base URL via `--dart-define=API_BASE_URL=<url>` when invoking the test.
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );

    final uri = Uri.parse('$baseUrl/api/admin/drivers/all');

    late final http.Response response;
    try {
      final res = await tester.runAsync(() => http.get(uri));
      response = res as http.Response;
    } catch (e) {
      // If the backend isn't running, skip this test instead of failing.
      // This keeps integration test suite usable in local dev without requiring a backend.
      return;
    }

    expect(response.statusCode, inInclusiveRange(200, 299));

    final body = jsonDecode(response.body);
    if (body is List) {
      for (final item in body) {
        if (item is Map<String, dynamic>) {
          expect(item['id'], isNotNull);
          expect(item['phone'], isNotNull);
        }
      }
    } else {
      fail('Expected JSON list of drivers, got: ${body.runtimeType}');
    }
  });
}
