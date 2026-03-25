package com.svtrucking.logistics.core;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;
import java.util.UUID;
import lombok.Data;

/**
 * Standardized API response wrapper for all endpoints.
 * Provides consistent response structure with metadata for traceability.
 */
@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

  private boolean success;
  private String message;
  private String code;
  private T data;
  private Object errors;

  @JsonFormat(shape = JsonFormat.Shape.STRING)
  private Instant timestamp;
  
  /**
   * Unique request identifier for tracing and debugging.
   * Useful for correlating logs across distributed systems.
   */
  private String requestId;
  
  /**
   * Total pages for paginated responses (optional, defaults to 1 for non-paginated)
   */
  private Integer totalPages;

  public ApiResponse(boolean success, String message, String code, T data, Object errors, Instant timestamp, String requestId) {
    this.success = success;
    this.message = message;
    this.code = code;
    this.data = data;
    this.errors = errors;
    this.timestamp = timestamp != null ? timestamp : Instant.now();
    this.requestId = requestId != null ? requestId : UUID.randomUUID().toString();
    this.totalPages = 1; // Default to 1 for non-paginated responses
  }

  // Backward compatibility constructors (without requestId)
  public ApiResponse(boolean success, String message, String code, T data, Object errors, Instant timestamp) {
    this(success, message, code, data, errors, timestamp, null);
  }

  public ApiResponse(boolean success, String message, T data, Object errors, Instant timestamp) {
    this(success, message, null, data, errors, timestamp, null);
  }

  public ApiResponse(boolean success, String message) {
    this(success, message, null, null, null, Instant.now(), null);
  }

  public ApiResponse(boolean success, String message, T data) {
    this(success, message, null, data, null, Instant.now(), null);
  }

  public ApiResponse(boolean success, String message, T data, Object errors) {
    this(success, message, null, data, errors, Instant.now(), null);
  }

  //  Convenience factory methods with auto-generated requestId
  public static <T> ApiResponse<T> success(String message) {
    return new ApiResponse<>(true, message, null, null, null, Instant.now(), UUID.randomUUID().toString());
  }

  public static <T> ApiResponse<T> ok(String message, T data) {
    return new ApiResponse<>(true, message, null, data, null, Instant.now(), UUID.randomUUID().toString());
  }

  public static <T> ApiResponse<T> fail(String message) {
    return new ApiResponse<>(false, message, null, null, null, Instant.now(), UUID.randomUUID().toString());
  }

  public static <T> ApiResponse<T> fail(String message, Object errors) {
    return new ApiResponse<>(false, message, null, null, errors, Instant.now(), UUID.randomUUID().toString());
  }

  public static <T> ApiResponse<T> failWithCode(String message, String code) {
    return new ApiResponse<>(false, message, code, null, null, Instant.now(), UUID.randomUUID().toString());
  }

  public static <T> ApiResponse<T> success(String message, T data) {
    return new ApiResponse<>(true, message, null, data, null, Instant.now(), UUID.randomUUID().toString());
  }

  public static <T> ApiResponse<T> unprocessable(String message, Object errors) {
    return new ApiResponse<>(false, message, null, null, errors, Instant.now(), UUID.randomUUID().toString());
  }
}
