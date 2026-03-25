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
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Task Attachment Entity - for files attached to tasks
 */
@Entity
@Table(name = "task_attachments", indexes = {
    @Index(name = "idx_task_attachments_task", columnList = "task_id"),
    @Index(name = "idx_task_attachments_uploaded_by", columnList = "uploaded_by_user_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskAttachment {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "task_id", nullable = false)
  private Task task;

  @Column(nullable = false, length = 255)
  private String fileName;

  @Column(nullable = false, length = 500)
  private String fileUrl;

  @Column(length = 100)
  private String mimeType;

  @Column(name = "file_size_bytes")
  private Long fileSizeBytes;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "uploaded_by_user_id", nullable = false)
  private User uploadedBy;

  @CreationTimestamp
  @Column(nullable = false, updatable = false)
  private LocalDateTime uploadedAt;

  @Column(length = 500)
  private String description;

  @Column(name = "is_deleted")
  @Builder.Default
  private Boolean isDeleted = false;

  @PrePersist
  protected void onCreate() {
    if (uploadedAt == null) {
      uploadedAt = LocalDateTime.now();
    }
  }
}
