package com.svtrucking.logistics.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class LoadingPalletItemDto {
  private Long id;

  @NotBlank
  private String itemDescription;

  private String palletTag;

  @NotNull
  @Min(1)
  private Integer quantity;

  private String unit;

  private String conditionNote;

  private boolean verifiedOk;
}
