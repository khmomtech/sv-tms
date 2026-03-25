package com.svtrucking.logistics.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotNull;

/**
 * Request DTO for dispatch approval decision.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DispatchApprovalRequest {

    @NotNull(message = "Dispatch ID is required")
    private Long dispatchId;

    @NotNull(message = "Action is required: APPROVED or REJECTED")
    private String action; // APPROVED, REJECTED, ON_HOLD

    private String remarks;

    // Optional flag: if true, admin must review POD photos before approving
    private Boolean podPhotosReviewed;

    // Optional flag: if true, create rework notification for driver
    private Boolean requireRework;
}
