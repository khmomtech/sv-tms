package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.enums.DispatchProofReviewStatus;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.DispatchProofEvent;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DispatchProofEventDto {
  private Long id;
  private Long dispatchId;
  private Long workflowVersionId;
  private String proofType;
  private Long actorUserId;
  private String actorRolesSnapshot;
  private DispatchStatus dispatchStatusAtSubmission;
  private boolean accepted;
  private String blockCode;
  private String blockReason;
  private String idempotencyKey;
  private int fileCount;
  private DispatchProofReviewStatus reviewStatus;
  private String reviewNote;
  private Long reviewedBy;
  private LocalDateTime reviewedAt;
  private LocalDateTime submittedAt;

  public static DispatchProofEventDto fromEntity(DispatchProofEvent event) {
    return DispatchProofEventDto.builder()
        .id(event.getId())
        .dispatchId(event.getDispatch() != null ? event.getDispatch().getId() : null)
        .workflowVersionId(event.getWorkflowVersionId())
        .proofType(event.getProofType())
        .actorUserId(event.getActorUserId())
        .actorRolesSnapshot(event.getActorRolesSnapshot())
        .dispatchStatusAtSubmission(event.getDispatchStatusAtSubmission())
        .accepted(event.isAccepted())
        .blockCode(event.getBlockCode())
        .blockReason(event.getBlockReason())
        .idempotencyKey(event.getIdempotencyKey())
        .fileCount(event.getFileCount())
        .reviewStatus(event.getReviewStatus())
        .reviewNote(event.getReviewNote())
        .reviewedBy(event.getReviewedBy())
        .reviewedAt(event.getReviewedAt())
        .submittedAt(event.getSubmittedAt())
        .build();
  }
}
