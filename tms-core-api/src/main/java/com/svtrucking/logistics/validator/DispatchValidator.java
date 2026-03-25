package com.svtrucking.logistics.validator;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.exception.InvalidDispatchDataException;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.workflow.DispatchStateMachine;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;

/**
 * Validator for Dispatch entity with comprehensive business rule validation.
 * Handles status transitions, driver/vehicle assignments, and conflict
 * detection.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DispatchValidator {

    private final DispatchRepository dispatchRepository;
    private final DriverRepository driverRepository;
    private final VehicleRepository vehicleRepository;
    private final DispatchStateMachine dispatchStateMachine;

    // Valid status transitions
    private static final EnumSet<DispatchStatus> ACTIVE_STATUSES = EnumSet.of(
            DispatchStatus.ASSIGNED,
            DispatchStatus.DRIVER_CONFIRMED,
            DispatchStatus.IN_QUEUE,
            DispatchStatus.ARRIVED_LOADING,
            DispatchStatus.SAFETY_PASSED,
            DispatchStatus.LOADING,
            DispatchStatus.LOADED,
            DispatchStatus.IN_TRANSIT,
            DispatchStatus.ARRIVED_UNLOADING,
            DispatchStatus.UNLOADING);

    private static final EnumSet<DispatchStatus> TERMINAL_STATUSES = EnumSet.of(
            DispatchStatus.DELIVERED,
            DispatchStatus.COMPLETED,
            DispatchStatus.CANCELLED);

    /**
     * Validates dispatch data before creation.
     */
    public void validateForCreate(Dispatch dispatch) {
        validateRequiredFields(dispatch);
        validateTransportOrder(dispatch);
        validateDriver(dispatch.getDriver());
        validateVehicle(dispatch.getVehicle());
        validateTimeConstraints(dispatch);
        validateInitialStatus(dispatch);
        validateDriverAvailability(dispatch.getDriver().getId(), dispatch.getStartTime(), null);
        validateVehicleAvailability(dispatch.getVehicle().getId(), dispatch.getStartTime(), null);
    }

    /**
     * Validates dispatch data before update.
     */
    public void validateForUpdate(Dispatch dispatch, Long dispatchId) {
        if (dispatchId == null) {
            throw new InvalidDispatchDataException("id", "Dispatch ID is required for update");
        }

        validateRequiredFields(dispatch);
        validateTransportOrder(dispatch);

        if (dispatch.getDriver() != null) {
            validateDriver(dispatch.getDriver());
            validateDriverAvailability(dispatch.getDriver().getId(), dispatch.getStartTime(), dispatchId);
        }

        if (dispatch.getVehicle() != null) {
            validateVehicle(dispatch.getVehicle());
            validateVehicleAvailability(dispatch.getVehicle().getId(), dispatch.getStartTime(), dispatchId);
        }

        validateTimeConstraints(dispatch);
    }

    /**
     * Validates status transition is allowed.
     */
    public void validateStatusTransition(DispatchStatus currentStatus, DispatchStatus newStatus) {
        if (currentStatus == null) {
            throw new InvalidDispatchDataException("status", "Current status cannot be null");
        }

        if (newStatus == null) {
            throw new InvalidDispatchDataException("status", "New status cannot be null");
        }

        if (currentStatus == newStatus) {
            return; // No change
        }

        // Cannot modify terminal statuses
        if (TERMINAL_STATUSES.contains(currentStatus)) {
            throw new InvalidDispatchDataException(
                    "status",
                    "Cannot change status from " + currentStatus + " (terminal state)");
        }

        // Validate specific transitions using injected state machine
        try {
            dispatchStateMachine.validateTransition(currentStatus, newStatus);
        } catch (IllegalArgumentException e) {
            throw new InvalidDispatchDataException(
                    "status",
                    "Invalid status transition from " + currentStatus + " to " + newStatus);
        }
    }

    /**
     * Validates driver assignment.
     */
    public void validateDriverAssignment(Long driverId, Long dispatchId) {
        if (driverId == null) {
            throw new InvalidDispatchDataException("driverId", "Driver ID is required");
        }

        Driver driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new InvalidDispatchDataException(
                        "driverId",
                        "Driver with ID " + driverId + " not found"));

        validateDriver(driver);

        // Check driver is not already assigned to active dispatch
        validateDriverAvailability(driverId, LocalDateTime.now(), dispatchId);
    }

    /**
     * Validates vehicle assignment.
     */
    public void validateVehicleAssignment(Long vehicleId, Long dispatchId) {
        if (vehicleId == null) {
            throw new InvalidDispatchDataException("vehicleId", "Vehicle ID is required");
        }

        Vehicle vehicle = vehicleRepository.findById(vehicleId)
                .orElseThrow(() -> new InvalidDispatchDataException(
                        "vehicleId",
                        "Vehicle with ID " + vehicleId + " not found"));

        validateVehicle(vehicle);

        // Check vehicle is not already assigned to active dispatch
        validateVehicleAvailability(vehicleId, LocalDateTime.now(), dispatchId);
    }

    /**
     * Validates dispatch cancellation is allowed.
     */
    public void validateForCancellation(Dispatch dispatch, String reason) {
        if (dispatch == null) {
            throw new InvalidDispatchDataException("dispatch", "Dispatch cannot be null");
        }

        if (TERMINAL_STATUSES.contains(dispatch.getStatus())) {
            throw new InvalidDispatchDataException(
                    "status",
                    "Cannot cancel dispatch with status " + dispatch.getStatus());
        }

        if (reason == null || reason.trim().isEmpty()) {
            throw new InvalidDispatchDataException("reason", "Cancellation reason is required");
        }

        if (reason.length() > 500) {
            throw new InvalidDispatchDataException(
                    "reason",
                    "Cancellation reason cannot exceed 500 characters");
        }
    }

    /**
     * Validates required fields are present.
     */
    private void validateRequiredFields(Dispatch dispatch) {
        if (dispatch == null) {
            throw new InvalidDispatchDataException("dispatch", "Dispatch object cannot be null");
        }

        if (dispatch.getTransportOrder() == null) {
            throw new InvalidDispatchDataException("transportOrder", "Transport order is required");
        }

        if (dispatch.getStatus() == null) {
            throw new InvalidDispatchDataException("status", "Dispatch status is required");
        }
    }

    /**
     * Validates transport order exists and is valid.
     */
    private void validateTransportOrder(Dispatch dispatch) {
        if (dispatch.getTransportOrder() == null) {
            throw new InvalidDispatchDataException("transportOrder", "Transport order is required");
        }

        if (dispatch.getTransportOrder().getId() == null) {
            throw new InvalidDispatchDataException(
                    "transportOrder",
                    "Transport order ID is required");
        }
    }

    /**
     * Validates driver is eligible for assignment.
     */
    private void validateDriver(Driver driver) {
        if (driver == null) {
            throw new InvalidDispatchDataException("driver", "Driver is required");
        }

        // If inactive, allow assignment but surface a warning-level message in logs.
        if (Boolean.FALSE.equals(driver.getIsActive())) {
            log.warn("Assigning inactive driver {} (id={})", driver.getName(), driver.getId());
        }

        // Add additional driver validation (license expiry, etc.)
        if (driver.getLicenseNumber() == null || driver.getLicenseNumber().trim().isEmpty()) {
            throw new InvalidDispatchDataException(
                    "driver",
                    "Driver must have a valid license number");
        }
    }

    /**
     * Validates vehicle is eligible for assignment.
     */
    private void validateVehicle(Vehicle vehicle) {
        if (vehicle == null) {
            throw new InvalidDispatchDataException("vehicle", "Vehicle is required");
        }

        if (vehicle.getStatus() == null) {
            throw new InvalidDispatchDataException("vehicle", "Vehicle status is required");
        }

        if (vehicle.getStatus() == VehicleStatus.OUT_OF_SERVICE
                || vehicle.getStatus() == VehicleStatus.MAINTENANCE) {
            throw new InvalidDispatchDataException(
                    "vehicle",
                    "Vehicle " + vehicle.getLicensePlate() + " is not available for dispatch");
        }

        // Add additional vehicle validation
        if (vehicle.getLicensePlate() == null || vehicle.getLicensePlate().trim().isEmpty()) {
            throw new InvalidDispatchDataException(
                    "vehicle",
                    "Vehicle must have a valid license plate");
        }
    }

    /**
     * Validates time constraints for dispatch.
     */
    private void validateTimeConstraints(Dispatch dispatch) {
        if (dispatch.getStartTime() == null) {
            dispatch.setStartTime(LocalDateTime.now());
        }

        // Start time cannot be too far in the past (more than 24 hours)
        if (dispatch.getStartTime().isBefore(LocalDateTime.now().minusHours(24))) {
            throw new InvalidDispatchDataException(
                    "startTime",
                    "Start time cannot be more than 24 hours in the past");
        }

        // Estimated arrival must be after start time
        if (dispatch.getEstimatedArrival() != null &&
                dispatch.getEstimatedArrival().isBefore(dispatch.getStartTime())) {
            throw new InvalidDispatchDataException(
                    "estimatedArrival",
                    "Estimated arrival must be after start time");
        }
    }

    /**
     * Validates initial status for new dispatch.
     */
    private void validateInitialStatus(Dispatch dispatch) {
        if (dispatch.getId() == null) {
            // For new dispatches, only PENDING or SCHEDULED are allowed
            if (dispatch.getStatus() != DispatchStatus.PENDING &&
                    dispatch.getStatus() != DispatchStatus.SCHEDULED) {
                throw new InvalidDispatchDataException(
                        "status",
                        "New dispatch must have status PENDING or SCHEDULED");
            }
        }
    }

    /**
     * Validates driver is available (not assigned to conflicting dispatch).
     */
    private void validateDriverAvailability(Long driverId, LocalDateTime startTime, Long excludeDispatchId) {
        LocalDateTime newStart = startTime != null ? startTime : LocalDateTime.now();
        List<Dispatch> activeDispatches = excludeDispatchId == null
                ? dispatchRepository.findByDriverIdAndStatusIn(driverId, ACTIVE_STATUSES)
                : dispatchRepository.findByDriverIdAndStatusInAndIdNot(driverId, ACTIVE_STATUSES, excludeDispatchId);

        // Allow scheduling if existing active dispatches have an estimatedArrival
        // before the new start
        List<String> blockingRoutes = activeDispatches.stream()
                .filter(d -> {
                    LocalDateTime eta = d.getEstimatedArrival();
                    if (eta != null && eta.isBefore(newStart)) {
                        return false; // non-overlapping
                    }
                    return true;
                })
                .map(d -> d.getRouteCode() + conflictWindowLabel(d))
                .toList();

        if (!blockingRoutes.isEmpty()) {
            throw new InvalidDispatchDataException(
                    "driver",
                    "Driver is already assigned to active dispatch(es): " + blockingRoutes);
        }
    }

    /**
     * Validates vehicle is available (not assigned to conflicting dispatch).
     */
    private void validateVehicleAvailability(Long vehicleId, LocalDateTime startTime, Long excludeDispatchId) {
        LocalDateTime newStart = startTime != null ? startTime : LocalDateTime.now();
        List<Dispatch> activeDispatches = excludeDispatchId == null
                ? dispatchRepository.findByVehicleIdAndStatusIn(vehicleId, ACTIVE_STATUSES)
                : dispatchRepository.findByVehicleIdAndStatusInAndIdNot(vehicleId, ACTIVE_STATUSES, excludeDispatchId);

        // Allow scheduling if active dispatches finish before the new start time
        List<String> blockingRoutes = activeDispatches.stream()
                .filter(d -> {
                    LocalDateTime eta = d.getEstimatedArrival();
                    if (eta != null && eta.isBefore(newStart)) {
                        return false; // no overlap
                    }
                    return true;
                })
                .map(d -> d.getRouteCode() + conflictWindowLabel(d))
                .toList();

        if (!blockingRoutes.isEmpty()) {
            throw new InvalidDispatchDataException(
                    "vehicle",
                    "Vehicle is already assigned to active dispatch(es): " + blockingRoutes);
        }
    }

    /** Builds a short time window label for conflict messages. */
    private String conflictWindowLabel(Dispatch d) {
        StringBuilder sb = new StringBuilder(" [");
        if (d.getStartTime() != null) {
            sb.append("start=").append(d.getStartTime());
        }
        if (d.getEstimatedArrival() != null) {
            if (d.getStartTime() != null)
                sb.append(", ");
            sb.append("eta=").append(d.getEstimatedArrival());
        }
        sb.append("]");
        return sb.toString();
    }

}
