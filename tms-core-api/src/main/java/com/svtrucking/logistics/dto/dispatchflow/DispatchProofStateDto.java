package com.svtrucking.logistics.dto.dispatchflow;

import com.svtrucking.logistics.enums.DispatchStatus;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DispatchProofStateDto {
  private Long dispatchId;
  private DispatchStatus currentStatus;
  private String linkedTemplateCode;
  private String resolvedTemplateCode;
  private Long workflowVersionId;
  private Long resolvedWorkflowVersionId;
  private Boolean polRequired;
  private Boolean polSubmitted;
  private LocalDateTime polSubmittedAt;
  private Boolean podRequired;
  private Boolean podSubmitted;
  private LocalDateTime podSubmittedAt;
  private Boolean podVerified;
  private boolean loadProofPresent;
  private boolean unloadProofPresent;
}
