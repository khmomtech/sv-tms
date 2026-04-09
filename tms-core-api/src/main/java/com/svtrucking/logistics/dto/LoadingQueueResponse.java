package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.WarehouseCode;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class LoadingQueueResponse {
  private Long id;
  private Long dispatchId;
  private String routeCode;
  private WarehouseCode warehouseCode;
  private LoadingQueueStatus status;
  private Integer queuePosition;
  private String bay;
  private String remarks;
  private LocalDateTime calledAt;
  private LocalDateTime loadingStartedAt;
  private LocalDateTime loadingCompletedAt;
  private DispatchStatus dispatchStatus;
  private LocalDateTime createdDate;
  private LocalDateTime updatedDate;
}
