package com.svtrucking.logistics.dto.response;

import com.svtrucking.logistics.enums.DispatchStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Response DTO for dispatch status update operations
 * 
 * Includes available next actions so Flutter UI can dynamically show
 * appropriate action buttons without hardcoding the workflow.
 * 
 * Enhanced in Phase 4 to include rich action metadata for fully
 * backend-driven UI rendering.
 * 
 * @since Phase 2 Refactoring - March 2, 2026
 * @updated Phase 4 - March 3, 2026 - Added action metadata
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DispatchStatusUpdateResponse {

    /**
     * Dispatch ID
     */
    private Long dispatchId;

    /**
     * The previous status (before update)
     */
    private DispatchStatus previousStatus;

    /**
     * The new status (current)
     */
    private DispatchStatus currentStatus;

    /**
     * List of valid next statuses that can be transitioned to from current status
     * Empty if currentStatus is terminal
     * 
     * @deprecated Use availableActions instead for rich metadata
     */
    @Deprecated(since = "Phase 4", forRemoval = false)
    private List<DispatchStatus> availableNextStates;

    /**
     * Rich metadata for each available action
     * Includes labels, icons, colors, validation rules
     * 
     * Client should render buttons based on this list without hardcoding
     * any business logic.
     * 
     * @since Phase 4 - March 3, 2026
     */
    private List<DispatchActionMetadata> availableActions;

    /**
     * Whether current status is a terminal state (no further transitions)
     */
    private boolean isTerminal;

    /**
     * Timestamp of when status was updated
     */
    private LocalDateTime updatedAt;

    /**
     * Reason for status change (if provided)
     */
    private String reason;

    /**
     * Full dispatch DTO with all current data
     */
    private Object dispatch;

    /**
     * Whether the current user (driver) is authorized to perform actions
     * Set to false if dispatch is assigned to different driver
     */
    private boolean canPerformActions;

    /**
     * Message explaining why actions are not available (if applicable)
     */
    private String actionRestrictionMessage;

    /**
     * Effective loading-type policy code on this dispatch.
     */
    private String loadingTypeCode;

    /**
     * Optional loading-type display name.
     */
    private String loadingTypeName;

    /**
     * Pinned workflow version id used for runtime decisions.
     */
    private Long workflowVersionId;

    /**
     * Resolved workflow version id after fallback logic.
     */
    private Long resolvedWorkflowVersionId;
}
