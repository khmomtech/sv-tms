package com.svtrucking.logistics.exception;

/**
 * Exception thrown when a dispatch cannot be found by ID.
 * Used to indicate HTTP 404 Not Found status.
 */
public class DispatchNotFoundException extends RuntimeException {

    public DispatchNotFoundException(Long id) {
        super("Dispatch not found with ID: " + id);
    }

    public DispatchNotFoundException(String message) {
        super(message);
    }

    public DispatchNotFoundException(Long id, Throwable cause) {
        super("Dispatch not found with ID: " + id, cause);
    }
}
