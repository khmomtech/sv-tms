// lib/models/version_info.dart
class VersionInfo {
  final String latestVersion;
  final String minSupportedVersion;
  final bool mandatoryUpdate;
  final String playStoreUrl;
  final String appStoreUrl;
  final String noteEn;
  final String noteKm;

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

  bool get hasStoreUrl => playStoreUrl.isNotEmpty || appStoreUrl.isNotEmpty;
}
