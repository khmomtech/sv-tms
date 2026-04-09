package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.enums.DispatchFlowActorType;
import com.svtrucking.logistics.enums.DispatchStatus;
import jakarta.validation.constraints.NotNull;
import java.util.Set;
import lombok.Data;

@Data
public class DispatchFlowSimulationRequest {
  @NotNull
  private Long dispatchId;

  private DispatchStatus targetStatus;
  private String proofType;
  private Set<DispatchFlowActorType> actorTypes;
}
