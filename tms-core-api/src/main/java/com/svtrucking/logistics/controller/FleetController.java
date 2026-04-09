package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.VehicleDto;
import com.svtrucking.logistics.dto.VehicleStatisticsDto;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.VehicleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/fleet")
@RequiredArgsConstructor
@Tag(name = "Fleet", description = "Fleet management — vehicle list, overview stats, service schedule")
public class FleetController {

    private final VehicleService vehicleService;

    /**
     * GET /api/fleet/overview
     * Fleet overview statistics: totals, by-status counts, by-type counts,
     * assignment rate.
     */
    @GetMapping("/overview")
    @Operation(summary = "Fleet overview statistics")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_READ + "')")
    public ResponseEntity<ApiResponse<VehicleStatisticsDto>> overview() {
        VehicleStatisticsDto stats = vehicleService.getFleetStatistics();
        return ResponseEntity.ok(new ApiResponse<>(true, "Fleet overview", stats, null, Instant.now()));
    }

    /**
     * GET /api/fleet/vehicles?search=&status=&type=&assigned=&page=0&size=20
     * Paginated, filterable vehicle list.
     */
    @GetMapping("/vehicles")
    @Operation(summary = "List vehicles with optional filters")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_READ + "')")
    public ResponseEntity<ApiResponse<Page<VehicleDto>>> listVehicles(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) VehicleStatus status,
            @RequestParam(required = false) VehicleType type,
            @RequestParam(required = false) Boolean assigned,
            Pageable pageable) {
        Page<VehicleDto> page = vehicleService.advancedSearch(search, status, type, null, null, assigned, pageable);
        return ResponseEntity.ok(new ApiResponse<>(true, "Vehicles", page, null, Instant.now()));
    }

    /**
     * GET /api/fleet/vehicles/requiring-service
     * Vehicles whose scheduled service is overdue or due within the configured
     * warning window.
     */
    @GetMapping("/vehicles/requiring-service")
    @Operation(summary = "Vehicles requiring service")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_READ + "')")
    public ResponseEntity<ApiResponse<List<VehicleDto>>> vehiclesRequiringService() {
        List<VehicleDto> vehicles = vehicleService.getVehiclesRequiringService();
        return ResponseEntity.ok(new ApiResponse<>(true, "Vehicles requiring service", vehicles, null, Instant.now()));
    }

    /**
     * GET /api/fleet/vehicles/{id}
     * Single vehicle detail.
     */
    @GetMapping("/vehicles/{id}")
    @Operation(summary = "Get single vehicle")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_READ + "')")
    public ResponseEntity<ApiResponse<VehicleDto>> getVehicle(@PathVariable Long id) {
        return vehicleService.getVehicleDtoById(id)
                .map(v -> ResponseEntity.ok(new ApiResponse<>(true, "Vehicle", v, null, Instant.now())))
                .orElse(ResponseEntity.status(404)
                        .body(new ApiResponse<>(false, "Vehicle not found", null, null, Instant.now())));
    }

    /**
     * PUT /api/fleet/vehicles/{id}
     * Update a vehicle (status, type, assignment target, service dates, etc.).
     */
    @PutMapping("/vehicles/{id}")
    @Operation(summary = "Update vehicle")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_UPDATE + "')")
    public ResponseEntity<ApiResponse<VehicleDto>> updateVehicle(
            @PathVariable Long id,
            @RequestBody VehicleDto dto) {
        VehicleDto updated = vehicleService.updateVehicle(id, dto);
        return ResponseEntity.ok(new ApiResponse<>(true, "Vehicle updated", updated, null, Instant.now()));
    }
}
