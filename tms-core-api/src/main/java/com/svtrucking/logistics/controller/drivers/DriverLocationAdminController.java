package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.service.DriverLocationService;
import com.svtrucking.logistics.service.LiveDriverQueryService;
import com.svtrucking.logistics.service.LocationIngestService;
import com.svtrucking.logistics.service.TelematicsProxyService;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * Controller for admin driver location operations (history, live queries).
 * Separated from DriverController to follow Single Responsibility Principle.
 * Note: Real-time location updates are handled by DriverLocationController.
 */
@RestController
@RequestMapping("/api/admin/drivers")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class DriverLocationAdminController {

  private final DriverLocationService driverLocationService;
  private final LiveDriverQueryService liveDriverQueryService;
  private final LocationIngestService locationIngestService;
  private final TelematicsProxyService telematicsProxyService;

  /**
   * Get driver location history.
   */
  @GetMapping("/{id}/location-history")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<?>> getDriverLocationHistory(
      @RequestHeader(value = "Authorization", required = false) String authorization,
      @PathVariable Long id) {
    try {
      if (telematicsProxyService.isForwardingEnabled()) {
        ResponseEntity<Object> proxied = telematicsProxyService.forwardGetObject(
            "/api/admin/telematics/driver/" + id + "/history",
            authorization);
        if (proxied.getStatusCode().is5xxServerError() || proxied.getStatusCode().value() == 504) {
          List<LocationHistoryDto> historyFallback = driverLocationService.getDriverLocationHistory(id);
          return ResponseEntity.ok()
              .header("X-History-Store", driverLocationService.historyStoreName())
              .header("X-History-Replay-Lag-Seconds", String.valueOf(driverLocationService.historyReplayLagSeconds()))
              .body(ApiResponse.success("Location history retrieved (fallback)", historyFallback));
        }
        return ResponseEntity.status(proxied.getStatusCode())
            .body(ApiResponse.success("Location history retrieved", proxied.getBody()));
      }
      List<LocationHistoryDto> history = driverLocationService.getDriverLocationHistory(id);
      return ResponseEntity.ok()
          .header("X-History-Store", driverLocationService.historyStoreName())
          .header("X-History-Replay-Lag-Seconds", String.valueOf(driverLocationService.historyReplayLagSeconds()))
          .body(ApiResponse.success("Location history retrieved", history));
    } catch (IllegalStateException e) {
      log.warn("History store unavailable for driver {}: {}", id, e.getMessage());
      return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
          .header("X-History-Store", "UNAVAILABLE")
          .body(ApiResponse.fail("History store unavailable"));
    } catch (Exception e) {
      log.error("Error retrieving location history for driver {}: {}", id, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to retrieve location history: " + e.getMessage()));
    }
  }

  /**
   * Get paginated driver location history.
   */
  @GetMapping("/{driverId}/location-history/paginated")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<Page<LocationHistoryDto>>> getDriverLocationHistoryPaginated(
      @PathVariable Long driverId,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    try {
      Page<LocationHistoryDto> historyPage = driverLocationService.getDriverLocationHistoryPaginated(driverId, page, size);
      return ResponseEntity.ok()
          .header("X-History-Store", driverLocationService.historyStoreName())
          .header("X-History-Replay-Lag-Seconds", String.valueOf(driverLocationService.historyReplayLagSeconds()))
          .body(ApiResponse.success("Paginated location history fetched", historyPage));
    } catch (IllegalStateException e) {
      log.warn("Paginated history store unavailable for driver {}: {}", driverId, e.getMessage());
      return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
          .header("X-History-Store", "UNAVAILABLE")
          .body(ApiResponse.fail("History store unavailable"));
    } catch (Exception e) {
      log.error("Error fetching paginated location history for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to fetch paginated location history: " + e.getMessage()));
    }
  }

  /**
   * Get live drivers for map display.
   */
  @GetMapping("/live-drivers")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<?>> liveDrivers(
      @RequestHeader(value = "Authorization", required = false) String authorization,
      @RequestParam(required = false, defaultValue = "true") Boolean onlyOnline,
      @RequestParam(required = false, defaultValue = "120") Integer onlineSeconds,
      @RequestParam(required = false) Double south,
      @RequestParam(required = false) Double west,
      @RequestParam(required = false) Double north,
      @RequestParam(required = false) Double east) {
    try {
      if (telematicsProxyService.isForwardingEnabled()) {
        String path = UriComponentsBuilder.fromPath("/api/admin/telematics/live-drivers")
            .queryParamIfPresent("online", Optional.ofNullable(onlyOnline))
            .queryParamIfPresent("onlineSeconds", Optional.ofNullable(onlineSeconds))
            .queryParamIfPresent("south", Optional.ofNullable(south))
            .queryParamIfPresent("west", Optional.ofNullable(west))
            .queryParamIfPresent("north", Optional.ofNullable(north))
            .queryParamIfPresent("east", Optional.ofNullable(east))
            .build()
            .toUriString();
        ResponseEntity<Object> proxied = telematicsProxyService.forwardGetObject(path, authorization);
        return ResponseEntity.status(proxied.getStatusCode())
            .body(ApiResponse.success("Fetched live drivers", proxied.getBody()));
      }
      List<LiveDriverDto> data = liveDriverQueryService.getLiveDrivers(onlyOnline, onlineSeconds, south, west, north, east);
      return ResponseEntity.ok(ApiResponse.success("Fetched live drivers", data));
    } catch (Exception e) {
      log.error("Error fetching live drivers: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to fetch live drivers: " + e.getMessage()));
    }
  }

  /**
   * Get latest location for single driver.
   */
  @GetMapping("/{driverId}/latest-location")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<?>> latestForDriver(
      @RequestHeader(value = "Authorization", required = false) String authorization,
      @PathVariable Long driverId) {
    try {
      if (telematicsProxyService.isForwardingEnabled()) {
        ResponseEntity<Object> proxied = telematicsProxyService.forwardGetObject(
            "/api/admin/telematics/driver/" + driverId + "/location",
            authorization);
        if (proxied.getStatusCode().is2xxSuccessful()) {
          return ResponseEntity.status(proxied.getStatusCode())
              .body(ApiResponse.success("Latest location retrieved", proxied.getBody()));
        }
        if (proxied.getStatusCode() == HttpStatus.NOT_FOUND) {
          return ResponseEntity.ok(ApiResponse.success("No location data available", null));
        }
      }
      Optional<LiveDriverDto> dto = liveDriverQueryService.getLatestForDriver(driverId);
      if (dto.isPresent()) {
        return ResponseEntity.ok(ApiResponse.success("Latest location retrieved", dto.get()));
      } else {
        return ResponseEntity.ok(ApiResponse.success("No location data available", null));
      }
    } catch (Exception e) {
      log.error("Error fetching latest location for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to fetch latest location: " + e.getMessage()));
    }
  }

  /**
   * Location history pipeline health for operations monitoring.
   */
  @GetMapping("/location-history/health")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
      "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<Map<String, Object>>> locationHistoryHealth() {
    try {
      Map<String, Object> health = locationIngestService.getHistoryPipelineHealth();
      return ResponseEntity.ok(ApiResponse.success("Location history pipeline health", health));
    } catch (Exception e) {
      log.error("Failed to fetch location history pipeline health: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to fetch location pipeline health: " + e.getMessage()));
    }
  }
}
