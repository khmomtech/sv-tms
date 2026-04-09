import 'package:flutter/foundation.dart';

/// Production-ready logger that only logs in debug mode.
/// Use this instead of debugPrint to ensure logs don't appear in production.
class AppLogger {
  static void log(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('📝 [LOG] $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack: $stackTrace');
      }
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [INFO] $message');
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // Always log errors even in production (they go to crash reporting)
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   Stack: $stackTrace');
    }
    
    // TODO: Send to Firebase Crashlytics in production
    // if (kReleaseMode && error != null) {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('[SUCCESS] $message');
    }
  }

  static void network(String message) {
    if (kDebugMode) {
      debugPrint('🌐 [NETWORK] $message');
    }
  }

  static void navigation(String message) {
    if (kDebugMode) {
      debugPrint('🧭 [NAV] $message');
    }
  }

  static void fcm(String message) {
    if (kDebugMode) {
      debugPrint('🔔 [FCM] $message');
    }
  }
}
