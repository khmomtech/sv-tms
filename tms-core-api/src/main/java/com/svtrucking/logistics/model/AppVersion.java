package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Data
@Entity
@Table(name = "app_versions")
public class AppVersion {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  // --- Global fields ---
  @Column(name = "latest_version", nullable = false)
  private String latestVersion;

  @Column(name = "min_supported_version")
  private String minSupportedVersion;

  @Column(name = "mandatory_update", nullable = false)
  private boolean mandatoryUpdate;

  @Column(name = "playstore_url", nullable = false)
  private String playstoreUrl;

  @Column(name = "appstore_url")
  private String appstoreUrl;

  @Column(name = "release_note_en", columnDefinition = "TEXT")
  private String releaseNoteEn;

  @Column(name = "release_note_km", columnDefinition = "TEXT")
  private String releaseNoteKm;

  @Column(name = "last_updated")
  private LocalDateTime lastUpdated;

  // --- Android specific ---
  @Column(name = "android_latest_version")
  private String androidLatestVersion;

  @Column(name = "android_mandatory_update")
  private boolean androidMandatoryUpdate;

  @Column(name = "android_release_note_en", columnDefinition = "TEXT")
  private String androidReleaseNoteEn;

  @Column(name = "android_release_note_km", columnDefinition = "TEXT")
  private String androidReleaseNoteKm;

  // --- iOS specific ---
  @Column(name = "ios_latest_version")
  private String iosLatestVersion;

  @Column(name = "ios_mandatory_update")
  private boolean iosMandatoryUpdate;

  @Column(name = "ios_release_note_en", columnDefinition = "TEXT")
  private String iosReleaseNoteEn;

  @Column(name = "ios_release_note_km", columnDefinition = "TEXT")
  private String iosReleaseNoteKm;

  // --- Maintenance ---
  @Column(name = "maintenance_active", nullable = false)
  private boolean maintenanceActive;

  @Column(name = "maintenance_message_en", columnDefinition = "TEXT")
  private String maintenanceMessageEn;

  @Column(name = "maintenance_message_km", columnDefinition = "TEXT")
  private String maintenanceMessageKm;

  @Column(name = "maintenance_until")
  private LocalDateTime maintenanceUntil;

  // --- Info messages ---
  @Column(name = "info_en", columnDefinition = "TEXT")
  private String infoEn;

  @Column(name = "info_km", columnDefinition = "TEXT")
  private String infoKm;
}
