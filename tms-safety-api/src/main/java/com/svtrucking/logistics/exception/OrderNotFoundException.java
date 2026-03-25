package com.svtrucking.logistics.exception;

/**
 * Exception thrown when an order cannot be found by ID.
 * Used to indicate HTTP 404 Not Found status.
 */
public class OrderNotFoundException extends RuntimeException {

    public OrderNotFoundException(Long id) {
        super("Order not found with ID: " + id);
    }

    public OrderNotFoundException(String message) {
        super(message);
    }

    public OrderNotFoundException(Long id, Throwable cause) {
        super("Order not found with ID: " + id, cause);
    }
}
