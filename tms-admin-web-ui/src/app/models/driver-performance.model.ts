export interface DriverPerformance {
  id?: number;
  driverId?: number;
  year?: number;
  month?: number;
  period?: string;
  monthName?: string;

  totalDeliveries?: number;
  completedDeliveries?: number;
  onTimeDeliveries?: number;
  lateDeliveries?: number;
  cancelledDeliveries?: number;
  completionRate?: number;
  onTimeRate?: number;

  incidentsCount?: number;
  safetyViolations?: number;
  safetyScore?: string;

  performanceScore?: number;
  onTimePercent?: number;
  averageRating?: number;
  totalRatings?: number;

  leaderboardRank?: number;
  rankTier?: string;

  totalDistanceKm?: number;
  fuelEfficiency?: number;

  lastCalculatedAt?: string;
  isFinalized?: boolean;
}
