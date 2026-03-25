package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.SafetyResult;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.math.BigDecimal;

@Entity
@Table(
    name = "pre_loading_safety_checks",
    indexes = {
        @Index(name = "idx_preload_dispatch", columnList = "dispatch_id"),
        @Index(name = "idx_preload_result", columnList = "result"),
        @Index(name = "idx_preload_checked_at", columnList = "checked_at"),
        @Index(name = "idx_preload_checked_by", columnList = "checked_by_user_id")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PreLoadingSafetyCheck {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "dispatch_id", nullable = false)
  private Dispatch dispatch;

  @Column(name = "driver_ppe_ok", nullable = false)
  private boolean driverPpeOk;

  @Column(name = "fire_extinguisher_ok", nullable = false)
  private boolean fireExtinguisherOk;

  @Column(name = "wheel_chock_ok", nullable = false)
  private boolean wheelChockOk;

  @Column(name = "truck_leakage_ok", nullable = false)
  private boolean truckLeakageOk;

  @Column(name = "truck_clean_ok", nullable = false)
  private boolean truckCleanOk;

  @Column(name = "truck_condition_ok", nullable = false)
  private boolean truckConditionOk;

  @Enumerated(EnumType.STRING)
  @Column(length = 20, nullable = false)
  private SafetyResult result;

  @Column(length = 500)
  private String failReason;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "checked_by_user_id")
  private User checkedBy;

  @Column(name = "checked_at")
  private LocalDateTime checkedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "loading_session_id")
  private LoadingSession loadingSession;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "proof_document_id")
  private LoadingDocument proofDocument;

  @Column(name = "location_lat", precision = 10, scale = 7)
  private BigDecimal locationLat;

  @Column(name = "location_lng", precision = 10, scale = 7)
  private BigDecimal locationLng;

  @Column(name = "client_uuid", length = 36, unique = true)
  private String clientUuid;

  @Column(name = "synced", nullable = false)
  @Builder.Default
  private boolean synced = false;

  @CreationTimestamp
  @Column(name = "created_date", updatable = false)
  private LocalDateTime createdDate;

  @UpdateTimestamp
  @Column(name = "updated_date")
  private LocalDateTime updatedDate;
}
