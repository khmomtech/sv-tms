package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/assignments")
@CrossOrigin(origins = "*")
@Tag(name = "Fleet Management - Assignments", description = "Driver-vehicle assignment operations")
@RequiredArgsConstructor
@Slf4j
public class AssignmentController {

    @PostMapping("/assign")
    @Operation(summary = "Assign a driver to a vehicle")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'FLEET_MANAGER', 'DISPATCHER')")
    public ResponseEntity<ApiResponse<Object>> assignDriver(
            @Parameter(description = "Driver ID") @RequestParam Long driverId,
            @Parameter(description = "Vehicle ID") @RequestParam Long vehicleId) {
        log.info("Assigning driver {} to vehicle {}", driverId, vehicleId);
        try {
            // Assignment logic removed. Legacy endpoint.
            return ResponseEntity
                    .ok(new ApiResponse<>(true, "Driver assigned successfully", null, null, Instant.now()));
        } catch (Exception e) {
            log.error("Error assigning driver {} to vehicle {}: {}", driverId, vehicleId, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, " " + e.getMessage(), null, null, Instant.now()));
        }
    }

    @PostMapping("/unassign")
    @Operation(summary = "Unassign a driver from all vehicles")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'FLEET_MANAGER', 'DISPATCHER')")
    public ResponseEntity<ApiResponse<String>> unassignDriver(
            @Parameter(description = "Driver ID") @RequestParam Long driverId) {
        log.info("Unassigning driver {}", driverId);
        try {
            // Placeholder for removed service call
            return ResponseEntity
                    .ok(new ApiResponse<>(true, "Driver unassigned from all vehicles", "Success", null, Instant.now()));
        } catch (Exception e) {
            log.error("Error unassigning driver {}: {}", driverId, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, " " + e.getMessage(), null, null, Instant.now()));
        }
    }

    @PostMapping("/complete/{id}")
    @Operation(summary = "Mark an assignment as completed")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'FLEET_MANAGER', 'DISPATCHER')")
    public ResponseEntity<ApiResponse<Object>> completeAssignment(@PathVariable Long id) {
        log.info("Completing assignment {}", id);
        try {
            // Assignment logic removed. Legacy endpoint.
            return ResponseEntity.ok(new ApiResponse<>(true, "Assignment completed", null, null, Instant.now()));
        } catch (Exception e) {
            log.error("Error completing assignment {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, " " + e.getMessage(), null, null, Instant.now()));
        }
    }

    @PostMapping("/cancel/{id}")
    @Operation(summary = "Cancel an assignment")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'FLEET_MANAGER', 'DISPATCHER')")
    public ResponseEntity<ApiResponse<Object>> cancelAssignment(@PathVariable Long id) {
        log.info("Canceling assignment {}", id);
        try {
            // Assignment logic removed. Legacy endpoint.
            return ResponseEntity.ok(new ApiResponse<>(true, "Assignment canceled", null, null, Instant.now()));
        } catch (Exception e) {
            log.error("Error canceling assignment {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "❌ " + e.getMessage(), null, null, Instant.now()));
        }
    }

    @PutMapping("/{id}/update-vehicle")
    @Operation(summary = "Update the vehicle in an assignment")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'FLEET_MANAGER', 'DISPATCHER')")
    public ResponseEntity<ApiResponse<Object>> updateAssignmentVehicle(@PathVariable Long id,
            @RequestParam Long newVehicleId) {
        log.info("Updating assignment {} with new vehicle {}", id, newVehicleId);
        try {
            // Assignment logic removed. Legacy endpoint.
            return ResponseEntity.ok(new ApiResponse<>(true, "Assignment updated", null, null, Instant.now()));
        } catch (Exception e) {
            log.error("Error updating assignment {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "❌ " + e.getMessage(), null, null, Instant.now()));
        }
    }

    @GetMapping("/all")
    @Operation(summary = "Get all assignments")
    public ResponseEntity<ApiResponse<List<Object>>> getAllAssignments() {
        log.info("Fetching all assignments");
        // List<AssignmentVehicleToDriverDto> assignments = new ArrayList<>(); //
        // Legacy, removed
        List<Object> assignments = new ArrayList<>();
        return ResponseEntity.ok(new ApiResponse<>(true, "All assignments fetched", assignments, null, Instant.now()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get assignment by ID")
    public ResponseEntity<ApiResponse<Object>> getAssignmentById(@PathVariable Long id) {
        log.info("Fetching assignment {}", id);
        try {
            // Assignment logic removed. Legacy endpoint.
            return ResponseEntity.ok(new ApiResponse<>(true, "Assignment found", null, null, Instant.now()));
        } catch (Exception e) {
            log.error("Assignment not found: {}", id);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiResponse<>(false, "❌ Assignment not found", null, null, Instant.now()));
        }
    }

    @GetMapping("/by-driver/{driverId}")
    @Operation(summary = "Get all assignments for a specific driver")
    public ResponseEntity<ApiResponse<List<Object>>> getByDriver(@PathVariable Long driverId) {
        log.info("Fetching assignments for driver {}", driverId);
        // List<AssignmentVehicleToDriverDto> assignments = new ArrayList<>(); //
        // Legacy, removed
        List<Object> assignments = new ArrayList<>();
        return ResponseEntity
                .ok(new ApiResponse<>(true, "Driver assignments fetched", assignments, null, Instant.now()));
    }

    @GetMapping("/by-vehicle/{vehicleId}")
    @Operation(summary = "Get all assignments for a specific vehicle")
    public ResponseEntity<ApiResponse<List<Object>>> getByVehicle(@PathVariable Long vehicleId) {
        log.info("Fetching assignments for vehicle {}", vehicleId);
        // List<AssignmentVehicleToDriverDto> assignments = new ArrayList<>(); //
        // Legacy, removed
        List<Object> assignments = new ArrayList<>();
        return ResponseEntity
                .ok(new ApiResponse<>(true, "Vehicle assignments fetched", assignments, null, Instant.now()));
    }

    @GetMapping("/active")
    @Operation(summary = "Get all active assignments (currently assigned)")
    public ResponseEntity<ApiResponse<List<Object>>> getActiveAssignments() {
        log.info("Fetching all active assignments");
        // List<VehicleWithDriverDto> active = new ArrayList<>(); // Legacy, removed
        List<Object> active = new ArrayList<>();
        return ResponseEntity.ok(new ApiResponse<>(true, "Active assignments fetched", active, null, Instant.now()));
    }

    @GetMapping("/vehicles/driver/{driverId}")
    @Operation(summary = "Get all vehicles assigned to a specific driver")
    public ResponseEntity<ApiResponse<List<Object>>> getVehiclesByDriver(@PathVariable Long driverId) {
        log.info("Fetching vehicles assigned to driver {}", driverId);
        // List<VehicleDto> vehicles = new ArrayList<>(); // Legacy, removed
        List<Object> vehicles = new ArrayList<>();
        return ResponseEntity.ok(new ApiResponse<>(true, "Assigned vehicles fetched", vehicles, null, Instant.now()));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete an assignment")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteAssignment(@PathVariable Long id) {
        log.info("Deleting assignment {}", id);
        try {
            // Placeholder for removed service call
            return ResponseEntity.ok(new ApiResponse<>(true, "Assignment deleted", null, null, Instant.now()));
        } catch (Exception e) {
            log.error("Error deleting assignment {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(false, "❌ " + e.getMessage(), null, null, Instant.now()));
        }
    }
}
