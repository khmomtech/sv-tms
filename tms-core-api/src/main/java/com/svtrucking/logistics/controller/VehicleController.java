package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.VehicleDto;
import com.svtrucking.logistics.dto.VehicleFuelLogDto;
import com.svtrucking.logistics.dto.VehicleStatisticsDto;
import com.svtrucking.logistics.dto.assignment.AssignmentResponse;
import com.svtrucking.logistics.enums.TruckSize;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.security.AuthorizationService;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.VehicleService;
import com.svtrucking.logistics.service.VehicleFuelLogService;
import com.svtrucking.logistics.service.VehicleDriverService;
import com.svtrucking.logistics.dto.VehicleSetupRequest;
import com.svtrucking.logistics.service.VehicleSetupService;
import com.svtrucking.logistics.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import com.svtrucking.logistics.exception.VehicleNotFoundException;
import com.svtrucking.logistics.exception.DuplicateLicensePlateException;
import com.svtrucking.logistics.exception.InvalidVehicleDataException;
import org.hibernate.LazyInitializationException;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.data.domain.Page;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/vehicles")
@CrossOrigin(origins = "*")
@Tag(name = "Fleet Management - Vehicles", description = "Vehicle fleet management operations")
@Slf4j
public class VehicleController {

    private final VehicleService vehicleService;
    private final VehicleDriverService vehicleDriverService;
    private final VehicleSetupService vehicleSetupService;
    private final VehicleFuelLogService vehicleFuelLogService;
    private final UserRepository userRepository;

    public VehicleController(
            VehicleService vehicleService,
            AuthorizationService authorizationService,
            VehicleDriverService vehicleDriverService,
            VehicleSetupService vehicleSetupService,
            VehicleFuelLogService vehicleFuelLogService,
            UserRepository userRepository) {
        this.vehicleService = vehicleService;
        this.vehicleDriverService = vehicleDriverService;
        this.vehicleSetupService = vehicleSetupService;
        this.vehicleFuelLogService = vehicleFuelLogService;
        this.userRepository = userRepository;
    }

    @GetMapping("/list")
    @Operation(summary = "Get all vehicles with pagination")
    public ResponseEntity<ApiResponse<Page<VehicleDto>>> getAllVehicles(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
        Page<VehicleDto> vehicles = vehicleService.getAllVehicles(pageable);
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Vehicles fetched successfully", vehicles, null, Instant.now()));
    }

    @GetMapping("/all")
    @Operation(summary = "Get all vehicles without pagination")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<VehicleDto>>> getAllVehiclesNoPage() {
        try {
            log.debug("Fetching all vehicles without pagination");
            List<VehicleDto> vehicles = vehicleService.getAllVehicles();
            log.debug("Retrieved {} vehicles", vehicles.size());
            return ResponseEntity.ok(
                    new ApiResponse<>(true, "All vehicles fetched", vehicles, null, Instant.now()));
        } catch (Exception e) {
            log.error("Error fetching all vehicles: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(false, "❌ Failed to fetch vehicles", null, e.getMessage(),
                                    Instant.now()));
        }
    }

    @GetMapping("/filter")
    @Operation(summary = "Filter vehicles (legacy endpoint - use /search instead)", deprecated = true)
    @Deprecated
    public ResponseEntity<ApiResponse<Page<VehicleDto>>> filterVehicles(
            @RequestParam Optional<String> search,
            @RequestParam Optional<String> truckSize,
            @RequestParam Optional<String> status,
            @RequestParam Optional<String> zone,
            @RequestParam Optional<String> driverAssignment,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());

        // Convert parameters to enums for advanced search
        VehicleStatus statusEnum = status.map(s -> VehicleStatus.valueOf(s.toUpperCase())).orElse(null);
        VehicleType typeEnum = null; // driver assignment filter handled below
        TruckSize sizeEnum = truckSize.map(s -> TruckSize.valueOf(s.toUpperCase())).orElse(null);
        Boolean assignmentFilter = null;
        if (driverAssignment.isPresent()) {
          String value = driverAssignment.get().toLowerCase();
          if ("assigned".equals(value)) {
            assignmentFilter = true;
          } else if ("unassigned".equals(value)) {
            assignmentFilter = false;
          }
        }

        Page<VehicleDto> filtered = vehicleService.advancedSearch(
                search.orElse(null),
                statusEnum,
                typeEnum,
                sizeEnum,
                zone.orElse(null),
                assignmentFilter,
                pageable);

        return ResponseEntity.ok(
                new ApiResponse<>(true, "Filtered vehicles returned (use /search endpoint instead)", filtered, null,
                        Instant.now()));
    }

    @GetMapping("/search")
    @Operation(summary = "Advanced vehicle search with multiple criteria")
    public ResponseEntity<ApiResponse<Page<VehicleDto>>> searchVehicles(
            @Parameter(description = "Search term for license plate, model, or manufacturer") @RequestParam(required = false) String search,
            @Parameter(description = "Filter by vehicle status") @RequestParam(required = false) VehicleStatus status,
            @Parameter(description = "Filter by vehicle type") @RequestParam(required = false) VehicleType type,
            @Parameter(description = "Filter by truck size") @RequestParam(required = false) TruckSize truckSize,
            @Parameter(description = "Filter by assigned zone") @RequestParam(required = false) String zone,
            @Parameter(description = "Filter by assignment") @RequestParam(required = false) Boolean assigned,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size) {

        log.info("Searching vehicles with filters - search: {}, status: {}, type: {}", search, status, type);
        Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
        Page<VehicleDto> results = vehicleService.advancedSearch(search, status, type, truckSize, zone, assigned, pageable);

        return ResponseEntity.ok(
                new ApiResponse<>(true, "Search results retrieved", results, null, Instant.now()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get vehicle by ID")
    public ResponseEntity<ApiResponse<VehicleDto>> getVehicleById(@PathVariable Long id) {
        log.info("Fetching vehicle by ID: {}", id);
        return vehicleService
                .getVehicleDtoById(id)
                .map(dto -> ResponseEntity.ok(new ApiResponse<>(true, "Vehicle found", dto, null, Instant.now())))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>(false, "❌ Vehicle not found", null, null, Instant.now())));
    }

    @GetMapping("/license/{licensePlate}")
    @Operation(summary = "Get vehicle by license plate")
    public ResponseEntity<ApiResponse<VehicleDto>> getByLicensePlate(@PathVariable String licensePlate) {
        log.info("Fetching vehicle by license plate: {}", licensePlate);
        return vehicleService
                .getVehicleDtoByLicensePlate(licensePlate)
                .map(dto -> ResponseEntity.ok(new ApiResponse<>(true, "Vehicle found", dto, null, Instant.now())))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>(false, "❌ Vehicle not found", null, null, Instant.now())));
    }

    @GetMapping("/{vehicleId}/driver-history")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_READ + "')")
    @Operation(summary = "Get driver history for the vehicle")
    public ResponseEntity<ApiResponse<Page<AssignmentResponse>>> getDriverHistory(
            @PathVariable Long vehicleId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean active) {
        Page<AssignmentResponse> history =
                vehicleDriverService.getVehicleDriverHistory(vehicleId, page, size, search, active);
        ApiResponse<Page<AssignmentResponse>> response =
                new ApiResponse<>(true, "Driver history retrieved", history, null, Instant.now());
        response.setTotalPages(history.getTotalPages());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{vehicleId}/fuel-logs")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_READ + "')")
    @Operation(summary = "Get fuel logs for a vehicle")
    public ResponseEntity<ApiResponse<Page<VehicleFuelLogDto>>> getFuelLogs(
            @PathVariable Long vehicleId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
        Page<VehicleFuelLogDto> logs = vehicleFuelLogService.list(vehicleId, search, pageable);
        ApiResponse<Page<VehicleFuelLogDto>> response =
                new ApiResponse<>(true, "Fuel logs retrieved", logs, null, Instant.now());
        response.setTotalPages(logs.getTotalPages());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{vehicleId}/fuel-logs")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_UPDATE + "')")
    @Operation(summary = "Create a fuel log for a vehicle")
    public ResponseEntity<ApiResponse<VehicleFuelLogDto>> createFuelLog(
            @PathVariable Long vehicleId,
            @Valid @RequestBody VehicleFuelLogDto dto,
            Authentication authentication) {
        dto.setVehicleId(vehicleId);
        Long userId = getUserIdFromAuth(authentication);
        VehicleFuelLogDto created = vehicleFuelLogService.create(dto, userId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, "Fuel log created", created, null, Instant.now()));
    }

    @PutMapping("/{vehicleId}/fuel-logs/{logId}")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_UPDATE + "')")
    @Operation(summary = "Update a fuel log for a vehicle")
    public ResponseEntity<ApiResponse<VehicleFuelLogDto>> updateFuelLog(
            @PathVariable Long vehicleId,
            @PathVariable Long logId,
            @Valid @RequestBody VehicleFuelLogDto dto) {
        dto.setVehicleId(vehicleId);
        VehicleFuelLogDto updated = vehicleFuelLogService.update(logId, dto);
        return ResponseEntity.ok(new ApiResponse<>(true, "Fuel log updated", updated, null, Instant.now()));
    }

    @DeleteMapping("/{vehicleId}/fuel-logs/{logId}")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_UPDATE + "')")
    @Operation(summary = "Delete a fuel log for a vehicle")
    public ResponseEntity<ApiResponse<Void>> deleteFuelLog(
            @PathVariable Long vehicleId, @PathVariable Long logId) {
        vehicleFuelLogService.delete(logId);
        return ResponseEntity.ok(new ApiResponse<>(true, "Fuel log deleted", null, null, Instant.now()));
    }

    @PostMapping
    @Operation(summary = "Create a new vehicle")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_CREATE + "')")
    public ResponseEntity<ApiResponse<VehicleDto>> addVehicle(@Valid @RequestBody VehicleDto dto) {
        try {
            log.info("Creating new vehicle: {}", dto.getLicensePlate());
            com.svtrucking.logistics.dto.VehicleDto created = vehicleService.addVehicle(VehicleDto.toEntity(dto));
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ApiResponse<>(true, "Vehicle created successfully", null, created, null, Instant.now()));
        } catch (DuplicateLicensePlateException e) {
            log.warn("Duplicate license plate: {}", dto.getLicensePlate());
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(new ApiResponse<>(false, "Vehicle with license plate '" + dto.getLicensePlate() + "' already exists!", "DUPLICATE_LICENSE_PLATE", null, null, Instant.now()));
        } catch (InvalidVehicleDataException e) {
            log.warn("Invalid vehicle data: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "Invalid vehicle data", "INVALID_VEHICLE_DATA", null, e.getMessage(), Instant.now()));
        } catch (Exception e) {
            log.error("Error creating vehicle: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "❌ Failed to create vehicle", "UNKNOWN_ERROR", null, e.getMessage(), Instant.now()));
        }
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing vehicle")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_UPDATE + "')")
    public ResponseEntity<ApiResponse<VehicleDto>> updateVehicle(
            @PathVariable Long id, @Valid @RequestBody VehicleDto dto) {
        try {
            log.info("Updating vehicle ID: {}", id);
            com.svtrucking.logistics.dto.VehicleDto updated = vehicleService.updateVehicle(id, dto);
            return ResponseEntity
                    .ok(new ApiResponse<>(true, "Vehicle updated successfully", updated, null, Instant.now()));
        } catch (VehicleNotFoundException e) {
            log.error("Vehicle not found for update: {}", id);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiResponse<>(false, "❌ Vehicle not found", null, e.getMessage(), Instant.now()));
        } catch (DuplicateLicensePlateException e) {
            log.warn("Duplicate license plate when updating vehicle {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(new ApiResponse<>(false, "❌ Duplicate license plate", null, e.getMessage(), Instant.now()));
        } catch (InvalidVehicleDataException e) {
            log.warn("Invalid vehicle data for update {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "❌ Invalid vehicle data", null, e.getMessage(), Instant.now()));
        } catch (LazyInitializationException e) {
            log.error("LazyInitializationException while updating vehicle {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "❌ Failed to update vehicle (lazy init)", null, e.getMessage(),
                            Instant.now()));
        } catch (Exception e) {
            log.error("Error updating vehicle: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(
                            new ApiResponse<>(
                                    false, "❌ Failed to update vehicle", null, e.getMessage(), Instant.now()));
        }
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a vehicle")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteVehicle(@PathVariable Long id) {
        try {
            log.info("Deleting vehicle ID: {}", id);
            vehicleService.deleteVehicle(id);
            return ResponseEntity.ok(
                    new ApiResponse<>(true, "Vehicle deleted", null, null, Instant.now()));
        } catch (EntityNotFoundException e) {
            log.error("Vehicle not found for deletion: {}", id);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(
                            new ApiResponse<>(false, "❌ Vehicle not found", null, e.getMessage(), Instant.now()));
        }
    }

    @GetMapping("/statistics")
    @Operation(summary = "Get comprehensive fleet statistics")
    public ResponseEntity<ApiResponse<VehicleStatisticsDto>> getFleetStatistics() {
        log.info("Fetching fleet statistics");
        VehicleStatisticsDto stats = vehicleService.getFleetStatistics();
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Fleet statistics retrieved", stats, null, Instant.now()));
    }

    @GetMapping("/status/{status}")
    @Operation(summary = "Get vehicles by status")
    public ResponseEntity<ApiResponse<List<VehicleDto>>> getVehiclesByStatus(@PathVariable VehicleStatus status) {
        log.info("Fetching vehicles with status: {}", status);
        List<VehicleDto> vehicles = vehicleService.getVehiclesByStatus(status);
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Vehicles retrieved", vehicles, null, Instant.now()));
    }

    @GetMapping("/unassigned")
    @Operation(summary = "Get all unassigned vehicles")
    public ResponseEntity<ApiResponse<List<VehicleDto>>> getUnassignedVehicles() {
        log.info("Fetching unassigned vehicles");
        List<VehicleDto> vehicles = vehicleService.getUnassignedVehicles();
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Unassigned vehicles retrieved", vehicles, null, Instant.now()));
    }

    @GetMapping("/service-due")
    @Operation(summary = "Get vehicles requiring service")
    public ResponseEntity<ApiResponse<List<VehicleDto>>> getVehiclesRequiringService() {
        log.info("Fetching vehicles requiring service");
        List<VehicleDto> vehicles = vehicleService.getVehiclesRequiringService();
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Vehicles requiring service retrieved", vehicles, null, Instant.now()));
    }

    @GetMapping("/trailers")
    @Operation(summary = "Get all trailers")
    public ResponseEntity<ApiResponse<List<VehicleDto>>> getTrailers() {
        log.info("Fetching all trailers");
        List<VehicleDto> trailers = vehicleService.getTrailers();
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Trailers retrieved", trailers, null, Instant.now()));
    }

    @PostMapping("/setup")
    @Operation(summary = "Complete vehicle master setup workflow")
    @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_CREATE + "')")
    public ResponseEntity<ApiResponse<VehicleDto>> setupVehicle(@Valid @RequestBody VehicleSetupRequest request) {
        try {
            log.info("Starting vehicle master setup for license plate: {}", request.getLicensePlate());
            VehicleDto result = vehicleSetupService.setupVehicle(request);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ApiResponse<>(true, "Vehicle setup completed successfully", result, null, Instant.now()));
        } catch (Exception e) {
            log.error("Error during vehicle setup: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "❌ Vehicle setup failed", null, e.getMessage(), Instant.now()));
        }
    }

    @GetMapping("/{vehicleId}/ready-status")
    @Operation(summary = "Check if vehicle is ready for operation")
    public ResponseEntity<ApiResponse<Boolean>> checkVehicleReadyStatus(@PathVariable Long vehicleId) {
        try {
            boolean isReady = vehicleSetupService.isVehicleReadyForOperation(vehicleId);
            return ResponseEntity.ok(
                    new ApiResponse<>(true, "Vehicle ready status checked", isReady, null, Instant.now()));
        } catch (Exception e) {
            log.error("Error checking vehicle ready status: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "❌ Failed to check vehicle status", false, e.getMessage(), Instant.now()));
        }
    }

    private Long getUserIdFromAuth(Authentication authentication) {
        if (authentication == null) return null;
        Object principal = authentication.getPrincipal();
        if (principal instanceof org.springframework.security.core.userdetails.UserDetails ud) {
            return userRepository.findByUsername(ud.getUsername()).map(u -> u.getId()).orElse(null);
        }
        if (principal instanceof String s) {
            return userRepository.findByUsername(s).map(u -> u.getId()).orElse(null);
        }
        return null;
    }
}
