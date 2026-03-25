package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.PhotoType;
import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.enums.RepairType;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.enums.WorkOrderType;
import jakarta.persistence.CascadeType;
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
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "work_orders", indexes = {
    @Index(name = "idx_wo_vehicle", columnList = "vehicle_id"),
    @Index(name = "idx_wo_status", columnList = "status"),
    @Index(name = "idx_wo_created", columnList = "created_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkOrder {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(unique = true, nullable = false, length = 50)
  private String woNumber;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vehicle_id", nullable = false)
  private Vehicle vehicle;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "maintenance_request_id")
  private MaintenanceRequest maintenanceRequest;

  @Column(columnDefinition = "TEXT")
  private String issueSummary;

  @Column(length = 300)
  private String title;

  @Column(columnDefinition = "TEXT")
  private String description;

  @Column(columnDefinition = "TEXT")
  private String notes;

  @Enumerated(EnumType.STRING)
  @Column(length = 30)
  @Builder.Default
  private WorkOrderStatus status = WorkOrderStatus.OPEN;

  @Enumerated(EnumType.STRING)
  @Column(length = 20, nullable = false)
  private WorkOrderType type;

  @Enumerated(EnumType.STRING)
  @Column(name = "repair_type", length = 20)
  private RepairType repairType;

  @Enumerated(EnumType.STRING)
  @Column(length = 20)
  @Builder.Default
  private Priority priority = Priority.NORMAL;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "assigned_technician_id")
  private User assignedTechnician;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "supervisor_id")
  private User supervisor;

  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime createdAt = LocalDateTime.now();

  private LocalDateTime scheduledDate;
  private LocalDateTime startedAt;
  private LocalDateTime completedAt;
  private LocalDateTime closedAt;

  @Column(precision = 10, scale = 2)
  @Builder.Default
  private BigDecimal laborCost = BigDecimal.ZERO;

  @Column(precision = 10, scale = 2)
  @Builder.Default
  private BigDecimal partsCost = BigDecimal.ZERO;

  @Column(precision = 10, scale = 2)
  @Builder.Default
  private BigDecimal totalCost = BigDecimal.ZERO;

  @Column(precision = 10, scale = 2)
  private BigDecimal estimatedCost;

  @Column(precision = 10, scale = 2)
  private BigDecimal actualCost;

  @Column(columnDefinition = "TEXT")
  private String remarks;

  @Builder.Default
  private Boolean approved = false;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "approved_by")
  private User approvedBy;

  private LocalDateTime approvedAt;

  @Column(columnDefinition = "TEXT")
  private String approvalRemarks;

  @Column(columnDefinition = "TEXT")
  private String rejectionReason;

  @Builder.Default
  private Boolean requiresApproval = true;

  @Column(length = 500)
  private String breakdownLocation;

  @Column
  private Double breakdownLatitude;

  @Column
  private Double breakdownLongitude;

  private LocalDateTime breakdownReportedAt;
  private LocalDateTime technicianDispatchedAt;
  private LocalDateTime technicianArrivedAt;
  private Integer downtimeMinutes;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "pm_schedule_id")
  private PMSchedule pmSchedule;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "driver_issue_id")
  private DriverIssue driverIssue;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "maintenance_task_id")
  private MaintenanceTaskType maintenanceTask;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by")
  private User createdBy;

  private LocalDateTime updatedAt;

  @Column(nullable = false)
  @Builder.Default
  private Boolean isDeleted = false;

  @OneToMany(mappedBy = "workOrder", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<WorkOrderTask> tasks = new ArrayList<>();

  @OneToMany(mappedBy = "workOrder", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<WorkOrderPhoto> photos = new ArrayList<>();

  @OneToMany(mappedBy = "workOrder", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<WorkOrderPart> parts = new ArrayList<>();

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }

  @PreUpdate
  protected void onUpdate() {
    updatedAt = LocalDateTime.now();
    calculateTotalCost();
  }

  public void calculateTotalCost() {
    this.totalCost = (this.laborCost != null ? this.laborCost : BigDecimal.ZERO)
        .add(this.partsCost != null ? this.partsCost : BigDecimal.ZERO);
  }

  public void addTask(WorkOrderTask task) {
    task.setWorkOrder(this);
    this.tasks.add(task);
  }

  public void addPhoto(String photoUrl, PhotoType type) {
    WorkOrderPhoto photo = new WorkOrderPhoto();
    photo.setWorkOrder(this);
    photo.setPhotoUrl(photoUrl);
    photo.setPhotoType(type);
    this.photos.add(photo);
  }

  public void addPart(PartsMaster part, Integer quantity, BigDecimal unitCost) {
    WorkOrderPart woPart = new WorkOrderPart();
    woPart.setWorkOrder(this);
    woPart.setPart(part);
    woPart.setQuantity(quantity);
    woPart.setUnitCost(unitCost);
    if (unitCost != null && quantity != null) {
      woPart.setTotalCost(unitCost.multiply(BigDecimal.valueOf(quantity)));
    }
    this.parts.add(woPart);
  }
}
