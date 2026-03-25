// lib/models/about_app_info.dart

class AboutAppInfo {
  final String appNameKm;
  final String appNameEn;
  final String androidVersion;
  final String iosVersion;
  final String contactEmail;
  final String privacyPolicyUrlKm;
  final String privacyPolicyUrlEn;
  final String termsConditionsUrlKm;
  final String termsConditionsUrlEn;

  AboutAppInfo({
    required this.appNameKm,
    required this.appNameEn,
    required this.androidVersion,
    required this.iosVersion,
    required this.contactEmail,
    required this.privacyPolicyUrlKm,
    required this.privacyPolicyUrlEn,
    required this.termsConditionsUrlKm,
    required this.termsConditionsUrlEn,
  });

  factory AboutAppInfo.fromJson(Map<String, dynamic> json) {
    return AboutAppInfo(
      appNameKm: json['appNameKm'] ?? '',
      appNameEn: json['appNameEn'] ?? '',
      androidVersion: json['androidVersion'] ?? '',
      iosVersion: json['iosVersion'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      privacyPolicyUrlKm: json['privacyPolicyUrlKm'] ?? '',
      privacyPolicyUrlEn: json['privacyPolicyUrlEn'] ?? '',
      termsConditionsUrlKm: json['termsConditionsUrlKm'] ?? '',
      termsConditionsUrlEn: json['termsConditionsUrlEn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appNameKm': appNameKm,
      'appNameEn': appNameEn,
      'androidVersion': androidVersion,
      'iosVersion': iosVersion,
      'contactEmail': contactEmail,
      'privacyPolicyUrlKm': privacyPolicyUrlKm,
      'privacyPolicyUrlEn': privacyPolicyUrlEn,
      'termsConditionsUrlKm': termsConditionsUrlKm,
      'termsConditionsUrlEn': termsConditionsUrlEn,
    };
  }
}
