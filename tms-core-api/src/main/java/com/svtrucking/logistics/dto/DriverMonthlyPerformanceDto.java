package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.DriverMonthlyPerformance;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DriverMonthlyPerformanceDto {

  private Long id;
  private Long driverId;
  private Integer year;
  private Integer month;
  private String period; // YYYY-MM
  private String monthName;

  // Delivery metrics
  private Integer totalDeliveries;
  private Integer completedDeliveries;
  private Integer onTimeDeliveries;
  private Integer lateDeliveries;
  private Integer cancelledDeliveries;
  private Integer completionRate;
  private Integer onTimeRate;

  // Safety metrics
  private Integer incidentsCount;
  private Integer safetyViolations;
  private String safetyScore;

  // Performance scores
  private Integer performanceScore;
  private Integer onTimePercent;
  private Double averageRating;
  private Integer totalRatings;

  // Ranking
  private Integer leaderboardRank;
  private String rankTier;

  // Distance and fuel
  private Double totalDistanceKm;
  private Double fuelEfficiency;

  // Metadata
  private LocalDate lastCalculatedAt;
  private Boolean isFinalized;

  public static DriverMonthlyPerformanceDto fromEntity(DriverMonthlyPerformance entity) {
    if (entity == null) return null;

    return DriverMonthlyPerformanceDto.builder()
        .id(entity.getId())
        .driverId(entity.getDriver().getId())
        .year(entity.getYear())
        .month(entity.getMonth())
        .period(entity.getPeriod())
        .monthName(entity.getMonthName())
        .totalDeliveries(entity.getTotalDeliveries())
        .completedDeliveries(entity.getCompletedDeliveries())
        .onTimeDeliveries(entity.getOnTimeDeliveries())
        .lateDeliveries(entity.getLateDeliveries())
        .cancelledDeliveries(entity.getCancelledDeliveries())
        .completionRate(entity.getCompletionRate())
        .onTimeRate(entity.getOnTimeRate())
        .incidentsCount(entity.getIncidentsCount())
        .safetyViolations(entity.getSafetyViolations())
        .safetyScore(entity.getSafetyScore())
        .performanceScore(entity.getPerformanceScore())
        .onTimePercent(entity.getOnTimePercent())
        .averageRating(entity.getAverageRating())
        .totalRatings(entity.getTotalRatings())
        .leaderboardRank(entity.getLeaderboardRank())
        .rankTier(entity.getRankTier())
        .totalDistanceKm(entity.getTotalDistanceKm())
        .fuelEfficiency(entity.getFuelEfficiency())
        .lastCalculatedAt(entity.getLastCalculatedAt())
        .isFinalized(entity.getIsFinalized())
        .build();
  }
}
