package com.svtrucking.logistics.validator;

import com.svtrucking.logistics.dto.VehicleDto;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.exception.InvalidVehicleDataException;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Validator for vehicle business rules and data integrity.
 * Extracted from VehicleService to follow Single Responsibility Principle.
 */
@Component
public class VehicleValidator {

    private static final int MIN_VEHICLE_YEAR = 1900;
    private static final int MAX_FUTURE_YEARS = 2;

    /**
     * Validates vehicle entity before save/update operations.
     *
     * @param vehicle Vehicle entity to validate
     * @throws InvalidVehicleDataException if validation fails
     */
    public void validateVehicle(Vehicle vehicle) {
        List<String> errors = new ArrayList<>();

        // Required fields
        if (vehicle.getLicensePlate() == null || vehicle.getLicensePlate().trim().isEmpty()) {
            errors.add("License plate is required");
        }

        if (vehicle.getStatus() == null) {
            errors.add("Status is required");
        }

        if (vehicle.getType() == null) {
            errors.add("Vehicle type is required");
        }

        // Business rules
        if (vehicle.getMileage() != null && vehicle.getMileage().compareTo(BigDecimal.ZERO) < 0) {
            errors.add("Mileage cannot be negative");
        }

        if (vehicle.getYearMade() != null) {
            int currentYear = LocalDate.now().getYear();
            if (vehicle.getYearMade() < MIN_VEHICLE_YEAR) {
                errors.add("Vehicle year must be " + MIN_VEHICLE_YEAR + " or later");
            }
            if (vehicle.getYearMade() > currentYear + MAX_FUTURE_YEARS) {
                errors.add("Vehicle year cannot be more than " + MAX_FUTURE_YEARS + " years in the future");
            }
        }

        // License plate format validation (basic)
        if (vehicle.getLicensePlate() != null && vehicle.getLicensePlate().length() > 20) {
            errors.add("License plate must not exceed 20 characters");
        }

        if (!errors.isEmpty()) {
            throw new InvalidVehicleDataException(String.join(", ", errors));
        }
    }

    /**
     * Validates vehicle DTO before creating/updating entity.
     *
     * @param dto VehicleDto to validate
     * @throws InvalidVehicleDataException if validation fails
     */
    public void validateVehicleDto(VehicleDto dto) {
        List<String> errors = new ArrayList<>();

        if (dto.getLicensePlate() == null || dto.getLicensePlate().trim().isEmpty()) {
            errors.add("License plate is required");
        }

        if (dto.getStatus() == null) {
            errors.add("Status is required");
        }

        if (dto.getType() == null) {
            errors.add("Vehicle type is required");
        }

        if (dto.getMileage() != null && dto.getMileage().compareTo(BigDecimal.ZERO) < 0) {
            errors.add("Mileage cannot be negative");
        }

        if (dto.getYearMade() != null) {
            int currentYear = LocalDate.now().getYear();
            if (dto.getYearMade() < MIN_VEHICLE_YEAR) {
                errors.add("Vehicle year must be " + MIN_VEHICLE_YEAR + " or later");
            }
            if (dto.getYearMade() > currentYear + MAX_FUTURE_YEARS) {
                errors.add("Vehicle year cannot be more than " + MAX_FUTURE_YEARS + " years in the future");
            }
        }

        if (!errors.isEmpty()) {
            throw new InvalidVehicleDataException(String.join(", ", errors));
        }
    }

    /**
     * Validates that vehicle can be assigned to a driver.
     *
     * @param vehicle Vehicle to check
     * @throws InvalidVehicleDataException if vehicle cannot be assigned
     */
    public void validateVehicleForAssignment(Vehicle vehicle) {
        if (vehicle == null) {
            throw new InvalidVehicleDataException("Vehicle cannot be null");
        }

        if (vehicle.getStatus() == VehicleStatus.OUT_OF_SERVICE) {
            throw new InvalidVehicleDataException(
                "vehicle.status",
                vehicle.getStatus().toString(),
                "Vehicle is out of service and cannot be assigned"
            );
        }

        if (vehicle.getStatus() == VehicleStatus.MAINTENANCE) {
            throw new InvalidVehicleDataException(
                "vehicle.status",
                vehicle.getStatus().toString(),
                "Vehicle is under maintenance and cannot be assigned"
            );
        }
    }

    /**
     * Validates vehicle status transition.
     *
     * @param currentStatus Current vehicle status
     * @param newStatus New vehicle status
     * @throws InvalidVehicleDataException if transition is not allowed
     */
    public void validateStatusTransition(VehicleStatus currentStatus, VehicleStatus newStatus) {
        if (currentStatus == null || newStatus == null) {
            throw new InvalidVehicleDataException("Both current and new status must be provided");
        }

        // Business rule: Cannot transition directly from OUT_OF_SERVICE to IN_USE
        if (currentStatus == VehicleStatus.OUT_OF_SERVICE && newStatus == VehicleStatus.IN_USE) {
            throw new InvalidVehicleDataException(
                "vehicle.status",
                newStatus.toString(),
                "Cannot transition directly from OUT_OF_SERVICE to IN_USE. Must go through AVAILABLE or MAINTENANCE first."
            );
        }
    }

    /**
     * Validates truck-specific fields when vehicle type is TRUCK.
     *
     * @param vehicle Vehicle to validate
     * @throws InvalidVehicleDataException if truck fields are invalid
     */
    public void validateTruckFields(Vehicle vehicle) {
        if (vehicle.getType() == VehicleType.TRUCK) {
            List<String> errors = new ArrayList<>();

            if (vehicle.getTruckSize() == null) {
                errors.add("Truck size is required for TRUCK type vehicles");
            }

            // Note: loadCapacity field removed from model
            // Capacity validation can be done via qtyPalletsCapacity if needed

            if (!errors.isEmpty()) {
                throw new InvalidVehicleDataException(String.join(", ", errors));
            }
        }
    }

    /**
     * Validates vehicle maintenance scheduling.
     *
     * @param vehicle Vehicle to validate
     * @throws InvalidVehicleDataException if maintenance dates are invalid
     */
    public void validateMaintenanceSchedule(Vehicle vehicle) {
        if (vehicle.getLastServiceDate() != null && vehicle.getNextServiceDue() != null) {
            if (vehicle.getNextServiceDue().isBefore(vehicle.getLastServiceDate())) {
                throw new InvalidVehicleDataException(
                    "vehicle.nextServiceDue",
                    vehicle.getNextServiceDue().toString(),
                    "Next service due date cannot be before last service date"
                );
            }
        }
    }
}
