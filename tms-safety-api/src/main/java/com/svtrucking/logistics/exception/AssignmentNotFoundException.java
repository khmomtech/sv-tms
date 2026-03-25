package com.svtrucking.logistics.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Exception thrown when a requested driver assignment is not found.
 * Returns HTTP 404 (Not Found) status.
 */
@ResponseStatus(HttpStatus.NOT_FOUND)
public class AssignmentNotFoundException extends ResourceNotFoundException {

  public AssignmentNotFoundException(Long assignmentId) {
    super(String.format("Assignment not found with id: %d", assignmentId));
  }

  public AssignmentNotFoundException(String message) {
    super(message);
  }
}
