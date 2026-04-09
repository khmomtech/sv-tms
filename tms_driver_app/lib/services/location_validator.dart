// 📁 lib/services/location_validator.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// Enhanced location spoofing detection with multiple heuristics
class LocationValidator {
  static const double _maxReasonableSpeedMps = 55.0; // ~200 km/h (trucks max ~120 km/h)
  static const double _maxReasonableAccelerationMps2 = 10.0; // Max truck acceleration
  // TODO: Implement satellite count validation when platform channels support it
  // static const int _minSatellites = 4; // GPS needs ≥4 satellites for fix
  static const int _perfectAccuracyThreshold = 10; // Track consecutive perfect readings
  
  Position? _lastPosition;
  DateTime? _lastTime;
  double? _lastSpeed;
  int _perfectAccuracyCount = 0;
  
  final List<String> _suspiciousProviders = [
    'fused',  // Some spoofing apps use this
    'mock',
    'test',
  ];
  
  /// Returns null if valid, error message if suspicious
  String? validateLocation(Position pos) {
    // 1. Direct mock flag (primary check)
    if (pos.isMocked) {
      _resetTracking();
      return 'Location has mock flag set';
    }
    
    // 2. Provider name check (Android only)
    if (Platform.isAndroid) {
      final provider = _getLocationProvider(pos);
      if (_suspiciousProviders.any((p) => provider?.toLowerCase().contains(p) ?? false)) {
        _resetTracking();
        return 'Suspicious location provider: $provider';
      }
    }
    
    // 3. Impossible speed detection
    if (_lastPosition != null && _lastTime != null) {
      final distance = _haversine(_lastPosition!, pos);
      final timeDiff = pos.timestamp.difference(_lastTime!).inSeconds;
      if (timeDiff > 0) {
        final speedMps = distance / timeDiff;
        if (speedMps > _maxReasonableSpeedMps) {
          _resetTracking();
          return 'Impossible speed detected: ${(speedMps * 3.6).toStringAsFixed(1)} km/h';
        }
        
        // 4. Impossible acceleration
        if (_lastSpeed != null) {
          final acceleration = (speedMps - _lastSpeed!) / timeDiff;
          if (acceleration.abs() > _maxReasonableAccelerationMps2) {
            _resetTracking();
            return 'Impossible acceleration detected: ${acceleration.toStringAsFixed(2)} m/s²';
          }
        }
        _lastSpeed = speedMps;
      }
    }
    
    // 5. Accuracy too perfect (spoofing apps often report very low accuracy constantly)
    if (pos.accuracy.isFinite && pos.accuracy < 3.0) {
      _perfectAccuracyCount++;
      if (_perfectAccuracyCount > _perfectAccuracyThreshold) {
        // Real GPS rarely achieves <3m consistently
        return 'Suspiciously perfect accuracy for ${_perfectAccuracyCount} consecutive readings';
      }
    } else {
      _perfectAccuracyCount = 0;
    }
    
    // 6. Speed consistency check
    if (pos.speed.isFinite && pos.speed > 0) {
      if (_lastPosition != null && _lastTime != null) {
        final calculatedSpeed = _haversine(_lastPosition!, pos) / 
            pos.timestamp.difference(_lastTime!).inSeconds;
        final reportedSpeed = pos.speed;
        
        // If reported speed differs significantly from calculated speed
        if ((calculatedSpeed - reportedSpeed).abs() > 20.0) {
          // Allow some variance, but not huge differences
          print('Speed mismatch: reported ${reportedSpeed.toStringAsFixed(1)} m/s, '
              'calculated ${calculatedSpeed.toStringAsFixed(1)} m/s');
        }
      }
    }
    
    _lastPosition = pos;
    _lastTime = pos.timestamp;
    return null; // Valid
  }
  
  void _resetTracking() {
    _lastPosition = null;
    _lastTime = null;
    _lastSpeed = null;
    _perfectAccuracyCount = 0;
  }
  
  String? _getLocationProvider(Position pos) {
    // Platform-specific provider extraction
    // For now, return null - could be enhanced with method channel
    return null;
  }
  
  double _haversine(Position a, Position b) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);
    final sinDlat = math.sin(dLat / 2);
    final sinDlon = math.sin(dLon / 2);
    final c = sinDlat * sinDlat +
        math.cos(_toRadians(a.latitude)) *
        math.cos(_toRadians(b.latitude)) *
        sinDlon * sinDlon;
    return R * 2 * math.asin(math.sqrt(c));
  }
  
  double _toRadians(double deg) => deg * math.pi / 180;
}
