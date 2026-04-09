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
public class BookingReportSummaryDto {
  private Long totalBookings;
  private Long confirmedBookings;
  private Long cancelledBookings;
  private Long convertedToOrderBookings;
  private Long newBookings;
  private BigDecimal totalRevenue;
  private BigDecimal averageCost;
  private Double confirmationRate;
  private Double cancellationRate;
  private Double conversionRate;
}
