package com.svtrucking.logistics.exception;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.http.HttpStatus;

/**
 * Standardized error response for all API endpoints.
 * Follows REST API best practices for error handling.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ErrorResponse {

  /** HTTP status code (e.g., 400, 404, 500) */
  private int status;

  /** HTTP status text (e.g., "Bad Request", "Not Found") */
  private String error;

  /** User-friendly error message */
  private String message;

  /** Technical error details (only included in development mode) */
  private String details;

  /** Request path that caused the error */
  private String path;

  /** Timestamp when error occurred */
  @Builder.Default private LocalDateTime timestamp = LocalDateTime.now();

  /** Validation errors (for 400 Bad Request) */
  private List<FieldError> fieldErrors;

  /** Additional context (optional) */
  private Map<String, Object> metadata;

  /** Request trace ID for debugging */
  private String traceId;

  /**
   * Field-level validation error
   */
  @Data
  @AllArgsConstructor
  @NoArgsConstructor
  public static class FieldError {
    private String field;
    private String message;
    private Object rejectedValue;
  }

  // Factory methods for common error scenarios

  public static ErrorResponse of(HttpStatus status, String message, String path) {
    return ErrorResponse.builder()
        .status(status.value())
        .error(status.getReasonPhrase())
        .message(message)
        .path(path)
        .build();
  }

  public static ErrorResponse badRequest(String message, String path) {
    return of(HttpStatus.BAD_REQUEST, message, path);
  }

  public static ErrorResponse unauthorized(String message, String path) {
    return of(HttpStatus.UNAUTHORIZED, message, path);
  }

  public static ErrorResponse forbidden(String message, String path) {
    return of(HttpStatus.FORBIDDEN, message, path);
  }

  public static ErrorResponse notFound(String message, String path) {
    return of(HttpStatus.NOT_FOUND, message, path);
  }

  public static ErrorResponse conflict(String message, String path) {
    return of(HttpStatus.CONFLICT, message, path);
  }

  public static ErrorResponse internalServerError(String message, String path) {
    return of(HttpStatus.INTERNAL_SERVER_ERROR, message, path);
  }
}
