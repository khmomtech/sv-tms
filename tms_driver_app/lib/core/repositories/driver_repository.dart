// 📁 lib/core/repositories/driver_repository.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/repositories/base_repository.dart';

/// Repository for driver-related data operations
/// 
/// Handles:
/// - Driver profile management
/// - Vehicle assignments
/// - Location updates
/// - Online status management
class DriverRepository extends BaseRepository {
  final SharedPreferences _prefs;
  
  static const String _profileCacheKey = 'cached_driver_profile';
  static const String _vehiclesCacheKey = 'cached_assigned_vehicles';
  static const String _assignmentCacheKey = 'cached_current_assignment';

  DriverRepository({
    required Dio dio,
    required SharedPreferences prefs,
  })  : _prefs = prefs,
        super(dio: dio);

  // ============================================================
  // Driver Profile Operations
  // ============================================================

  /// Get driver profile by ID with cache fallback
  Future<Map<String, dynamic>?> getDriverProfile(String driverId) async {
    return executeWithRetry(
      () async {
        final response = await dio.get(
          '${ApiConstants.baseUrl}${ApiConstants.driverEndpoints['profile']!.replaceAll('{id}', driverId)}',
        );

        if (response.statusCode == 200 && response.data != null) {
          final profile = response.data as Map<String, dynamic>;
          await _cacheDriverProfile(profile);
          return profile;
        }
        return null;
      },
      label: 'getDriverProfile',
    );
  }

  /// Get cached driver profile (offline support)
  Future<Map<String, dynamic>?> getCachedDriverProfile() async {
    try {
      final cached = _prefs.getString(_profileCacheKey);
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    } catch (e) {
      log('Error reading cached profile: $e');
    }
    return null;
  }

  /// Cache driver profile locally
  Future<void> _cacheDriverProfile(Map<String, dynamic> profile) async {
    try {
      await _prefs.setString(_profileCacheKey, jsonEncode(profile));
    } catch (e) {
      log('Error caching profile: $e');
    }
  }

  // ============================================================
  // Vehicle Assignment Operations
  // ============================================================

  /// Get assigned vehicles for driver
  Future<List<Map<String, dynamic>>> getAssignedVehicles(String driverId) async {
    return executeWithRetry(
      () async {
        final response = await dio.get(
          '${ApiConstants.baseUrl}${ApiConstants.driverEndpoints['assigned-vehicles']!.replaceAll('{id}', driverId)}',
        );

        if (response.statusCode == 200 && response.data != null) {
          final vehicles = List<Map<String, dynamic>>.from(response.data);
          await _cacheAssignedVehicles(vehicles);
          return vehicles;
        }
        return [];
      },
      label: 'getAssignedVehicles',
    );
  }

  /// Get current vehicle assignment (permanent + temporary)
  Future<Map<String, dynamic>?> getCurrentAssignment(String driverId) async {
    return executeWithRetry(
      () async {
        final response = await dio.get(
          '${ApiConstants.baseUrl}${ApiConstants.driverEndpoints['current-assignment']!.replaceAll('{id}', driverId)}',
        );

        if (response.statusCode == 200 && response.data != null) {
          final assignment = response.data as Map<String, dynamic>;
          await _cacheCurrentAssignment(assignment);
          return assignment;
        }
        return null;
      },
      label: 'getCurrentAssignment',
    );
  }

  /// Assign vehicle to driver
  Future<Map<String, dynamic>?> assignVehicle({
    required String driverId,
    required int vehicleId,
  }) async {
    return executeWithRetry(
      () async {
        final response = await dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.driverEndpoints['assign-vehicle']!.replaceAll('{id}', driverId)}',
          data: {'vehicleId': vehicleId},
        );

        if (response.statusCode == 200 && response.data != null) {
          return response.data as Map<String, dynamic>;
        }
        return null;
      },
      label: 'assignVehicle',
    );
  }

  Future<void> _cacheAssignedVehicles(List<Map<String, dynamic>> vehicles) async {
    try {
      await _prefs.setString(_vehiclesCacheKey, jsonEncode(vehicles));
    } catch (e) {
      log('Error caching assigned vehicles: $e');
    }
  }

  Future<void> _cacheCurrentAssignment(Map<String, dynamic> assignment) async {
    try {
      await _prefs.setString(_assignmentCacheKey, jsonEncode(assignment));
    } catch (e) {
      log('Error caching current assignment: $e');
    }
  }

  // ============================================================
  // Location Updates
  // ============================================================

  /// Update driver location
  Future<bool> updateLocation({
    required String driverId,
    required Position position,
    String? deviceId,
  }) async {
    return executeWithRetry(
      () async {
        final locationData = {
          'driverId': int.parse(driverId),
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speedKmh': position.speed * 3.6, // m/s to km/h
          'heading': position.heading,
          'accuracyMeters': position.accuracy,
          'source': 'FLUTTER_ANDROID',
          'locationSource': 'gps',
          'clientTime': DateTime.now().millisecondsSinceEpoch,
        };

        if (deviceId != null) {
          locationData['deviceId'] = deviceId;
        }

        final response = await dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.driverEndpoints['update-location']}',
          data: locationData,
        );

        return response.statusCode == 200;
      },
      label: 'updateLocation',
      maxRetries: 1, // Location updates shouldn't retry too much
    );
  }

  // ============================================================
  // Online Status Management
  // ============================================================

  /// Update driver online status
  Future<bool> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
  }) async {
    return executeWithRetry(
      () async {
        final endpoint = isOnline
            ? ApiConstants.driverEndpoints['go-online']
            : ApiConstants.driverEndpoints['go-offline'];

        final response = await dio.post(
          '${ApiConstants.baseUrl}${endpoint!.replaceAll('{id}', driverId)}',
        );

        return response.statusCode == 200;
      },
      label: 'updateOnlineStatus',
    );
  }

  // ============================================================
  // Cache Management
  // ============================================================

  /// Clear all driver-related cache
  Future<void> clearCache() async {
    await Future.wait([
      _prefs.remove(_profileCacheKey),
      _prefs.remove(_vehiclesCacheKey),
      _prefs.remove(_assignmentCacheKey),
    ]);
  }
}
