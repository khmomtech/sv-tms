package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.enums.DispatchFlowActorType;
import jakarta.validation.constraints.NotEmpty;
import java.util.Map;
import lombok.Data;

@Data
public class DispatchFlowRuleActorsUpdateRequest {
  @NotEmpty
  private Map<DispatchFlowActorType, Boolean> actors;
}
