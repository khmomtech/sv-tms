import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tms_driver_app/core/network/api_constants.dart';

/// A service class for handling driver-related API calls.
class DriverApiService {
  final http.Client _client;

  DriverApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the current vehicle assignment for the authenticated driver.
  ///
  /// Calls `GET /driver/current-assignment` (self endpoint — driver derived from JWT).
  /// Falls back to `GET /driver/{driverId}/current-assignment` for older backend versions.
  Future<Map<String, dynamic>?> getCurrentAssignment({
    required String driverId,
    required Map<String, String> headers,
  }) async {
    final baseUrl = ApiConstants.baseUrl.trim();
    if (baseUrl.isEmpty) return null;

    final candidates = [
      // Prefer self endpoint (driver context)
      Uri.parse('$baseUrl/driver/current-assignment'),
      // Legacy fallback style (driver id path)
      if (driverId.trim().isNotEmpty)
        Uri.parse('$baseUrl/driver/$driverId/current-assignment'),
      // Admin / backwards compatibility endpoint if driver-facing path missing
      if (driverId.trim().isNotEmpty)
        Uri.parse('$baseUrl/admin/drivers/$driverId/current-assignment'),
    ];

    for (final uri in candidates) {
      try {
        final res = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 8));

        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final decodedBody = jsonDecode(res.body);

          // Standard API wrapper check
          if (decodedBody is Map<String, dynamic>) {
            if (decodedBody.containsKey('success') && decodedBody['success'] == false) {
              debugPrint('getCurrentAssignment: API returned success=false');
              return null;
            }
            if (decodedBody.containsKey('error')) {
              debugPrint('getCurrentAssignment: API returned error=${decodedBody['error']}');
              return null;
            }
          }

          final parsed = _extractResponseDataMap(res.body);
          if (parsed != null && parsed.isNotEmpty) {
            // Normalize to at least one recognized vehicle field (Effective > Temporary > Permanent > Assigned)
            if (!parsed.containsKey('effectiveVehicle')) {
              final fallbackVehicle = parsed['temporaryVehicle'] ?? parsed['permanentVehicle'] ?? parsed['assignedVehicle'];
              if (fallbackVehicle != null && fallbackVehicle is Map<String, dynamic>) {
                parsed['effectiveVehicle'] = fallbackVehicle;
              }
            }

            if (parsed.containsKey('effectiveVehicle') || parsed.containsKey('permanentVehicle') || parsed.containsKey('assignedVehicle')) {
              return parsed;
            }
            debugPrint('getCurrentAssignment: response missing vehicle data');
          }
        }

        // Invalid token — retrying other endpoints won't help.
        if (res.statusCode == 401) {
          debugPrint('getCurrentAssignment: 401 Unauthorized, stopping.');
          return null;
        }

        debugPrint('getCurrentAssignment: $uri → ${res.statusCode}');
      } catch (e) {
        debugPrint('getCurrentAssignment: $uri failed: $e');
      }
    }

    debugPrint('getCurrentAssignment: no successful response.');
    return null;
  }

  /// Fetches the latest known location of a driver from the server.
  Future<Map<String, dynamic>?> getDriverLocation({
    required String driverId,
    required Map<String, String> headers,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/driver/$driverId/latest-location');
      final res = await _client.get(uri, headers: headers);
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return (body['data'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
      }
    } catch (e) {
      debugPrint('Error in getDriverLocation: $e');
    }
    return null;
  }

  /// Extracts the 'data' map from a standard API response.
  Map<String, dynamic>? _extractResponseDataMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map) {
          return data.cast<String, dynamic>();
        }
        // Fallback for responses where the data is at the root.
        if (decoded.containsKey('effectiveVehicle') ||
            decoded.containsKey('permanentVehicle')) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Error decoding response body: $e');
    }
    return null;
  }
}
