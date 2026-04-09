package com.svtrucking.logistics.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Exception thrown when invalid vehicle data is provided during create or update operations.
 * Returns HTTP 400 (Bad Request) status.
 */
@ResponseStatus(HttpStatus.BAD_REQUEST)
public class InvalidVehicleDataException extends RuntimeException {

  public InvalidVehicleDataException(String message) {
    super(message);
  }

  public InvalidVehicleDataException(String message, Throwable cause) {
    super(message, cause);
  }

  public InvalidVehicleDataException(String field, String value, String reason) {
    super(String.format("Invalid vehicle data: field '%s' with value '%s' - %s", field, value, reason));
  }
}
