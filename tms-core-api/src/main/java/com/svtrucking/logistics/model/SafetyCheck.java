package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DailySafetyCheckStatus;
import com.svtrucking.logistics.enums.SafetyRiskLevel;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.*;

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

  private String shift;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "driver_id", nullable = false)
  private Driver driver;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vehicle_id", nullable = false)
  private Vehicle vehicle;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false)
  private DailySafetyCheckStatus status;

  @Enumerated(EnumType.STRING)
  @Column(name = "risk_level")
  private SafetyRiskLevel riskLevel;

  @Enumerated(EnumType.STRING)
  @Column(name = "risk_override")
  private SafetyRiskLevel riskOverride;

  @Column(name = "submitted_at")
  private LocalDateTime submittedAt;

  @Column(name = "approved_at")
  private LocalDateTime approvedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "approved_by")
  private User approvedBy;

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
