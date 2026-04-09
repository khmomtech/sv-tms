package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.WarehouseCode;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class LoadingSessionResponse {
  private Long id;
  private Long dispatchId;
  private Long queueId;
  private WarehouseCode warehouseCode;
  private String bay;
  private LocalDateTime startedAt;
  private LocalDateTime endedAt;
  private String remarks;
  private DispatchStatus dispatchStatus;
  private LoadingQueueStatus queueStatus;
  private List<LoadingPalletItemDto> palletItems;
  private List<LoadingEmptiesReturnDto> emptiesReturns;
  private List<LoadingDocumentDto> documents;
}
