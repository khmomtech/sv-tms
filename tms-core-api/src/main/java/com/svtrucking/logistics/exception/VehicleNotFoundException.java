package com.svtrucking.logistics.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Exception thrown when a requested vehicle is not found in the system.
 * Returns HTTP 404 (Not Found) status.
 */
@ResponseStatus(HttpStatus.NOT_FOUND)
public class VehicleNotFoundException extends ResourceNotFoundException {

  public VehicleNotFoundException(Long vehicleId) {
    super(String.format("Vehicle not found with id: %d", vehicleId));
  }

  /**
   * Create exception for vehicle not found by license plate.
   */
  public static VehicleNotFoundException byLicensePlate(String licensePlate) {
    return new VehicleNotFoundException(
        String.format("Vehicle not found with license plate: %s", licensePlate)
    );
  }

  /**
   * Private constructor for custom messages.
   */
  private VehicleNotFoundException(String message) {
    super(message);
  }
}

