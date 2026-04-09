package com.svtrucking.logistics.exception;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for GlobalExceptionHandler
 */
@DisplayName("GlobalExceptionHandler Unit Tests")
class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler handler;
    private MockHttpServletRequest request;

    @BeforeEach
    void setUp() {
        handler = new GlobalExceptionHandler();
        request = new MockHttpServletRequest();
    }

    @Test
    @DisplayName("handleNoResourceFound returns 404 for non-existent endpoint")
    void testHandleNoResourceFound() {
        // Arrange
        request.setRequestURI("/api/tasks");
        request.setMethod("POST");
        NoResourceFoundException exception = new NoResourceFoundException(null, "/api/tasks");

        // Act
        ResponseEntity<GlobalExceptionHandler.ErrorResponse> response = 
            handler.handleNoResourceFound(exception, request);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getStatus()).isEqualTo(404);
        assertThat(response.getBody().getError()).isEqualTo("API Endpoint Not Found");
        assertThat(response.getBody().getMessage()).contains("/api/tasks");
        assertThat(response.getBody().getTimestamp()).isNotNull();
    }

    @Test
    @DisplayName("handleNoResourceFound suggests correct endpoints for /api/tasks")
    void testHandleNoResourceFoundSuggestsCorrectEndpoints() {
        // Arrange
        request.setRequestURI("/api/tasks");
        request.setMethod("GET");
        NoResourceFoundException exception = new NoResourceFoundException(null, "/api/tasks");

        // Act
        ResponseEntity<GlobalExceptionHandler.ErrorResponse> response = 
            handler.handleNoResourceFound(exception, request);

        // Assert
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage())
            .contains("technician/tasks")
            .contains("maintenance-tasks");
    }

    @Test
    @DisplayName("handleNoResourceFound provides generic message for other endpoints")
    void testHandleNoResourceFoundGenericMessage() {
        // Arrange
        request.setRequestURI("/api/other-endpoint");
        request.setMethod("GET");
        NoResourceFoundException exception = new NoResourceFoundException(null, "/api/other-endpoint");

        // Act
        ResponseEntity<GlobalExceptionHandler.ErrorResponse> response = 
            handler.handleNoResourceFound(exception, request);

        // Assert
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage())
            .contains("/api/other-endpoint")
            .contains("API documentation");
    }

    @Test
    @DisplayName("handleResourceNotFound returns 404 for resource not found")
    void testHandleResourceNotFound() {
        // Arrange
        ResourceNotFoundException exception = new ResourceNotFoundException("Driver with ID 123 not found");

        // Act
        ResponseEntity<GlobalExceptionHandler.ErrorResponse> response = 
            handler.handleResourceNotFound(exception);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getStatus()).isEqualTo(404);
        assertThat(response.getBody().getError()).isEqualTo("Not Found");
        assertThat(response.getBody().getMessage()).contains("Driver");
    }

    @Test
    @DisplayName("handleGenericException returns 500 for unexpected errors")
    void testHandleGenericException() {
        // Arrange
        Exception exception = new RuntimeException("Unexpected error");

        // Act
        ResponseEntity<GlobalExceptionHandler.ErrorResponse> response = 
            handler.handleGenericException(exception);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getStatus()).isEqualTo(500);
        assertThat(response.getBody().getError()).isEqualTo("Internal Server Error");
        assertThat(response.getBody().getMessage()).isEqualTo("An unexpected error occurred");
    }

    @Test
    @DisplayName("Error response structure is valid")
    void testErrorResponseStructure() {
        // Arrange
        request.setRequestURI("/api/tasks");
        NoResourceFoundException exception = new NoResourceFoundException(null, "/api/tasks");

        // Act
        ResponseEntity<GlobalExceptionHandler.ErrorResponse> response = 
            handler.handleNoResourceFound(exception, request);

        // Assert
        GlobalExceptionHandler.ErrorResponse errorResponse = response.getBody();
        assertThat(errorResponse).isNotNull();
        assertThat(errorResponse.getTimestamp()).isNotNull();
        assertThat(errorResponse.getStatus()).isGreaterThan(0);
        assertThat(errorResponse.getError()).isNotBlank();
        assertThat(errorResponse.getMessage()).isNotBlank();
    }
}
