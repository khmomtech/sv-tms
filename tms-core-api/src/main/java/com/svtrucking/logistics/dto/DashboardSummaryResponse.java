package com.svtrucking.logistics.dto;

import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DashboardSummaryResponse {
  private DashboardSummaryDto summary;
  private List<TopDriverDto> topDrivers;
  private List<DriverDto> liveDrivers;
}
