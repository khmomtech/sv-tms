// 📁 lib/core/security/security_config.dart

import 'package:flutter/foundation.dart';

/// Centralized Security Configuration
/// 
/// Manages security policies, timeout values, and encryption settings
class SecurityConfig {
  // ============================================================
  // App Tracking / ATT
  // ============================================================
  /// Set to `true` only if the app performs cross-app user-level tracking (IDFA).
  /// Keep `false` for this driver app (enterprise) to avoid showing the ATT prompt.
  static const bool appUsesTracking = false;

  // ============================================================
  // Network Security
  // ============================================================
  
  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 15);
  
  /// Receive timeout duration
  static const Duration receiveTimeout = Duration(seconds: 20);
  
  /// Send timeout duration
  static const Duration sendTimeout = Duration(seconds: 20);
  
  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;
  
  /// Retry backoff multiplier (milliseconds)
  static const int retryBackoffMs = 400;
  
  // ============================================================
  // Authentication & Token Management
  // ============================================================
  
  /// JWT access token expiry leeway (seconds before expiry to refresh)
  static const int tokenExpiryLeeway = 300; // 5 minutes
  
  /// Minimum interval between token refresh attempts
  static const Duration minTokenRefreshInterval = Duration(minutes: 1);
  
  /// Maximum token refresh retry attempts
  static const int maxTokenRefreshRetries = 3;
  
  /// Access token cache TTL
  static const Duration accessTokenCacheTtl = Duration(seconds: 5);
  
  // ============================================================
  // Biometric Authentication
  // ============================================================
  
  /// Enable biometric authentication by default
  static const bool biometricEnabledByDefault = false;
  
  /// Biometric authentication timeout
  static const Duration biometricTimeout = Duration(seconds: 30);
  
  /// Allow biometric fallback to device PIN/password
  static const bool allowBiometricFallback = false;
  
  // ============================================================
  // Certificate Pinning
  // ============================================================
  
  /// Enable certificate pinning in production
  static bool get certificatePinningEnabled => !kDebugMode;
  
  /// Allow self-signed certificates in debug mode
  static bool get allowSelfSignedCerts => kDebugMode;
  
  // ============================================================
  // Session Management
  // ============================================================
  
  /// Session timeout duration (logout after inactivity)
  static const Duration sessionTimeout = Duration(hours: 8);
  
  /// Session warning before timeout (show warning dialog)
  static const Duration sessionWarningBefore = Duration(minutes: 5);
  
  /// Auto-lock app after background duration
  static const Duration autoLockDelay = Duration(minutes: 5);
  
  // ============================================================
  // Data Encryption
  // ============================================================
  
  /// Encrypt sensitive data in local storage
  static const bool encryptLocalData = true;
  
  /// Use device hardware encryption when available
  static const bool useHardwareEncryption = true;
  
  // ============================================================
  // Security Headers
  // ============================================================
  
  /// Default security headers for API requests
  static Map<String, String> get securityHeaders => {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  };
  
  // ============================================================
  // Password Policy
  // ============================================================
  
  /// Minimum password length
  static const int minPasswordLength = 8;
  
  /// Require password complexity (uppercase, lowercase, number, special char)
  static const bool requirePasswordComplexity = true;
  
  /// Password expiry days (0 = no expiry)
  static const int passwordExpiryDays = 90;
  
  /// Prevent password reuse count
  static const int preventPasswordReuse = 3;
  
  // ============================================================
  // Rate Limiting
  // ============================================================
  
  /// Maximum login attempts before lockout
  static const int maxLoginAttempts = 5;
  
  /// Account lockout duration after max attempts
  static const Duration accountLockoutDuration = Duration(minutes: 15);
  
  /// Maximum API requests per minute
  static const int maxApiRequestsPerMinute = 60;
  
  // ============================================================
  // Logging & Monitoring
  // ============================================================
  
  /// Log security events (auth failures, suspicious activity)
  static const bool logSecurityEvents = true;
  
  /// Send security events to monitoring service
  static const bool sendSecurityEventsToMonitoring = !kDebugMode;
  
  /// Log sensitive data in debug mode only
  static bool get logSensitiveData => kDebugMode;
  
  // ============================================================
  // Helper Methods
  // ============================================================
  
  /// Check if running in secure environment (production)
  static bool get isSecureEnvironment => !kDebugMode && !kProfileMode;
  
  /// Get environment-specific configuration
  static String get environment {
    if (kDebugMode) return 'development';
    if (kProfileMode) return 'staging';
    return 'production';
  }
  
  /// Validate security configuration
  static bool validateConfig() {
    bool isValid = true;
    
    // Validate timeout values
    if (connectionTimeout.inSeconds <= 0) {
      debugPrint('[SecurityConfig] Invalid connection timeout');
      isValid = false;
    }
    
    // Validate token settings
    if (tokenExpiryLeeway <= 0) {
      debugPrint('[SecurityConfig] Invalid token expiry leeway');
      isValid = false;
    }
    
    // Validate retry settings
    if (maxRetryAttempts < 0 || maxRetryAttempts > 10) {
      debugPrint('[SecurityConfig] Invalid max retry attempts');
      isValid = false;
    }
    
    if (isValid) {
      debugPrint('[SecurityConfig] Configuration validated successfully');
    }
    
    return isValid;
  }
  
  /// Print security configuration summary
  static void printConfig() {
    debugPrint('[SecurityConfig] Security Configuration:');
    debugPrint('  Environment: $environment');
    debugPrint('  Certificate Pinning: $certificatePinningEnabled');
    debugPrint('  Biometric Auth: $biometricEnabledByDefault');
    debugPrint('  Data Encryption: $encryptLocalData');
    debugPrint('  Session Timeout: ${sessionTimeout.inHours}h');
    debugPrint('  Token Expiry Leeway: ${tokenExpiryLeeway}s');
    debugPrint('  Max Retry Attempts: $maxRetryAttempts');
    debugPrint('  Connection Timeout: ${connectionTimeout.inSeconds}s');
  }
}
