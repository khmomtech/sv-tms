package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.WarehouseCode;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(
    name = "loading_queue",
    indexes = {
        @Index(name = "idx_loading_queue_dispatch", columnList = "dispatch_id", unique = true),
        @Index(name = "idx_loading_queue_status", columnList = "status"),
        @Index(name = "idx_loading_queue_warehouse", columnList = "warehouse_code")
    }
)
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoadingQueue {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @OneToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "dispatch_id", nullable = false, unique = true)
  private Dispatch dispatch;

  @Enumerated(EnumType.STRING)
  @Column(name = "warehouse_code", length = 10, nullable = false)
  private WarehouseCode warehouseCode;

  @Enumerated(EnumType.STRING)
  @Column(name = "status", length = 20, nullable = false)
  private LoadingQueueStatus status;

  @Column(name = "queue_position")
  private Integer queuePosition;

  @Column(name = "bay", length = 32)
  private String bay;

  @Column(name = "remarks", length = 500)
  private String remarks;

  @Column(name = "called_at")
  private LocalDateTime calledAt;

  @Column(name = "loading_started_at")
  private LocalDateTime loadingStartedAt;

  @Column(name = "loading_completed_at")
  private LocalDateTime loadingCompletedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by")
  private User createdBy;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "updated_by")
  private User updatedBy;

  @CreationTimestamp
  @Column(name = "created_date", updatable = false)
  private LocalDateTime createdDate;

  @UpdateTimestamp
  @Column(name = "updated_date")
  private LocalDateTime updatedDate;
}
