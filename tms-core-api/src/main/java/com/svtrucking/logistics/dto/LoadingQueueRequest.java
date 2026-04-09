package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.WarehouseCode;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class LoadingQueueRequest {

  @NotNull
  private Long dispatchId;

  @NotNull
  private WarehouseCode warehouseCode;

  private Integer queuePosition;

  private String remarks;
}
