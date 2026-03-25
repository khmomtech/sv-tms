package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.*;

@Entity
@Table(
    name = "work_order_mechanics",
    indexes = {
      @Index(name = "idx_wo_mechanic_wo", columnList = "work_order_id"),
      @Index(name = "idx_wo_mechanic_mechanic", columnList = "mechanic_id")
    },
    uniqueConstraints = {@UniqueConstraint(name = "uk_wo_mechanic", columnNames = {"work_order_id", "mechanic_id"})})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkOrderMechanic {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "work_order_id", nullable = false)
  private WorkOrder workOrder;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "mechanic_id", nullable = false)
  private Mechanic mechanic;

  @Column(length = 50)
  @Builder.Default
  private String role = "MECHANIC";

  @Column(name = "assigned_at", nullable = false)
  @Builder.Default
  private LocalDateTime assignedAt = LocalDateTime.now();

  @PrePersist
  protected void onCreate() {
    if (assignedAt == null) {
      assignedAt = LocalDateTime.now();
    }
  }
}

