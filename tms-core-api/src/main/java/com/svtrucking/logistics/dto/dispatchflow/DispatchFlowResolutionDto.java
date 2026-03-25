package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.dto.response.DispatchActionMetadata;
import com.svtrucking.logistics.enums.DispatchStatus;
import java.util.List;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DispatchFlowResolutionDto {
  private Long dispatchId;
  private String linkedTemplateCode;
  private String resolvedTemplateCode;
  private String resolvedTemplateName;
  private Long workflowVersionId;
  private Long resolvedWorkflowVersionId;
  private boolean fallbackToDefault;
  private boolean fallbackToStateMachine;
  private DispatchStatus currentStatus;
  private DispatchProofStateDto proofState;
  private List<DispatchActionMetadata> availableActions;
}
