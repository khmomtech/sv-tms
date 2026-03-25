package com.svtrucking.logistics.exception;

/**
 * Exception thrown when a driver cannot be found by ID.
 * Used to indicate HTTP 404 Not Found status.
 */
public class DriverNotFoundException extends RuntimeException {

    public DriverNotFoundException(Long id) {
        super("Driver not found with ID: " + id);
    }

    public DriverNotFoundException(String message) {
        super(message);
    }

    public DriverNotFoundException(Long id, Throwable cause) {
        super("Driver not found with ID: " + id, cause);
    }
}
