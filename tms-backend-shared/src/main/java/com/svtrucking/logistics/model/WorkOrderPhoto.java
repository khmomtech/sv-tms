package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.PhotoType;
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
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "work_order_photos",
    indexes = {
      @Index(name = "idx_woph_work_order", columnList = "work_order_id"),
      @Index(name = "idx_woph_task", columnList = "task_id"),
      @Index(name = "idx_woph_type", columnList = "photo_type")
    })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkOrderPhoto {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "work_order_id", nullable = false)
  private WorkOrder workOrder;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "task_id")
  private WorkOrderTask task;

  @Column(nullable = false, length = 500)
  private String photoUrl;

  @Enumerated(EnumType.STRING)
  @Column(length = 20, nullable = false)
  private PhotoType photoType;

  @Column(columnDefinition = "TEXT")
  private String description;

  @Column(nullable = false)
  @Builder.Default
  private LocalDateTime uploadedAt = LocalDateTime.now();

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "uploaded_by")
  private User uploadedBy;

  @PrePersist
  protected void onCreate() {
    if (uploadedAt == null) {
      uploadedAt = LocalDateTime.now();
    }
  }
}
