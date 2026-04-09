package com.svtrucking.logistics.workflow;

import com.svtrucking.logistics.enums.DispatchStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for DispatchStateMachine
 *
 * Verifies:
 * - All state transitions are correctly defined
 * - Terminal states are properly identified
 * - Query methods work correctly
 * - Edge cases are handled
 * - Breakdown / investigation / safety retry paths
 *
 * @since Phase 2 Refactoring - March 2, 2026; expanded Phase 5.1
 */
@DisplayName("Dispatch State Machine Tests")
class DispatchStateMachineTest {

    private DispatchStateMachine stateMachine;

    @BeforeEach
    void setUp() {
        stateMachine = new DispatchStateMachine();
    }

    // -------------------- Existing core tests (fixed) --------------------

    @DisplayName("1. PENDING transitions: ASSIGNED, SCHEDULED, CANCELLED")
    @Test
    void testPendingTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.PENDING);

        assertEquals(3, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.ASSIGNED));
        assertTrue(nextStates.contains(DispatchStatus.SCHEDULED));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));

        assertFalse(nextStates.contains(DispatchStatus.DRIVER_CONFIRMED));
        assertFalse(nextStates.contains(DispatchStatus.DELIVERED));
    }

    @DisplayName("2. ASSIGNED transitions: DRIVER_CONFIRMED, CANCELLED, REJECTED")
    @Test
    void testAssignedTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.ASSIGNED);

        assertEquals(3, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.DRIVER_CONFIRMED));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));
        assertTrue(nextStates.contains(DispatchStatus.REJECTED));
    }

    @DisplayName("3. DRIVER_CONFIRMED transitions: ARRIVED_LOADING, CANCELLED only — APPROVED removed (Phase 1.3)")
    @Test
    void testDriverConfirmedTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.DRIVER_CONFIRMED);

        assertEquals(2, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.ARRIVED_LOADING));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));

        // APPROVED was removed in Phase 1.3 — must NOT be present
        assertFalse(nextStates.contains(DispatchStatus.APPROVED));
        assertFalse(nextStates.contains(DispatchStatus.IN_TRANSIT));
        assertFalse(nextStates.contains(DispatchStatus.LOADING));
        assertFalse(nextStates.contains(DispatchStatus.IN_QUEUE));
    }

    @DisplayName("4. Complete happy path from ASSIGNED → COMPLETED")
    @Test
    void testCompleteWorkflow() {
        assertTrue(stateMachine.canTransition(DispatchStatus.ASSIGNED, DispatchStatus.DRIVER_CONFIRMED));
        assertTrue(stateMachine.canTransition(DispatchStatus.DRIVER_CONFIRMED, DispatchStatus.ARRIVED_LOADING));
        assertTrue(stateMachine.canTransition(DispatchStatus.ARRIVED_LOADING, DispatchStatus.SAFETY_PASSED));
        assertTrue(stateMachine.canTransition(DispatchStatus.SAFETY_PASSED, DispatchStatus.IN_QUEUE));
        assertTrue(stateMachine.canTransition(DispatchStatus.IN_QUEUE, DispatchStatus.LOADING));
        assertTrue(stateMachine.canTransition(DispatchStatus.LOADING, DispatchStatus.LOADED));
        assertTrue(stateMachine.canTransition(DispatchStatus.LOADED, DispatchStatus.IN_TRANSIT));
        assertTrue(stateMachine.canTransition(DispatchStatus.IN_TRANSIT, DispatchStatus.ARRIVED_UNLOADING));
        assertTrue(stateMachine.canTransition(DispatchStatus.ARRIVED_UNLOADING, DispatchStatus.UNLOADING));
        assertTrue(stateMachine.canTransition(DispatchStatus.UNLOADING, DispatchStatus.UNLOADED));
        assertTrue(stateMachine.canTransition(DispatchStatus.UNLOADED, DispatchStatus.DELIVERED));
        assertTrue(stateMachine.canTransition(DispatchStatus.DELIVERED, DispatchStatus.COMPLETED));

        assertFalse(stateMachine.canTransition(DispatchStatus.COMPLETED, DispatchStatus.DELIVERED));
    }

    @DisplayName("5. Invalid transitions are rejected")
    @Test
    void testCanTransitionInvalid() {
        assertFalse(stateMachine.canTransition(DispatchStatus.ASSIGNED, DispatchStatus.LOADING));
        assertFalse(stateMachine.canTransition(DispatchStatus.DRIVER_CONFIRMED, DispatchStatus.IN_TRANSIT));
        assertFalse(stateMachine.canTransition(DispatchStatus.LOADING, DispatchStatus.SAFETY_PASSED));
        assertFalse(stateMachine.canTransition(DispatchStatus.COMPLETED, DispatchStatus.DELIVERED));
        assertFalse(stateMachine.canTransition(DispatchStatus.LOADING, DispatchStatus.ASSIGNED));
    }

    @DisplayName("6. Terminal states return correct transitions (SAFETY_FAILED is NOT terminal)")
    @Test
    void testTerminalStateTransitions() {
        assertTrue(stateMachine.getNextStates(DispatchStatus.COMPLETED).isEmpty());
        assertTrue(stateMachine.getNextStates(DispatchStatus.CANCELLED).isEmpty());
        assertTrue(stateMachine.getNextStates(DispatchStatus.REJECTED).isEmpty());

        // SAFETY_FAILED is a retry state — has transitions back to ARRIVED_LOADING
        Set<DispatchStatus> safetyFailedNext = stateMachine.getNextStates(DispatchStatus.SAFETY_FAILED);
        assertFalse(safetyFailedNext.isEmpty(), "SAFETY_FAILED must not be a dead end");
        assertTrue(safetyFailedNext.contains(DispatchStatus.ARRIVED_LOADING));
        assertTrue(safetyFailedNext.contains(DispatchStatus.CANCELLED));
    }

    @DisplayName("7. isTerminal correctly identifies terminal vs non-terminal states")
    @Test
    void testIsTerminal() {
        assertTrue(stateMachine.isTerminal(DispatchStatus.COMPLETED));
        assertTrue(stateMachine.isTerminal(DispatchStatus.CANCELLED));
        assertTrue(stateMachine.isTerminal(DispatchStatus.REJECTED));

        assertFalse(stateMachine.isTerminal(DispatchStatus.PENDING));
        assertFalse(stateMachine.isTerminal(DispatchStatus.ASSIGNED));
        assertFalse(stateMachine.isTerminal(DispatchStatus.DRIVER_CONFIRMED));
        assertFalse(stateMachine.isTerminal(DispatchStatus.SAFETY_FAILED));
        assertFalse(stateMachine.isTerminal(DispatchStatus.IN_TRANSIT_BREAKDOWN));
    }

    @DisplayName("8. validateTransition throws for invalid transition")
    @Test
    void testValidateTransitionInvalid() {
        Exception ex = assertThrows(IllegalArgumentException.class,
                () -> stateMachine.validateTransition(DispatchStatus.ASSIGNED, DispatchStatus.LOADING));

        assertTrue(ex.getMessage().contains("Invalid status transition"));
    }

    @DisplayName("9. validateTransition does not throw for valid transition")
    @Test
    void testValidateTransitionValid() {
        assertDoesNotThrow(
                () -> stateMachine.validateTransition(DispatchStatus.ASSIGNED, DispatchStatus.DRIVER_CONFIRMED));
    }

    // -------------------- Safety flow --------------------

    @DisplayName("10. SAFETY_PASSED transitions: IN_QUEUE, CANCELLED only")
    @Test
    void testSafetyPassedTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.SAFETY_PASSED);

        assertEquals(2, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.IN_QUEUE));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));
    }

    @DisplayName("11. SAFETY_FAILED is NOT a terminal state")
    @Test
    void testSafetyFailedIsNotTerminal() {
        assertFalse(stateMachine.isTerminal(DispatchStatus.SAFETY_FAILED),
                "SAFETY_FAILED must not be terminal — driver must be able to retry");
    }

    @DisplayName("12. Safety retry path: SAFETY_FAILED → ARRIVED_LOADING is allowed")
    @Test
    void testSafetyRetryPath() {
        assertTrue(stateMachine.canTransition(DispatchStatus.SAFETY_FAILED, DispatchStatus.ARRIVED_LOADING),
                "Driver must be able to re-present after safety failure");
    }

    @DisplayName("13. Safety bypass: ARRIVED_LOADING → IN_QUEUE is allowed (feature-flag enforcement is in policy layer)")
    @Test
    void testArrivedLoadingDirectToInQueue() {
        assertTrue(stateMachine.canTransition(DispatchStatus.ARRIVED_LOADING, DispatchStatus.IN_QUEUE),
                "ARRIVED_LOADING → IN_QUEUE bypass must be in the state machine");
    }

    @DisplayName("14. ARRIVED_LOADING allows SAFETY_PASSED, SAFETY_FAILED, IN_QUEUE, CANCELLED")
    @Test
    void testArrivedLoadingTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.ARRIVED_LOADING);

        assertTrue(nextStates.contains(DispatchStatus.SAFETY_PASSED));
        assertTrue(nextStates.contains(DispatchStatus.SAFETY_FAILED));
        assertTrue(nextStates.contains(DispatchStatus.IN_QUEUE));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));
    }

    // -------------------- Breakdown flow --------------------

    @DisplayName("15. IN_TRANSIT → IN_TRANSIT_BREAKDOWN is allowed")
    @Test
    void testInTransitToBreakdown() {
        assertTrue(stateMachine.canTransition(DispatchStatus.IN_TRANSIT, DispatchStatus.IN_TRANSIT_BREAKDOWN));
    }

    @DisplayName("16. IN_TRANSIT_BREAKDOWN → IN_TRANSIT recovery is allowed")
    @Test
    void testBreakdownRecovery() {
        assertTrue(stateMachine.canTransition(DispatchStatus.IN_TRANSIT_BREAKDOWN, DispatchStatus.IN_TRANSIT),
                "Breakdown must be recoverable (resume transit after repair)");
    }

    @DisplayName("17. IN_TRANSIT_BREAKDOWN → PENDING_INVESTIGATION escalation is allowed")
    @Test
    void testBreakdownEscalation() {
        assertTrue(stateMachine.canTransition(DispatchStatus.IN_TRANSIT_BREAKDOWN,
                DispatchStatus.PENDING_INVESTIGATION));
    }

    @DisplayName("18. PENDING_INVESTIGATION → DELIVERED resolution is allowed")
    @Test
    void testPendingInvestigationResolution() {
        assertTrue(stateMachine.canTransition(DispatchStatus.PENDING_INVESTIGATION, DispatchStatus.DELIVERED));
    }

    @DisplayName("19. IN_TRANSIT_BREAKDOWN transitions: IN_TRANSIT, PENDING_INVESTIGATION, CANCELLED")
    @Test
    void testInTransitBreakdownTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.IN_TRANSIT_BREAKDOWN);

        assertEquals(3, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.IN_TRANSIT));
        assertTrue(nextStates.contains(DispatchStatus.PENDING_INVESTIGATION));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));
    }

    // -------------------- APPROVED gate --------------------

    @DisplayName("20. APPROVED can only proceed to ARRIVED_LOADING or CANCELLED")
    @Test
    void testApprovedTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.APPROVED);

        assertEquals(2, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.ARRIVED_LOADING));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));

        // Must NOT allow backward moves
        assertFalse(nextStates.contains(DispatchStatus.PENDING));
        assertFalse(nextStates.contains(DispatchStatus.ASSIGNED));
        assertFalse(nextStates.contains(DispatchStatus.DRIVER_CONFIRMED));
    }

    @DisplayName("21. DRIVER_CONFIRMED cannot transition to APPROVED (removed in Phase 1.3)")
    @Test
    void testDriverConfirmedNotToApproved() {
        assertFalse(stateMachine.canTransition(DispatchStatus.DRIVER_CONFIRMED, DispatchStatus.APPROVED),
                "DRIVER_CONFIRMED → APPROVED was removed in Phase 1.3 and must not be re-added");
    }

    // -------------------- PLANNED / SCHEDULED --------------------

    @DisplayName("22. PLANNED transitions: PENDING, CANCELLED")
    @Test
    void testPlannedTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.PLANNED);

        assertEquals(2, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.PENDING));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));
    }

    @DisplayName("23. SCHEDULED transitions: ASSIGNED, CANCELLED")
    @Test
    void testScheduledTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.SCHEDULED);

        assertEquals(2, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.ASSIGNED));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));
    }

    // -------------------- Hub flow --------------------

    @DisplayName("24. AT_HUB transitions: HUB_LOADING, IN_TRANSIT, CANCELLED")
    @Test
    void testAtHubTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.AT_HUB);

        assertEquals(3, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.HUB_LOADING));
        assertTrue(nextStates.contains(DispatchStatus.IN_TRANSIT));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));
    }

    @DisplayName("25. HUB_LOADING transitions: IN_TRANSIT, CANCELLED")
    @Test
    void testHubLoadingTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.HUB_LOADING);

        assertEquals(2, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.IN_TRANSIT));
        assertTrue(nextStates.contains(DispatchStatus.CANCELLED));
    }

    // -------------------- Closure path --------------------

    @DisplayName("26. DELIVERED transitions: FINANCIAL_LOCKED, COMPLETED (not CLOSED directly)")
    @Test
    void testDeliveredTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.DELIVERED);

        assertEquals(2, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.FINANCIAL_LOCKED));
        assertTrue(nextStates.contains(DispatchStatus.COMPLETED));
        assertFalse(nextStates.contains(DispatchStatus.CLOSED));
    }

    @DisplayName("27. FINANCIAL_LOCKED transitions: CLOSED, COMPLETED")
    @Test
    void testFinancialLockedTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.FINANCIAL_LOCKED);

        assertEquals(2, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.CLOSED));
        assertTrue(nextStates.contains(DispatchStatus.COMPLETED));
    }

    @DisplayName("28. CLOSED transitions: COMPLETED only")
    @Test
    void testClosedTransitions() {
        Set<DispatchStatus> nextStates = stateMachine.getNextStates(DispatchStatus.CLOSED);

        assertEquals(1, nextStates.size());
        assertTrue(nextStates.contains(DispatchStatus.COMPLETED));
    }

    // -------------------- Null / edge cases --------------------

    @DisplayName("29. Null inputs return false / empty — no NullPointerException")
    @Test
    void testNullInputHandling() {
        assertFalse(stateMachine.canTransition(null, DispatchStatus.ASSIGNED));
        assertFalse(stateMachine.canTransition(DispatchStatus.ASSIGNED, null));
        assertFalse(stateMachine.canTransition(null, null));
        assertFalse(stateMachine.isTerminal(null));

        Set<DispatchStatus> result = stateMachine.getNextStates(null);
        assertNotNull(result);
        assertTrue(result.isEmpty());
    }

    // -------------------- Exhaustive map coverage --------------------

    @DisplayName("30. All DispatchStatus values have an entry in the transition map")
    @Test
    void testAllStatusesCoveredInTransitionMap() {
        Map<DispatchStatus, Set<DispatchStatus>> map = stateMachine.getTransitionMap();
        for (DispatchStatus status : DispatchStatus.values()) {
            assertTrue(map.containsKey(status),
                    "DispatchStatus." + status.name() + " is missing from the transition map");
        }
    }
}
