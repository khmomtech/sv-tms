package com.svtrucking.logistics.dto.dispatchflow;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import lombok.Data;

@Data
public class DispatchFlowRuleReorderRequest {

  @NotEmpty(message = "ruleIds is required")
  private List<Long> ruleIds;
}

