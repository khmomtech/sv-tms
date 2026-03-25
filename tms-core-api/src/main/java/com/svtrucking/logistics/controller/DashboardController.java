package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DashboardSummaryResponse;
import com.svtrucking.logistics.dto.DriverDto;
import com.svtrucking.logistics.dto.LiveDriverDto;
import com.svtrucking.logistics.dto.LoadingSummaryRowDto;
import com.svtrucking.logistics.dto.TopDriverDto;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.service.CacheStats;
import com.svtrucking.logistics.service.DashboardService;
import com.svtrucking.logistics.service.LiveLocationCacheServiceInterface;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/dashboard")
@CrossOrigin(origins = "${app.cors.allowed-origins:*}")
@Slf4j
public class DashboardController {

  private final DashboardService dashboardService;
  
  @Autowired(required = false)
  private LiveLocationCacheServiceInterface cacheService;
  
  public DashboardController(DashboardService dashboardService) {
    this.dashboardService = dashboardService;
  }

  /**
   * Get comprehensive dashboard summary including summary stats, top drivers, and live drivers.
   *
   * @param fromDate Optional start date for filtering data
   * @param toDate Optional end date for filtering data
   * @return ResponseEntity with ApiResponse containing dashboard summary data
   */
  @GetMapping("/summary")
  public ResponseEntity<ApiResponse<DashboardSummaryResponse>> getDashboardSummary(
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate fromDate,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate toDate) {

    // Validate date range if both dates are provided
    validateDateRange(fromDate, toDate);
    // Normalize missing dates (if only one provided, make it a single-day range; if none, default
    // to today)
    LocalDate[] normalized = normalizeDateRange(fromDate, toDate);
    fromDate = normalized[0];
    toDate = normalized[1];

    try {
      DashboardSummaryResponse response =
          DashboardSummaryResponse.builder()
              .summary(dashboardService.getSummary(fromDate, toDate))
              .topDrivers(dashboardService.getTopDriversThisWeek())
              .liveDrivers(dashboardService.getLiveDriverDtos())
              .build();

      return ResponseEntity.ok(ApiResponse.ok("Dashboard summary fetched", response));
    } catch (Exception e) {
      return ResponseEntity.internalServerError()
          .body(ApiResponse.fail("Failed to fetch dashboard summary", e.getMessage()));
    }
  }

  /**
   * Get summary statistics only.
   *
   * @param fromDate Optional start date for filtering data
   * @param toDate Optional end date for filtering data
   * @return ResponseEntity with ApiResponse containing loading summary data
   */
  @GetMapping("/summary-stats")
  public ResponseEntity<ApiResponse<List<LoadingSummaryRowDto>>> getSummaryStatsOnly(
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate fromDate,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate toDate,
      @RequestParam(required = false) String customerName,
      @RequestParam(required = false) String truckType) {

    validateDateRange(fromDate, toDate);
    // Normalize missing dates (if only one provided, make it a single-day range; if none, default
    // to today)
    LocalDate[] normalized = normalizeDateRange(fromDate, toDate);
    fromDate = normalized[0];
    toDate = normalized[1];

    try {
      List<LoadingSummaryRowDto> data =
          dashboardService.getSummaryStats(fromDate, toDate, customerName, truckType);
      return ResponseEntity.ok(ApiResponse.ok("Summary loaded", data));
    } catch (Exception e) {
      return ResponseEntity.internalServerError()
          .body(ApiResponse.fail("Failed to fetch summary stats", e.getMessage()));
    }
  }

  /**
   * Get top performing drivers.
   *
   * @return ResponseEntity with ApiResponse containing top drivers data
   */
  @GetMapping("/top-drivers")
  public ResponseEntity<ApiResponse<List<TopDriverDto>>> getTopDrivers() {
    try {
      List<TopDriverDto> topDrivers = dashboardService.getTopDriversThisWeek();
      return ResponseEntity.ok(ApiResponse.ok("Top drivers this week", topDrivers));
    } catch (Exception e) {
      return ResponseEntity.internalServerError()
          .body(ApiResponse.fail("Failed to fetch top drivers", e.getMessage()));
    }
  }

  /**
   * Get currently live drivers with their locations from Redis cache only.
   * This endpoint demonstrates Redis caching functionality.
   *
   * @return ResponseEntity with ApiResponse containing cached live drivers data
   */
  @GetMapping("/live-drivers-cached")
  public ResponseEntity<ApiResponse<List<DriverDto>>> getLiveDriversCachedOnly() {
    try {
      // For demonstration, get cached data for known driver IDs
      List<Long> driverIds = List.of(1L, 2L, 3L, 4L, 8L);
      Map<Long, LiveDriverDto> cachedLocations = dashboardService.getCachedDriverLocations(driverIds);

      List<DriverDto> result = cachedLocations.entrySet().stream()
          .map(entry -> DriverDto.builder()
              .id(entry.getKey())
              .name(entry.getValue().getDriverName() != null ? entry.getValue().getDriverName() : "Driver " + entry.getKey())
              .vehicleType(VehicleType.UNKNOWN)
              .latitude(entry.getValue().getLatitude())
              .longitude(entry.getValue().getLongitude())
              .lastLocationAt(entry.getValue().getUpdatedAt() != null ?
                  entry.getValue().getUpdatedAt().atZone(java.time.ZoneId.systemDefault()).toLocalDateTime() : null)
              .build())
          .toList();

      return ResponseEntity.ok(ApiResponse.ok("Cached live driver locations (Redis only)", result));
    } catch (Exception e) {
      return ResponseEntity.internalServerError()
          .body(ApiResponse.fail("Failed to fetch cached drivers", e.getMessage()));
    }
  }

  /**
   * Validate that fromDate is not after toDate.
   *
   * @param fromDate Start date
   * @param toDate End date
   * @throws IllegalArgumentException if fromDate is after toDate
   */
  private void validateDateRange(LocalDate fromDate, LocalDate toDate) {
    if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
      throw new IllegalArgumentException("From date cannot be after to date");
    }
  }

  /**
   * Normalize the provided date range: - If both dates are null: use today as both from/to. - If
   * only one is provided: use that same date for both (single-day range). - If both provided and
   * valid: keep as is.
   */
  private LocalDate[] normalizeDateRange(LocalDate fromDate, LocalDate toDate) {
    LocalDate today = LocalDate.now();
    if (fromDate == null && toDate == null) {
      return new LocalDate[] {today, today};
    }
    if (fromDate == null) {
      return new LocalDate[] {toDate, toDate};
    }
    if (toDate == null) {
      return new LocalDate[] {fromDate, fromDate};
    }
    return new LocalDate[] {fromDate, toDate};
  }

  /**
   * Get Redis cache statistics and performance metrics.
   * Useful for monitoring cache effectiveness and Redis health.
   *
   * @return ResponseEntity with ApiResponse containing cache statistics
   */
  @GetMapping("/cache-stats")
  public ResponseEntity<ApiResponse<Map<String, Object>>> getCacheStats() {
    try {
      if (cacheService == null) {
        return ResponseEntity.ok(ApiResponse.ok("Cache not available (Redis disabled in test mode)", Map.of(
            "entryCount", 0,
            "memoryUsageMB", "0.00",
            "cachePrefix", "live:location:",
            "ttlSeconds", 300,
            "description", "Redis cache disabled"
        )));
      }
      
      CacheStats stats = cacheService.getCacheStats();

      Map<String, Object> cacheInfo = Map.of(
          "entryCount", stats.entryCount,
          "memoryUsageMB", String.format("%.2f", stats.getMemoryUsageMB()),
          "cachePrefix", "live:location:",
          "ttlSeconds", 300,
          "description", "Redis cache for live driver locations"
      );

      return ResponseEntity.ok(ApiResponse.ok("Cache statistics retrieved", cacheInfo));
    } catch (Exception e) {
      return ResponseEntity.internalServerError()
          .body(ApiResponse.fail("Failed to fetch cache stats", e.getMessage()));
    }
  }

  /** Handle bad request scenarios (e.g., invalid date ranges). */
  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ApiResponse<Object>> handleIllegalArgument(IllegalArgumentException ex) {
    return ResponseEntity.badRequest().body(ApiResponse.fail(ex.getMessage(), null));
  }
}
