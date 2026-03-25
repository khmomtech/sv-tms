package com.svtrucking.logistics.safety.domain;

import com.svtrucking.logistics.enums.DailySafetyCheckStatus;
import com.svtrucking.logistics.enums.SafetyRiskLevel;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "safety_checks",
    indexes = {
      @Index(name = "idx_safety_check_status", columnList = "status"),
      @Index(name = "idx_safety_check_date", columnList = "check_date"),
      @Index(name = "idx_safety_check_driver", columnList = "driver_id"),
      @Index(name = "idx_safety_check_vehicle", columnList = "vehicle_id"),
      @Index(name = "idx_safety_check_risk", columnList = "risk_level")
    })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SafetyCheck {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "check_date", nullable = false)
  private LocalDate checkDate;

  @Column(name = "shift", length = 50)
  private String shift;

  @Column(name = "driver_id", nullable = false)
  private Long driverId;

  @Column(name = "vehicle_id", nullable = false)
  private Long vehicleId;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 32)
  private DailySafetyCheckStatus status;

  @Enumerated(EnumType.STRING)
  @Column(name = "risk_level", length = 32)
  private SafetyRiskLevel riskLevel;

  @Enumerated(EnumType.STRING)
  @Column(name = "risk_override", length = 32)
  private SafetyRiskLevel riskOverride;

  @Column(name = "submitted_at")
  private LocalDateTime submittedAt;

  @Column(name = "approved_at")
  private LocalDateTime approvedAt;

  @Column(name = "approved_by_user_id")
  private Long approvedByUserId;

  @Column(name = "reject_reason", length = 1000)
  private String rejectReason;

  @Column(columnDefinition = "TEXT")
  private String notes;

  @Column(name = "gps_lat")
  private Double gpsLat;

  @Column(name = "gps_lng")
  private Double gpsLng;

  @Column(name = "created_at")
  private LocalDateTime createdAt;

  @Column(name = "updated_at")
  private LocalDateTime updatedAt;

  @Builder.Default
  @OneToMany(mappedBy = "safetyCheck", cascade = CascadeType.ALL, orphanRemoval = true)
  private List<SafetyCheckItem> items = new ArrayList<>();

  @Builder.Default
  @OneToMany(mappedBy = "safetyCheck", cascade = CascadeType.ALL, orphanRemoval = true)
  private List<SafetyCheckAttachment> attachments = new ArrayList<>();

  @Builder.Default
  @OneToMany(mappedBy = "safetyCheck", cascade = CascadeType.ALL, orphanRemoval = true)
  private List<SafetyCheckAudit> audits = new ArrayList<>();

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }

  @PreUpdate
  protected void onUpdate() {
    updatedAt = LocalDateTime.now();
  }
}

