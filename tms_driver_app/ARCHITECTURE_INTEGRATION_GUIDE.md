# Architecture Integration Quick Guide

**Time Required**: 15 minutes  
**Phase**: 2 of 5  
**Prerequisites**: Phase 1 (Foundation) completed ✅

## Step 1: Update main.dart (5 minutes)

Replace the existing main() function and MyApp class:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:tms_tms_driver_app/core/di/service_locator.dart';
import 'package:tms_tms_driver_app/core/errors/error_boundary.dart';
import 'package:tms_tms_driver_app/core/errors/error_handler.dart';
import 'package:tms_tms_driver_app/firebase_options.dart';

// Import all providers
import 'package:tms_tms_driver_app/providers/theme_provider.dart';
import 'package:tms_tms_driver_app/providers/settings_provider.dart';
import 'package:tms_tms_driver_app/providers/contact_provider.dart';
import 'package:tms_tms_driver_app/providers/user_provider.dart';
import 'package:tms_tms_driver_app/providers/sign_in_provider.dart';
import 'package:tms_tms_driver_app/providers/driver_provider.dart';
import 'package:tms_tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_tms_driver_app/providers/notification_provider.dart';
import 'package:tms_tms_driver_app/providers/driver_issue_provider.dart';
import 'package:tms_tms_driver_app/providers/auth_provider.dart';
import 'package:tms_tms_driver_app/providers/about_app_provider.dart';
import 'package:tms_tms_driver_app/services/session_manager.dart';

// Firebase background handler (keep existing)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📬 Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // 🆕 Setup dependency injection
  await setupServiceLocator();
  
  // 🆕 Run app with error boundary
  runApp(
    ErrorBoundary(
      errorHandler: sl<ErrorHandler>(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🆕 Use service locator for dependency injection
        ChangeNotifierProvider(create: (_) => sl<ThemeProvider>()),
        ChangeNotifierProvider(create: (_) => sl<SettingsProvider>()),
        ChangeNotifierProvider(create: (_) => sl<ContactProvider>()),
        ChangeNotifierProvider(create: (_) => sl<UserProvider>()),
        ChangeNotifierProvider(create: (_) => sl<SignInProvider>()),
        ChangeNotifierProvider(create: (_) => sl<DriverProvider>()),
        ChangeNotifierProvider(create: (_) => sl<DispatchProvider>()),
        ChangeNotifierProvider(create: (_) => sl<NotificationProvider>()),
        ChangeNotifierProvider(create: (_) => sl<DriverIssueProvider>()),
        ChangeNotifierProvider(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => sl<AboutAppProvider>()),
        ChangeNotifierProvider(create: (_) => sl<SessionManager>()),
      ],
      child: const _ThemedApp(),
    );
  }
}

// Keep _ThemedApp and remaining code as-is
```

## Step 2: Update Service Locator Imports (3 minutes)

The service_locator.dart file needs actual import paths. Update these imports:

```dart
// lib/core/di/service_locator.dart

// Add missing provider imports
import 'package:tms_tms_driver_app/providers/theme_provider.dart';
// ... (add all other providers that exist)
```

## Step 3: Temporary Provider Stubs (5 minutes)

Until providers are refactored, update service_locator.dart to use existing providers without repository dependencies:

```dart
// In setupServiceLocator(), update provider registrations:

// ============================================================
// Providers (State Management Layer)
// ============================================================

// Providers WITHOUT repository dependencies (use existing)
sl.registerFactory<ThemeProvider>(() => ThemeProvider());
sl.registerFactory<SettingsProvider>(() => SettingsProvider());
sl.registerFactory<ContactProvider>(() => ContactProvider());
sl.registerFactory<UserProvider>(() => UserProvider());
sl.registerFactory<SignInProvider>(() => SignInProvider());
sl.registerFactory<DriverIssueProvider>(() => DriverIssueProvider());
sl.registerFactory<AuthProvider>(() => AuthProvider());
sl.registerFactory<AboutAppProvider>(() => AboutAppProvider());

// Providers that WILL USE repositories (temporary: use existing for now)
// TODO Phase 3: Refactor these to accept repository parameter
sl.registerFactory<DriverProvider>(() => DriverProvider());
sl.registerFactory<DispatchProvider>(() => DispatchProvider());
sl.registerFactory<NotificationProvider>(() => NotificationProvider());
```

## Step 4: Run and Test (2 minutes)

```bash
cd tms_driver_app
flutter pub get
flutter run
```

### Verification Checklist:
- [ ] App starts without errors
- [ ] Login still works
- [ ] Dispatches load correctly
- [ ] No runtime errors in console
- [ ] All providers accessible

## Troubleshooting

### Error: "Cannot find service locator"
**Fix**: Ensure `setupServiceLocator()` is called before `runApp()`

### Error: "Provider not found"
**Fix**: Check that provider is registered in `service_locator.dart` and imported in `main.dart`

### Error: "Circular dependency"
**Fix**: Review provider dependencies, ensure no circular references

### Error: "Late initialization error"
**Fix**: Ensure `WidgetsFlutterBinding.ensureInitialized()` is called first

## Next Steps

After Phase 2 integration is complete and verified:

**Phase 3** (2-3 hours): Refactor providers to use repositories
- Update `DriverProvider` constructor to accept `DriverRepository`
- Update `DispatchProvider` constructor to accept `DispatchRepository`
- Update `NotificationProvider` constructor to accept `NotificationRepository`
- Remove direct HTTP calls from providers

See `ARCHITECTURE_CODE_QUALITY_IMPROVEMENTS.md` for detailed refactoring examples.

## Rollback Plan

If issues occur, revert main.dart changes:

```bash
git checkout main.dart
```

The new architecture files can remain (they're not used until providers are refactored in Phase 3).
