package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.enums.MaintenanceRequestType;
import com.svtrucking.logistics.enums.Priority;
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
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "maintenance_requests",
    indexes = {
      @Index(name = "idx_mr_vehicle", columnList = "vehicle_id"),
      @Index(name = "idx_mr_status", columnList = "status"),
      @Index(name = "idx_mr_requested_at", columnList = "requested_at"),
      @Index(name = "idx_mr_failure_code", columnList = "failure_code_id")
    })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaintenanceRequest {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "mr_number", unique = true, nullable = false, length = 50)
  private String mrNumber;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vehicle_id", nullable = false)
  private Vehicle vehicle;

  @Column(nullable = false, length = 200)
  private String title;

  @Column(columnDefinition = "TEXT")
  private String description;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "failure_code_id")
  private FailureCode failureCode;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  @Builder.Default
  private Priority priority = Priority.NORMAL;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  @Builder.Default
  private MaintenanceRequestStatus status = MaintenanceRequestStatus.SUBMITTED;

  @Enumerated(EnumType.STRING)
  @Column(name = "request_type", nullable = false, length = 20)
  @Builder.Default
  private MaintenanceRequestType requestType = MaintenanceRequestType.REPAIR;

  @Column(name = "requested_at", nullable = false)
  @Builder.Default
  private LocalDateTime requestedAt = LocalDateTime.now();

  @Column(name = "approved_at")
  private LocalDateTime approvedAt;

  @Column(name = "rejected_at")
  private LocalDateTime rejectedAt;

  @Column(name = "approval_remarks", columnDefinition = "TEXT")
  private String approvalRemarks;

  @Column(name = "rejection_reason", columnDefinition = "TEXT")
  private String rejectionReason;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by")
  private User createdBy;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "approved_by")
  private User approvedBy;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "rejected_by")
  private User rejectedBy;

  @Column(name = "updated_at")
  private LocalDateTime updatedAt;

  @Column(name = "is_deleted", nullable = false)
  @Builder.Default
  private Boolean isDeleted = false;

  @PrePersist
  protected void onCreate() {
    if (requestedAt == null) {
      requestedAt = LocalDateTime.now();
    }
    if (requestType == null) {
      requestType = MaintenanceRequestType.REPAIR;
    }
    updatedAt = LocalDateTime.now();
  }

  @PreUpdate
  protected void onUpdate() {
    updatedAt = LocalDateTime.now();
  }
}
