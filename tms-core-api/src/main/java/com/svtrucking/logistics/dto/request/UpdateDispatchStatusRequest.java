package com.svtrucking.logistics.dto.request;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;

/**
 * Request DTO for updating dispatch status
 * 
 * Replaces previous unstructured approach of passing status as:
 * - Query parameter: ?status=ARRIVED_LOADING
 * - Request body Map: {"status": "ARRIVED_LOADING"}
 * 
 * Now provides:
 * - Type-safe status (uses enum)
 * - Validation annotations
 * - Clear contract for API clients
 * - Audit trail support (reason field)
 * 
 * @since Phase 2 Refactoring - March 2, 2026
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateDispatchStatusRequest {

    /**
     * The new status to transition to
     * Must be a valid transition from current status
     */
    @JsonAlias({"newStatus"})
    @NotNull(message = "Status is required")
    private DispatchStatus status;

    /**
     * Optional reason for status change
     * Useful for audit trail and debugging
     * Example: "Driver arrived on time", "Vehicle breakdown", "Safety check failed"
     */
    private String reason;

    /**
     * Optional timestamp of when status change should be recorded
     * If not provided, server will use current timestamp
     */
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
    private LocalDateTime timestamp;

    /**
     * Optional metadata for the status transition
     * Can contain driver location, vehicle data, photo URLs, etc.
     * Implementation-specific usage
     */
    private java.util.Map<String, Object> metadata;
}
