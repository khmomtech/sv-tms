package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.SafetyResult;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class PreLoadingSafetyCheckResponse {
  private Long id;
  private Long dispatchId;
  private boolean driverPpeOk;
  private boolean fireExtinguisherOk;
  private boolean wheelChockOk;
  private boolean truckLeakageOk;
  private boolean truckCleanOk;
  private boolean truckConditionOk;
  private SafetyResult result;
  private String failReason;
  private Long checkedByUserId;
  private String checkedByName;
  private String checkedByUsername;
  private LocalDateTime checkedAt;
  private LocalDateTime createdDate;
  private String clientUuid;
  private Double locationLat;
  private Double locationLng;
  private Long loadingSessionId;
  private Long proofDocumentId;
  private boolean synced;
  private String dispatchStatusAfterCheck;
  private Boolean autoTransitionApplied;
  private String transitionMessage;
}
