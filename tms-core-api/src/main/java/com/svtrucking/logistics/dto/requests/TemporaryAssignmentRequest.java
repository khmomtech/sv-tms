package com.svtrucking.logistics.dto.requests;

import java.time.LocalDateTime;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TemporaryAssignmentRequest {
  @NotNull(message = "vehicleId is required")
  private Long vehicleId;

  @Future(message = "Expiry must be in the future")
  private LocalDateTime expiry; // Optional; if null lasts until manual removal/reset

  @Size(max = 255, message = "Reason max length 255 characters")
  private String reason; // Optional audit context
}
