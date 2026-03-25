package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "case_attachments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CaseAttachment {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "case_id", nullable = false)
  private Case caseEntity;

  @Column(name = "file_name", length = 255, nullable = false)
  private String fileName;

  @Column(name = "file_path", length = 500, nullable = false)
  private String filePath;

  @Column(name = "file_size")
  private Long fileSize;

  @Column(name = "mime_type", length = 100)
  private String mimeType;

  @Column(columnDefinition = "TEXT")
  private String description;

  @Column(name = "uploaded_at", nullable = false)
  @Builder.Default
  private LocalDateTime uploadedAt = LocalDateTime.now();

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "uploaded_by_user_id")
  private User uploadedByUser;

  @PrePersist
  protected void onCreate() {
    if (uploadedAt == null) {
      uploadedAt = LocalDateTime.now();
    }
  }
}
