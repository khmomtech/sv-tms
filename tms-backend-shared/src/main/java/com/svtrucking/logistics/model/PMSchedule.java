package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.PMTriggerType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "pm_schedules")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PMSchedule {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, length = 200)
  private String scheduleName;

  public String getPmName() {
    return scheduleName;
  }

  public void setPmName(String pmName) {
    this.scheduleName = pmName;
  }

  @Column(columnDefinition = "TEXT")
  private String description;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vehicle_id")
  private Vehicle vehicle;

  @Column(length = 100)
  private String vehicleType;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  private PMTriggerType triggerType;

  @Column(nullable = false)
  private Integer triggerInterval;

  @Builder.Default
  private Integer reminderBeforeKm = 1000;

  @Builder.Default
  private Integer reminderBeforeDays = 7;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "task_type_id")
  private MaintenanceTaskType taskType;

  @Builder.Default
  private Boolean active = true;

  private LocalDateTime lastPerformedAt;
  private Integer lastPerformedKm;
  private Integer lastPerformedEngineHours;

  public LocalDate getLastPerformedDate() {
    return lastPerformedAt != null ? lastPerformedAt.toLocalDate() : null;
  }

  public void setLastPerformedDate(LocalDate date) {
    this.lastPerformedAt = date != null ? date.atStartOfDay() : null;
  }

  public Integer getIntervalKm() {
    return triggerType == PMTriggerType.KILOMETER ? triggerInterval : null;
  }

  public void setIntervalKm(Integer km) {
    if (km != null) {
      this.triggerType = PMTriggerType.KILOMETER;
      this.triggerInterval = km;
    }
  }

  public Integer getIntervalDays() {
    return triggerType == PMTriggerType.DATE ? triggerInterval : null;
  }

  public void setIntervalDays(Integer days) {
    if (days != null) {
      this.triggerType = PMTriggerType.DATE;
      this.triggerInterval = days;
    }
  }

  public Integer getIntervalEngineHours() {
    return triggerType == PMTriggerType.ENGINE_HOUR ? triggerInterval : null;
  }

  public void setIntervalEngineHours(Integer hours) {
    if (hours != null) {
      this.triggerType = PMTriggerType.ENGINE_HOUR;
      this.triggerInterval = hours;
    }
  }

  public MaintenanceTaskType getMaintenanceTaskType() {
    return taskType;
  }

  public void setMaintenanceTaskType(MaintenanceTaskType taskType) {
    this.taskType = taskType;
  }

  private LocalDate nextDueDate;
  private Integer nextDueKm;
  private Integer nextDueEngineHours;

  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime createdAt = LocalDateTime.now();

  private LocalDateTime updatedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by")
  private User createdBy;

  @Column(nullable = false)
  @Builder.Default
  private Boolean isDeleted = false;

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

  public boolean isDue(Integer currentKm, LocalDate currentDate, Integer currentEngineHours) {
    return switch (triggerType) {
      case KILOMETER -> currentKm != null && nextDueKm != null && currentKm >= nextDueKm;
      case DATE -> currentDate != null && nextDueDate != null && !currentDate.isBefore(nextDueDate);
      case ENGINE_HOUR ->
          currentEngineHours != null && nextDueEngineHours != null
              && currentEngineHours >= nextDueEngineHours;
    };
  }

  public boolean isDueSoon(Integer currentKm, LocalDate currentDate, Integer currentEngineHours) {
    return switch (triggerType) {
      case KILOMETER ->
          currentKm != null && nextDueKm != null && currentKm >= (nextDueKm - reminderBeforeKm);
      case DATE ->
          currentDate != null && nextDueDate != null
              && !currentDate.isBefore(nextDueDate.minusDays(reminderBeforeDays));
      case ENGINE_HOUR ->
          currentEngineHours != null && nextDueEngineHours != null
              && currentEngineHours >= (nextDueEngineHours - 50);
    };
  }
}
