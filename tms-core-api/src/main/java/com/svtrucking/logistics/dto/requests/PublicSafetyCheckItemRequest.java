package com.svtrucking.logistics.dto.requests;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class PublicSafetyCheckItemRequest {
  @NotBlank
  private String category;

  @NotBlank
  private String label;

  private Boolean ok;

  private String remark;
}
