package com.svtrucking.logistics.dto;

import java.math.BigDecimal;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BookingAnalyticsDto {
  private String name; // Customer name, driver name, vehicle type, service type, etc.
  private Long count;
  private BigDecimal revenue;
  private BigDecimal averageCost;
  private Double confirmationRate;
  private Double conversionRate;
}
