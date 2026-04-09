package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.*;

@Entity
@Table(name = "pm_schedule_history")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PMScheduleHistory {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "pm_schedule_id", nullable = false)
  private PMSchedule pmSchedule;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vehicle_id", nullable = false)
  private Vehicle vehicle;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "work_order_id")
  private WorkOrder workOrder;

  private LocalDateTime performedAt;
  private Integer performedKm;
  private Integer performedEngineHours;

  // DTO-compatible alias
  public Integer getPerformedAtKm() {
    return performedKm;
  }

  public void setPerformedAtKm(Integer km) {
    this.performedKm = km;
  }

  private LocalDate nextDueDate;
  private Integer nextDueKm;
  private Integer nextDueEngineHours;

  @Column(columnDefinition = "TEXT")
  private String notes;

  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime createdAt = LocalDateTime.now();

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }
}
