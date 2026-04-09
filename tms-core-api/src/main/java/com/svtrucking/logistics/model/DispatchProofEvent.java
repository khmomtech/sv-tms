package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DispatchProofReviewStatus;
import com.svtrucking.logistics.enums.DispatchStatus;
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
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "dispatch_proof_event")
@Getter
@Setter
@NoArgsConstructor
public class DispatchProofEvent {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "dispatch_id", nullable = false)
  private Dispatch dispatch;

  @Column(name = "workflow_version_id")
  private Long workflowVersionId;

  @Column(name = "proof_type", nullable = false, length = 20)
  private String proofType;

  @Column(name = "actor_user_id")
  private Long actorUserId;

  @Column(name = "actor_roles_snapshot", length = 500)
  private String actorRolesSnapshot;

  @Enumerated(EnumType.STRING)
  @Column(name = "dispatch_status_at_submission", length = 50)
  private DispatchStatus dispatchStatusAtSubmission;

  @Column(name = "accepted", nullable = false)
  private boolean accepted;

  @Column(name = "block_code", length = 100)
  private String blockCode;

  @Column(name = "block_reason", length = 500)
  private String blockReason;

  @Column(name = "idempotency_key", length = 150)
  private String idempotencyKey;

  @Column(name = "file_count", nullable = false)
  private int fileCount;

  @Enumerated(EnumType.STRING)
  @Column(name = "review_status", nullable = false, length = 20)
  private DispatchProofReviewStatus reviewStatus = DispatchProofReviewStatus.NOT_REQUIRED;

  @Column(name = "review_note", length = 500)
  private String reviewNote;

  @Column(name = "reviewed_by")
  private Long reviewedBy;

  @Column(name = "reviewed_at")
  private LocalDateTime reviewedAt;

  @Column(name = "submitted_at", nullable = false)
  private LocalDateTime submittedAt;

  @PrePersist
  void onCreate() {
    if (submittedAt == null) {
      submittedAt = LocalDateTime.now();
    }
  }
}
