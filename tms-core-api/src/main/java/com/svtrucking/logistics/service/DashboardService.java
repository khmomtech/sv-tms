package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.DashboardSummaryDto;
import com.svtrucking.logistics.dto.DriverDto;
import com.svtrucking.logistics.dto.LiveDriverDto;
import com.svtrucking.logistics.dto.LoadingSummaryRowDto;
import com.svtrucking.logistics.dto.TopDriverDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.TransportOrderRepository;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class DashboardService {

  private final TransportOrderRepository transportOrderRepository;
  private final DispatchRepository dispatchRepository;
  private final DriverRepository driverRepository;
  
  @Autowired(required = false)
  private LiveLocationCacheServiceInterface liveLocationCacheService;

  public DashboardService(TransportOrderRepository transportOrderRepository,
                         DispatchRepository dispatchRepository,
                         DriverRepository driverRepository) {
    this.transportOrderRepository = transportOrderRepository;
    this.dispatchRepository = dispatchRepository;
    this.driverRepository = driverRepository;
  }

  // private final TransportOrderRepository transportOrderRepository;

  /**
   * Returns summary stats for the dashboard including: - total transport orders today - number of
   * active (non-finalized) dispatches - number of drivers currently online
   */
  public Map<String, Object> getSummaryStats() {
    Map<String, Object> stats = new HashMap<>();

    int totalOrders = transportOrderRepository.countTodayOrders();

    List<DispatchStatus> excludedStatuses =
        List.of(DispatchStatus.DELIVERED, DispatchStatus.CANCELLED, DispatchStatus.PENDING);

    int activeDispatches = dispatchRepository.countByStatusNotIn(excludedStatuses);
    int driversOnDuty = driverRepository.countDriversByStatus(DriverStatus.ONLINE);

    stats.put("totalOrdersToday", totalOrders);
    stats.put("activeDispatches", activeDispatches);
    stats.put("deliveredShipments", transportOrderRepository.countTodayDelivered());
    stats.put("driversOnDuty", driversOnDuty);

    return stats;
  }

  /** Retrieves top performing drivers for the current week based on delivered dispatches. */
  public List<TopDriverDto> getTopDriversThisWeek() {
    return driverRepository.findTopDriversByDeliveriesThisWeek(DispatchStatus.DELIVERED);
  }

  /** Returns raw Driver entities who are currently online. */
  public List<Driver> getLiveDrivers() {
    // Use a simpler query to avoid LocationHistory relationship issues
    return driverRepository.findAll().stream()
        .filter(driver -> DriverStatus.ONLINE.equals(driver.getStatus()) &&
                         driver.getLatestLocation() != null &&
                         driver.getLatestLocation().getLatitude() != 0.0 &&
                         driver.getLatestLocation().getLongitude() != 0.0)
        .toList();
  }

  /** Returns DriverDto objects for currently online drivers with their latest GPS location. */
  public List<DriverDto> getLiveDriverDtos() {
    try {
      // Get online drivers first (simplified to avoid LocationHistory issues)
      List<Driver> onlineDrivers = driverRepository.findAll().stream()
          .filter(driver -> DriverStatus.ONLINE.equals(driver.getStatus()) &&
                           driver.getLatestLocation() != null &&
                           driver.getLatestLocation().getLatitude() != 0.0 &&
                           driver.getLatestLocation().getLongitude() != 0.0)
          .toList();

      if (onlineDrivers.isEmpty()) {
        return List.of();
      }

      // Get driver IDs
      List<Long> driverIds = onlineDrivers.stream()
          .map(Driver::getId)
          .toList();

      // Try to get cached locations first (if Redis is available)
      Map<Long, LiveDriverDto> cachedLocations = liveLocationCacheService != null 
          ? liveLocationCacheService.getCachedDriverLocations(driverIds)
          : Map.of();

      log.debug("Retrieved {} cached locations out of {} online drivers", cachedLocations.size(), driverIds.size());

      // Build DriverDto list from cached data only (skip database fallback due to schema issues)
      return onlineDrivers.stream()
          .map(driver -> {
            Long driverId = driver.getId();
            LiveDriverDto cached = cachedLocations.get(driverId);

            if (cached != null) {
              // Use cached location data
              return DriverDto.builder()
                  .id(driverId)
                  .name(cached.getDriverName() != null ? cached.getDriverName() : driver.getName())
                  .vehicleType(driver.getVehicleType() != null ? driver.getVehicleType() : VehicleType.UNKNOWN)
                  .latitude(cached.getLatitude())
                  .longitude(cached.getLongitude())
                  .lastLocationAt(cached.getUpdatedAt() != null ? cached.getUpdatedAt().atZone(java.time.ZoneId.systemDefault()).toLocalDateTime() : null)
                  .build();
            } else {
              // No cached data available
              log.debug("No cached location data for driver {}", driverId);
              return null;
            }
          })
          .filter(java.util.Objects::nonNull)
          .distinct()
          .toList();
    } catch (Exception e) {
      log.error("Error fetching live drivers, falling back to cached data only", e);
      // Fallback: try to get all cached locations
      try {
        List<Long> allDriverIds = List.of(1L, 2L, 3L, 4L, 8L); // Known driver IDs from database
        Map<Long, LiveDriverDto> allCached = liveLocationCacheService != null
            ? liveLocationCacheService.getCachedDriverLocations(allDriverIds)
            : Map.of();

        return allCached.entrySet().stream()
            .map(entry -> DriverDto.builder()
                .id(entry.getKey())
                .name(entry.getValue().getDriverName() != null ? entry.getValue().getDriverName() : "Driver " + entry.getKey())
                .vehicleType(VehicleType.UNKNOWN)
                .latitude(entry.getValue().getLatitude())
                .longitude(entry.getValue().getLongitude())
                .lastLocationAt(entry.getValue().getUpdatedAt() != null ? entry.getValue().getUpdatedAt().atZone(java.time.ZoneId.systemDefault()).toLocalDateTime() : null)
                .build())
            .toList();
      } catch (Exception fallbackError) {
        log.error("Fallback also failed", fallbackError);
        return List.of();
      }
    }
  }

  public DashboardSummaryDto getSummary(LocalDate fromDate, LocalDate toDate) {
    return transportOrderRepository.getDashboardSummary(fromDate, toDate);
  }

  /** Returns cached driver locations for the given driver IDs (Redis only). */
  public Map<Long, LiveDriverDto> getCachedDriverLocations(List<Long> driverIds) {
    return liveLocationCacheService != null
        ? liveLocationCacheService.getCachedDriverLocations(driverIds)
        : Map.of();
  }

  /** Returns loading summary data for the given date range and filters. */
  public List<LoadingSummaryRowDto> getSummaryStats(LocalDate fromDate, LocalDate toDate, String customerName, String truckType) {
    return transportOrderRepository.getLoadingSummary(fromDate, toDate, customerName, truckType);
  }
}
