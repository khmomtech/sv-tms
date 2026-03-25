package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Task Activity Log - audit trail for all task changes
 */
@Entity
@Table(name = "task_activity_log", indexes = {
    @Index(name = "idx_task_activity_task", columnList = "task_id"),
    @Index(name = "idx_task_activity_user", columnList = "user_id"),
    @Index(name = "idx_task_activity_created", columnList = "created_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskActivityLog {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "task_id", nullable = false)
  private Task task;

  @Column(nullable = false, length = 50)
  private String action; // CREATED, STATUS_CHANGED, ASSIGNED, COMMENTED, ATTACHMENT_ADDED, COMPLETED

  @Column(nullable = false, columnDefinition = "TEXT")
  private String message;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id")
  private User user;

  @CreationTimestamp
  @Column(nullable = false, updatable = false)
  private LocalDateTime createdAt;

  // JSON metadata for additional context
  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "json")
  @Builder.Default
  private Map<String, Object> metadata = new HashMap<>();

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }
}
