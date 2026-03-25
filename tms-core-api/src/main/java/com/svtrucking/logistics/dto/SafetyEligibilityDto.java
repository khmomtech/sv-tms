package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.DailySafetyCheckStatus;
import com.svtrucking.logistics.enums.SafetyRiskLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SafetyEligibilityDto {
  private boolean eligible;
  private DailySafetyCheckStatus status;
  private SafetyRiskLevel riskLevel;
  private Long safetyCheckId;
  private String message;
}
