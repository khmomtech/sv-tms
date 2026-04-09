package com.svtrucking.logistics.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for reopening a dispatch that has already been delivered, closed,
 * or completed.
 * Transitions dispatch to PENDING_INVESTIGATION for rework or damage claim
 * processing.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReopenDispatchRequest {

    @NotBlank(message = "Reopen reason is required")
    private String reason;

    /** Optional damage claim or incident reference number. */
    private String damageClaimReference;
}
