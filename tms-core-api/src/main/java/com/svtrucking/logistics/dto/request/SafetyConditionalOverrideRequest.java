package com.svtrucking.logistics.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.NotNull;
import java.util.List;

/**
 * Request DTO for conditional override of safety check failures.
 * Submitted by supervisor/manager to override FAILED or CONDITIONAL checks.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SafetyConditionalOverrideRequest {

    @NotNull(message = "Safety check ID is required")
    private Long safetyCheckId;

    @NotNull(message = "Decision is required: APPROVED or REJECTED")
    private String decision; // APPROVED or REJECTED

    @NotNull(message = "Remarks are required for override decision")
    private String remarks;

    // List of items that are approved to proceed despite failures
    private List<Long> approvedItemIds;
}
