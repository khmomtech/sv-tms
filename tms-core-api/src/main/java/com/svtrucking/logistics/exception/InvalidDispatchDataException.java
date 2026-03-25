package com.svtrucking.logistics.exception;

/**
 * Exception thrown when dispatch data fails business validation rules.
 * Used to indicate HTTP 400 Bad Request status.
 * 
 * Examples:
 * - Missing required fields (driver, vehicle, order)
 * - Invalid status transitions
 * - Business rule violations (driver already assigned, etc.)
 */
public class InvalidDispatchDataException extends RuntimeException {

    private final String field;
    private final String reason;
    private final String code;
    private final String requiredInput;
    private final String nextAllowedAction;

    public InvalidDispatchDataException(String message) {
        super(message);
        this.field = null;
        this.reason = message;
        this.code = null;
        this.requiredInput = null;
        this.nextAllowedAction = null;
    }

    public InvalidDispatchDataException(String message, Throwable cause) {
        super(message, cause);
        this.field = null;
        this.reason = message;
        this.code = null;
        this.requiredInput = null;
        this.nextAllowedAction = null;
    }

    public InvalidDispatchDataException(String field, String reason) {
        super(String.format("Invalid dispatch data - %s: %s", field, reason));
        this.field = field;
        this.reason = reason;
        this.code = null;
        this.requiredInput = null;
        this.nextAllowedAction = null;
    }

    public InvalidDispatchDataException(
            String field,
            String reason,
            String code,
            String requiredInput,
            String nextAllowedAction) {
        super(String.format("Invalid dispatch data - %s: %s", field, reason));
        this.field = field;
        this.reason = reason;
        this.code = code;
        this.requiredInput = requiredInput;
        this.nextAllowedAction = nextAllowedAction;
    }

    public String getField() {
        return field;
    }

    public String getReason() {
        return reason;
    }

    public String getCode() {
        return code;
    }

    public String getRequiredInput() {
        return requiredInput;
    }

    public String getNextAllowedAction() {
        return nextAllowedAction;
    }
}
