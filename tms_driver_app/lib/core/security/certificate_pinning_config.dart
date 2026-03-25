// 📁 lib/core/security/certificate_pinning_config.dart

import 'dart:io';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Certificate Pinning Configuration
/// 
/// Implements SSL/TLS certificate pinning to prevent MITM attacks by validating
/// server certificates against known SHA-256 fingerprints
class CertificatePinningConfig {
  
  // ============================================================
  // Production Certificate Fingerprints (SHA-256)
  // ============================================================
  
  /// Production server certificate SHA-256 fingerprints
  /// 
  /// To get certificate fingerprints:
  /// ```bash
  /// # Method 1: Using openssl
  /// openssl s_client -connect your-domain.com:443 -servername your-domain.com < /dev/null 2>/dev/null | \
  ///   openssl x509 -fingerprint -sha256 -noout
  /// 
  /// # Method 2: Using echo and openssl
  /// echo | openssl s_client -connect your-domain.com:443 2>/dev/null | \
  ///   openssl x509 -fingerprint -sha256 -noout
  /// 
  /// # Method 3: From certificate file
  /// openssl x509 -in certificate.crt -fingerprint -sha256 -noout
  /// ```
  static const List<String> productionCertificates = [
    // TODO: Add production server certificate SHA-256 fingerprints
    // Example format: 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99'
    
    // Example for common CAs (replace with your actual certificates):
    // 'E7:2E:4E:4B:E6:7D:8E:7E:9A:0E:6C:7D:F6:3E:8E:4E:7E:9A:0E:6C:7D:F6:3E:8E:4E:7E:9A:0E:6C:7D:F6:3E',
  ];
  
  // ============================================================
  // Development Certificate Fingerprints (for self-signed certs)
  // ============================================================
  
  /// Development/staging certificate fingerprints (self-signed certificates)
  static const List<String> developmentCertificates = [
    // Add self-signed certificate fingerprints for local development
    // These are only used in debug mode
  ];
  
  // ============================================================
  // Certificate Pinning Logic
  // ============================================================
  
  /// Get certificates based on current environment
  static List<String> getCertificates() {
    if (kDebugMode) {
      // In debug mode, use development certificates if available
      if (developmentCertificates.isNotEmpty) {
        debugPrint('[CertPinning] Using development certificates (${developmentCertificates.length} certs)');
        return developmentCertificates;
      }
      debugPrint('[CertPinning] Debug mode: No development certificates configured');
      return [];
    }
    
    // In production, only use production certificates
    if (productionCertificates.isEmpty) {
      debugPrint('[CertPinning] WARNING: No production certificates configured!');
    } else {
      debugPrint('[CertPinning] Using production certificates (${productionCertificates.length} certs)');
    }
    return productionCertificates;
  }
  
  /// Create pinned HTTP client with certificate validation
  static HttpClient createPinnedHttpClient() {
    final client = HttpClient();
    
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // In debug mode with no certificates configured, allow all connections
      if (kDebugMode && getCertificates().isEmpty) {
        debugPrint('[CertPinning] Debug mode: Allowing certificate for $host (no pinning configured)');
        return true;
      }
      
      // Get pinned certificates
      final pinnedCerts = getCertificates();
      if (pinnedCerts.isEmpty) {
        debugPrint('[CertPinning] No certificates configured for $host - blocking connection');
        return false;
      }
      
      // Calculate certificate SHA-256 fingerprint
      final certFingerprint = _getCertificateSha256Fingerprint(cert);
      
      // Check if certificate matches any pinned certificate
      final isValid = pinnedCerts.any((pinned) {
        final normalizedPinned = _normalizeFingerprint(pinned);
        final normalizedCert = _normalizeFingerprint(certFingerprint);
        return normalizedPinned == normalizedCert;
      });
      
      if (isValid) {
        debugPrint('[CertPinning] Certificate validated for $host');
      } else {
        debugPrint('[CertPinning] Certificate validation FAILED for $host:$port');
        debugPrint('   Expected one of:');
        for (final pinned in pinnedCerts) {
          debugPrint('     - $pinned');
        }
        debugPrint('   Got: $certFingerprint');
      }
      
      return isValid;
    };
    
    return client;
  }
  
  /// Configure Dio with certificate pinning
  static void configureDio(Dio dio) {
    debugPrint('[CertPinning] Configuring Dio with certificate pinning');
    
    final adapter = IOHttpClientAdapter(
      createHttpClient: () {
        return createPinnedHttpClient();
      },
    );
    
    dio.httpClientAdapter = adapter;
    debugPrint('[CertPinning] Dio configured with certificate pinning');
  }
  
  // ============================================================
  // Helper Methods
  // ============================================================
  
  /// Calculate SHA-256 fingerprint of certificate
  static String _getCertificateSha256Fingerprint(X509Certificate cert) {
    try {
      // Get DER encoded certificate bytes
      final der = cert.der;
      
      // Calculate SHA-256 hash
      final digest = sha256.convert(der);
      
      // Convert to colon-separated hex format (AA:BB:CC:DD:...)
      final fingerprint = digest.bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':');
      
      return fingerprint;
    } catch (e) {
      debugPrint('[CertPinning] Error calculating certificate fingerprint: $e');
      return '';
    }
  }
  
  /// Normalize fingerprint for comparison (remove colons, convert to uppercase)
  static String _normalizeFingerprint(String fingerprint) {
    return fingerprint
        .replaceAll(':', '')
        .replaceAll(' ', '')
        .toUpperCase()
        .trim();
  }
  
  /// Validate certificate pinning configuration
  static bool validateConfiguration() {
    if (kDebugMode) {
      debugPrint('🔍 [CertPinning] Validating configuration (debug mode)');
      if (developmentCertificates.isEmpty && productionCertificates.isEmpty) {
        debugPrint('[CertPinning] No certificates configured (debug mode - this is OK for development)');
      }
      return true;
    }
    
    // Production validation
    if (productionCertificates.isEmpty) {
      debugPrint('[CertPinning] CRITICAL: No production certificates configured!');
      return false;
    }
    
    // Validate fingerprint format
    for (final cert in productionCertificates) {
      if (!_isValidFingerprintFormat(cert)) {
        debugPrint('[CertPinning] Invalid fingerprint format: $cert');
        return false;
      }
    }
    
    debugPrint('[CertPinning] Configuration validated (${productionCertificates.length} production certificates)');
    return true;
  }
  
  /// Check if fingerprint is in valid SHA-256 format
  static bool _isValidFingerprintFormat(String fingerprint) {
    // SHA-256 fingerprint should be 64 hex characters (32 bytes)
    // Format: AA:BB:CC:... (95 characters with colons) or AABBCC... (64 characters without)
    final normalized = _normalizeFingerprint(fingerprint);
    
    // Check length (SHA-256 = 32 bytes = 64 hex characters)
    if (normalized.length != 64) {
      return false;
    }
    
    // Check if all characters are valid hex
    final hexRegex = RegExp(r'^[0-9A-F]+$');
    return hexRegex.hasMatch(normalized);
  }
  
  /// Print certificate pinning status
  static void printStatus() {
    debugPrint('[CertPinning] Certificate Pinning Status:');
    debugPrint('   Environment: ${kDebugMode ? 'Debug' : 'Production'}');
    debugPrint('   Production Certificates: ${productionCertificates.length}');
    debugPrint('   Development Certificates: ${developmentCertificates.length}');
    debugPrint('   Active Certificates: ${getCertificates().length}');
    debugPrint('   Configuration Valid: ${validateConfiguration()}');
  }
}
