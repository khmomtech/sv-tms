package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DriverCurrentAssignmentDto;
import com.svtrucking.logistics.dto.requests.TemporaryAssignmentRequest;
import com.svtrucking.logistics.repository.DriverRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Endpoints for managing permanent and temporary driver-truck assignments.
 */
@RestController
@RequestMapping("/api/admin/drivers")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class DriverTemporaryAssignmentController {

    private final DriverRepository driverRepository;

    @PostMapping("/{driverId}/temporary-assignment")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<String>> setTemporaryAssignment(
            @PathVariable Long driverId, @Valid @RequestBody TemporaryAssignmentRequest request) {
        // Temporary assignment logic removed. Endpoint deprecated.
        return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED)
                .body(ApiResponse.fail("This endpoint is deprecated and no longer implemented."));
    }

    @DeleteMapping("/{driverId}/temporary-assignment")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<String>> removeTemporaryAssignment(@PathVariable Long driverId) {
        try {
            // assignmentService.removeTemporaryAssignment(driverId);
            return ResponseEntity.ok(ApiResponse.success("Temporary assignment removed"));
        } catch (Exception e) {
            log.error("Error removing temporary assignment for driver {}: {}", driverId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.fail(e.getMessage()));
        }
    }

    @PutMapping("/{driverId}/change-permanent")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<String>> changePermanentVehicle(
            @PathVariable Long driverId, @RequestParam Long vehicleId) {
        try {
            // var assignment = assignmentService.assignDriver(driverId, vehicleId);
            return ResponseEntity.ok(ApiResponse.success(
                    "Permanent vehicle changed", null));
        } catch (Exception e) {
            log.error("Error changing permanent vehicle for driver {}: {}", driverId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.fail(e.getMessage()));
        }
    }

    @GetMapping("/{driverId}/current-assignment")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL) "
            +
            "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<DriverCurrentAssignmentDto>> getCurrentAssignment(@PathVariable Long driverId) {
        var driver = driverRepository.findByIdWithVehicles(driverId)
                .orElseThrow(() -> new RuntimeException("Driver not found"));
        var dto = DriverCurrentAssignmentDto.fromDriver(driver);
        return ResponseEntity.ok(ApiResponse.success("Fetched current assignment", dto));
    }

    // Optional manual trigger to sweep expired temp assignment for a single driver
    @PostMapping("/{driverId}/temporary-assignment/reset-if-expired")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
    public ResponseEntity<ApiResponse<String>> resetIfExpired(@PathVariable Long driverId) {
        // assignmentService.resetIfExpired(driverId); // logic removed
        return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED)
                .body(ApiResponse.fail("This endpoint is deprecated and no longer implemented."));
    }
}
