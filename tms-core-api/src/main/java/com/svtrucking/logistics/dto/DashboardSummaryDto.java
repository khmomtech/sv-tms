package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class DashboardSummaryDto {
  private long totalOrders;
  private long pendingOrders;
  private long inTransitOrders;
  private long completedOrders;
  private long cancelledOrders;
  private long todayOrders;
  private long scheduledDeliveriesToday;
}
