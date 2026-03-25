package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IncidentStatisticsDto {
  private Long total;
  private Map<String, Long> byStatus;
  private Map<String, Long> byGroup;
  private Map<String, Long> bySeverity;
  private Long slaBreached;
  private Long withinSla;
}
