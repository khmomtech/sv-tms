package com.svtrucking.logistics.dto.dispatchflow;

import lombok.Data;

@Data
public class DispatchProofReviewDecisionRequest {
  private Boolean approved;
  private String auditNote;
}
