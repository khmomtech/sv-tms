package com.svtrucking.logistics.exception;

import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.security.authorization.AuthorizationDeniedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import jakarta.persistence.OptimisticLockException;
import org.apache.catalina.connector.ClientAbortException;
import org.springframework.web.context.request.async.AsyncRequestNotUsableException;
import java.net.SocketException;

/**
 * Global exception handler for all REST controllers.
 * Provides consistent error responses across the entire application.
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

  /**
   * Handle JSON deserialization errors (e.g., invalid format, empty string for
   * object, etc.)
   * This provides clear feedback to the frontend and logs the root cause for
   * debugging.
   */
  @ExceptionHandler(org.springframework.http.converter.HttpMessageNotReadableException.class)
  public ResponseEntity<ErrorResponse> handleDeserializationError(
      org.springframework.http.converter.HttpMessageNotReadableException ex) {
    // Find the root cause for detailed error reporting
    Throwable root = ex.getMostSpecificCause() != null ? ex.getMostSpecificCause() : ex;
    String userMessage = "Invalid request format: " + root.getMessage();
    log.error("Deserialization error: {}", userMessage, ex);
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Invalid Request Format")
        .message(userMessage)
        .build();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }
  // ============================================================
  // NOT FOUND (404) EXCEPTIONS
  // ============================================================

  @ExceptionHandler(ResourceNotFoundException.class)
  public ResponseEntity<ErrorResponse> handleResourceNotFound(ResourceNotFoundException ex) {
    log.error("Resource not found: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.NOT_FOUND.value())
        .error("Not Found")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
  }

  @ExceptionHandler(DriverNotFoundException.class)
  public ResponseEntity<ErrorResponse> handleDriverNotFound(DriverNotFoundException ex) {
    log.error("Driver not found: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.NOT_FOUND.value())
        .error("Driver Not Found")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
  }

  @ExceptionHandler(VehicleNotFoundException.class)
  public ResponseEntity<ErrorResponse> handleVehicleNotFound(VehicleNotFoundException ex) {
    log.error("Vehicle not found: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.NOT_FOUND.value())
        .error("Vehicle Not Found")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
  }

  @ExceptionHandler(AssignmentNotFoundException.class)
  public ResponseEntity<ErrorResponse> handleAssignmentNotFound(AssignmentNotFoundException ex) {
    log.error("Assignment not found: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.NOT_FOUND.value())
        .error("Assignment Not Found")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
  }

  @ExceptionHandler(NotificationNotFoundException.class)
  public ResponseEntity<ErrorResponse> handleNotificationNotFound(NotificationNotFoundException ex) {
    log.error("Notification not found: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.NOT_FOUND.value())
        .error("Notification Not Found")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
  }

  @ExceptionHandler(CustomerNotFoundException.class)
  public ResponseEntity<ErrorResponse> handleCustomerNotFound(CustomerNotFoundException ex) {
    log.error("Customer not found: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.NOT_FOUND.value())
        .error("Customer Not Found")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
  }

  @ExceptionHandler(DispatchNotFoundException.class)
  public ResponseEntity<ErrorResponse> handleDispatchNotFound(DispatchNotFoundException ex) {
    log.error("Dispatch not found: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.NOT_FOUND.value())
        .error("Dispatch Not Found")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
  }

  @ExceptionHandler(OrderNotFoundException.class)
  public ResponseEntity<ErrorResponse> handleOrderNotFound(OrderNotFoundException ex) {
    log.error("Order not found: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.NOT_FOUND.value())
        .error("Order Not Found")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
  }

  @ExceptionHandler(AuthorizationDeniedException.class)
  public ResponseEntity<ErrorResponse> handleAccessDenied(AuthorizationDeniedException ex) {
    log.warn("Access denied: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.FORBIDDEN.value())
        .error("Forbidden")
        .message("Access is denied")
        .build();
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
  }

  @ExceptionHandler(ResponseStatusException.class)
  public ResponseEntity<ErrorResponse> handleResponseStatus(ResponseStatusException ex) {
    HttpStatus status = HttpStatus.resolve(ex.getStatusCode().value());
    HttpStatus resolved = status != null ? status : HttpStatus.INTERNAL_SERVER_ERROR;
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(resolved.value())
        .error(resolved.getReasonPhrase())
        .message(ex.getReason())
        .build();
    return ResponseEntity.status(resolved).body(error);
  }

  @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
  public ResponseEntity<ErrorResponse> handleMethodNotSupported(HttpRequestMethodNotSupportedException ex) {
    String supported = ex.getSupportedHttpMethods() != null ? ex.getSupportedHttpMethods().toString() : "N/A";
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.METHOD_NOT_ALLOWED.value())
        .error("Method Not Allowed")
        .message("Request method '" + ex.getMethod() + "' is not supported. Supported: " + supported)
        .build();
    return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(error);
  }

  @ExceptionHandler(IllegalStateException.class)
  public ResponseEntity<ErrorResponse> handleIllegalState(IllegalStateException ex) {
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.CONFLICT.value())
        .error("Conflict")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
  }

  @ExceptionHandler(SecurityException.class)
  public ResponseEntity<ErrorResponse> handleSecurity(SecurityException ex) {
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.FORBIDDEN.value())
        .error("Forbidden")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
  }

  // ============================================================
  // BAD REQUEST (400) EXCEPTIONS
  // ============================================================

  @ExceptionHandler(InvalidDriverDataException.class)
  public ResponseEntity<ErrorResponse> handleInvalidDriverData(InvalidDriverDataException ex) {
    log.error("Invalid driver data: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Invalid Driver Data")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  @ExceptionHandler(InvalidVehicleDataException.class)
  public ResponseEntity<ErrorResponse> handleInvalidVehicleData(InvalidVehicleDataException ex) {
    log.error("Invalid vehicle data: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Invalid Vehicle Data")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  @ExceptionHandler(DriverValidationException.class)
  public ResponseEntity<ErrorResponse> handleDriverValidation(DriverValidationException ex) {
    log.error("Driver validation failed: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Driver Validation Failed")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  @ExceptionHandler(BusinessException.class)
  public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException ex) {
    log.error("Business rule violation: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Business Rule Violation")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  @ExceptionHandler(DuplicateLicensePlateException.class)
  public ResponseEntity<ErrorResponse> handleDuplicateLicensePlate(DuplicateLicensePlateException ex) {
    log.error("Duplicate license plate: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Duplicate License Plate")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  @ExceptionHandler(DuplicateCustomerException.class)
  public ResponseEntity<ErrorResponse> handleDuplicateCustomer(DuplicateCustomerException ex) {
    log.error("Duplicate customer data: {}", ex.getMessage());

    // Parse the exception message to determine which field is duplicated
    String message = ex.getMessage();
    Map<String, String> fieldErrors = new HashMap<>();
    String errorType = "Duplicate Customer";

    if (message.contains("email")) {
      fieldErrors.put("email", "This email is already in use");
      errorType = "Duplicate Email";
    } else if (message.contains("phone")) {
      fieldErrors.put("phone", "This phone number is already in use");
      errorType = "Duplicate Phone Number";
    } else if (message.contains("customerCode") || message.contains("customer code")) {
      fieldErrors.put("customerCode", "This customer code is already in use");
      errorType = "Duplicate Customer Code";
    } else {
      fieldErrors.put("_global", message);
    }

    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.CONFLICT.value())
        .error(errorType)
        .message(message)
        .validationErrors(fieldErrors)
        .build();
    return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
  }

  @ExceptionHandler(InvalidCustomerDataException.class)
  public ResponseEntity<ErrorResponse> handleInvalidCustomerData(InvalidCustomerDataException ex) {
    log.error("Invalid customer data: {}", ex.getMessage());
    Map<String, String> fieldErrors = new HashMap<>();
    if (ex.getField() != null) {
      String fieldMessage = ex.getReason() != null ? ex.getReason() : ex.getMessage();
      fieldErrors.put(ex.getField(), fieldMessage);
    }
    String userMessage = ex.getReason() != null && ex.getField() != null
        ? String.format("%s (%s)", ex.getReason(), ex.getField())
        : ex.getMessage();

    ErrorResponse.ErrorResponseBuilder builder = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Invalid Customer Data")
        .message(userMessage);

    if (!fieldErrors.isEmpty()) {
      builder.validationErrors(fieldErrors);
    }

    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(builder.build());
  }

  @ExceptionHandler(InvalidDispatchDataException.class)
  public ResponseEntity<ErrorResponse> handleInvalidDispatchData(InvalidDispatchDataException ex) {
    log.error("Invalid dispatch data: {}", ex.getMessage());
    Map<String, String> fieldErrors = new HashMap<>();
    if (ex.getField() != null) {
      fieldErrors.put(ex.getField(), ex.getReason() != null ? ex.getReason() : ex.getMessage());
    }
    // Ensure frontend always receives a `validationErrors` map for UI display.
    if (fieldErrors.isEmpty()) {
      fieldErrors.put("_global", ex.getMessage());
    }

    ErrorResponse.ErrorResponseBuilder builder = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Invalid Dispatch Data")
        .message(ex.getMessage())
        .validationErrors(fieldErrors)
        .code(ex.getCode())
        .requiredInput(ex.getRequiredInput())
        .nextAllowedAction(ex.getNextAllowedAction());

    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(builder.build());
  }

  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ErrorResponse> handleIllegalArgument(IllegalArgumentException ex) {
    log.error("Illegal argument: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Bad Request")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ErrorResponse> handleValidationErrors(MethodArgumentNotValidException ex) {
    Map<String, String> errors = new HashMap<>();
    ex.getBindingResult()
        .getAllErrors()
        .forEach(
            error -> {
              String fieldName = ((FieldError) error).getField();
              String errorMessage = error.getDefaultMessage();
              errors.put(fieldName, errorMessage);
            });

    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Validation Failed")
        .message("Input validation errors")
        .validationErrors(errors)
        .build();

    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  @ExceptionHandler(MethodArgumentTypeMismatchException.class)
  public ResponseEntity<ErrorResponse> handleMethodArgumentTypeMismatch(
      MethodArgumentTypeMismatchException ex) {
    String field = ex.getName() != null ? ex.getName() : "parameter";
    String value = ex.getValue() != null ? ex.getValue().toString() : "null";
    String expected = ex.getRequiredType() != null ? ex.getRequiredType().getSimpleName() : "valid type";

    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Bad Request")
        .message(
            String.format(
                "Invalid value '%s' for '%s'. Expected %s.",
                value, field, expected))
        .build();

    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  @ExceptionHandler(MissingServletRequestParameterException.class)
  public ResponseEntity<ErrorResponse> handleMissingRequestParameter(MissingServletRequestParameterException ex) {
    String message = String.format("Required request parameter '%s' is missing", ex.getParameterName());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Missing Request Parameter")
        .message(message)
        .build();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  @ExceptionHandler(ConstraintViolationException.class)
  public ResponseEntity<ErrorResponse> handleConstraintViolation(ConstraintViolationException ex) {
    Map<String, String> errors = new HashMap<>();
    ex.getConstraintViolations().forEach(violation ->
        errors.put(violation.getPropertyPath().toString(), violation.getMessage()));

    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.BAD_REQUEST.value())
        .error("Validation Failed")
        .message("Constraint violations occurred")
        .validationErrors(errors)
        .build();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
  }

  // ============================================================
  // INTERNAL SERVER ERROR (500) EXCEPTIONS
  // ============================================================

  @ExceptionHandler(DriverFileUploadException.class)
  public ResponseEntity<ErrorResponse> handleDriverFileUpload(DriverFileUploadException ex) {
    log.error("Driver file upload failed: {}", ex.getMessage(), ex);
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
        .error("File Upload Failed")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
  }

  @ExceptionHandler(org.springframework.dao.DataAccessException.class)
  public ResponseEntity<ErrorResponse> handleDataAccess(DataAccessException ex) {
    log.error("Database access error: {}", ex.getMessage(), ex);
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.SERVICE_UNAVAILABLE.value())
        .error("Service Unavailable")
        .message("Database is currently unavailable. Please try again later.")
        .build();
    return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(error);
  }

  // ============================================================
  // CONFLICT (409) EXCEPTIONS
  // ============================================================

  @ExceptionHandler(BusinessConflictException.class)
  public ResponseEntity<ErrorResponse> handleBusinessConflict(BusinessConflictException ex) {
    log.warn("Business conflict: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.CONFLICT.value())
        .error("Conflict")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
  }

  @ExceptionHandler(OptimisticLockException.class)
  public ResponseEntity<ErrorResponse> handleOptimisticLock(OptimisticLockException ex) {
    log.warn("Optimistic lock conflict: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.CONFLICT.value())
        .error("Conflict")
        .message("The resource was modified by another request. Please retry.")
        .build();
    return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
  }

  @ExceptionHandler(org.springframework.orm.ObjectOptimisticLockingFailureException.class)
  public ResponseEntity<ErrorResponse> handleSpringOptimisticLock(
      org.springframework.orm.ObjectOptimisticLockingFailureException ex) {
    log.warn("Optimistic lock conflict (Spring ORM): entity={}, id={}",
        ex.getPersistentClassName(), ex.getIdentifier());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.CONFLICT.value())
        .error("Conflict")
        .message("The resource was modified by another concurrent request. Please retry.")
        .build();
    return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
  }

  // ============================================================
  // UNPROCESSABLE ENTITY (422) EXCEPTIONS
  // ============================================================

  @ExceptionHandler(AssignmentValidationException.class)
  public ResponseEntity<ErrorResponse> handleAssignmentValidation(AssignmentValidationException ex) {
    log.error("Assignment validation failed: {}", ex.getMessage());
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.UNPROCESSABLE_ENTITY.value())
        .error("Assignment Validation Failed")
        .message(ex.getMessage())
        .build();
    return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(error);
  }

  // ============================================================
  // GENERIC EXCEPTION HANDLER (Catch-all)
  // ============================================================

  /**
   * Handle 404 errors for non-existent API endpoints
   * This catches cases where clients call endpoints that don't exist
   */
  @ExceptionHandler(org.springframework.web.servlet.resource.NoResourceFoundException.class)
  public ResponseEntity<ErrorResponse> handleNoResourceFound(
      org.springframework.web.servlet.resource.NoResourceFoundException ex,
      jakarta.servlet.http.HttpServletRequest request) {
    String requestedPath = request.getRequestURI();
    log.warn("API endpoint not found: {} {}", request.getMethod(), requestedPath);

    // Provide helpful error message with suggestions
    String message = String.format(
        "API endpoint '%s' not found. Please check the API documentation for available endpoints.",
        requestedPath);

    // Add specific suggestions for common mistakes
    if (requestedPath.equals("/api/tasks")) {
      message += " Did you mean '/api/technician/tasks' or '/api/admin/maintenance-tasks'?";
    }

    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.NOT_FOUND.value())
        .error("API Endpoint Not Found")
        .message(message)
        .build();
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorResponse> handleGenericException(Exception ex) {
    // Detect common client-abort / broken-pipe scenarios and avoid logging full
    // stacktraces
    Throwable cause = ex;
    while (cause != null) {
      if (cause instanceof ClientAbortException
          || cause instanceof AsyncRequestNotUsableException
          || (cause instanceof SocketException && cause.getMessage() != null
              && cause.getMessage().toLowerCase().contains("broken pipe"))) {
        // Client disconnected (browser closed / network issue). Don't treat as
        // application error.
        log.debug("Client disconnected while server was writing response: {}", cause.getMessage());
        // Return 204 No Content to indicate nothing further to send, and avoid
        // serializing an error body
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
      }
      cause = cause.getCause();
    }

    log.error("Unexpected error occurred", ex);
    ErrorResponse error = ErrorResponse.builder()
        .timestamp(LocalDateTime.now())
        .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
        .error("Internal Server Error")
        .message("An unexpected error occurred")
        .build();
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
  }

  @lombok.Data
  @lombok.Builder
  public static class ErrorResponse {
    private LocalDateTime timestamp;
    private int status;
    private String error;
    private String message;
    private Map<String, String> validationErrors;
    private String code;
    private String requiredInput;
    private String nextAllowedAction;
  }
}
