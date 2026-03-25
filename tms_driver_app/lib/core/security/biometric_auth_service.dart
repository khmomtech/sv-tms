// 📁 lib/core/security/biometric_auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biometric Authentication Service
/// 
/// Provides fingerprint/face unlock functionality for:
/// - App launch authentication
/// - Sensitive operations (profile updates, password changes)
/// - Payment/transaction confirmations
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  
  static const String _kBiometricEnabledKey = 'biometric_auth_enabled';
  static const String _kBiometricTypeKey = 'biometric_auth_type';

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('[BiometricAuth] Error checking device support: $e');
      return false;
    }
  }

  /// Get available biometric types on device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[BiometricAuth] Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if biometric authentication is enabled by user
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kBiometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('[BiometricAuth] Error checking if biometric enabled: $e');
      return false;
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      // First verify user can authenticate
      final canAuth = await authenticate(
        reason: 'Enable biometric authentication for quick and secure login',
      );

      if (!canAuth) {
        return false;
      }

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kBiometricEnabledKey, true);

      // Save biometric type
      final types = await getAvailableBiometrics();
      if (types.isNotEmpty) {
        await prefs.setString(_kBiometricTypeKey, types.first.toString());
      }

      debugPrint('[BiometricAuth] Biometric authentication enabled');
      return true;
    } catch (e) {
      debugPrint('[BiometricAuth] Error enabling biometric: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kBiometricEnabledKey, false);
      await prefs.remove(_kBiometricTypeKey);
      debugPrint('🔓 [BiometricAuth] Biometric authentication disabled');
    } catch (e) {
      debugPrint('[BiometricAuth] Error disabling biometric: $e');
    }
  }

  /// Authenticate user with biometrics
  /// 
  /// [reason] - Message shown to user explaining why authentication is needed
  /// [sensitiveTransaction] - Set to true for high-security operations
  Future<bool> authenticate({
    required String reason,
    bool sensitiveTransaction = false,
  }) async {
    try {
      // Check if device supports biometrics
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        debugPrint('[BiometricAuth] Device does not support biometric authentication');
        return false;
      }

      // Authenticate
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true, // Keep auth dialog until user cancels
          sensitiveTransaction: sensitiveTransaction,
          biometricOnly: true, // Only biometrics, no PIN/password fallback
          useErrorDialogs: true, // Show error dialogs
        ),
      );

      if (authenticated) {
        debugPrint('[BiometricAuth] Authentication successful');
      } else {
        debugPrint('[BiometricAuth] Authentication failed or cancelled');
      }

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('[BiometricAuth] Platform exception: ${e.message}');
      
      // Handle specific error codes
      if (e.code == 'NotAvailable') {
        debugPrint('[BiometricAuth] Biometric authentication not available');
      } else if (e.code == 'NotEnrolled') {
        debugPrint('[BiometricAuth] No biometrics enrolled on device');
      } else if (e.code == 'PasscodeNotSet') {
        debugPrint('[BiometricAuth] Device passcode not set');
      }
      
      return false;
    } catch (e) {
      debugPrint('[BiometricAuth] Unexpected error: $e');
      return false;
    }
  }

  /// Authenticate for app launch (when biometric is enabled)
  Future<bool> authenticateForAppLaunch() async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        // Biometric not enabled, allow access
        return true;
      }

      return await authenticate(
        reason: 'Authenticate to access Smart Truck Driver App',
        sensitiveTransaction: false,
      );
    } catch (e) {
      debugPrint('[BiometricAuth] Error during app launch authentication: $e');
      // On error, allow access (fail open for better UX)
      return true;
    }
  }

  /// Authenticate for sensitive operations
  Future<bool> authenticateForSensitiveOperation(String operation) async {
    return await authenticate(
      reason: 'Authenticate to $operation',
      sensitiveTransaction: true,
    );
  }

  /// Get human-readable biometric type name
  Future<String> getBiometricTypeName() async {
    try {
      final types = await getAvailableBiometrics();
      if (types.isEmpty) {
        return 'Biometric';
      }

      final type = types.first;
      switch (type) {
        case BiometricType.face:
          return 'Face ID';
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.iris:
          return 'Iris';
        case BiometricType.strong:
          return 'Strong Biometric';
        case BiometricType.weak:
          return 'Weak Biometric';
      }
    } catch (e) {
      return 'Biometric';
    }
  }

  /// Check if specific biometric type is available
  Future<bool> isBiometricTypeAvailable(BiometricType type) async {
    final types = await getAvailableBiometrics();
    return types.contains(type);
  }
}
