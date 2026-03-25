package com.svtrucking.logistics.dto.dispatchflow;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DispatchWorkflowBindingDto {
  private Long dispatchId;
  private String linkedTemplateCode;
  private Long workflowVersionId;
  private String resolvedTemplateCode;
  private Long resolvedWorkflowVersionId;
  private boolean fallbackToDefault;
  private boolean fallbackToStateMachine;
  private DispatchProofStateDto proofState;
}
