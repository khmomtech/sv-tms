package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import com.svtrucking.logistics.enums.SafetyCheckStatus;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class LoadingDispatchDetailResponse {
  private Long dispatchId;
  private DispatchDto dispatch;
  private LoadingQueueResponse queue;
  private LoadingSessionResponse session;
  private Boolean preEntrySafetyRequired;
  private PreEntrySafetyStatus preEntrySafetyStatus;
  private SafetyCheckStatus loadingSafetyStatus;
}
