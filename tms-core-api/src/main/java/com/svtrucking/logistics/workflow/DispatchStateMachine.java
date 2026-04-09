package com.svtrucking.logistics.workflow;

import com.svtrucking.logistics.dto.response.DispatchActionMetadata;
import com.svtrucking.logistics.dto.response.DispatchActionMetadata.ActionType;
import com.svtrucking.logistics.enums.DispatchStatus;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Dispatch State Machine
 * 
 * Central authority for all valid dispatch status transitions.
 * Single source of truth - keep in sync with Flutter DispatchTransitions class.
 *
 * Replaces scattered transition logic previously in DispatchValidator.java
 * 
 * Design:
 * - Immutable transition map
 * - Compile-time safe (all statuses covered)
 * - Queryable (can ask "what are valid next states?")
 * - Testable
 * 
 * @since Phase 2 Refactoring - March 2, 2026
 */
import java.util.Comparator;
@Slf4j
@Component
public class DispatchStateMachine {

        /**
         * Defines ALL valid state transitions
         * Key: Current Status
         * Value: Set of allowed next statuses
         * Value: Empty set for terminal states
         * 
         * CRITICAL: Must include entries for ALL DispatchStatus enum values
         * even if not all exist in normal workflow (e.g., PLANNED, AT_HUB, etc)
         * to prevent returning empty sets for unknown statuses.
         */
        private static final Map<DispatchStatus, Set<DispatchStatus>> TRANSITIONS = Map.ofEntries(
                        // PLANNED is initial state - can go to PENDING
                        Map.entry(DispatchStatus.PLANNED, Set.of(
                                        DispatchStatus.PENDING,
                                        DispatchStatus.CANCELLED)),

                        // PENDING can go to: ASSIGNED, SCHEDULED, or be CANCELLED
                        Map.entry(DispatchStatus.PENDING, Set.of(
                                        DispatchStatus.ASSIGNED,
                                        DispatchStatus.SCHEDULED,
                                        DispatchStatus.CANCELLED)),

                        // SCHEDULED can go to: ASSIGNED or be CANCELLED
                        Map.entry(DispatchStatus.SCHEDULED, Set.of(
                                        DispatchStatus.ASSIGNED,
                                        DispatchStatus.CANCELLED)),

                        // ASSIGNED can go to: DRIVER_CONFIRMED, CANCELLED, or REJECTED
                        Map.entry(DispatchStatus.ASSIGNED, Set.of(
                                        DispatchStatus.DRIVER_CONFIRMED,
                                        DispatchStatus.CANCELLED,
                                        DispatchStatus.REJECTED)),

                        // DRIVER_CONFIRMED can go to: ARRIVED_LOADING or be CANCELLED
                        // APPROVED is an admin-only action, not driver-initiated
                        Map.entry(DispatchStatus.DRIVER_CONFIRMED, Set.of(
                                        DispatchStatus.ARRIVED_LOADING,
                                        DispatchStatus.CANCELLED)),

                        // APPROVED is a one-way gate: can only proceed to loading or cancel
                        Map.entry(DispatchStatus.APPROVED, Set.of(
                                        DispatchStatus.ARRIVED_LOADING,
                                        DispatchStatus.CANCELLED)),

                        // REJECTED is terminal
                        Map.entry(DispatchStatus.REJECTED, Set.of()),

                        // IN_QUEUE can go to: LOADING or be CANCELLED
                        Map.entry(DispatchStatus.IN_QUEUE, Set.of(
                                        DispatchStatus.LOADING,
                                        DispatchStatus.CANCELLED)),

                        // ARRIVED_LOADING can go to: SAFETY_PASSED or directly to IN_QUEUE
                        // (IN_QUEUE bypass is allowed only when safety gate feature flag is off;
                        // DispatchWorkflowPolicyService enforces the feature-flag guard)
                        Map.entry(DispatchStatus.ARRIVED_LOADING, Set.of(
                                        DispatchStatus.SAFETY_PASSED,
                                        DispatchStatus.SAFETY_FAILED,
                                        DispatchStatus.IN_QUEUE,
                                        DispatchStatus.CANCELLED)),

                        // LOADING can go to: LOADED or be CANCELLED
                        Map.entry(DispatchStatus.LOADING, Set.of(
                                        DispatchStatus.LOADED,
                                        DispatchStatus.CANCELLED)),

                        // LOADED can go to: AT_HUB, IN_TRANSIT or be CANCELLED
                        Map.entry(DispatchStatus.LOADED, Set.of(
                                        DispatchStatus.AT_HUB,
                                        DispatchStatus.IN_TRANSIT,
                                        DispatchStatus.CANCELLED)),

                        // SAFETY_PASSED can go to: IN_QUEUE or be CANCELLED
                        Map.entry(DispatchStatus.SAFETY_PASSED, Set.of(
                                        DispatchStatus.IN_QUEUE,
                                        DispatchStatus.CANCELLED)),

                        // SAFETY_FAILED can retry: driver fixes vehicle and re-presents at loading
                        Map.entry(DispatchStatus.SAFETY_FAILED, Set.of(
                                        DispatchStatus.ARRIVED_LOADING,
                                        DispatchStatus.CANCELLED)),

                        // AT_HUB can go to: HUB_LOADING or IN_TRANSIT or be CANCELLED
                        Map.entry(DispatchStatus.AT_HUB, Set.of(
                                        DispatchStatus.HUB_LOADING,
                                        DispatchStatus.IN_TRANSIT,
                                        DispatchStatus.CANCELLED)),

                        // HUB_LOADING can go to: IN_TRANSIT or be CANCELLED
                        Map.entry(DispatchStatus.HUB_LOADING, Set.of(
                                        DispatchStatus.IN_TRANSIT,
                                        DispatchStatus.CANCELLED)),

                        // IN_TRANSIT can go to: ARRIVED_UNLOADING or AT_HUB or report a breakdown
                        Map.entry(DispatchStatus.IN_TRANSIT, Set.of(
                                        DispatchStatus.ARRIVED_UNLOADING,
                                        DispatchStatus.AT_HUB,
                                        DispatchStatus.IN_TRANSIT_BREAKDOWN,
                                        DispatchStatus.CANCELLED)),

                        // IN_TRANSIT_BREAKDOWN: breakdown resolved → resume, or escalate to
                        // investigation
                        Map.entry(DispatchStatus.IN_TRANSIT_BREAKDOWN, Set.of(
                                        DispatchStatus.IN_TRANSIT,
                                        DispatchStatus.PENDING_INVESTIGATION,
                                        DispatchStatus.CANCELLED)),

                        // PENDING_INVESTIGATION: admin resolves → mark delivered or cancel
                        Map.entry(DispatchStatus.PENDING_INVESTIGATION, Set.of(
                                        DispatchStatus.DELIVERED,
                                        DispatchStatus.CANCELLED)),

                        // ARRIVED_UNLOADING can go to: UNLOADING or be CANCELLED
                        Map.entry(DispatchStatus.ARRIVED_UNLOADING, Set.of(
                                        DispatchStatus.UNLOADING,
                                        DispatchStatus.CANCELLED)),

                        // UNLOADING can go to: UNLOADED or SAFETY_PASSED/SAFETY_FAILED or be CANCELLED
                        Map.entry(DispatchStatus.UNLOADING, Set.of(
                                        DispatchStatus.UNLOADED,
                                        DispatchStatus.SAFETY_PASSED,
                                        DispatchStatus.SAFETY_FAILED,
                                        DispatchStatus.CANCELLED)),

                        // UNLOADED can go to: DELIVERED or be CANCELLED
                        Map.entry(DispatchStatus.UNLOADED, Set.of(
                                        DispatchStatus.DELIVERED,
                                        DispatchStatus.CANCELLED)),

                        // DELIVERED can go to: FINANCIAL_LOCKED or COMPLETED
                        Map.entry(DispatchStatus.DELIVERED, Set.of(
                                        DispatchStatus.FINANCIAL_LOCKED,
                                        DispatchStatus.COMPLETED)),

                        // FINANCIAL_LOCKED can go to: CLOSED or COMPLETED
                        Map.entry(DispatchStatus.FINANCIAL_LOCKED, Set.of(
                                        DispatchStatus.CLOSED,
                                        DispatchStatus.COMPLETED)),

                        // CLOSED can go to: COMPLETED only
                        Map.entry(DispatchStatus.CLOSED, Set.of(
                                        DispatchStatus.COMPLETED)),

                        // Terminal states - no transitions allowed
                        Map.entry(DispatchStatus.COMPLETED, Set.of()),
                        Map.entry(DispatchStatus.CANCELLED, Set.of()));

        /**
         * Terminal statuses - no further transitions possible
         */
        private static final Set<DispatchStatus> TERMINAL_STATUSES = Set.of(
                        DispatchStatus.COMPLETED,
                        DispatchStatus.CANCELLED,
                        DispatchStatus.REJECTED);

        public Set<DispatchStatus> getNextStates(DispatchStatus currentStatus) {
                if (currentStatus == null) {
                        return Set.of();
                }
                return TRANSITIONS.getOrDefault(currentStatus, Set.of());
        }

        /**
         * Check if a transition is valid
         *
         * @param fromStatus Current status
         * @param toStatus   Target status
         * @return true if transition is allowed, false otherwise
         */
        public boolean canTransition(DispatchStatus fromStatus, DispatchStatus toStatus) {
                if (fromStatus == null || toStatus == null) {
                        log.warn("Null status in transition check: from={}, to={}", fromStatus, toStatus);
                        return false;
                }

                Set<DispatchStatus> nextStates = getNextStates(fromStatus);
                return nextStates.contains(toStatus);
        }

        /**
         * Check if a status is a terminal state (no further transitions)
         *
         * @param status The status to check
         * @return true if status is terminal, false otherwise
         */
        public boolean isTerminal(DispatchStatus status) {
                if (status == null) {
                        return false;
                }
                return TERMINAL_STATUSES.contains(status);
        }

        /**
         * Check if a status is active (dispatch in progress)
         *
         * @param status The status to check
         * @return true if status represents active dispatch, false otherwise
         */
        public boolean isActive(DispatchStatus status) {
                if (status == null) {
                        return false;
                }
                return !isTerminal(status) && status != DispatchStatus.PENDING
                                && status != DispatchStatus.SCHEDULED;
        }

        /**
         * Validate a status transition and throw exception if invalid
         * This is the method called by DispatchValidator
         *
         * @param fromStatus Current status
         * @param toStatus   Target status
         * @throws IllegalArgumentException if transition is not allowed
         */
        public void validateTransition(DispatchStatus fromStatus, DispatchStatus toStatus)
                        throws IllegalArgumentException {

                if (fromStatus == null || toStatus == null) {
                        throw new IllegalArgumentException("Status cannot be null");
                }

                if (isTerminal(fromStatus)) {
                        throw new IllegalArgumentException(
                                        String.format("Cannot transition from terminal status %s", fromStatus));
                }

                if (!canTransition(fromStatus, toStatus)) {
                        throw new IllegalArgumentException(
                                        String.format("Invalid status transition from %s to %s", fromStatus, toStatus));
                }
        }

        /**
         * Get all statuses
         *
         * @return All possible dispatch statuses
         */
        public Set<DispatchStatus> getAllStatuses() {
                return TRANSITIONS.keySet();
        }

        /**
         * Get all terminal statuses
         *
         * @return Set of terminal statuses
         */
        public Set<DispatchStatus> getTerminalStatuses() {
                return Set.copyOf(TERMINAL_STATUSES);
        }

        /**
         * Get transition map (read-only for inspection)
         * Useful for logging, documentation, testing
         *
         * @return Immutable copy of transition map
         */
        public Map<DispatchStatus, Set<DispatchStatus>> getTransitionMap() {
                return Map.copyOf(TRANSITIONS);
        }

        /**
         * Get action metadata for all available transitions from current status
         * 
         * This is the KEY method for backend-driven UI approach.
         * Returns rich metadata that tells the client exactly how to render each
         * button.
         * 
         * @param currentStatus Current dispatch status
         * @return List of action metadata, ordered by priority
         * @since Phase 4 - March 3, 2026
         */
        public List<DispatchActionMetadata> getActionMetadata(DispatchStatus currentStatus) {
                if (currentStatus == null) {
                        return List.of();
                }

                Set<DispatchStatus> nextStates = getNextStates(currentStatus);
                if (nextStates.isEmpty()) {
                        return List.of();
                }

                return nextStates.stream()
                                .map(targetStatus -> buildActionMetadata(currentStatus, targetStatus))
                                .sorted(Comparator.comparingInt(DispatchActionMetadata::getPriority))
                                .collect(Collectors.toList());
        }

        /**
         * Build action metadata for a specific status transition
         * 
         * Central place where ALL UI rendering decisions are made.
         * Modify this method to change how actions appear in the mobile app.
         * 
         * @param fromStatus Current status
         * @param toStatus   Target status
         * @return Action metadata
         */
        private DispatchActionMetadata buildActionMetadata(DispatchStatus fromStatus, DispatchStatus toStatus) {
                return DispatchActionMetadata.builder()
                                .targetStatus(toStatus)
                                .actionLabel(getActionLabel(fromStatus, toStatus))
                                .actionType(getActionType(fromStatus, toStatus))
                                .iconName(getIconName(toStatus))
                                .buttonColor(getButtonColor(toStatus))
                                .requiresConfirmation(requiresConfirmation(toStatus))
                                .requiresAdminApproval(requiresAdminApproval(toStatus))
                                .driverInitiated(isDriverInitiated(fromStatus, toStatus))
                                .requiresInput(requiresInput(toStatus))
                                .priority(getPriority(fromStatus, toStatus))
                                .isDestructive(isDestructive(toStatus))
                                .build();
        }

        /**
         * Get user-friendly action label for status transition
         * This is used as translation key on client side: "dispatch.action.{label}"
         */
        private String getActionLabel(DispatchStatus from, DispatchStatus to) {
                // Map specific transitions to action labels
                return switch (to) {
                        case DRIVER_CONFIRMED -> "confirm_pickup";
                        case ARRIVED_LOADING -> "arrive_at_loading";
                        case LOADING -> "start_loading";
                        case LOADED -> "finish_loading";
                        case SAFETY_PASSED -> from == DispatchStatus.ARRIVED_LOADING
                                        ? "get_ticket"
                                        : "pass_safety_check";
                        case AT_HUB -> "arrive_at_hub";
                        case HUB_LOADING -> "start_hub_loading";
                        case IN_TRANSIT -> from == DispatchStatus.LOADED ? "depart_for_delivery"
                                        : from == DispatchStatus.HUB_LOADING ? "depart_from_hub"
                                        : from == DispatchStatus.IN_TRANSIT_BREAKDOWN ? "resume_transit"
                                        : "start_transit";
                        case IN_TRANSIT_BREAKDOWN -> "report_breakdown";
                        case PENDING_INVESTIGATION -> "escalate_to_investigation";
                        case ARRIVED_UNLOADING -> "arrive_at_unloading";
                        case UNLOADING -> "start_unloading";
                        case UNLOADED -> "finish_unloading";
                        case DELIVERED -> "complete_delivery";
                        case COMPLETED -> "mark_completed";
                        case CANCELLED -> "cancel_dispatch";
                        case REJECTED -> "reject_dispatch";
                        case FINANCIAL_LOCKED -> "lock_financials";
                        case CLOSED -> "close_dispatch";
                        case IN_QUEUE -> from == DispatchStatus.SAFETY_PASSED
                                        ? "safety_check"
                                        : "enter_queue";
                        case APPROVED -> "approve_dispatch";
                        case SCHEDULED -> "schedule_dispatch";
                        case ASSIGNED -> "assign_dispatch";
                        case PENDING -> "set_pending";
                        default -> "move_to_" + to.name().toLowerCase();
                };
        }

        /**
         * Get action type for classification
         */
        private ActionType getActionType(DispatchStatus from, DispatchStatus to) {
                return switch (to) {
                        case CANCELLED, REJECTED -> ActionType.DESTRUCTIVE;
                        case ARRIVED_LOADING, ARRIVED_UNLOADING, AT_HUB -> ActionType.ARRIVAL;
                        case LOADING, LOADED, UNLOADING, UNLOADED, HUB_LOADING -> ActionType.OPERATION;
                        case DELIVERED, COMPLETED, CLOSED -> ActionType.COMPLETION;
                        case PENDING, ASSIGNED, SCHEDULED, APPROVED, PENDING_INVESTIGATION -> ActionType.ADMINISTRATIVE;
                        case IN_QUEUE, IN_TRANSIT_BREAKDOWN -> ActionType.OPERATION;
                        default -> ActionType.PROGRESS;
                };
        }

        /**
         * Get Material Icons icon name
         */
        private String getIconName(DispatchStatus status) {
                return switch (status) {
                        case DRIVER_CONFIRMED -> "check_circle";
                        case ARRIVED_LOADING, ARRIVED_UNLOADING -> "location_on";
                        case LOADING, UNLOADING -> "sync";
                        case LOADED, UNLOADED -> "done_all";
                        case IN_TRANSIT -> "local_shipping";
                        case IN_TRANSIT_BREAKDOWN -> "car_crash";
                        case PENDING_INVESTIGATION -> "search";
                        case AT_HUB -> "warehouse";
                        case HUB_LOADING -> "inventory";
                        case DELIVERED -> "verified";
                        case COMPLETED -> "flag";
                        case CANCELLED -> "cancel";
                        case REJECTED -> "block";
                        case SAFETY_PASSED -> "verified_user";
                        case FINANCIAL_LOCKED -> "lock";
                        case CLOSED -> "archive";
                        default -> "arrow_forward";
                };
        }

        /**
         * Get button color (hex format)
         */
        private String getButtonColor(DispatchStatus status) {
                return switch (status) {
                        case CANCELLED, REJECTED -> "#F44336"; // Red
                        case IN_TRANSIT_BREAKDOWN -> "#FF5722"; // Deep Orange - alert
                        case PENDING_INVESTIGATION -> "#FF9800"; // Amber - investigation
                        case DRIVER_CONFIRMED, LOADED, UNLOADED -> "#4CAF50"; // Green
                        case ARRIVED_LOADING, ARRIVED_UNLOADING -> "#FF9800"; // Orange
                        case LOADING, UNLOADING, HUB_LOADING -> "#2196F3"; // Blue
                        case IN_TRANSIT -> "#9C27B0"; // Purple
                        case DELIVERED, COMPLETED -> "#4CAF50"; // Green
                        case SAFETY_PASSED -> "#00C853"; // Bright Green
                        case AT_HUB -> "#673AB7"; // Deep Purple
                        case FINANCIAL_LOCKED, CLOSED -> "#607D8B"; // Blue Grey
                        default -> "#2196F3"; // Default Blue
                };
        }

        /**
         * Whether action requires confirmation dialog
         */
        private boolean requiresConfirmation(DispatchStatus status) {
                return status == DispatchStatus.CANCELLED || status == DispatchStatus.REJECTED
                                || status == DispatchStatus.COMPLETED;
        }

        /**
         * Whether action requires admin approval before execution
         */
        private boolean requiresAdminApproval(DispatchStatus status) {
                // Currently no actions require admin approval
                // Could add: FINANCIAL_LOCKED, CLOSED, etc.
                return false;
        }

        /**
         * Whether action is driver-initiated (vs auto-transition or admin-only)
         */
        private boolean isDriverInitiated(DispatchStatus from, DispatchStatus to) {
                // Most actions are driver-initiated
                // Admin-only would be: ASSIGNED, SCHEDULED, APPROVED, PENDING_INVESTIGATION
                return to != DispatchStatus.ASSIGNED && to != DispatchStatus.SCHEDULED
                                && to != DispatchStatus.APPROVED && to != DispatchStatus.FINANCIAL_LOCKED
                                && to != DispatchStatus.PENDING_INVESTIGATION;
        }

        /**
         * Whether action requires additional input (reason, notes, etc.)
         */
        private boolean requiresInput(DispatchStatus status) {
                return status == DispatchStatus.CANCELLED || status == DispatchStatus.REJECTED
                                || status == DispatchStatus.IN_TRANSIT_BREAKDOWN;
        }

        /**
         * Get action priority for ordering (lower = higher priority)
         */
        private int getPriority(DispatchStatus from, DispatchStatus to) {
                // Destructive actions (cancel/reject) always at bottom
                if (to == DispatchStatus.CANCELLED || to == DispatchStatus.REJECTED) {
                        return 100;
                }

                // Normal progression has highest priority
                if (isNormalProgression(from, to)) {
                        return 1;
                }

                // Sideways moves (queue, hub) have medium priority
                if (to == DispatchStatus.IN_QUEUE || to == DispatchStatus.AT_HUB) {
                        return 50;
                }

                // Everything else
                return 25;
        }

        /**
         * Check if transition represents normal forward progression
         */
        private boolean isNormalProgression(DispatchStatus from, DispatchStatus to) {
                // Define the happy path
                return switch (from) {
                        case ASSIGNED -> to == DispatchStatus.DRIVER_CONFIRMED;
                        case DRIVER_CONFIRMED -> to == DispatchStatus.ARRIVED_LOADING;
                        case ARRIVED_LOADING -> to == DispatchStatus.SAFETY_PASSED;
                        case SAFETY_PASSED -> to == DispatchStatus.IN_QUEUE;
                        case IN_QUEUE -> to == DispatchStatus.LOADING;
                        case LOADING -> to == DispatchStatus.LOADED;
                        case LOADED -> to == DispatchStatus.IN_TRANSIT;
                        case IN_TRANSIT -> to == DispatchStatus.ARRIVED_UNLOADING;
                        case ARRIVED_UNLOADING -> to == DispatchStatus.UNLOADING;
                        case UNLOADING -> to == DispatchStatus.UNLOADED;
                        case UNLOADED -> to == DispatchStatus.DELIVERED;
                        case DELIVERED -> to == DispatchStatus.COMPLETED || to == DispatchStatus.FINANCIAL_LOCKED;
                        case FINANCIAL_LOCKED -> to == DispatchStatus.CLOSED;
                        case CLOSED -> to == DispatchStatus.COMPLETED;
                        default -> false;
                };
        }

        /**
         * Whether action is destructive (cancellation, rejection)
         */
        private boolean isDestructive(DispatchStatus status) {
                return status == DispatchStatus.CANCELLED || status == DispatchStatus.REJECTED;
        }
}
