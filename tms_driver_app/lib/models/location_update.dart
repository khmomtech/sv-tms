// import 'package:geolocator/geolocator.dart';

// class LocationUpdate {
//   final Position position;
//   final int batteryLevel; // 0..100 (or -1 if unknown)

//   /// Canonical UTC timestamp. (Preferred by the rest of the app)
//   final DateTime timestamp;

//   final bool isBatterySaver; // Battery Saver mode hint
//   final bool isReducedAccuracy; // best-effort hint (iOS reduced precision)
//   final bool isKeepAlive; // true when sent as stationary keep-alive ping

//   /// Constructor supports both `timestamp` and legacy `timestampUtc` (either or).
//   const LocationUpdate({
//     required this.position,
//     this.batteryLevel = -1,
//     DateTime? timestamp,
//     DateTime? timestampUtc, // legacy alias
//     this.isBatterySaver = false,
//     this.isReducedAccuracy = false,
//     this.isKeepAlive = false,
//   }) : timestamp = (timestamp ?? timestampUtc ?? DateTime.now().toUtc());

//   /// Legacy alias getter to avoid breaking older call sites.
//   DateTime get timestampUtc => timestamp;

//   /// Convenience accessors
//   double get latitude => position.latitude;
//   double get longitude => position.longitude;

//   Map<String, dynamic> toJson() {
//     // Normalize speed to km/h; floor tiny drift, cap extremes.
//     double? speedKmh;
//     if (position.speed.isFinite && position.speed >= 0) {
//       speedKmh = (position.speed * 3.6);
//       if (speedKmh < 2.0) speedKmh = 0.0; // <2 km/h → 0
//       if (speedKmh > 180.0) speedKmh = 180.0;
//     }

//     return {
//       "latitude": position.latitude,
//       "longitude": position.longitude,

//       // Backward + forward compatibility (server may read either):
//       "speed": speedKmh, // km/h
//       "clientSpeedKmh": speedKmh, // km/h (preferred)

//       "accuracyMeters": position.accuracy.isFinite ? position.accuracy : null,
//       "heading": position.heading.isFinite ? position.heading : null,
//       "speedAccuracy":
//           position.speedAccuracy.isFinite ? position.speedAccuracy : null,
//       "isMocked": position.isMocked,

//       "batteryLevel": batteryLevel,
//       "batterySaver": isBatterySaver,
//       "reducedAccuracy": isReducedAccuracy,

//       // Canonical timestamp field used across the app:
//       "timestamp": timestamp.toIso8601String(),
//       "timestampEpochMs": timestamp.millisecondsSinceEpoch,

//       "keepAlive": isKeepAlive,
//       "source": "FLUTTER",
//     };
//   }

//   @override
//   String toString() =>
//       'LocationUpdate(lat=${position.latitude}, lng=${position.longitude}, '
//       'spd=${position.speed}, acc=${position.accuracy}, bat=$batteryLevel, '
//       'saver=$isBatterySaver, reduced=$isReducedAccuracy, keepAlive=$isKeepAlive, '
//       't=$timestamp)';
// }
