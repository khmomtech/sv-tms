package com.svtrucking.logistics.exception;

/**
 * Exception thrown when customer data fails business validation rules.
 * Used to indicate HTTP 400 Bad Request status.
 * 
 * Examples:
 * - Missing required fields (name, phone)
 * - Invalid data format (email, phone number)
 * - Business rule violations
 */
public class InvalidCustomerDataException extends RuntimeException {

    private final String field;
    private final String reason;

    public InvalidCustomerDataException(String message) {
        super(message);
        this.field = null;
        this.reason = message;
    }

    public InvalidCustomerDataException(String message, Throwable cause) {
        super(message, cause);
        this.field = null;
        this.reason = message;
    }

    public InvalidCustomerDataException(String field, String reason) {
        super(String.format("Invalid customer data - %s: %s", field, reason));
        this.field = field;
        this.reason = reason;
    }

    public String getField() {
        return field;
    }

    public String getReason() {
        return reason;
    }
}
