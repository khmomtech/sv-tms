package com.svtrucking.logistics.validator;

import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.exception.AssignmentValidationException;
import com.svtrucking.logistics.model.VehicleDriver;
import com.svtrucking.logistics.repository.VehicleDriverRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import lombok.RequiredArgsConstructor;

import java.time.LocalDateTime;

/**
 * Validator for driver assignment business rules.
 * Ensures assignments follow business logic and constraints.
 * Supports multiple vehicle assignments per driver (only one active at a time).
 */
@Component
@RequiredArgsConstructor
public class AssignmentValidator {

    private final VehicleDriverRepository assignmentRepository;

    @Value("${app.assignment.enforce-license-class:true}")
    private boolean enforceLicenseClass;

    /**
     * Validates that a driver can be assigned to a vehicle.
     * Supports multiple vehicle assignments per driver (only one active at a time).
     *
     * @param driver Driver to assign
     * @param vehicle Vehicle to assign
     * @throws AssignmentValidationException if assignment is not valid
     */
    public void validateAssignment(Driver driver, Vehicle vehicle) {
        validateDriverEligibility(driver);
        validateVehicleAvailability(vehicle);
        validateLicenseRequirements(driver, vehicle);
        validateNoDuplicateAssignment(driver, vehicle);
    }

    /**
     * Validates driver eligibility for assignment.
     * Checks driver status (allows multiple active assignments through VehicleDriver table).
     * 
     * @param driver Driver to validate
     * @param allowVehicleDriver if true, allows assignment even if driver has permanent assignments
     * @throws AssignmentValidationException if driver is not eligible
     */
    public void validateDriverEligibility(Driver driver, boolean allowVehicleDriver) {
        if (driver == null) {
            throw new AssignmentValidationException("Driver cannot be null");
        }

        // Check driver status - must be IDLE or ONLINE
        if (driver.getStatus() != DriverStatus.IDLE && driver.getStatus() != DriverStatus.ONLINE) {
            throw new AssignmentValidationException(
                "Driver status is " + driver.getStatus() + ". Must be IDLE or ONLINE to be assigned."
            );
        }
        // Note: Multiple vehicle assignments are now supported through VehicleDriver table
        // The service will unassign previous active assignments and mark new one as active
    }

    /**
     * Validates driver eligibility for permanent assignment.
     *
     * @param driver Driver to validate
     * @throws AssignmentValidationException if driver is not eligible
     */
    public void validateDriverEligibility(Driver driver) {
        validateDriverEligibility(driver, false);
    }

    /**
     * Validates vehicle availability for assignment.
     *
     * @param vehicle Vehicle to validate
     * @throws AssignmentValidationException if vehicle is not available
     */
    public void validateVehicleAvailability(Vehicle vehicle) {
        if (vehicle == null) {
            throw new AssignmentValidationException("Vehicle cannot be null");
        }

        // Check vehicle status
        if (vehicle.getStatus() == VehicleStatus.OUT_OF_SERVICE) {
            throw AssignmentValidationException.vehicleNotAvailable(
                vehicle.getId(),
                "Vehicle is out of service"
            );
        }

        if (vehicle.getStatus() == VehicleStatus.MAINTENANCE) {
            throw AssignmentValidationException.vehicleNotAvailable(
                vehicle.getId(),
                "Vehicle is under maintenance"
            );
        }

        if (vehicle.getStatus() == VehicleStatus.IN_USE) {
            throw new AssignmentValidationException(
                "Vehicle " + vehicle.getId() + " is currently in use and cannot be assigned"
            );
        }
    }

    /**
     * Validates driver license requirements match vehicle requirements.
     *
     * @param driver Driver to validate
     * @param vehicle Vehicle to validate
     * @throws AssignmentValidationException if license requirements don't match
     */
    public void validateLicenseRequirements(Driver driver, Vehicle vehicle) {
        // Truck vehicles require commercial license, unless disabled by config
        if (vehicle.getType() == VehicleType.TRUCK && enforceLicenseClass) {
            String licenseClass = driver.getLicenseClass();
            if (licenseClass == null || licenseClass.trim().isEmpty()) {
                throw new AssignmentValidationException(
                    "Driver " + driver.getId() + " does not have a license class specified"
                );
            }
            if (!isCommercialLicense(licenseClass)) {
                throw new AssignmentValidationException(
                    "Driver " + driver.getId() + " does not have required commercial license for truck vehicles (has: " + licenseClass + ")"
                );
            }
        }
    }

    /**
     * Validates temporary assignment parameters.
     * Temporary assignments are allowed even if driver has a permanent assignment.
     *
     * @param driver Driver to assign temporarily
     * @param vehicle Vehicle to assign
     * @param expiryDate Temporary assignment expiry
     * @throws AssignmentValidationException if temporary assignment is not valid
     */
    public void validateTemporaryAssignment(Driver driver, Vehicle vehicle, LocalDateTime expiryDate) {
        // For temporary assignments, allow even if driver has permanent assignment
        validateDriverEligibility(driver, true);
        validateVehicleAvailability(vehicle);
        validateLicenseRequirements(driver, vehicle);

        if (expiryDate == null) {
            throw new AssignmentValidationException("Expiry date is required for temporary assignments");
        }

        if (expiryDate.isBefore(LocalDateTime.now())) {
            throw new AssignmentValidationException("Expiry date must be in the future");
        }

        // Check if driver already has a temporary assignment
        if (driver.getTempAssignedVehicle() != null) {
            throw new AssignmentValidationException(
                "Driver already has a temporary assignment. Please remove it first."
            );
        }
    }

    /**
     * Validates assignment unassignment operation.
     *
     * @param assignment Assignment to unassign
     * @throws AssignmentValidationException if unassignment is not valid
     */
    public void validateUnassignment(VehicleDriver assignment) {
        if (assignment == null) {
            throw new AssignmentValidationException("Assignment cannot be null");
        }

        if (assignment.getRevokedAt() != null) {
            throw new AssignmentValidationException("Assignment has already been unassigned");
        }
    }

    /**
     * Checks if license class is commercial grade.
     * Supports both Cambodia and international license classes.
     *
     * @param licenseClass License class to check
     * @return true if commercial license
     */
    private boolean isCommercialLicense(String licenseClass) {
        if (licenseClass == null) {
            return false;
        }
        
        String upperClass = licenseClass.toUpperCase().trim();
        
        // Cambodia commercial license classes
        // C: Truck (3,500-16,000 kg)
        // C1: Medium truck (≤7,500 kg)
        // D: Passenger bus
        // E: Tractor/Trailer
        if (upperClass.equals("C") || upperClass.equals("C1") || 
            upperClass.equals("D") || upperClass.equals("E")) {
            return true;
        }
        
        // International commercial license classes
        // CDL: Commercial Driver's License
        // Class 1, 2, 3: Australian/NZ system
        if (upperClass.startsWith("CDL") || 
            upperClass.matches("CLASS\\s*[123]")) {
            return true;
        }
        
        return false;
    }

    /**
     * Validates that driver and vehicle are not already assigned together.
     * Prevents assigning the same driver-vehicle pair twice.
     * Note: Previous active assignments to other vehicles are automatically unassigned by service.
     *
     * @param driver Driver to validate
     * @param vehicle Vehicle to validate
     * @throws AssignmentValidationException if driver-vehicle pair already has active assignment
     */
    private void validateNoDuplicateAssignment(Driver driver, Vehicle vehicle) {
        // Check if there's already an ASSIGNED assignment for this driver-vehicle pair
        if (assignmentRepository.findActiveByDriverIdAndVehicleId(driver.getId(), vehicle.getId()).isPresent()) {
            throw new AssignmentValidationException(
                String.format(
                    "Driver %d is already assigned to vehicle %d. Cannot create duplicate assignment.",
                    driver.getId(),
                    vehicle.getId()
                )
            );
        }
    }
}
