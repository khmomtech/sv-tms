package com.svtrucking.logistics.exception;

/**
 * Exception thrown when driver file upload operations fail.
 * Used to indicate HTTP 500 Internal Server Error status.
 * 
 * Examples:
 * - File I/O errors during profile picture upload
 * - Invalid file type (not allowed extension)
 * - File size exceeds limit
 * - Disk space issues
 * - Permission errors
 */
public class DriverFileUploadException extends RuntimeException {

    public DriverFileUploadException(String message) {
        super(message);
    }

    public DriverFileUploadException(String message, Throwable cause) {
        super(message, cause);
    }
}
