import 'package:flutter_test/flutter_test.dart';
import 'package:tms_driver_app/screens/shipment/profile/profile_vm.dart';

void main() {
  group('ProfileVm.fromMaps', () {
    test('maps full name and monthly metrics', () {
      final vm = ProfileVm.fromMaps(
        profile: <String, dynamic>{
          'id': 889210,
          'firstName': 'John',
          'lastName': 'Doe',
          'companyName': 'Global Logistics',
          'profilePictureUrl': 'https://example.com/avatar.jpg',
        },
        monthly: <String, dynamic>{
          'onTimePercent': 95,
          'safetyScore': 'Excellent',
          'totalDistanceMiles': 12500,
        },
        providerDriverId: '889210',
        driverFallback: 'Driver',
        companyFallback: 'Company',
        notAvailable: 'N/A',
      );

      expect(vm.displayName, 'John Doe');
      expect(vm.companyName, 'Global Logistics');
      expect(vm.driverCode, '#889210');
      expect(vm.safeDrivingPercent, 98);
      expect(vm.onTimePercent, 95);
      expect(vm.milesDrivenLabel, '12.5k');
      expect(vm.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('falls back when profile fields are missing', () {
      final vm = ProfileVm.fromMaps(
        profile: const <String, dynamic>{'name': 'Fallback Name'},
        monthly: const <String, dynamic>{},
        providerDriverId: '10',
        driverFallback: 'Driver',
        companyFallback: 'Global Logistics',
        notAvailable: 'N/A',
      );

      expect(vm.displayName, 'Fallback Name');
      expect(vm.companyName, 'Global Logistics');
      expect(vm.driverCode, '#10');
      expect(vm.milesDrivenLabel, 'N/A');
      expect(vm.safeDrivingPercent, 0);
      expect(vm.onTimePercent, 0);
      expect(vm.avatarUrl, isNull);
    });

    test('converts distance from km when miles are unavailable', () {
      final vm = ProfileVm.fromMaps(
        profile: const <String, dynamic>{'id': 7},
        monthly: const <String, dynamic>{'totalDistanceKm': 1000},
        providerDriverId: '7',
        driverFallback: 'Driver',
        companyFallback: 'Company',
        notAvailable: 'N/A',
      );

      expect(vm.milesDrivenLabel, '621');
    });
  });
}
