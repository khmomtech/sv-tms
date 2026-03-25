// lib/core/constants/app_constants.dart

class AppConstants {
  /// General App Info
  static const String appName = 'Smart Truck Driver App';
  static const String appVersion = '1.2.0';

  /// Supported Locales
  static const String defaultLanguage = 'km';
  static const List<String> supportedLanguages = ['en', 'km'];

  /// API & Firebase
  static const String firebaseChannelId = 'sv_driver_notifications';

  /// SharedPreferences Keys
  static const String prefToken = 'accessToken';
  static const String prefDriverId = 'driverId';
  static const String prefDeviceToken = 'last_synced_device_token';
  static const String prefBaseUrl = 'apiUrl';

  /// Misc
  static const int splashDelayMs = 1500;
}
