package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.*;

@Entity
@Table(
    name = "safety_check_attachments",
    indexes = {
      @Index(name = "idx_safety_check_attachments_check", columnList = "safety_check_id"),
      @Index(name = "idx_safety_check_attachments_item", columnList = "item_id"),
      @Index(name = "idx_safety_check_attachments_uploaded_by", columnList = "uploaded_by")
    })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SafetyCheckAttachment {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "safety_check_id", nullable = false)
  private SafetyCheck safetyCheck;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "item_id")
  private SafetyCheckItem item;

  @Column(name = "file_url", nullable = false, length = 500)
  private String fileUrl;

  @Column(name = "file_name", length = 255)
  private String fileName;

  @Column(name = "mime_type", length = 100)
  private String mimeType;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "uploaded_by")
  private User uploadedBy;

  @Column(name = "created_at")
  private LocalDateTime createdAt;

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
  }
}
