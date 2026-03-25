package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.Data;

@Entity
@Table(name = "about_app_info")
@Data
public class AboutAppInfo {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  private String appNameKm;
  private String appNameEn;

  private String androidVersion;
  private String iosVersion;
  private String contactEmail;

  @Column(columnDefinition = "TEXT")
  private String privacyPolicyUrlKm;

  @Column(columnDefinition = "TEXT")
  private String privacyPolicyUrlEn;

  @Column(columnDefinition = "TEXT")
  private String termsConditionsUrlKm;

  @Column(columnDefinition = "TEXT")
  private String termsConditionsUrlEn;

  private LocalDateTime lastUpdated;
}
