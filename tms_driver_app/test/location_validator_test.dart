import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tms_driver_app/services/location_validator.dart';

void main() {
  test('detects mock flag', () {
    final validator = LocationValidator();
    final pos = Position(
      latitude: 0.0,
      longitude: 0.0,
      accuracy: 5.0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      timestamp: DateTime.now(),
      isMocked: true,
    );

    final res = validator.validateLocation(pos);
    expect(res, isNotNull);
    expect(res!.toLowerCase(), contains('mock'));
  });

  test('detects impossible speed', () {
    final validator = LocationValidator();
    final t0 = DateTime.now();

    final pos1 = Position(
      latitude: 0.0,
      longitude: 0.0,
      accuracy: 5.0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      timestamp: t0,
      isMocked: false,
    );

    // Move ~11km in 1 second -> impossible speed
    final pos2 = Position(
      latitude: 0.1,
      longitude: 0.0,
      accuracy: 5.0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      timestamp: t0.add(const Duration(seconds: 1)),
      isMocked: false,
    );

    expect(validator.validateLocation(pos1), isNull);
    final res = validator.validateLocation(pos2);
    expect(res, isNotNull);
    expect(res!.toLowerCase(), contains('impossible speed'));
  });

  test('detects suspiciously perfect accuracy after threshold', () {
    final validator = LocationValidator();
    final t0 = DateTime.now();

    String? last;
    for (var i = 0; i < 12; i++) {
      final pos = Position(
        latitude: 0.0,
        longitude: 0.0,
        accuracy: 2.0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        timestamp: t0.add(Duration(seconds: i)),
        isMocked: false,
      );
      last = validator.validateLocation(pos);
    }

    expect(last, isNotNull);
    expect(last!.toLowerCase(), contains('suspiciously perfect accuracy'));
  });
}
