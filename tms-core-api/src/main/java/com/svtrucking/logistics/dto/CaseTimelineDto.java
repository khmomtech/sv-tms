package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.TimelineEntryType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CaseTimelineDto {

  private Long id;
  private Long caseId;
  private TimelineEntryType entryType;
  private String message;
  private LocalDateTime createdAt;
  private Long createdByUserId;
  private String createdByUsername;
  private String metadata;
}
