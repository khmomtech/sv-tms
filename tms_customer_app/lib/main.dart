import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';
import 'services/local_storage.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

export 'package:firebase_core/firebase_core.dart' show Firebase;

// Use a compile-time define so the backend URL can be set per build/run:
// flutter run --dart-define=API_BASE_URL=https://api.example.com
// For Android emulator: 10.0.2.2:8080, iOS simulator: localhost:8080
const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080');

/// Top-level background message handler.
/// Must be annotated so the Dart compiler does not tree-shake it.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be re-initialized in the background isolate.
  await Firebase.initializeApp();
  debugPrint(
      '[FCM-BG] ${message.notification?.title}: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before anything else
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize storage and auth service, attempt to restore session before building UI
  final storage = LocalStorage();
  final authService = AuthService(storage: storage);
  await authService.tryRestore();

  // Start FCM integration (non-blocking; failures are caught internally)
  final notificationService = NotificationService();
  notificationService.init(
    getToken: () => authService.getToken(),
    getCustomerId: () async => authService.currentUser?.customerId,
  );

  // Read persisted locale (if any)
  await EasyLocalization.ensureInitialized();
  final savedLocaleCode = await storage.getString('locale');
  final Locale startLocale =
      savedLocaleCode != null ? Locale(savedLocaleCode) : const Locale('km');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('km')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      startLocale: startLocale,
      child: createApp(
          apiBaseUrl: _apiBaseUrl,
          storage: storage,
          authService: authService,
          notificationService: notificationService),
    ),
  );
}
