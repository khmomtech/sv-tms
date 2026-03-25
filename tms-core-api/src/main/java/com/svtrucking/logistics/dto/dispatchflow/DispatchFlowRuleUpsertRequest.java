package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.enums.DispatchStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class DispatchFlowRuleUpsertRequest {
  @NotNull private DispatchStatus fromStatus;
  @NotNull private DispatchStatus toStatus;

  private Boolean enabled = Boolean.TRUE;
  private Integer priority = 100;
  private Boolean requiresConfirmation = Boolean.FALSE;
  private Boolean requiresInput = Boolean.FALSE;
  private String validationMessage;
  private String metadataJson;
  private DispatchFlowProofPolicyDto proofPolicy;
}
