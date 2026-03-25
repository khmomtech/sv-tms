package com.svtrucking.logistics.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Exception thrown when assignment operation fails due to business rule violations.
 * Returns HTTP 422 (Unprocessable Entity) status.
 * 
 * Examples:
 * - Driver is not qualified to drive the vehicle type
 * - Vehicle is not available (in use, maintenance, out of service)
 * - Driver already has an active assignment
 * - Vehicle already has an assigned driver
 */
@ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
public class AssignmentValidationException extends RuntimeException {

  public AssignmentValidationException(String message) {
    super(message);
  }

  public AssignmentValidationException(String message, Throwable cause) {
    super(message, cause);
  }

  /**
   * Create exception for driver not qualified.
   */
  public static AssignmentValidationException driverNotQualified(Long driverId, String vehicleType, String requiredLicense) {
    return new AssignmentValidationException(
        String.format("Driver %d is not qualified to drive %s (requires license class %s)", 
            driverId, vehicleType, requiredLicense));
  }

  /**
   * Create exception for vehicle not available.
   */
  public static AssignmentValidationException vehicleNotAvailable(Long vehicleId, String status) {
    return new AssignmentValidationException(
        String.format("Vehicle %d is not available for assignment (current status: %s)", 
            vehicleId, status));
  }

  /**
   * Create exception for driver already assigned.
   */
  public static AssignmentValidationException driverAlreadyAssigned(Long driverId, Long vehicleId) {
    return new AssignmentValidationException(
        String.format("Driver %d already has an active assignment to vehicle %d", 
            driverId, vehicleId));
  }

  /**
   * Create exception for vehicle already assigned.
   */
  public static AssignmentValidationException vehicleAlreadyAssigned(Long vehicleId, Long driverId) {
    return new AssignmentValidationException(
        String.format("Vehicle %d is already assigned to driver %d", 
            vehicleId, driverId));
  }
}
