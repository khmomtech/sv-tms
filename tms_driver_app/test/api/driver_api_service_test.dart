import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tms_driver_app/services/driver_api_service.dart';

void main() {
  group('DriverApiService', () {
    test('getCurrentAssignment returns assignment data when response is valid', () async {
      final mockClient = MockClient((request) async {
        final body = {
          'success': true,
          'data': {
            'driverId': 30211,
            'permanentVehicle': {
              'id': 100,
              'licensePlate': '1AB-2345',
              'type': 'Truck',
            },
            'effectiveVehicle': {
              'id': 100,
              'licensePlate': '1AB-2345',
              'type': 'Truck',
            }
          }
        };
        return http.Response(jsonEncode(body), 200, headers: {'Content-Type': 'application/json'});
      });

      final api = DriverApiService(client: mockClient);
      final result = await api.getCurrentAssignment(
        driverId: '30211',
        headers: {'Authorization': 'Bearer test-token'},
      );

      expect(result, isNotNull);
      expect(result!['driverId'], 30211);
      expect(result['effectiveVehicle'], isNotNull);
      expect(result['permanentVehicle'], isNotNull);
    });

    test('getCurrentAssignment tries admin endpoint fallback when first candidate returns 404', () async {
      final calls = <String>[];
      final mockClient = MockClient((request) async {
        calls.add(request.url.toString());
        if (request.url.path.endsWith('/driver/current-assignment')) {
          return http.Response('', 404);
        }
        if (request.url.path.endsWith('/driver/30211/current-assignment')) {
          return http.Response('', 404);
        }
        final body = {
          'success': true,
          'data': {
            'driverId': 30211,
            'assignedVehicle': {
              'id': 100,
              'licensePlate': '1AB-2345',
              'type': 'Truck',
            }
          }
        };
        return http.Response(jsonEncode(body), 200, headers: {'Content-Type': 'application/json'});
      });

      final api = DriverApiService(client: mockClient);
      final result = await api.getCurrentAssignment(
        driverId: '30211',
        headers: {'Authorization': 'Bearer test-token'},
      );

      expect(calls.length, 3);
      expect(result, isNotNull);
      expect(result!['effectiveVehicle'], isNotNull);
      expect(result['effectiveVehicle']['licensePlate'], '1AB-2345');
    });

    test('getCurrentAssignment returns null when response has error property', () async {
      final mockClient = MockClient((request) async {
        final body = {
          'success': false,
          'error': 'Driver not assigned',
        };
        return http.Response(jsonEncode(body), 200, headers: {'Content-Type': 'application/json'});
      });

      final api = DriverApiService(client: mockClient);
      final result = await api.getCurrentAssignment(
        driverId: '30211',
        headers: {'Authorization': 'Bearer test-token'},
      );

      expect(result, isNull);
    });

    test('getCurrentAssignment returns null when no vehicle fields are present', () async {
      final mockClient = MockClient((request) async {
        final body = {
          'success': true,
          'data': {
            'driverId': 30211,
            'note': 'No vehicle assigned yet',
          }
        };
        return http.Response(jsonEncode(body), 200, headers: {'Content-Type': 'application/json'});
      });

      final api = DriverApiService(client: mockClient);
      final result = await api.getCurrentAssignment(
        driverId: '30211',
        headers: {'Authorization': 'Bearer test-token'},
      );

      expect(result, isNull);
    });
  });
}
