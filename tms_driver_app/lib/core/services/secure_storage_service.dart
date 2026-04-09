// 📁 lib/core/services/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// Secure storage service for sensitive data
/// Uses FlutterSecureStorage for tokens and SharedPreferences for non-sensitive data
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ============== Secure Storage (for tokens, passwords) ==============

  /// Save access token securely
  Future<void> saveAccessToken(String token) async {
    try {
      await _secureStorage.write(key: 'access_token', value: token);
      Logger.debug('Access token saved securely');
    } catch (e) {
      Logger.error('Failed to save access token: $e');
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: 'access_token');
    } catch (e) {
      Logger.error('Failed to read access token: $e');
      return null;
    }
  }

  /// Save refresh token securely
  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: 'refresh_token', value: token);
      Logger.debug('Refresh token saved securely');
    } catch (e) {
      Logger.error('Failed to save refresh token: $e');
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: 'refresh_token');
    } catch (e) {
      Logger.error('Failed to read refresh token: $e');
      return null;
    }
  }

  /// Delete all secure tokens
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      Logger.debug('Tokens cleared from secure storage');
    } catch (e) {
      Logger.error('Failed to clear tokens: $e');
      rethrow;
    }
  }

  // ============== SharedPreferences (for non-sensitive data) ==============

  /// Save driver ID
  Future<void> saveDriverId(String driverId) async {
    await init();
    await _prefs?.setString('driverId', driverId);
    Logger.debug('Driver ID saved');
  }

  /// Get driver ID
  Future<String?> getDriverId() async {
    await init();
    return _prefs?.getString('driverId');
  }

  /// Save API URL
  Future<void> saveApiUrl(String url) async {
    await init();
    await _prefs?.setString('apiUrl', url);
  }

  /// Get API URL
  Future<String?> getApiUrl() async {
    await init();
    return _prefs?.getString('apiUrl');
  }

  /// Save WebSocket URL
  Future<void> saveWsUrl(String url) async {
    await init();
    await _prefs?.setString('wsUrl', url);
  }

  /// Get WebSocket URL
  Future<String?> getWsUrl() async {
    await init();
    return _prefs?.getString('wsUrl');
  }

  /// Save driver name
  Future<void> saveDriverName(String name) async {
    await init();
    await _prefs?.setString('driverName', name);
  }

  /// Get driver name
  Future<String?> getDriverName() async {
    await init();
    return _prefs?.getString('driverName');
  }

  /// Save vehicle plate
  Future<void> saveVehiclePlate(String plate) async {
    await init();
    await _prefs?.setString('vehiclePlate', plate);
  }

  /// Get vehicle plate
  Future<String?> getVehiclePlate() async {
    await init();
    return _prefs?.getString('vehiclePlate');
  }

  /// Save FCM device token
  Future<void> saveDeviceToken(String token) async {
    await init();
    await _prefs?.setString('last_synced_device_token', token);
  }

  /// Get FCM device token
  Future<String?> getDeviceToken() async {
    await init();
    return _prefs?.getString('last_synced_device_token');
  }

  /// Clear all app data
  Future<void> clearAll() async {
    await clearTokens();
    await init();
    await _prefs?.clear();
    Logger.debug('All storage cleared');
  }

  /// Clear only authentication data (logout)
  Future<void> clearAuthData() async {
    await clearTokens();
    await init();
    await _prefs?.remove('driverId');
    await _prefs?.remove('driverName');
    await _prefs?.remove('vehiclePlate');
    Logger.debug('Auth data cleared');
  }
}
