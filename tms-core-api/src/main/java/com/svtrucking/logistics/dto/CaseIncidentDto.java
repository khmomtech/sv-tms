package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
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
public class CaseIncidentDto {

  private Long id;
  private Long caseId;
  private String caseCode;
  private Long incidentId;
  private String incidentCode;
  private LocalDateTime linkedAt;
  private Long linkedByUserId;
  private String linkedByUsername;
  private String notes;

  // Optional: full incident details
  private IncidentDto incident;
}
