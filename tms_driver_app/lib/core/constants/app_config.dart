// 📁 lib/core/constants/app_config.dart

/// Application-wide configuration constants
class AppConfig {
  // Prevent instantiation
  AppConfig._();

  // ============== API Configuration ==============
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ============== Location Configuration ==============
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const double locationDistanceFilterMeters = 10.0;
  static const Duration locationTimeout = Duration(seconds: 10);
  static const int maxBufferedLocationUpdates = 5000;

  // Accuracy thresholds
  static const double minAccuracyMeters = 50.0;
  static const double maxAcceptableErrorMeters = 100.0;

  // ============== Cache Configuration ==============
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 50; // Number of items

  // ============== WebSocket Configuration ==============
  static const Duration wsReconnectDelay = Duration(seconds: 5);
  static const int wsMaxReconnectAttempts = 10;
  static const Duration wsHeartbeatInterval = Duration(seconds: 30);
  static const Duration wsPingTimeout = Duration(seconds: 10);

  // ============== UI Configuration ==============
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration toastDuration = Duration(seconds: 3);
  static const int maxUploadImages = 5;
  static const int maxImageSizeMB = 5;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ============== Feature Flags ==============
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;

  // Debug features
  static const bool showDebugBanner = false;
  static const bool verboseLogging = false;

  // ============== Storage Keys ==============
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyDriverId = 'driverId';
  static const String keyDriverName = 'driverName';
  static const String keyVehiclePlate = 'vehiclePlate';
  static const String keyDeviceToken = 'device_token';
  static const String keyApiUrl = 'apiUrl';
  static const String keyWsUrl = 'wsUrl';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyOnboardingComplete = 'onboarding_complete';

  // ============== Validation Rules ==============
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minPhoneLength = 9;
  static const int maxPhoneLength = 15;

  // ============== Error Messages ==============
  static const String errorNoInternet = 'No internet connection';
  static const String errorTimeout = 'Request timed out';
  static const String errorServer = 'Server error occurred';
  static const String errorUnexpected = 'An unexpected error occurred';
  static const String errorInvalidCredentials = 'Invalid credentials';
  static const String errorSessionExpired =
      'Session expired. Please login again.';
}
