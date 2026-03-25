package com.svtrucking.logistics.exception;

/**
 * Exception thrown when driver validation fails.
 * Used to indicate HTTP 400 Bad Request status.
 * 
 * This is a general validation exception for driver operations.
 * More specific than InvalidDriverDataException, used for operation-specific validations.
 * 
 * Examples:
 * - Driver already assigned to vehicle
 * - Driver not eligible for assignment (inactive, no license)
 * - Duplicate license number
 * - Invalid status transition
 */
public class DriverValidationException extends RuntimeException {

    public DriverValidationException(String message) {
        super(message);
    }

    public DriverValidationException(String message, Throwable cause) {
        super(message, cause);
    }

    public DriverValidationException(String operation, String reason) {
        super(String.format("Driver validation failed for %s: %s", operation, reason));
    }
}
