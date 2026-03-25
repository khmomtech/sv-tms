package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DispatchFlowVersionStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "dispatch_flow_template_version",
    uniqueConstraints = {
      @UniqueConstraint(
          name = "uk_dispatch_flow_template_version",
          columnNames = {"template_id", "version_no"})
    })
@Getter
@Setter
@NoArgsConstructor
public class DispatchFlowTemplateVersion {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "template_id", nullable = false)
  private DispatchFlowTemplate template;

  @Column(name = "version_no", nullable = false)
  private Integer versionNo;

  @Column(name = "version_label", nullable = false, length = 40)
  private String versionLabel;

  @Enumerated(EnumType.STRING)
  @Column(name = "status", nullable = false, length = 20)
  private DispatchFlowVersionStatus status = DispatchFlowVersionStatus.PUBLISHED;

  @Column(name = "active_published", nullable = false)
  private boolean activePublished = false;

  @Column(name = "source_updated_at")
  private LocalDateTime sourceUpdatedAt;

  @Column(name = "notes", length = 255)
  private String notes;

  @Column(name = "created_by")
  private Long createdBy;

  @Column(name = "published_at", nullable = false)
  private LocalDateTime publishedAt;

  @Column(name = "created_at", nullable = false)
  private LocalDateTime createdAt;

  @Column(name = "updated_at", nullable = false)
  private LocalDateTime updatedAt;

  @PrePersist
  void onCreate() {
    LocalDateTime now = LocalDateTime.now();
    if (createdAt == null) createdAt = now;
    if (updatedAt == null) updatedAt = now;
    if (publishedAt == null) publishedAt = now;
  }

  @PreUpdate
  void onUpdate() {
    updatedAt = LocalDateTime.now();
  }
}
