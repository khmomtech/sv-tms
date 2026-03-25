package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.LoadingDocumentType;
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
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(
    name = "loading_documents",
    indexes = {
        @Index(name = "idx_loading_doc_dispatch", columnList = "dispatch_id"),
        @Index(name = "idx_loading_doc_session", columnList = "loading_session_id"),
        @Index(name = "idx_loading_doc_type", columnList = "document_type")
    }
)
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoadingDocument {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "loading_session_id", nullable = false)
  private LoadingSession loadingSession;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "dispatch_id", nullable = false)
  private Dispatch dispatch;

  @Enumerated(EnumType.STRING)
  @Column(name = "document_type", length = 50, nullable = false)
  private LoadingDocumentType documentType;

  @Column(name = "file_name", length = 255, nullable = false)
  private String fileName;

  @Column(name = "file_url", length = 512, nullable = false)
  private String fileUrl;

  @Column(name = "mime_type", length = 100)
  private String mimeType;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "uploaded_by")
  private User uploadedBy;

  @CreationTimestamp
  @Column(name = "uploaded_at", updatable = false)
  private LocalDateTime uploadedAt;
}
