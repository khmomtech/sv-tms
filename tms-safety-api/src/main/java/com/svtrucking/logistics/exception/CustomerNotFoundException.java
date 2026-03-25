package com.svtrucking.logistics.exception;

/**
 * Exception thrown when a customer cannot be found by ID.
 * Used to indicate HTTP 404 Not Found status.
 */
public class CustomerNotFoundException extends RuntimeException {

    public CustomerNotFoundException(Long id) {
        super("Customer not found with ID: " + id);
    }

    public CustomerNotFoundException(String message) {
        super(message);
    }

    public CustomerNotFoundException(Long id, Throwable cause) {
        super("Customer not found with ID: " + id, cause);
    }
}
