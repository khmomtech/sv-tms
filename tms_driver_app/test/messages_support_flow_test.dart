import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/chat_provider.dart';
import 'package:tms_driver_app/screens/messages/messages_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('support-entry chat screen shows Help Center context and seeded draft',
      (tester) async {
    final chatProvider = _FakeChatProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatProvider>.value(
        value: chatProvider,
        child: const MaterialApp(
          home: MessagesScreen(
            entryPoint: 'support_center',
            initialDraft: 'Hi support, I need help with ',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Support Team'), findsOneWidget);
    expect(find.text('Support request started from Help Center'), findsOneWidget);
    expect(find.text('Hi support, I need help with '), findsOneWidget);
  });
}

class _FakeChatProvider extends ChatProvider {
  _FakeChatProvider()
      : super(
          driverIdResolver: () async => 99,
          accessTokenResolver: () async => null,
          pathResolver: (path) => path,
        );

  @override
  Future<void> loadMessages({bool force = false}) async {}
}
