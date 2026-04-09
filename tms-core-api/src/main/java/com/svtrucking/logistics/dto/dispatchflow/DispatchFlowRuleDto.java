package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.enums.DispatchFlowActorType;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.DispatchFlowTransitionRule;
import java.util.Map;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DispatchFlowRuleDto {
  private Long id;
  private Long templateId;
  private DispatchStatus fromStatus;
  private DispatchStatus toStatus;
  private boolean enabled;
  private int priority;
  private boolean requiresConfirmation;
  private boolean requiresInput;
  private String validationMessage;
  private String metadataJson;
  private DispatchFlowProofPolicyDto proofPolicy;
  private Map<DispatchFlowActorType, Boolean> actors;

  public static DispatchFlowRuleDto fromEntity(
      DispatchFlowTransitionRule rule,
      Map<DispatchFlowActorType, Boolean> actors,
      DispatchFlowProofPolicyDto proofPolicy) {
    return DispatchFlowRuleDto.builder()
        .id(rule.getId())
        .templateId(rule.getTemplate().getId())
        .fromStatus(rule.getFromStatus())
        .toStatus(rule.getToStatus())
        .enabled(rule.isEnabled())
        .priority(rule.getPriority())
        .requiresConfirmation(rule.isRequiresConfirmation())
        .requiresInput(rule.isRequiresInput())
        .validationMessage(rule.getValidationMessage())
        .metadataJson(rule.getMetadataJson())
        .proofPolicy(proofPolicy)
        .actors(actors)
        .build();
  }
}
