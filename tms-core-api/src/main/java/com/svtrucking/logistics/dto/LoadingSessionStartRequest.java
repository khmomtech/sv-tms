package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.WarehouseCode;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class LoadingSessionStartRequest {

  private Long queueId;

  @NotNull
  private Long dispatchId;

  private WarehouseCode warehouseCode;

  private String bay;

  private LocalDateTime startedAt;

  private String remarks;
}
