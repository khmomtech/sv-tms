package com.svtrucking.logistics.dto.dispatchflow;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import lombok.Data;

@Data
public class DispatchFlowAssignDispatchRequest {
  @NotEmpty
  private List<Long> dispatchIds;

  @NotBlank
  private String templateCode;

  private Boolean allowOperationalOverride;
  private String auditNote;
}
