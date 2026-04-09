package com.svtrucking.logistics.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Request DTO for assigning a driver to a vehicle (permanent assignment).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "Request to assign a driver to a vehicle")
public class DriverAssignmentRequest {

  @NotNull(message = "Driver ID is required")
  @Schema(description = "ID of the driver to assign", example = "42", required = true)
  private Long driverId;

  @NotNull(message = "Vehicle ID is required")
  @Schema(description = "ID of the vehicle to assign", example = "123", required = true)
  private Long vehicleId;

  @Schema(description = "Assignment notes or reason", example = "Regular route assignment")
  @Size(max = 500, message = "Notes must be less than 500 characters")
  private String notes;
}
