package com.svtrucking.logistics.exception;

/**
 * Exception thrown when driver data fails business validation rules.
 * Used to indicate HTTP 400 Bad Request status.
 * 
 * Examples:
 * - Missing required fields (name, license, phone)
 * - Invalid data format (phone number, license number)
 * - Business rule violations (partner without company name)
 */
public class InvalidDriverDataException extends RuntimeException {

    public InvalidDriverDataException(String message) {
        super(message);
    }

    public InvalidDriverDataException(String message, Throwable cause) {
        super(message, cause);
    }

    public InvalidDriverDataException(String field, String reason) {
        super(String.format("Invalid driver data - %s: %s", field, reason));
    }
}
