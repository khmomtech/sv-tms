import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'local_storage.dart';

/// Static service for customer-facing incident data.
/// Read-only — customers can view but not create or modify incidents.
class IncidentService {
  static Future<List<Map<String, dynamic>>?> fetchIncidents(
      int customerId) async {
    const base = String.fromEnvironment('API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8080');
    // page=0&size=50 — backend uses Spring Data Pageable with @PageableDefault(50)
    final url = Uri.parse(
        '$base/api/customer/$customerId/incidents?page=0&size=50');
    try {
      final token = await LocalStorage().getToken();
      final headers = {'Accept': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final res = await http.get(url, headers: headers);
      if (kDebugMode) {
        debugPrint('FetchIncidents: ${res.statusCode} ${res.body}');
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        // Unwrap ApiResponse envelope: {success, message, data: {content:[...]} }
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          // Paginated response: data = {content: [...], totalElements: ..., ...}
          if (data is Map<String, dynamic> && data['content'] is List) {
            return (data['content'] as List)
                .whereType<Map<String, dynamic>>()
                .toList();
          }
          // Non-paginated fallback (e.g. direct array in data)
          if (data is List) {
            return (data).whereType<Map<String, dynamic>>().toList();
          }
        }
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList();
        }
      }
      if (kDebugMode) {
        debugPrint('FetchIncidents non-200: ${res.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('FetchIncidents error: $e');
      return null;
    }
  }
}
