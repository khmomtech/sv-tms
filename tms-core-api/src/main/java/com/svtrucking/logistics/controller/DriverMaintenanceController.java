package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.MaintenanceRequestDto;
import com.svtrucking.logistics.model.MaintenanceTask;
import com.svtrucking.logistics.model.VehicleDriver;
import com.svtrucking.logistics.repository.MaintenanceTaskRepository;
import com.svtrucking.logistics.repository.VehicleDriverRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.MaintenanceRequestService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

/**
 * Driver-scoped maintenance endpoints.
 *
 * Drivers do not hold MAINTENANCE_READ permission so they cannot call
 * MaintenanceRequestController. This controller resolves the driver's
 * currently assigned vehicle server-side (never trusting client-supplied
 * vehicleId) and exposes exactly two operations:
 *
 * GET /api/driver/maintenance/my-vehicle/tasks — read tasks for their vehicle
 * POST /api/driver/maintenance/requests — submit a new maintenance request
 */
@RestController
@RequestMapping("/api/driver/maintenance")
@RequiredArgsConstructor
@Tag(name = "Driver Maintenance", description = "Driver-scoped: view vehicle maintenance tasks and submit requests")
public class DriverMaintenanceController {

    private final AuthenticatedUserUtil authUtil;
    private final VehicleDriverRepository vehicleDriverRepository;
    private final MaintenanceTaskRepository maintenanceTaskRepository;
    private final MaintenanceRequestService maintenanceRequestService;

    /**
     * Returns all maintenance tasks for the driver's currently assigned vehicle,
     * ordered by dueDate ascending so overdue items surface first.
     */
    @GetMapping("/my-vehicle/tasks")
    @Operation(summary = "Maintenance tasks for driver's current vehicle")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<ApiResponse<List<MaintenanceTask>>> getMyVehicleTasks() {
        Long driverId = resolveDriverId();
        if (driverId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new ApiResponse<>(false, "Authenticated user is not a driver", null, null, Instant.now()));
        }
        VehicleDriver vd = vehicleDriverRepository.findActiveByDriverId(driverId).orElse(null);
        if (vd == null) {
            return ResponseEntity.ok(
                    new ApiResponse<>(true, "No vehicle currently assigned", List.of(), null, Instant.now()));
        }
        List<MaintenanceTask> tasks = maintenanceTaskRepository
                .findByVehicleIdOrderByDueDateAsc(vd.getVehicle().getId());
        return ResponseEntity.ok(new ApiResponse<>(true, "Maintenance tasks", tasks, null, Instant.now()));
    }

    /**
     * Driver submits a maintenance request for their assigned vehicle.
     * vehicleId is always resolved server-side — any value in the request body is
     * ignored.
     */
    @PostMapping("/requests")
    @Operation(summary = "Submit maintenance request for driver's current vehicle")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<ApiResponse<MaintenanceRequestDto>> submitRequest(
            @RequestBody MaintenanceRequestDto dto) {
        Long driverId = resolveDriverId();
        if (driverId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new ApiResponse<>(false, "Authenticated user is not a driver", null, null, Instant.now()));
        }
        VehicleDriver vd = vehicleDriverRepository.findActiveByDriverId(driverId).orElse(null);
        if (vd == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "No vehicle assigned to driver", null, null, Instant.now()));
        }
        // Override with server-resolved vehicle — never trust client-supplied vehicleId
        dto.setVehicleId(vd.getVehicle().getId());
        Long userId = authUtil.getCurrentUserId();
        MaintenanceRequestDto created = maintenanceRequestService.create(dto, userId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, "Maintenance request submitted", created, null, Instant.now()));
    }

    /**
     * Resolves the driverId for the currently authenticated user, or null if not a
     * driver.
     */
    private Long resolveDriverId() {
        try {
            return authUtil.getCurrentDriverId();
        } catch (RuntimeException e) {
            return null;
        }
    }
}
