import 'package:flutter_test/flutter_test.dart';
import 'package:tms_driver_app/models/dispatch_action_metadata.dart';

void main() {
  group('DispatchActionMetadata.fromJson', () {
    test('applies defaults when optional metadata fields are missing', () {
      final metadata = DispatchActionMetadata.fromJson({
        'targetStatus': 'ARRIVED_LOADING',
        'actionLabel': 'arrive_at_loading',
      });

      expect(metadata.targetStatus, 'ARRIVED_LOADING');
      expect(metadata.actionLabel, 'arrive_at_loading');
      expect(metadata.actionType, ActionType.progress);
      expect(metadata.iconName, 'arrow_forward');
      expect(metadata.buttonColor, '#2196F3');
      expect(metadata.requiresConfirmation, isFalse);
      expect(metadata.requiresAdminApproval, isFalse);
      expect(metadata.driverInitiated, isTrue);
      expect(metadata.requiresInput, isFalse);
      expect(metadata.requiredInput, 'NONE');
      expect(metadata.blockedCode, isNull);
      expect(metadata.inputRouteHint, isNull);
      expect(metadata.priority, 50);
      expect(metadata.isDestructive, isFalse);
    });

    test('parses structured blocked input hints for POL/POD flows', () {
      final metadata = DispatchActionMetadata.fromJson({
        'targetStatus': 'IN_TRANSIT',
        'actionLabel': 'depart_for_delivery',
        'blockedCode': 'POL_REQUIRED',
        'requiredInput': 'POL',
        'inputRouteHint': 'LOAD_PROOF',
      });

      expect(metadata.blockedCode, 'POL_REQUIRED');
      expect(metadata.requiredInput, 'POL');
      expect(metadata.inputRouteHint, 'LOAD_PROOF');
    });
  });
}
