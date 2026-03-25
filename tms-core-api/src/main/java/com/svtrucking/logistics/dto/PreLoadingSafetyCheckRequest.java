package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.SafetyResult;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class PreLoadingSafetyCheckRequest {
  @NotNull private Long dispatchId;
  @NotNull private Boolean driverPpeOk;
  @NotNull private Boolean fireExtinguisherOk;
  @NotNull private Boolean wheelChockOk;
  @NotNull private Boolean truckLeakageOk;
  @NotNull private Boolean truckCleanOk;
  @NotNull private Boolean truckConditionOk;
  @NotNull private SafetyResult result;

  @Size(max = 500)
  private String failReason;

  private Long checkedByUserId;
  private LocalDateTime checkedAt;
  // Optional fields for offline/idempotency and location
  @Size(max = 36)
  private String clientUuid;

  private Double locationLat;
  private Double locationLng;

  private Long loadingSessionId;
  private Long proofDocumentId;
}
