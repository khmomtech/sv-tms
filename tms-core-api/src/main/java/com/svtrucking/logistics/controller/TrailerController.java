package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.VehicleDto;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.service.TrailerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/trailers")
@CrossOrigin(origins = "*")
@Tag(name = "Fleet Management - Trailers", description = "Trailer fleet management operations")
@RequiredArgsConstructor
@Slf4j
public class TrailerController {

  private final TrailerService trailerService;

  @GetMapping("/list")
  @Operation(summary = "Get all trailers with pagination")
  public ResponseEntity<ApiResponse<Page<VehicleDto>>> getAllTrailers(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "15") int size) {

    log.info("Fetching trailers - page: {}, size: {}", page, size);
    Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
    Page<VehicleDto> trailers = trailerService.getAllTrailers(pageable);

    return ResponseEntity.ok(
        new ApiResponse<>(true, "Trailers fetched successfully", trailers, null, Instant.now()));
  }

  @GetMapping("/all")
  @Operation(summary = "Get all trailers without pagination")
  public ResponseEntity<ApiResponse<List<VehicleDto>>> getAllTrailersNoPage() {
    log.info("Fetching all trailers");
    List<VehicleDto> trailers = trailerService.getAllTrailers();

    return ResponseEntity.ok(
        new ApiResponse<>(true, "All trailers fetched", trailers, null, Instant.now()));
  }

  @GetMapping("/available")
  @Operation(summary = "Get all available trailers (not assigned to any truck)")
  public ResponseEntity<ApiResponse<List<VehicleDto>>> getAvailableTrailers() {
    log.info("Fetching available trailers");
    List<VehicleDto> trailers = trailerService.getAvailableTrailers();

    return ResponseEntity.ok(
        new ApiResponse<>(true, "Available trailers fetched", trailers, null, Instant.now()));
  }

  @GetMapping("/search")
  @Operation(summary = "Search trailers with filters")
  public ResponseEntity<ApiResponse<Page<VehicleDto>>> searchTrailers(
      @Parameter(description = "Search term for license plate, model, or manufacturer") @RequestParam(required = false) String search,
      @Parameter(description = "Filter by trailer status") @RequestParam(required = false) VehicleStatus status,
      @Parameter(description = "Filter by assigned zone") @RequestParam(required = false) String zone,
      @Parameter(description = "Filter by assignment status (true=assigned to truck, false=unassigned)") @RequestParam(required = false) Boolean assigned,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "15") int size) {

    log.info("Searching trailers - search: {}, status: {}, zone: {}, assigned: {}",
        search, status, zone, assigned);

    Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
    Page<VehicleDto> results = trailerService.searchTrailers(search, status, zone, assigned, pageable);

    return ResponseEntity.ok(
        new ApiResponse<>(true, "Trailer search results", results, null, Instant.now()));
  }

  @GetMapping("/by-truck/{vehicleId}")
  @Operation(summary = "Get trailers assigned to a specific truck")
  public ResponseEntity<ApiResponse<List<VehicleDto>>> getTrailersByTruck(@PathVariable Long vehicleId) {
    log.info("Fetching trailers for truck ID: {}", vehicleId);

    try {
      List<VehicleDto> trailers = trailerService.getTrailersByTruck(vehicleId);
      return ResponseEntity.ok(
          new ApiResponse<>(true, "Trailers retrieved", trailers, null, Instant.now()));
    } catch (Exception e) {
      log.error("Error fetching trailers for truck {}: {}", vehicleId, e.getMessage());
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(new ApiResponse<>(false, "❌ " + e.getMessage(), null, null, Instant.now()));
    }
  }

  @PostMapping("/{trailerId}/assign/{vehicleId}")
  @Operation(summary = "Assign trailer to a truck")
  @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'FLEET_MANAGER')")
  public ResponseEntity<ApiResponse<VehicleDto>> assignTrailerToTruck(
      @PathVariable Long trailerId,
      @PathVariable Long vehicleId) {

    log.info("Assigning trailer {} to truck {}", trailerId, vehicleId);

    try {
      VehicleDto result = trailerService.assignTrailerToTruck(trailerId, vehicleId);
      return ResponseEntity.ok(
          new ApiResponse<>(true, "Trailer assigned successfully", result, null, Instant.now()));
    } catch (Exception e) {
      log.error("Error assigning trailer {} to truck {}: {}", trailerId, vehicleId, e.getMessage());
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(new ApiResponse<>(false, "❌ " + e.getMessage(), null, null, Instant.now()));
    }
  }

  @PostMapping("/{trailerId}/unassign")
  @Operation(summary = "Unassign trailer from its current truck")
  @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'FLEET_MANAGER')")
  public ResponseEntity<ApiResponse<VehicleDto>> unassignTrailer(@PathVariable Long trailerId) {
    log.info("Unassigning trailer {}", trailerId);

    try {
      VehicleDto result = trailerService.unassignTrailer(trailerId);
      return ResponseEntity.ok(
          new ApiResponse<>(true, "Trailer unassigned successfully", result, null, Instant.now()));
    } catch (Exception e) {
      log.error("Error unassigning trailer {}: {}", trailerId, e.getMessage());
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(new ApiResponse<>(false, "❌ " + e.getMessage(), null, null, Instant.now()));
    }
  }
}
