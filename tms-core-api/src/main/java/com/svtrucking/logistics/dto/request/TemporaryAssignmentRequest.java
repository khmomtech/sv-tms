package com.svtrucking.logistics.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Request DTO for temporary driver-vehicle assignment.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "Request for temporary driver-vehicle assignment")
public class TemporaryAssignmentRequest {

  @NotNull(message = "Driver ID is required")
  @Schema(description = "ID of the driver to assign temporarily", example = "42", required = true)
  private Long driverId;

  @NotNull(message = "Vehicle ID is required")
  @Schema(description = "ID of the vehicle to assign temporarily", example = "123", required = true)
  private Long vehicleId;

  @NotNull(message = "Expiry date/time is required")
  @Future(message = "Expiry must be in the future")
  @Schema(description = "When this temporary assignment expires", example = "2025-12-31T23:59:59", required = true)
  private LocalDateTime expiry;

  @NotNull(message = "Reason is required for temporary assignments")
  @Size(min = 5, max = 500, message = "Reason must be between 5 and 500 characters")
  @Schema(description = "Reason for temporary assignment", example = "Vehicle under maintenance", required = true)
  private String reason;
}
