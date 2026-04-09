package com.svtrucking.logistics.model;

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
    name = "loading_sessions",
    indexes = {
        @Index(name = "idx_loading_session_dispatch", columnList = "dispatch_id", unique = true),
        @Index(name = "idx_loading_session_warehouse", columnList = "warehouse_code"),
        @Index(name = "idx_loading_session_started", columnList = "started_at")
    }
)
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoadingSession {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @OneToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "dispatch_id", nullable = false, unique = true)
  private Dispatch dispatch;

  @OneToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "queue_id")
  private LoadingQueue queue;

  @Enumerated(EnumType.STRING)
  @Column(name = "warehouse_code", length = 10, nullable = false)
  private WarehouseCode warehouseCode;

  @Column(name = "bay", length = 32)
  private String bay;

  @Column(name = "started_at")
  private LocalDateTime startedAt;

  @Column(name = "ended_at")
  private LocalDateTime endedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "started_by")
  private User startedBy;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "ended_by")
  private User endedBy;

  @Column(name = "remarks", length = 500)
  private String remarks;

  @CreationTimestamp
  @Column(name = "created_date", updatable = false)
  private LocalDateTime createdDate;

  @UpdateTimestamp
  @Column(name = "updated_date")
  private LocalDateTime updatedDate;
}
