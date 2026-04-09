// 📁 lib/services/geofence_manager.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class GeofenceRegion {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final GeofenceType type;
  
  GeofenceRegion({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0, // Default 100m radius
    required this.type,
  });
}

enum GeofenceType {
  pickup,
  delivery,
  warehouse,
  restArea,
}

enum GeofenceEvent {
  enter,
  exit,
  dwell, // Inside for >X minutes
}

class GeofenceEventData {
  final String regionId;
  final String regionName;
  final GeofenceEvent event;
  final double distanceFromCenter;
  final DateTime timestamp;
  
  GeofenceEventData({
    required this.regionId,
    required this.regionName,
    required this.event,
    required this.distanceFromCenter,
    required this.timestamp,
  });
}

class GeofenceManager {
  final Map<String, GeofenceRegion> _regions = {};
  final Map<String, bool> _insideState = {}; // Track which regions driver is inside
  final Map<String, DateTime> _enteredAt = {}; // Track entry time for dwell detection
  
  static const double _dwellThresholdMinutes = 2.0; // Consider "arrived" after 2 min
  
  final ValueNotifier<List<GeofenceEventData>> events = ValueNotifier([]);
  
  void addGeofence(GeofenceRegion region) {
    _regions[region.id] = region;
    _insideState[region.id] = false;
    print('📍 Added geofence: ${region.name} (${region.radiusMeters}m radius)');
  }
  
  void removeGeofence(String regionId) {
    final region = _regions.remove(regionId);
    _insideState.remove(regionId);
    _enteredAt.remove(regionId);
    if (region != null) {
      print('📍 Removed geofence: ${region.name}');
    }
  }
  
  void clearAllGeofences() {
    print('📍 Clearing all ${_regions.length} geofences');
    _regions.clear();
    _insideState.clear();
    _enteredAt.clear();
  }
  
  /// Call this with each location update
  List<GeofenceEventData> checkPosition(Position position) {
    final List<GeofenceEventData> triggeredEvents = [];
    
    for (final region in _regions.values) {
      final distance = _haversine(
        position.latitude,
        position.longitude,
        region.latitude,
        region.longitude,
      );
      
      final isInside = distance <= region.radiusMeters;
      final wasInside = _insideState[region.id] ?? false;
      
      if (isInside && !wasInside) {
        // ENTER event
        _insideState[region.id] = true;
        _enteredAt[region.id] = DateTime.now();
        
        final eventData = GeofenceEventData(
          regionId: region.id,
          regionName: region.name,
          event: GeofenceEvent.enter,
          distanceFromCenter: distance,
          timestamp: DateTime.now(),
        );
        triggeredEvents.add(eventData);
        
        print('📍 ENTER: ${region.name} (${distance.toStringAsFixed(0)}m from center)');
        
      } else if (!isInside && wasInside) {
        // EXIT event
        _insideState[region.id] = false;
        _enteredAt.remove(region.id);
        
        final eventData = GeofenceEventData(
          regionId: region.id,
          regionName: region.name,
          event: GeofenceEvent.exit,
          distanceFromCenter: distance,
          timestamp: DateTime.now(),
        );
        triggeredEvents.add(eventData);
        
        print('📍 EXIT: ${region.name}');
        
      } else if (isInside && wasInside) {
        // Check DWELL
        final enteredAt = _enteredAt[region.id];
        if (enteredAt != null) {
          final dwellMinutes = DateTime.now().difference(enteredAt).inMinutes.toDouble();
          if (dwellMinutes >= _dwellThresholdMinutes) {
            final eventData = GeofenceEventData(
              regionId: region.id,
              regionName: region.name,
              event: GeofenceEvent.dwell,
              distanceFromCenter: distance,
              timestamp: DateTime.now(),
            );
            triggeredEvents.add(eventData);
            
            print('📍 DWELL: ${region.name} for ${dwellMinutes.toStringAsFixed(1)} min');
            
            // Reset entered time to avoid repeated dwell events
            _enteredAt[region.id] = DateTime.now();
          }
        }
      }
    }
    
    if (triggeredEvents.isNotEmpty) {
      events.value = triggeredEvents;
    }
    
    return triggeredEvents;
  }
  
  /// Get current status for all regions
  Map<String, bool> getCurrentStatus() {
    return Map.from(_insideState);
  }
  
  /// Check if inside any geofence
  bool isInsideAnyGeofence() {
    return _insideState.values.any((inside) => inside);
  }
  
  /// Get distance to nearest geofence
  double? getDistanceToNearestGeofence(Position position) {
    if (_regions.isEmpty) return null;
    
    double? minDistance;
    for (final region in _regions.values) {
      final distance = _haversine(
        position.latitude,
        position.longitude,
        region.latitude,
        region.longitude,
      );
      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }
  
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.asin(math.sqrt(a));
  }
  
  double _toRadians(double deg) => deg * math.pi / 180;
}
