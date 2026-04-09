
package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.assignment.*;
import com.svtrucking.logistics.dto.assignment.DriverWithAssignmentResponse;
import com.svtrucking.logistics.exception.BusinessException;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.service.VehicleDriverService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/assignments/permanent")
@RequiredArgsConstructor
@Tag(name = "Permanent Assignments", description = "Manage permanent truck-to-driver assignments (1:1 model)")
@Slf4j
public class VehicleDriverController {

    private static final String REQUEST_ID_HEADER = "X-Request-ID";
    private final VehicleDriverService assignmentService;

    @PostMapping
    @Operation(summary = "Assign truck to driver", description = "Creates or updates permanent assignment. Automatically revokes previous assignments for both driver and truck. Idempotent operation.")
    public ResponseEntity<ApiResponse<AssignmentResponse>> assignTruckToDriver(
            @Valid @RequestBody AssignmentRequest request,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestHeader(value = REQUEST_ID_HEADER, required = false) String requestId) {

        String adminUser = userDetails != null ? userDetails.getUsername() : "system";
        String trackingId = requestId != null ? requestId : UUID.randomUUID().toString();

        try {
            log.info("[{}] Assignment request received from user: {}", trackingId, adminUser);
            AssignmentResponse response = assignmentService.assignTruckToDriver(request, adminUser);
            log.info("[{}] Assignment completed successfully: assignmentId={}", trackingId, response.getId());
            return ResponseEntity.ok(ApiResponse.success("Truck assigned successfully", response));
        } catch (ResourceNotFoundException e) {
            log.error("[{}] Resource not found: {}", trackingId, e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.fail(e.getMessage()));
        } catch (BusinessException e) {
            log.error("[{}] Business rule violation: {}", trackingId, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.fail(e.getMessage()));
        } catch (Exception e) {
            log.error("[{}] Unexpected error during assignment", trackingId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.fail(
                            "An unexpected error occurred. Please contact support with request ID: " + trackingId));
        }
    }

    @GetMapping("/{driverId}")
    @Operation(summary = "Get driver's assigned truck")
    public ResponseEntity<ApiResponse<AssignmentResponse>> getDriverAssignment(
            @PathVariable Long driverId) {
        AssignmentResponse response = assignmentService.getDriverAssignment(driverId);
        if (response == null) {
            return ResponseEntity.ok(ApiResponse.success("No active assignment found for driver"));
        }
        return ResponseEntity.ok(ApiResponse.success("Assignment retrieved", response));
    }

    @GetMapping("/truck/{vehicleId}")
    @Operation(summary = "Get truck's assigned driver")
    public ResponseEntity<ApiResponse<AssignmentResponse>> getTruckAssignment(
            @PathVariable Long vehicleId) {
        AssignmentResponse response = assignmentService.getTruckAssignment(vehicleId);
        if (response == null) {
            return ResponseEntity.ok(ApiResponse.success("No active assignment found for truck"));
        }
        return ResponseEntity.ok(ApiResponse.success("Assignment retrieved", response));
    }

    @DeleteMapping("/{driverId}")
    @Operation(summary = "Revoke driver's truck assignment")
    public ResponseEntity<ApiResponse<Void>> revokeDriverAssignment(
            @PathVariable Long driverId,
            @RequestParam(required = false) String reason,
            @AuthenticationPrincipal UserDetails userDetails) {
        String adminUser = userDetails != null ? userDetails.getUsername() : "system";
        assignmentService.revokeDriverAssignment(driverId, adminUser, reason);
        return ResponseEntity.ok(ApiResponse.success("Assignment revoked"));
    }

    @GetMapping("/stats")
    @Operation(summary = "Get assignment statistics")
    public ResponseEntity<ApiResponse<java.util.Map<String, Object>>> getStats() {
        return ResponseEntity.ok(ApiResponse.success("Statistics retrieved", assignmentService.getAssignmentStats()));
    }

    @GetMapping("/list")
    @Operation(summary = "List assignments with optional filters")
    public ResponseEntity<ApiResponse<java.util.List<AssignmentResponse>>> listAssignments(
            @RequestParam(required = false) Long driverId,
            @RequestParam(required = false) Long vehicleId,
            @RequestParam(required = false) Boolean active) {
        java.util.List<AssignmentResponse> assignments = assignmentService.getAssignments(driverId, vehicleId, active);
        return ResponseEntity.ok(ApiResponse.success("Assignments retrieved", assignments));
    }

    @GetMapping("/drivers/with-assignments")
    @Operation(summary = "List all drivers with assignment status")
    public ResponseEntity<ApiResponse<java.util.List<DriverWithAssignmentResponse>>> listDriversWithAssignments() {
        java.util.List<DriverWithAssignmentResponse> drivers = assignmentService.getAllDriversWithAssignments();
        return ResponseEntity.ok(ApiResponse.success("Drivers with assignments", drivers));
    }
}
