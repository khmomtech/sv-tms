import 'package:flutter_test/flutter_test.dart';
import 'package:tms_driver_app/utils/stop_utils.dart';

void main() {
  group('codeForStop', () {
    test('uses direct code if present', () {
      final stop = {'code': 'ABC', 'name': 'Warehouse'};
      expect(codeForStop(stop), 'ABC');
    });

    test('uses address code when direct code missing', () {
      final stop = {
        'name': 'Warehouse',
        'address': {'code': 'WH1', 'name': 'Warehouse Name'}
      };
      expect(codeForStop(stop), 'WH1');
    });

    test('handles address as plain string', () {
      final stop = {
        'name': 'Drop',
        'address': 'Central Market',
      };
      expect(codeForStop(stop), 'Central Market');
    });

    test('derives short code from name when no code present', () {
      final stop = {
        'name': '',
        'address': {'name': 'Long Name Location'}
      };
      expect(codeForStop(stop), 'LNL');
    });
  });

  group('nameForStop', () {
    test('prefers direct name', () {
      final stop = {'name': 'Pickup A', 'address': {'name': 'Other'}};
      expect(nameForStop(stop), 'Pickup A');
    });

    test('falls back to address name/description', () {
      final stop = {
        'address': {'description': 'Desc', 'address': 'Addr'}
      };
      expect(nameForStop(stop), 'Desc');
    });
  });
}
