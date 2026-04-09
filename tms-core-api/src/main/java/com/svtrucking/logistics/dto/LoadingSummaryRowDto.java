package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoadingSummaryRowDto {
  private String customer;
  private String toDestination;
  private long totalTrip;
  private long completed;
  private long pending;
  private long loading;
  private long truckArrived;
  private long truckNotArrived;
  private double achievedPercentage;

  // Fields not in the new query but kept for compatibility
  private long completedLoading; // Same as completed
  private long approved;
  private long scheduled;
  private long inProgress;
  private long cancelled;
  private long rejected;

  // Constructor that matches the new JPQL query parameter order
  public LoadingSummaryRowDto(
      String customer,
      String toDestination,
      long totalTrip,
      long completed,
      long pending,
      long loading,
      long truckArrived,
      long truckNotArrived,
      double achievedPercentage) {
    this.customer = customer;
    this.toDestination = toDestination;
    this.totalTrip = totalTrip;
    this.completed = completed;
    this.pending = pending;
    this.loading = loading;
    this.truckArrived = truckArrived;
    this.truckNotArrived = truckNotArrived;
    this.achievedPercentage = achievedPercentage;

    // Set default values for fields not provided in the new query
    this.completedLoading = completed; // Same as completed
    this.approved = 0;
    this.scheduled = 0;
    this.inProgress = loading; // Same as loading
    this.cancelled = 0;
    this.rejected = 0;
  }
}
