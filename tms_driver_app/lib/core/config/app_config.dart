import 'package:flutter/foundation.dart';

/// Environment configuration for the driver app.
/// Automatically switches based on build mode (debug/profile/release).
class AppConfig {
  static const String appName = 'Smart Truck Driver App';
  static const String appVersion = '1.0.0';

  static const String _envApiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _envWsBaseUrl =
      String.fromEnvironment('WS_BASE_URL', defaultValue: '');
  static const bool reviewerMode =
      bool.fromEnvironment('REVIEWER_MODE', defaultValue: false);

  // API Configuration
  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl;
    }
    // Production-safe default. Local/dev should override via --dart-define.
    return 'https://svtms.svtrucking.biz/api';
  }

  static String get wsBaseUrl {
    if (_envWsBaseUrl.isNotEmpty) {
      return _envWsBaseUrl;
    }
    // Production-safe default. Local/dev should override via --dart-define.
    return 'wss://svtms.svtrucking.biz/ws';
  }

  // Feature Flags
  static bool get enableDebugApiOverride => kDebugMode;
  static bool get enablePerformanceLogging => !kReleaseMode;
  static bool get enableCrashReporting => kReleaseMode;
  static bool get requireApprovedDevice =>
      (kReleaseMode && !reviewerMode) ||
      const bool.fromEnvironment(
        'REQUIRE_DEVICE_APPROVAL',
        defaultValue: false,
      );

  // Location Tracking Settings
  static const int locationUpdateIntervalMs = 5000; // 5 seconds
  static const double locationAccuracyMeters = 20.0;
  static const int locationMinDistanceMeters = 10;

  // File Upload Settings
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxImagesPerIssue = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'heic'];

  // Cache Settings
  static const int tokenCacheDurationMinutes = 60;
  static const int profileCacheDurationMinutes = 30;

  // Network Settings
  static const int apiTimeoutSeconds = 30;
  static const int connectionTimeoutSeconds = 10;
  static const int maxRetryAttempts = 3;

  // Google Maps
  static const String googleMapsApiKey = ''; // Add your key here

  // Firebase
  static const String firebaseProjectId = 'sv-driver-app';
  static const String firebaseSenderId = ''; // Add your sender ID

  // Build Info
  static String get buildMode {
    if (kReleaseMode) return 'Release';
    if (kProfileMode) return 'Profile';
    return 'Debug';
  }

  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => kDebugMode;
}
