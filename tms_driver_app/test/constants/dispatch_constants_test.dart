import 'package:flutter_test/flutter_test.dart';
import 'package:tms_driver_app/constants/dispatch_constants.dart';

void main() {
  group('DispatchStatus Constants', () {
    test('all status constants are unique', () {
      final allStatuses = {
        DispatchStatus.planned,
        DispatchStatus.pending,
        DispatchStatus.financialLocked,
        DispatchStatus.closed,
        DispatchStatus.assigned,
        DispatchStatus.driverConfirmed,
        DispatchStatus.scheduled,
        DispatchStatus.arrivedLoading,
        DispatchStatus.loading,
        DispatchStatus.loaded,
        DispatchStatus.atHub,
        DispatchStatus.hubLoading,
        DispatchStatus.inQueue,
        DispatchStatus.inTransit,
        DispatchStatus.arrivedUnloading,
        DispatchStatus.unloading,
        DispatchStatus.unloaded,
        DispatchStatus.delivered,
        DispatchStatus.completed,
        DispatchStatus.cancelled,
        DispatchStatus.rejected,
        DispatchStatus.approved,
        DispatchStatus.safetyPassed,
        DispatchStatus.safetyFailed,
      };

      expect(allStatuses.length, 24);
    });

    test('terminal statuses are correctly identified', () {
      expect(
          DispatchStatus.terminalStatuses, contains(DispatchStatus.completed));
      expect(
          DispatchStatus.terminalStatuses, contains(DispatchStatus.cancelled));
      expect(
          DispatchStatus.terminalStatuses, contains(DispatchStatus.rejected));
      expect(DispatchStatus.terminalStatuses.length, 3);
    });

    test('active statuses do not include pending', () {
      expect(DispatchStatus.activeStatuses,
          isNot(contains(DispatchStatus.pending)));
      expect(DispatchStatus.activeStatuses,
          isNot(contains(DispatchStatus.assigned)));
      expect(DispatchStatus.activeStatuses, contains(DispatchStatus.inTransit));
    });

    test('isTerminal checks work correctly', () {
      expect(DispatchStatus.isTerminal(DispatchStatus.completed), true);
      expect(DispatchStatus.isTerminal(DispatchStatus.assigned), false);
    });

    test('isActive checks work correctly', () {
      expect(DispatchStatus.isActive(DispatchStatus.inTransit), true);
      expect(DispatchStatus.isActive(DispatchStatus.pending), false);
      expect(DispatchStatus.isActive(DispatchStatus.completed), false);
    });

    test('display names are provided for all statuses', () {
      expect(DispatchStatus.getDisplayName(DispatchStatus.driverConfirmed),
          'Driver Confirmed');
      expect(DispatchStatus.getDisplayName(DispatchStatus.arrivedLoading),
          'Arrived at Loading');
      expect(DispatchStatus.getDisplayName(DispatchStatus.inTransit),
          'In Transit');
    });
  });

  group('DispatchTransitions', () {
    test('ASSIGNED has correct next states', () {
      final nextStates =
          DispatchTransitions.allowedNextStates[DispatchStatus.assigned];

      expect(nextStates, contains(DispatchStatus.driverConfirmed));
      expect(nextStates, contains(DispatchStatus.cancelled));
      expect(nextStates, contains(DispatchStatus.rejected));
      expect(nextStates!.length, 3);
    });

    test('DRIVER_CONFIRMED has correct next states (critical Phase 2)', () {
      final nextStates =
          DispatchTransitions.allowedNextStates[DispatchStatus.driverConfirmed];

      expect(nextStates, contains(DispatchStatus.arrivedLoading));
      expect(nextStates, contains(DispatchStatus.cancelled));
      expect(nextStates, isNot(contains(DispatchStatus.inTransit)));
      expect(nextStates!.length, 2);
    });

    test('getNextStates returns correct values', () {
      final nextStates =
          DispatchTransitions.getNextStates(DispatchStatus.loading);

      expect(nextStates, contains(DispatchStatus.loaded));
      expect(nextStates, contains(DispatchStatus.cancelled));
    });

    test('canTransition validates transitions', () {
      expect(
        DispatchTransitions.canTransition(
            DispatchStatus.assigned, DispatchStatus.driverConfirmed),
        true,
      );

      expect(
        DispatchTransitions.canTransition(
            DispatchStatus.assigned, DispatchStatus.inTransit),
        false,
      );
    });

    test('terminal states have no next states', () {
      final completedNextStates =
          DispatchTransitions.getNextStates(DispatchStatus.completed);
      expect(completedNextStates, isEmpty);

      final cancelledNextStates =
          DispatchTransitions.getNextStates(DispatchStatus.cancelled);
      expect(cancelledNextStates, isEmpty);
    });

    test('transition labels are provided for common states', () {
      expect(
        DispatchTransitions.getTransitionLabel(DispatchStatus.assigned),
        'dispatch.confirm.pickup',
      );

      expect(
        DispatchTransitions.getTransitionLabel(DispatchStatus.arrivedLoading),
        'dispatch.action.arrive_loading',
      );
    });

    test('complete workflow transitions are valid', () {
      // ASSIGNED → DRIVER_CONFIRMED
      expect(
        DispatchTransitions.canTransition(
            DispatchStatus.assigned, DispatchStatus.driverConfirmed),
        true,
      );

      // DRIVER_CONFIRMED → ARRIVED_LOADING
      expect(
        DispatchTransitions.canTransition(
            DispatchStatus.driverConfirmed, DispatchStatus.arrivedLoading),
        true,
      );

      // ARRIVED_LOADING → SAFETY_PASSED
      expect(
        DispatchTransitions.canTransition(
            DispatchStatus.arrivedLoading, DispatchStatus.safetyPassed),
        true,
      );

      // SAFETY_PASSED → IN_QUEUE
      expect(
        DispatchTransitions.canTransition(
            DispatchStatus.safetyPassed, DispatchStatus.inQueue),
        true,
      );

      // IN_QUEUE → LOADING
      expect(
        DispatchTransitions.canTransition(
            DispatchStatus.inQueue, DispatchStatus.loading),
        true,
      );

      // LOADING → LOADED
      expect(
        DispatchTransitions.canTransition(
            DispatchStatus.loading, DispatchStatus.loaded),
        true,
      );
    });
  });

  group('DispatchAction Constants', () {
    test('all action constants are defined', () {
      expect(DispatchAction.accept, 'ACCEPT');
      expect(DispatchAction.reject, 'REJECT');
      expect(DispatchAction.cancel, 'CANCEL');
      expect(DispatchAction.transitionStatus, 'TRANSITION_STATUS');
      expect(DispatchAction.uploadProof, 'UPLOAD_PROOF');
    });
  });
}
