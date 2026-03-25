import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GDPR Consent Management Service
/// 
/// Handles user consent for data processing in compliance with:
/// - GDPR (General Data Protection Regulation) - EU
/// - CCPA (California Consumer Privacy Act) - California, USA
/// - App Store Privacy Requirements
/// 
/// Features:
/// - Granular consent management (analytics, marketing, location)
/// - User rights: Access, Deletion, Portability, Objection
/// - Consent versioning and re-consent triggering
/// - Audit trail for compliance
class GDPRConsentService {
  static final GDPRConsentService _instance = GDPRConsentService._internal();
  factory GDPRConsentService() => _instance;
  GDPRConsentService._internal();

  // Storage keys
  static const String _keyConsentGiven = 'gdpr_consent_given';
  static const String _keyConsentVersion = 'gdpr_consent_version';
  static const String _keyConsentTimestamp = 'gdpr_consent_timestamp';
  static const String _keyAnalyticsConsent = 'gdpr_analytics_consent';
  static const String _keyMarketingConsent = 'gdpr_marketing_consent';
  static const String _keyLocationConsent = 'gdpr_location_consent';
  static const String _keyDataProcessingConsent = 'gdpr_data_processing_consent';
  static const String _keyCookieConsent = 'gdpr_cookie_consent';
  static const String _keyThirdPartyConsent = 'gdpr_third_party_consent';

  // Current consent policy version - increment when policy changes
  static const int currentConsentVersion = 1;

  /// Check if user has given GDPR consent
  Future<bool> hasGivenConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final consentGiven = prefs.getBool(_keyConsentGiven) ?? false;
    final consentVersion = prefs.getInt(_keyConsentVersion) ?? 0;

    // Re-consent required if version changed
    if (consentGiven && consentVersion < currentConsentVersion) {
      debugPrint('GDPR: Consent version outdated, re-consent required');
      return false;
    }

    return consentGiven;
  }

  /// Record user consent
  Future<void> giveConsent({
    required bool analytics,
    required bool marketing,
    required bool location,
    required bool dataProcessing,
    required bool cookies,
    required bool thirdParty,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();

    await prefs.setBool(_keyConsentGiven, true);
    await prefs.setInt(_keyConsentVersion, currentConsentVersion);
    await prefs.setString(_keyConsentTimestamp, timestamp);
    await prefs.setBool(_keyAnalyticsConsent, analytics);
    await prefs.setBool(_keyMarketingConsent, marketing);
    await prefs.setBool(_keyLocationConsent, location);
    await prefs.setBool(_keyDataProcessingConsent, dataProcessing);
    await prefs.setBool(_keyCookieConsent, cookies);
    await prefs.setBool(_keyThirdPartyConsent, thirdParty);

    debugPrint('GDPR: Consent recorded (v$currentConsentVersion) at $timestamp');
    _logConsentAudit('CONSENT_GIVEN', {
      'version': currentConsentVersion,
      'analytics': analytics,
      'marketing': marketing,
      'location': location,
      'dataProcessing': dataProcessing,
      'cookies': cookies,
      'thirdParty': thirdParty,
    });
  }

  /// Withdraw consent (GDPR Right to Object)
  Future<void> withdrawConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConsentGiven, false);
    await prefs.setBool(_keyAnalyticsConsent, false);
    await prefs.setBool(_keyMarketingConsent, false);
    await prefs.setBool(_keyLocationConsent, false);
    await prefs.setBool(_keyDataProcessingConsent, false);
    await prefs.setBool(_keyCookieConsent, false);
    await prefs.setBool(_keyThirdPartyConsent, false);

    debugPrint('GDPR: All consent withdrawn');
    _logConsentAudit('CONSENT_WITHDRAWN', {});
  }

  /// Get specific consent status
  Future<bool> hasAnalyticsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAnalyticsConsent) ?? false;
  }

  Future<bool> hasMarketingConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMarketingConsent) ?? false;
  }

  Future<bool> hasLocationConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLocationConsent) ?? false;
  }

  Future<bool> hasDataProcessingConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDataProcessingConsent) ?? false;
  }

  Future<bool> hasCookieConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCookieConsent) ?? false;
  }

  Future<bool> hasThirdPartyConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyThirdPartyConsent) ?? false;
  }

  /// Get all consent preferences
  Future<Map<String, dynamic>> getConsentPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'consentGiven': prefs.getBool(_keyConsentGiven) ?? false,
      'consentVersion': prefs.getInt(_keyConsentVersion) ?? 0,
      'consentTimestamp': prefs.getString(_keyConsentTimestamp),
      'analytics': prefs.getBool(_keyAnalyticsConsent) ?? false,
      'marketing': prefs.getBool(_keyMarketingConsent) ?? false,
      'location': prefs.getBool(_keyLocationConsent) ?? false,
      'dataProcessing': prefs.getBool(_keyDataProcessingConsent) ?? false,
      'cookies': prefs.getBool(_keyCookieConsent) ?? false,
      'thirdParty': prefs.getBool(_keyThirdPartyConsent) ?? false,
    };
  }

  /// Update specific consent preference
  Future<void> updateConsentPreference(String type, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    String key;

    switch (type) {
      case 'analytics':
        key = _keyAnalyticsConsent;
        break;
      case 'marketing':
        key = _keyMarketingConsent;
        break;
      case 'location':
        key = _keyLocationConsent;
        break;
      case 'dataProcessing':
        key = _keyDataProcessingConsent;
        break;
      case 'cookies':
        key = _keyCookieConsent;
        break;
      case 'thirdParty':
        key = _keyThirdPartyConsent;
        break;
      default:
        debugPrint('GDPR: Unknown consent type: $type');
        return;
    }

    await prefs.setBool(key, value);
    debugPrint('GDPR: Updated $type consent to $value');
    _logConsentAudit('CONSENT_UPDATED', {'type': type, 'value': value});
  }

  /// Check if user is in GDPR region (EU)
  /// In production, use IP geolocation or device locale
  bool isGDPRRegion() {
    // Check device locale for EU countries
    // This is a simplified check - in production use proper geolocation
    final locale = PlatformDispatcher.instance.locale.countryCode ?? '';
    final euCountries = [
      'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR',
      'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL',
      'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'GB', 'IS', 'LI', 'NO'
    ];
    
    final isEU = euCountries.contains(locale.toUpperCase());
    debugPrint('🌍 GDPR: Region check - Locale: $locale, Is EU: $isEU');
    return isEU;
  }

  /// Check if user is in CCPA region (California)
  bool isCCPARegion() {
    // In production, use proper geolocation
    // For now, check if locale is US
    final locale = PlatformDispatcher.instance.locale.countryCode ?? '';
    return locale.toUpperCase() == 'US';
  }

  /// Export user data (GDPR Right to Data Portability)
  Future<Map<String, dynamic>> exportUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final userData = <String, dynamic>{};

    for (final key in allKeys) {
      final value = prefs.get(key);
      userData[key] = value;
    }

    debugPrint('📦 GDPR: User data exported (${userData.length} entries)');
    _logConsentAudit('DATA_EXPORT_REQUESTED', {'entries': userData.length});

    return {
      'exportDate': DateTime.now().toIso8601String(),
      'dataVersion': '1.0',
      'preferences': userData,
      'consentHistory': await getConsentPreferences(),
    };
  }

  /// Delete all user data (GDPR Right to Erasure)
  Future<void> deleteAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    debugPrint('🗑️ GDPR: All user data deleted');
    _logConsentAudit('DATA_DELETION_REQUESTED', {});
  }

  /// Log consent audit trail for compliance
  void _logConsentAudit(String action, Map<String, dynamic> details) {
    // In production, send to audit logging service
    debugPrint('📝 GDPR Audit: $action - ${details.toString()}');
  }

  /// Get GDPR compliance status
  Future<Map<String, dynamic>> getComplianceStatus() async {
    final hasConsent = await hasGivenConsent();
    final preferences = await getConsentPreferences();
    final isEU = isGDPRRegion();
    final isCA = isCCPARegion();

    return {
      'hasGivenConsent': hasConsent,
      'isGDPRRegion': isEU,
      'isCCPARegion': isCA,
      'requiresConsent': isEU || isCA,
      'consentVersion': preferences['consentVersion'],
      'currentVersion': currentConsentVersion,
      'needsUpdate': preferences['consentVersion'] < currentConsentVersion,
      'consentTimestamp': preferences['consentTimestamp'],
      'preferences': preferences,
    };
  }

  /// Print compliance status for debugging
  Future<void> printComplianceStatus() async {
    final status = await getComplianceStatus();
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('GDPR COMPLIANCE STATUS');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Has Given Consent: ${status['hasGivenConsent']}');
    debugPrint('Is GDPR Region (EU): ${status['isGDPRRegion']}');
    debugPrint('Is CCPA Region (CA): ${status['isCCPARegion']}');
    debugPrint('Requires Consent: ${status['requiresConsent']}');
    debugPrint('Consent Version: ${status['consentVersion']}/${status['currentVersion']}');
    debugPrint('Needs Update: ${status['needsUpdate']}');
    debugPrint('Consent Timestamp: ${status['consentTimestamp']}');
    debugPrint('Preferences: ${status['preferences']}');
    debugPrint('═══════════════════════════════════════════════════════');
  }
}
