package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.YearMonth;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "driver_monthly_performance", 
       uniqueConstraints = @UniqueConstraint(columnNames = {"driver_id", "year_num", "month_num"}))
public class DriverMonthlyPerformance {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "driver_id", nullable = false,
      foreignKey = @ForeignKey(ConstraintMode.NO_CONSTRAINT))
  private Driver driver;

  // Avoid reserved keywords (e.g. H2 "YEAR") in generated DDL.
  @Column(name = "year_num", nullable = false)
  private Integer year;

  // Avoid reserved keywords (e.g. H2 "MONTH") in generated DDL.
  @Column(name = "month_num", nullable = false)
  private Integer month; // 1-12

  // Performance metrics for the month
  @Column(name = "total_deliveries")
  @Builder.Default
  private Integer totalDeliveries = 0;

  @Column(name = "completed_deliveries")
  @Builder.Default
  private Integer completedDeliveries = 0;

  @Column(name = "on_time_deliveries")
  @Builder.Default
  private Integer onTimeDeliveries = 0;

  @Column(name = "late_deliveries")
  @Builder.Default
  private Integer lateDeliveries = 0;

  @Column(name = "cancelled_deliveries")
  @Builder.Default
  private Integer cancelledDeliveries = 0;

  // Safety metrics
  @Column(name = "incidents_count")
  @Builder.Default
  private Integer incidentsCount = 0;

  @Column(name = "safety_violations")
  @Builder.Default
  private Integer safetyViolations = 0;

  // Calculated scores (0-100)
  @Column(name = "performance_score")
  @Builder.Default
  private Integer performanceScore = 0;

  @Column(name = "on_time_percent")
  @Builder.Default
  private Integer onTimePercent = 0;

  // Customer feedback
  @Column(name = "total_ratings")
  @Builder.Default
  private Integer totalRatings = 0;

  @Column(name = "average_rating")
  private Double averageRating;

  // Ranking
  @Column(name = "leaderboard_rank")
  @Builder.Default
  private Integer leaderboardRank = 0;

  @Column(name = "rank_tier")
  private String rankTier; // Gold, Silver, Bronze

  @Column(name = "safety_score")
  @Builder.Default
  private String safetyScore = "Good";

  // Distance and fuel
  @Column(name = "total_distance_km")
  private Double totalDistanceKm;

  @Column(name = "fuel_efficiency")
  private Double fuelEfficiency;

  // Metadata
  @Column(name = "last_calculated_at")
  private LocalDate lastCalculatedAt;

  @Column(name = "is_finalized")
  @Builder.Default
  private Boolean isFinalized = false;

  // Helper methods
  @Transient
  public String getMonthName() {
    return YearMonth.of(year, month).getMonth().name();
  }

  @Transient
  public String getPeriod() {
    return String.format("%04d-%02d", year, month);
  }

  @Transient
  public Integer getCompletionRate() {
    if (totalDeliveries == 0) return 0;
    return (completedDeliveries * 100) / totalDeliveries;
  }

  @Transient
  public Integer getOnTimeRate() {
    if (completedDeliveries == 0) return 0;
    return (onTimeDeliveries * 100) / completedDeliveries;
  }

  @Transient
  public Boolean hasIncidents() {
    return incidentsCount > 0 || safetyViolations > 0;
  }
}
