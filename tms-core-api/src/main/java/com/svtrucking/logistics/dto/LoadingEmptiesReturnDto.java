package com.svtrucking.logistics.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class LoadingEmptiesReturnDto {
  private Long id;

  @NotBlank
  private String itemName;

  @NotNull
  @Min(0)
  private Integer quantity;

  private String unit;

  private String conditionNote;

  private LocalDateTime recordedAt;
}
