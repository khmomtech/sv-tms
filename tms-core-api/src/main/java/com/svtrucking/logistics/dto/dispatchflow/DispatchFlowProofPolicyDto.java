package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.enums.DispatchStatus;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DispatchFlowProofPolicyDto {
  @Builder.Default
  private Boolean proofRequired = Boolean.FALSE;

  @Builder.Default
  private String requiredInputType = "NONE";

  private String proofType;
  private List<DispatchStatus> proofSubmissionAllowedStatuses;
  private String proofSubmissionMode;
  private DispatchStatus autoAdvanceStatusAfterProof;
  @Builder.Default
  private Boolean proofReviewRequired = Boolean.FALSE;
  @Builder.Default
  private Boolean allowLateProofRecovery = Boolean.FALSE;
  private String blockMessage;
  private String blockCode;
  private Integer minImages;
  private Integer maxImages;
  @Builder.Default
  private Boolean signatureRequired = Boolean.FALSE;
  @Builder.Default
  private Boolean locationRequired = Boolean.FALSE;
  @Builder.Default
  private Boolean remarksRequired = Boolean.FALSE;
  private Long maxFileSizeBytes;
  private List<String> mimeTypes;
}
