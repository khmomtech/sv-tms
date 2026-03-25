/// Dispatch status constants and workflow definitions
///
/// This is the single source of truth for dispatch statuses and their transitions.
/// Keep in sync with backend DispatchStateMachine.java
///
/// Complete Status Flow:
/// PLANNED → PENDING → [ASSIGNED/SCHEDULED] → DRIVER_CONFIRMED
///   → ARRIVED_LOADING → [SAFETY_PASSED | SAFETY_FAILED (retry) | IN_QUEUE (bypass)]
///   → IN_QUEUE → LOADING → LOADED → [AT_HUB → HUB_LOADING →] IN_TRANSIT
///   → [IN_TRANSIT_BREAKDOWN → {IN_TRANSIT (recovery) | PENDING_INVESTIGATION}]
///   → ARRIVED_UNLOADING → UNLOADING → UNLOADED → DELIVERED
///   → [FINANCIAL_LOCKED → CLOSED] → COMPLETED
///
/// Safety checkpoint: ARRIVED_LOADING → SAFETY_PASSED/SAFETY_FAILED
///   SAFETY_FAILED is NOT terminal — driver can retry from ARRIVED_LOADING
/// Breakdown path: IN_TRANSIT → IN_TRANSIT_BREAKDOWN → IN_TRANSIT or PENDING_INVESTIGATION
/// Terminal States: COMPLETED, CANCELLED, REJECTED
///
/// Total: 26 dispatch statuses (synced with backend DispatchStateMachine.java)
class DispatchStatus {
  // Prevent instantiation
  DispatchStatus._();

  // ============== All Status Values ==============
  // Use these constants instead of magic strings

  /// Dispatch planned (initial state before pending)
  static const String planned = 'PLANNED';

  /// Dispatch pending for assignment
  static const String pending = 'PENDING';

  /// Dispatch assigned to driver (driver hasn't confirmed yet)
  static const String assigned = 'ASSIGNED';

  /// Driver confirmed they will take this dispatch
  static const String driverConfirmed = 'DRIVER_CONFIRMED';

  /// Scheduled for future date
  static const String scheduled = 'SCHEDULED';

  /// Driver arrived at loading location
  static const String arrivedLoading = 'ARRIVED_LOADING';

  /// Currently loading goods
  static const String loading = 'LOADING';

  /// Goods fully loaded
  static const String loaded = 'LOADED';

  /// At transportation hub for transfer
  static const String atHub = 'AT_HUB';

  /// Loading at hub for transfer
  static const String hubLoading = 'HUB_LOADING';

  /// In queue for loading (waiting)
  static const String inQueue = 'IN_QUEUE';

  /// Vehicle in transit to delivery location
  static const String inTransit = 'IN_TRANSIT';

  /// Vehicle broke down during transit — driver awaits assistance
  static const String inTransitBreakdown = 'IN_TRANSIT_BREAKDOWN';

  /// Dispatch under investigation (e.g. after breakdown escalation or reopen)
  static const String pendingInvestigation = 'PENDING_INVESTIGATION';

  /// Driver arrived at unloading location
  static const String arrivedUnloading = 'ARRIVED_UNLOADING';

  /// Currently unloading goods
  static const String unloading = 'UNLOADING';

  /// Goods fully unloaded
  static const String unloaded = 'UNLOADED';

  /// Delivered to customer
  static const String delivered = 'DELIVERED';

  /// Financial records locked for processing
  static const String financialLocked = 'FINANCIAL_LOCKED';

  /// Dispatch closed (final state before completed)
  static const String closed = 'CLOSED';

  /// Dispatch fully completed
  static const String completed = 'COMPLETED';

  /// Dispatch cancelled
  static const String cancelled = 'CANCELLED';

  /// Dispatch rejected by driver
  static const String rejected = 'REJECTED';

  /// Dispatch approved (after safety checks)
  static const String approved = 'APPROVED';

  /// Safety checks passed
  static const String safetyPassed = 'SAFETY_PASSED';

  /// Safety checks failed
  static const String safetyFailed = 'SAFETY_FAILED';

  // ============== Status Sets for Filtering ==============

  /// Statuses that are pending assignment
  static const Set<String> pendingStatuses = {
    planned,
    pending,
    scheduled,
  };

  /// Statuses where driver action is required
  static const Set<String> assignedStatuses = {
    assigned,
  };

  /// Active statuses (dispatch is in progress)
  static const Set<String> activeStatuses = {
    driverConfirmed,
    arrivedLoading,
    loading,
    loaded,
    atHub,
    hubLoading,
    inQueue,
    inTransit,
    inTransitBreakdown,
    pendingInvestigation,
    arrivedUnloading,
    unloading,
    unloaded,
    approved,
    safetyPassed,
    safetyFailed,
  };

  /// Terminal statuses (no more transitions possible)
  static const Set<String> terminalStatuses = {
    completed,
    cancelled,
    rejected,
  };

  /// Completion flow statuses (after delivery)
  static const Set<String> completionStatuses = {
    delivered,
    financialLocked,
    closed,
  };

  /// All statuses combined
  static const Set<String> allStatuses = {
    planned,
    pending,
    financialLocked,
    closed,
    assigned,
    driverConfirmed,
    scheduled,
    arrivedLoading,
    loading,
    loaded,
    atHub,
    hubLoading,
    inQueue,
    inTransit,
    inTransitBreakdown,
    pendingInvestigation,
    arrivedUnloading,
    unloading,
    unloaded,
    delivered,
    completed,
    cancelled,
    rejected,
    approved,
    safetyPassed,
    safetyFailed,
  };

  // ============== Status Display Names ==============

  static Map<String, String> displayNames = {
    pending: 'Pending',
    assigned: 'Assigned',
    driverConfirmed: 'Driver Confirmed',
    scheduled: 'Scheduled',
    arrivedLoading: 'Arrived at Loading',
    loading: 'Loading',
    loaded: 'Loaded',
    inQueue: 'In Queue',
    inTransit: 'In Transit',
    inTransitBreakdown: 'In Transit - Breakdown',
    pendingInvestigation: 'Pending Investigation',
    arrivedUnloading: 'Arrived at Unloading',
    unloading: 'Unloading',
    unloaded: 'Unloaded',
    delivered: 'Delivered',
    completed: 'Completed',
    cancelled: 'Cancelled',
    rejected: 'Rejected',
    approved: 'Approved',
    safetyPassed: 'Safety Passed',
    safetyFailed: 'Safety Failed',
  };

  /// Get display name for a status
  static String getDisplayName(String status) {
    return displayNames[status] ?? status;
  }

  /// Check if a status is terminal (no more transitions)
  static bool isTerminal(String status) {
    return terminalStatuses.contains(status);
  }

  /// Check if a status is active (in progress)
  static bool isActive(String status) {
    return activeStatuses.contains(status);
  }

  /// Check if a status is pending
  static bool isPending(String status) {
    return pendingStatuses.contains(status);
  }
}

// ============================================================
// STATUS TRANSITIONS - SINGLE SOURCE OF TRUTH
// Mirrors: tms-backend/.../DispatchValidator.java:384-412
// ============================================================

class DispatchTransitions {
  // Prevent instantiation
  DispatchTransitions._();

  /// Map of all valid transitions by current status
  /// Key: Current Status
  /// Value: Set of allowed next statuses
  ///
  /// IMPORTANT: Keep in sync with backend DispatchValidator.isValidTransition()
  static const Map<String, Set<String>> allowedNextStates = {
    DispatchStatus.pending: {
      DispatchStatus.assigned,
      DispatchStatus.scheduled,
      DispatchStatus.cancelled,
    },
    DispatchStatus.scheduled: {
      DispatchStatus.assigned,
      DispatchStatus.cancelled,
    },
    DispatchStatus.assigned: {
      DispatchStatus.driverConfirmed,
      DispatchStatus.cancelled,
      DispatchStatus.rejected,
    },
    DispatchStatus.driverConfirmed: {
      DispatchStatus.arrivedLoading,
      DispatchStatus.cancelled,
    },
    DispatchStatus.inQueue: {
      DispatchStatus.loading,
      DispatchStatus.cancelled,
    },
    DispatchStatus.arrivedLoading: {
      DispatchStatus.safetyPassed,
      DispatchStatus.safetyFailed,
      DispatchStatus.inQueue,
      DispatchStatus.cancelled,
    },
    DispatchStatus.safetyPassed: {
      DispatchStatus.inQueue,
      DispatchStatus.cancelled,
    },
    DispatchStatus.loading: {
      DispatchStatus.loaded,
      DispatchStatus.cancelled,
    },
    DispatchStatus.loaded: {
      DispatchStatus.inTransit,
      DispatchStatus.cancelled,
    },
    DispatchStatus.inTransit: {
      DispatchStatus.arrivedUnloading,
      DispatchStatus.atHub,
      DispatchStatus.inTransitBreakdown,
      DispatchStatus.cancelled,
    },
    DispatchStatus.inTransitBreakdown: {
      DispatchStatus.inTransit,
      DispatchStatus.pendingInvestigation,
      DispatchStatus.cancelled,
    },
    DispatchStatus.pendingInvestigation: {
      DispatchStatus.delivered,
      DispatchStatus.cancelled,
    },
    DispatchStatus.arrivedUnloading: {
      DispatchStatus.unloading,
      DispatchStatus.cancelled,
    },
    DispatchStatus.unloading: {
      DispatchStatus.unloaded,
      DispatchStatus.cancelled,
    },
    DispatchStatus.unloaded: {
      DispatchStatus.delivered,
      DispatchStatus.cancelled,
    },
    DispatchStatus.delivered: {
      DispatchStatus.completed,
    },
    // Terminal states - no transitions
    DispatchStatus.completed: {},
    DispatchStatus.cancelled: {},
    DispatchStatus.rejected: {},
    DispatchStatus.approved: {},
    DispatchStatus.safetyFailed: {
      DispatchStatus.arrivedLoading,
      DispatchStatus.cancelled,
    },
  };

  /// Get allowed next statuses for current status
  static Set<String> getNextStates(String currentStatus) {
    return allowedNextStates[currentStatus] ?? {};
  }

  /// Check if transition is allowed
  static bool canTransition(String from, String to) {
    final nextStates = getNextStates(from);
    return nextStates.contains(to);
  }

  /// Get action button label for a transition
  static Map<String, String> transitionLabels = {
    DispatchStatus.assigned: 'dispatch.confirm.pickup',
    DispatchStatus.arrivedLoading: 'dispatch.action.arrive_loading',
    DispatchStatus.safetyPassed: 'dispatch.action.pass_safety_check',
    DispatchStatus.inQueue: 'dispatch.action.safety_check',
    DispatchStatus.loading: 'dispatch.action.load',
    DispatchStatus.loaded: 'dispatch.action.load_complete',
    DispatchStatus.inTransit: 'dispatch.action.start_transit',
    DispatchStatus.inTransitBreakdown: 'dispatch.action.report_breakdown',
    DispatchStatus.pendingInvestigation: 'dispatch.action.investigation',
    DispatchStatus.arrivedUnloading: 'dispatch.action.arrive_unloading',
    DispatchStatus.unloading: 'dispatch.action.unload',
    DispatchStatus.unloaded: 'dispatch.action.confirm_delivery',
  };

  /// Get i18n label for a status transition
  /// Returns the label for the action button that transitions TO this status
  static String getTransitionLabel(String status) {
    return transitionLabels[status] ?? 'dispatch.action.continue';
  }
}

// ============================================================
// ACTION TYPES - For better type safety than strings
// ============================================================

class DispatchAction {
  // Prevent instantiation
  DispatchAction._();

  static const String accept = 'ACCEPT';
  static const String reject = 'REJECT';
  static const String cancel = 'CANCEL';
  static const String transitionStatus = 'TRANSITION_STATUS';
  static const String uploadProof = 'UPLOAD_PROOF';
}
