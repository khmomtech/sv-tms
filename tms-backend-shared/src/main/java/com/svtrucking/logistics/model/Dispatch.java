package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.DispatchApprovalStatus;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import com.svtrucking.logistics.enums.SafetyCheckStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.CascadeType;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Version;
import org.hibernate.annotations.BatchSize;

@Setter
@Getter
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Table(name = "dispatches", indexes = {
    @Index(name = "idx_dispatch_driver", columnList = "driver_id"),
    @Index(name = "idx_dispatch_status", columnList = "status"),
    @Index(name = "idx_dispatch_date", columnList = "created_date"),
    @Index(name = "idx_dispatch_approval_status", columnList = "approval_status"),
    @Index(name = "idx_dispatch_pre_entry_safety", columnList = "pre_entry_safety_status")
})
public class Dispatch {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Version
  @Column(name = "version", nullable = false)
  private Long version;

  // Unique Route or Trip Code
  @Column(name = "route_code")
  private String routeCode;

  @Column(name = "tracking_no")
  private String trackingNo;

  @Column(name = "truck_trip")
  private String truckTrip;

  @Column(name = "from_location")
  private String fromLocation;

  @Column(name = "to_location")
  private String toLocation;

  private LocalDate deliveryDate;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "customer_id")
  private Customer customer;

  private LocalDateTime startTime;
  private LocalDateTime estimatedArrival;

  @Enumerated(EnumType.STRING)
  private DispatchStatus status;

  @Enumerated(EnumType.STRING)
  @Column(name = "safety_status")
  private SafetyCheckStatus safetyStatus;

  // Link to Transport Order (nullable for bulk trips)
  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "transport_order_id", nullable = true)
  private TransportOrder transportOrder;

  /** Assigned Driver - can be null for planned or bulk dispatches. */
  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "driver_id", nullable = true)
  private Driver driver;

  /** Assigned Vehicle - can be null for planned or bulk dispatches. */
  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vehicle_id", nullable = true)
  private Vehicle vehicle;

  // Created By
  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by", nullable = true)
  private User createdBy;

  @Column(name = "trip_type")
  private String tripType; // e.g., BULK, REGULAR, etc.

  @Column(name = "loading_type_code", nullable = false, length = 30)
  @Builder.Default
  private String loadingTypeCode = "GENERAL";

  @Column(name = "workflow_version_id")
  private Long workflowVersionId;

  @Column(nullable = false, updatable = false)
  private LocalDateTime createdDate;

  @Column(nullable = false)
  private LocalDateTime updatedDate;

  // Stops on the trip
  @OneToMany(mappedBy = "dispatch", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
  @BatchSize(size = 10)
  private List<DispatchStop> stops;

  // Items being transported
  @OneToMany(mappedBy = "dispatch", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
  @BatchSize(size = 10)
  private List<DispatchItem> items;

  @Column(name = "cancel_reason")
  private String cancelReason;

  @Column(name = "odo_start", precision = 12, scale = 2)
  private BigDecimal odoStart;

  @Column(name = "odo_end", precision = 12, scale = 2)
  private BigDecimal odoEnd;

  @Column(name = "actual_km_official", precision = 12, scale = 2)
  private BigDecimal actualKmOfficial;

  @Column(name = "gps_estimated_km", precision = 12, scale = 2)
  private BigDecimal gpsEstimatedKm;

  @Column(name = "km_locked_flag", nullable = false)
  @Builder.Default
  private Boolean kmLockedFlag = Boolean.FALSE;

  @Column(name = "expense_locked_flag", nullable = false)
  @Builder.Default
  private Boolean expenseLockedFlag = Boolean.FALSE;

  @Column(name = "revenue_locked_flag", nullable = false)
  @Builder.Default
  private Boolean revenueLockedFlag = Boolean.FALSE;

  @Column(name = "financial_locked_flag", nullable = false)
  @Builder.Default
  private Boolean financialLockedFlag = Boolean.FALSE;

  @Column(name = "route_locked_flag", nullable = false)
  @Builder.Default
  private Boolean routeLockedFlag = Boolean.FALSE;

  @Column(name = "km_locked_at")
  private LocalDateTime kmLockedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "km_locked_by")
  private User kmLockedBy;

  @Column(name = "closed_at")
  private LocalDateTime closedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "closed_by")
  private User closedBy;

  // Proof of loading
  @OneToOne(mappedBy = "dispatch", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
  private LoadProof loadProof;

  // Proof of unloading
  @OneToOne(mappedBy = "dispatch", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
  private UnloadProof unloadProof;

  // ===================== APPROVAL WORKFLOW FIELDS =====================
  @Enumerated(EnumType.STRING)
  @Column(name = "approval_status", length = 50)
  @Builder.Default
  private DispatchApprovalStatus approvalStatus = DispatchApprovalStatus.NONE;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "approved_by")
  private User approvedBy;

  @Column(name = "approved_at")
  private LocalDateTime approvedAt;

  @Column(name = "approval_remarks", columnDefinition = "TEXT")
  private String approvalRemarks;

  // ===================== PROOF OF LOADING (POL) FIELDS =====================
  @Column(name = "pol_required")
  @Builder.Default
  private Boolean polRequired = false;

  @Column(name = "pol_submitted")
  @Builder.Default
  private Boolean polSubmitted = false;

  @Column(name = "pol_submitted_at")
  private LocalDateTime polSubmittedAt;

  @Column(name = "pod_required")
  @Builder.Default
  private Boolean podRequired = false;

  @Column(name = "pod_submitted")
  @Builder.Default
  private Boolean podSubmitted = false;

  @Column(name = "pod_submitted_at")
  private LocalDateTime podSubmittedAt;

  @Column(name = "pod_verified")
  @Builder.Default
  private Boolean podVerified = false;

  // ===================== PRE-ENTRY SAFETY CHECK FIELDS =====================
  @Enumerated(EnumType.STRING)
  @Column(name = "pre_entry_safety_status", length = 50)
  @Builder.Default
  private PreEntrySafetyStatus preEntrySafetyStatus = PreEntrySafetyStatus.NOT_STARTED;

  @Column(name = "pre_entry_safety_required")
  @Builder.Default
  private Boolean preEntrySafetyRequired = false;

  @PrePersist
  protected void onCreate() {
    this.createdDate = LocalDateTime.now();
    this.updatedDate = LocalDateTime.now();
    if (this.version == null) {
      this.version = 0L;
    }
  }

  @PreUpdate
  protected void onUpdate() {
    this.updatedDate = LocalDateTime.now();
  }
}
