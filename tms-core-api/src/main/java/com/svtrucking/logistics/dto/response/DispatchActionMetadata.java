package com.svtrucking.logistics.dto.response;

import com.svtrucking.logistics.enums.DispatchStatus;
import java.util.List;
import java.util.Set;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Metadata for a single dispatch action/transition
 * 
 * Provides all information needed by client UI to render action buttons
 * without hardcoding business logic on the client side.
 * 
 * Backend-driven UI approach: Server tells client what actions are available
 * and how to display them.
 * 
 * @since Phase 4 - Dynamic Action Buttons Enhancement - March 3, 2026
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DispatchActionMetadata {

    /**
     * Target status this action will transition to
     */
    private DispatchStatus targetStatus;

    /**
     * User-friendly action label (e.g., "Confirm Pickup", "Start Loading")
     * Localized on client side using this as translation key
     */
    private String actionLabel;

    /**
     * Action type for UI rendering
     */
    private ActionType actionType;

    /**
     * Icon name (Material Icons naming convention)
     * Flutter can map to Icons.{iconName}
     */
    private String iconName;

    /**
     * Suggested button color (hex format)
     */
    private String buttonColor;

    /**
     * Whether this action requires additional confirmation dialog
     */
    private boolean requiresConfirmation;

    /**
     * Whether this action requires admin approval before execution
     */
    private boolean requiresAdminApproval;

    /**
     * Whether this action can be initiated by driver
     * (false means auto-transition or admin-only)
     */
    private boolean driverInitiated;

    /**
     * Whether this action requires additional data/form input
     * (e.g., reason for cancellation, delivery notes)
     */
    private boolean requiresInput;

    /**
     * Optional validation message if action is conditionally available
     */
    private String validationMessage;

    /**
     * Execution priority (lower number = higher priority)
     * Used for button ordering in UI
     */
    private int priority;

    /**
     * Whether this action is destructive (cancellation, rejection)
     */
    private boolean isDestructive;

    /**
     * Actor types allowed by policy for this transition.
     * Values are stringified enum names for API compatibility.
     */
    private Set<String> allowedActorTypes;

    /**
     * Computed permission marker for current authenticated user.
     */
    @Builder.Default
    private boolean allowedForCurrentUser = true;

    /**
     * Optional reason when the action is blocked for current user.
     */
    private String blockedReason;

    /**
     * Optional stable code for blocked action reason (e.g. POL_REQUIRED, POD_REQUIRED).
     */
    private String blockedCode;

    /**
     * Explicit input requirement marker for client routing (NONE, POL, POD).
     */
    @Builder.Default
    private String requiredInput = "NONE";

    /**
     * Optional route hint for client input flow (LOAD_PROOF, UNLOAD_PROOF).
     */
    private String inputRouteHint;

    /**
     * Resolved dispatch workflow template code that produced this action.
     */
    private String templateCode;

    /**
     * Backing transition-rule id when action comes from DB policy.
     */
    private Long ruleId;

    /**
     * Configured statuses where required proof can be submitted.
     */
    private List<DispatchStatus> proofSubmissionAllowedStatuses;

    /**
     * Proof submission mode for client/support visibility.
     */
    private String proofSubmissionMode;

    /**
     * Whether submitted proof requires admin review.
     */
    private boolean proofReviewRequired;

    /**
     * Whether late proof recovery is allowed by policy.
     */
    private boolean allowLateProofRecovery;

    /**
     * Status reached automatically after successful proof submission.
     */
    private DispatchStatus autoAdvanceStatusAfterProof;

    /**
     * Published workflow version id that owns this action.
     */
    private Long workflowVersionId;

    /**
     * Action type classification
     */
    public enum ActionType {
        /**
         * Normal status progression
         */
        PROGRESS,

        /**
         * Arrival at location
         */
        ARRIVAL,

        /**
         * Loading/unloading operations
         */
        OPERATION,

        /**
         * Completion actions
         */
        COMPLETION,

        /**
         * Reversible actions (back to previous state)
         */
        REVERT,

        /**
         * Destructive actions (cancel, reject)
         */
        DESTRUCTIVE,

        /**
         * Administrative actions
         */
        ADMINISTRATIVE
    }
}
