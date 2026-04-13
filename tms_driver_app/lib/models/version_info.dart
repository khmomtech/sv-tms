// lib/models/version_info.dart
import 'package:flutter/foundation.dart';

class VersionInfo {
  final String latestVersion;
  final String minSupportedVersion;
  final bool mandatoryUpdate;
  final String playStoreUrl;
  final String appStoreUrl;
  final String noteEn;
  final String noteKm;

  final String androidLatestVersion;
  final bool androidMandatoryUpdate;
  final String androidReleaseNoteEn;
  final String androidReleaseNoteKm;

  final String iosLatestVersion;
  final bool iosMandatoryUpdate;
  final String iosReleaseNoteEn;
  final String iosReleaseNoteKm;

  // New optional fields for maintenance/info messages
  final String maintenanceMessageEn;
  final String maintenanceMessageKm;
  final bool maintenanceActive;
  final String maintenanceUntil; // ISO string from backend, may be empty
  final String infoEn;
  final String infoKm;

  // Optional controls from backend to explicitly toggle banner visibility/type
  final bool systemBannerEnabled; // if false, do not show banner even if message present
  final String systemBannerType; // e.g., MAINTENANCE, INFO (optional, cosmetic)

  const VersionInfo({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.mandatoryUpdate,
    required this.playStoreUrl,
    required this.appStoreUrl,
    required this.noteEn,
    required this.noteKm,
    this.androidLatestVersion = '',
    this.androidMandatoryUpdate = false,
    this.androidReleaseNoteEn = '',
    this.androidReleaseNoteKm = '',
    this.iosLatestVersion = '',
    this.iosMandatoryUpdate = false,
    this.iosReleaseNoteEn = '',
    this.iosReleaseNoteKm = '',
    this.maintenanceMessageEn = '',
    this.maintenanceMessageKm = '',
    this.maintenanceActive = false,
    this.maintenanceUntil = '',
    this.infoEn = '',
    this.infoKm = '',
    this.systemBannerEnabled = true,
    this.systemBannerType = 'AUTO',
  });

  factory VersionInfo.fromJson(Map<String, dynamic> j) => VersionInfo(
        latestVersion: (j['latestVersion'] ?? '').toString().trim(),
        minSupportedVersion: (j['minSupportedVersion'] ?? '').toString().trim(),
        mandatoryUpdate: (j['mandatoryUpdate'] ?? false) == true,
        playStoreUrl: (j['playstoreUrl'] ?? '').toString().trim(),
        appStoreUrl: (j['appstoreUrl'] ?? '').toString().trim(),
        noteEn: (j['releaseNoteEn'] ?? '').toString(),
        noteKm: (j['releaseNoteKm'] ?? '').toString(),
        androidLatestVersion: (j['androidLatestVersion'] ?? '').toString().trim(),
        androidMandatoryUpdate: (j['androidMandatoryUpdate'] ?? false) == true,
        androidReleaseNoteEn: (j['androidReleaseNoteEn'] ?? '').toString(),
        androidReleaseNoteKm: (j['androidReleaseNoteKm'] ?? '').toString(),
        iosLatestVersion: (j['iosLatestVersion'] ?? '').toString().trim(),
        iosMandatoryUpdate: (j['iosMandatoryUpdate'] ?? false) == true,
        iosReleaseNoteEn: (j['iosReleaseNoteEn'] ?? '').toString(),
        iosReleaseNoteKm: (j['iosReleaseNoteKm'] ?? '').toString(),

        // Safe defaults if backend doesn’t provide
        maintenanceMessageEn: (j['maintenanceMessageEn'] ?? '').toString(),
        maintenanceMessageKm: (j['maintenanceMessageKm'] ?? '').toString(),
        maintenanceActive: (j['maintenanceActive'] ?? false) == true,
        maintenanceUntil: (j['maintenanceUntil'] ?? '').toString(),
        infoEn: (j['infoEn'] ?? '').toString(),
        infoKm: (j['infoKm'] ?? '').toString(),
        systemBannerEnabled:
            ((j['systemBannerEnabled'] ?? true) == true),
        systemBannerType: (j['systemBannerType'] ?? 'AUTO').toString(),
      );

  bool get _useAndroid => defaultTargetPlatform == TargetPlatform.android;
  bool get _useIos => defaultTargetPlatform == TargetPlatform.iOS;

  String get effectiveLatestVersion {
    if (_useAndroid && androidLatestVersion.trim().isNotEmpty) {
      return androidLatestVersion.trim();
    }
    if (_useIos && iosLatestVersion.trim().isNotEmpty) {
      return iosLatestVersion.trim();
    }
    return latestVersion.trim();
  }

  bool get effectiveMandatoryUpdate {
    if (_useAndroid && androidMandatoryUpdate) {
      return true;
    }
    if (_useIos && iosMandatoryUpdate) {
      return true;
    }
    return mandatoryUpdate;
  }

  String effectiveReleaseNote({required bool isKhmer}) {
    if (_useAndroid) {
      final candidate =
          isKhmer ? androidReleaseNoteKm.trim() : androidReleaseNoteEn.trim();
      if (candidate.isNotEmpty) return candidate;
    }
    if (_useIos) {
      final candidate = isKhmer ? iosReleaseNoteKm.trim() : iosReleaseNoteEn.trim();
      if (candidate.isNotEmpty) return candidate;
    }
    return isKhmer ? noteKm.trim() : noteEn.trim();
  }

  String get effectiveStoreUrl {
    if (_useAndroid && playStoreUrl.trim().isNotEmpty) {
      return playStoreUrl.trim();
    }
    if (_useIos && appStoreUrl.trim().isNotEmpty) {
      return appStoreUrl.trim();
    }
    return playStoreUrl.trim().isNotEmpty
        ? playStoreUrl.trim()
        : appStoreUrl.trim();
  }

  bool get hasStoreUrl => playStoreUrl.isNotEmpty || appStoreUrl.isNotEmpty;
}
