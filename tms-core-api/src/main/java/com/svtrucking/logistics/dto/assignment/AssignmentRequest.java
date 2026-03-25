package com.svtrucking.logistics.dto.assignment;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AssignmentRequest {
    @NotNull(message = "Driver ID is required")
    @Min(value = 1, message = "Driver ID must be positive")
    private Long driverId;

    @NotNull(message = "Truck ID is required")
    @Min(value = 1, message = "Truck ID must be positive")
    @JsonAlias("vehicleId")
    private Long vehicleId;

    @Size(max = 500, message = "Reason must not exceed 500 characters")
    private String reason;

    private Boolean forceReassignment; // Allow admin override for conflicts
}
