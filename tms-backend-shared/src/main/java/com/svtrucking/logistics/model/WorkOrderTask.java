package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.TaskStatus;
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
    name = "work_order_tasks",
    indexes = {
      @Index(name = "idx_wot_work_order", columnList = "work_order_id"),
      @Index(name = "idx_wot_status", columnList = "status"),
      @Index(name = "idx_wot_assigned", columnList = "assigned_technician_id")
    })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkOrderTask {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "work_order_id", nullable = false)
  private WorkOrder workOrder;

  @Column(length = 200)
  private String category;

  public String getTaskName() {
    return category;
  }

  public void setTaskName(String taskName) {
    this.category = taskName;
  }

  @Column(columnDefinition = "TEXT")
  private String description;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "assigned_technician_id")
  private User assignedTechnician;

  @Column(columnDefinition = "TEXT")
  private String diagnosisResult;

  @Column(columnDefinition = "TEXT")
  private String actionsTaken;

  @Builder.Default
  private Integer timeSpentMinutes = 0;

  private Double estimatedHours;
  private Double actualHours;

  @Column(columnDefinition = "TEXT")
  private String notes;

  public void setActualHours(Double hours) {
    this.actualHours = hours;
    if (hours != null) {
      this.timeSpentMinutes = (int) (hours * 60);
    }
  }

  public Double getActualHours() {
    if (actualHours != null) {
      return actualHours;
    }
    return timeSpentMinutes != null ? timeSpentMinutes / 60.0 : null;
  }

  @Enumerated(EnumType.STRING)
  @Column(length = 20)
  @Builder.Default
  private TaskStatus status = TaskStatus.OPEN;

  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime createdAt = LocalDateTime.now();

  private LocalDateTime startedAt;
  private LocalDateTime completedAt;
  private LocalDateTime updatedAt;

  @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<WorkOrderPart> partsUsed = new ArrayList<>();

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
