import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tms_driver_app/services/location_service.dart';

void main() {
  test('LocationUpdate.toJson includes expected fields', () {
    final t0 = DateTime.now().toUtc();
    final pos = Position(
      latitude: 10.0,
      longitude: 20.0,
      accuracy: 4.0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 90,
      headingAccuracy: 0,
      speed: 5.0, // m/s => 18 km/h
      speedAccuracy: 0,
      timestamp: t0,
      isMocked: false,
    );

    final upd = LocationUpdate(
      position: pos,
      batteryLevel: 85,
      timestamp: t0,
      isKeepAlive: false,
      isBatterySaver: false,
    );

    final map = upd.toJson(driverId: 123, driverName: 'Alice', vehiclePlate: 'XYZ-1');

    expect(map['driverId'], 123);
    expect(map['driverName'], 'Alice');
    expect(map['vehiclePlate'], 'XYZ-1');
    expect(map['latitude'], 10.0);
    expect(map['longitude'], 20.0);
    expect(map['batteryLevel'], 85);
    expect(map['isMocked'], false);
    expect(map['clientTime'], isNotNull);
    expect(map['timestampEpochMs'], isA<int>());

    // clientSpeedKmh should be roughly 18.0
    expect((map['clientSpeedKmh'] as num).toDouble(), closeTo(18.0, 0.5));
  });
}
