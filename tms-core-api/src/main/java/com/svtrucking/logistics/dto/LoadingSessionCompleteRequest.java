package com.svtrucking.logistics.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class LoadingSessionCompleteRequest {

  @NotNull
  private Long sessionId;

  private LocalDateTime endedAt;

  private String remarks;

  @Valid
  private List<LoadingPalletItemDto> palletItems;

  @Valid
  private List<LoadingEmptiesReturnDto> emptiesReturns;
}
