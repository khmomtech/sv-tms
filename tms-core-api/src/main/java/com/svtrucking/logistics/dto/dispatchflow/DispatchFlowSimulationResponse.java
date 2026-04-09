package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.dto.response.DispatchActionMetadata;
import com.svtrucking.logistics.enums.DispatchFlowActorType;
import com.svtrucking.logistics.enums.DispatchStatus;
import java.util.List;
import java.util.Set;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DispatchFlowSimulationResponse {
  private Long dispatchId;
  private String linkedTemplateCode;
  private String resolvedTemplateCode;
  private Long workflowVersionId;
  private Long resolvedWorkflowVersionId;
  private DispatchStatus currentStatus;
  private DispatchStatus targetStatus;
  private String proofType;
  private Set<DispatchFlowActorType> actorTypes;
  private boolean allowed;
  private String blockedCode;
  private String blockedReason;
  private DispatchFlowProofPolicyDto proofPolicy;
  private DispatchProofStateDto proofState;
  private List<DispatchActionMetadata> availableActions;
}
