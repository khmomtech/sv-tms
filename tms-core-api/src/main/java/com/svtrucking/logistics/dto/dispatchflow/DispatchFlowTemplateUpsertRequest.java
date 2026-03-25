package com.svtrucking.logistics.dto.dispatchflow;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class DispatchFlowTemplateUpsertRequest {
  @NotBlank
  @Size(max = 30)
  private String code;

  @NotBlank
  @Size(max = 120)
  private String name;

  @Size(max = 255)
  private String description;

  private Boolean active = Boolean.TRUE;
}
