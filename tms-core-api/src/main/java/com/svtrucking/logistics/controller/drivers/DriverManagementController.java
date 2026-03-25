package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.dto.requests.*;
import com.svtrucking.logistics.service.DriverService;
import com.svtrucking.logistics.application.driver.DriverAppService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Controller for basic driver management operations (CRUD, search, profile).
 * Separated from DriverController to follow Single Responsibility Principle.
 */
@RestController
@RequestMapping("/api/admin/drivers")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class DriverManagementController {

  private final DriverAppService driverAppService;
  private final DriverService driverService;

  /**
   * Create a new driver with associated user account.
   */
  @PostMapping("/add")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<DriverDto>> createDriver(
      @Valid @RequestBody DriverCreateRequest request) {
    try {
      DriverDto saved = driverAppService.createDriver(request);
      return ResponseEntity.status(HttpStatus.CREATED)
          .body(ApiResponse.success("Driver created successfully", saved));
    } catch (Exception e) {
      log.error("Error creating driver: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail("Failed to create driver: " + e.getMessage()));
    }
  }

  /**
   * Get paginated list of all drivers.
   */
  @GetMapping("/list")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<PageResponse<DriverDto>>> getAllDrivers(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "5") int size) {
    try {
      Page<DriverDto> drivers = driverAppService.listDrivers(PageRequest.of(page, size));
      return ResponseEntity.ok(ApiResponse.success("Drivers fetched successfully", new PageResponse<>(drivers)));
    } catch (Exception e) {
      log.error("Error fetching drivers: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to fetch drivers: " + e.getMessage()));
    }
  }

  /**
   * Get all drivers without pagination (legacy endpoint).
   */
  @GetMapping("/alllists")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<PageResponse<DriverDto>>> getAllListDrivers(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "5") int size) {
    try {
      Page<DriverDto> drivers = driverAppService.listDrivers(PageRequest.of(page, size));
      return ResponseEntity.ok(ApiResponse.success("Fetched", new PageResponse<>(drivers)));
    } catch (Exception e) {
      log.error("Error fetching driver list: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to fetch driver list: " + e.getMessage()));
    }
  }

  /**
   * Get all drivers as list without pagination.
   */
  @GetMapping("/all")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<List<DriverDto>>> getAllDriversNoPag() {
    try {
      List<DriverDto> drivers = driverAppService.quickSearch("");
      return ResponseEntity.ok(ApiResponse.success("Drivers fetched successfully", drivers));
    } catch (Exception e) {
      log.error("Error fetching all drivers: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to fetch drivers: " + e.getMessage()));
    }
  }

  /**
   * Search drivers by query string.
   */
  @GetMapping("/search")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<List<DriverDto>>> searchDrivers(@RequestParam String query) {
    try {
      List<DriverDto> drivers = driverAppService.quickSearch(query);
      return ResponseEntity.ok(ApiResponse.success("Drivers found", drivers));
    } catch (Exception e) {
      log.error("Error searching drivers with query '{}': {}", query, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to search drivers: " + e.getMessage()));
    }
  }

  /**
   * Get driver by ID.
   */
  @GetMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<DriverDto>> getDriverById(@PathVariable Long id) {
    try {
      log.debug("Fetching driver with id: {}", id);
      DriverDto dto = driverAppService.getDriver(id);
      log.debug("Successfully retrieved driver: {} (name: {})", id, dto.getName());
      return ResponseEntity.ok(ApiResponse.success("Driver found", dto));
    } catch (RuntimeException e) {
      log.error("Error retrieving driver with id {}: {}", id, e.getMessage());
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(ApiResponse.fail("Driver not found"));
    }
  }

  /**
   * Update driver information.
   */
  @PutMapping(value = "/update/{id}", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<DriverDto>> updateDriver(
      @PathVariable Long id, @RequestBody DriverUpdateRequest request) {
    try {
      DriverDto updatedDriver = driverAppService.updateDriver(id, request);
      return ResponseEntity.ok(ApiResponse.success("Driver updated", updatedDriver));
    } catch (Exception e) {
      log.error("Error updating driver {}: {}", id, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail("Update failed: " + e.getMessage()));
    }
  }

  /**
   * Delete driver.
   */
  @DeleteMapping("/delete/{id}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> deleteDriver(@PathVariable Long id) {
    try {
      driverAppService.deleteDriver(id);
      return ResponseEntity.ok(ApiResponse.success("Driver deleted"));
    } catch (Exception e) {
      log.error("Error deleting driver {}: {}", id, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail(e.getMessage()));
    }
  }

  /**
   * Advanced search with filters.
   */
  @PostMapping("/advanced-search")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
          "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<PageResponse<DriverDto>>> advancedSearchDrivers(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "12") int size,
      @RequestBody(required = false) DriverFilterRequest filters) {
    try {
      DriverFilterRequest searchFilters = (filters == null) ? new DriverFilterRequest() : filters;
      Page<DriverDto> result = driverService.advancedSearchDrivers(
          page, size, searchFilters.getQuery(), searchFilters.getIsActive(),
          searchFilters.getMinRating(), searchFilters.getMaxRating(), searchFilters.getZone(),
          searchFilters.getVehicleType(), searchFilters.getStatus(), searchFilters.getIsPartner());
      return ResponseEntity.ok(ApiResponse.success("Advanced driver filter applied", new PageResponse<>(result)));
    } catch (Exception e) {
      log.error("Error performing advanced search: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to perform advanced search: " + e.getMessage()));
    }
  }

  /**
   * Upload driver profile picture.
   */
  @PostMapping(path = "/{driverId}/upload-profile", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> uploadProfilePictureAdmin(
      @PathVariable Long driverId, @RequestParam("profilePicture") MultipartFile file) {
    try {
      String fileUrl = driverService.saveProfilePicture(driverId, file);
      return ResponseEntity.ok(ApiResponse.success("Profile picture updated", fileUrl));
    } catch (Exception e) {
      log.error("Error uploading profile picture for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail("Upload failed: " + e.getMessage()));
    }
  }

  /**
   * Update driver device token.
   */
  @PostMapping("/update-device-token")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> updateDeviceToken(@RequestBody DeviceTokenRequest request) {
    try {
      driverService.updateDeviceToken(request.getDriverId(), request.getDeviceToken());
      return ResponseEntity.ok(ApiResponse.success("Token updated"));
    } catch (Exception e) {
      log.error("Error updating device token: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(ApiResponse.fail(e.getMessage()));
    }
  }

  /**
   * Get driver device token.
   */
  @GetMapping("/{id}/device-token")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) " +
                "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> getDeviceToken(@PathVariable Long id) {
    try {
      String token = driverService.getDeviceToken(id);
      return ResponseEntity.ok(ApiResponse.success("Token fetched", token));
    } catch (Exception e) {
      log.error("Error getting device token for driver {}: {}", id, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(ApiResponse.fail("Driver not found"));
    }
  }

  /**
   * Update driver heartbeat.
   */
  @PostMapping("/{driverId}/heartbeat")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<ApiResponse<String>> driverHeartbeat(
      @PathVariable Long driverId, @RequestBody HeartbeatDto dto) {
    try {
      driverService.updateHeartbeat(driverId, dto);
      return ResponseEntity.ok(ApiResponse.success("Heartbeat updated"));
    } catch (Exception e) {
      log.error("Error updating heartbeat for driver {}: {}", driverId, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to update heartbeat: " + e.getMessage()));
    }
  }
}
