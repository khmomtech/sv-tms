package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "work_order_parts",
    indexes = {
      @Index(name = "idx_wop_work_order", columnList = "work_order_id"),
      @Index(name = "idx_wop_task", columnList = "task_id"),
      @Index(name = "idx_wop_part", columnList = "part_id")
    })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkOrderPart {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "work_order_id", nullable = false)
  private WorkOrder workOrder;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "task_id")
  private WorkOrderTask task;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "part_id", nullable = false)
  private PartsMaster part;

  @Column(nullable = false)
  @Builder.Default
  private Integer quantity = 1;

  public Double getQuantityAsDouble() {
    return quantity != null ? quantity.doubleValue() : null;
  }

  public void setQuantityFromDouble(Double qty) {
    this.quantity = qty != null ? qty.intValue() : null;
    recalculateTotalCost();
  }

  @Column(precision = 10, scale = 2)
  private BigDecimal unitCost;

  public BigDecimal getUnitPrice() {
    return unitCost;
  }

  public void setUnitPrice(BigDecimal price) {
    this.unitCost = price;
    recalculateTotalCost();
  }

  @Column(precision = 10, scale = 2)
  private BigDecimal totalCost;

  @Column(length = 500)
  private String notes;

  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime addedAt = LocalDateTime.now();

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "added_by")
  private User addedBy;

  @PrePersist
  protected void onCreate() {
    if (addedAt == null) {
      addedAt = LocalDateTime.now();
    }
    recalculateTotalCost();
  }

  @PreUpdate
  protected void onUpdate() {
    recalculateTotalCost();
  }

  private void recalculateTotalCost() {
    if (unitCost != null && quantity != null) {
      totalCost = unitCost.multiply(BigDecimal.valueOf(quantity));
    }
  }
}
