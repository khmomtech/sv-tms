import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tms_driver_app/core/network/api_constants.dart';

/// Dashboard Provider
/// Manages dashboard KPI data and statistics
class DashboardKpiProvider with ChangeNotifier {
  // KPI Data
  int _todayTrips = 0;
  int _completedTrips = 0;
  int _pendingTrips = 0;
  int _activeTrips = 0;
  double _todayEarnings = 0.0;
  
  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  int get todayTrips => _todayTrips;
  int get completedTrips => _completedTrips;
  int get pendingTrips => _pendingTrips;
  int get activeTrips => _activeTrips;
  double get todayEarnings => _todayEarnings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch dashboard KPI data for the driver
  Future<void> fetchDashboardKpis({String? driverId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await ApiConstants.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('No access token found');
      }

      // Call backend dashboard API
        final url = driverId != null
          ? '${ApiConstants.baseUrl}/driver/dashboard/$driverId'
          : '${ApiConstants.baseUrl}/dashboard/summary';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _parseKpiData(data);
      } else {
        throw Exception('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching dashboard KPIs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Parse KPI data from API response
  void _parseKpiData(Map<String, dynamic> data) {
    // Handle both direct and nested response formats
    final kpiData = data['data'] ?? data;

    _todayTrips = _parseInt(kpiData['todayTrips']) ?? 
                  _parseInt(kpiData['totalTrips']) ?? 0;
    _completedTrips = _parseInt(kpiData['completedTrips']) ?? 0;
    _pendingTrips = _parseInt(kpiData['pendingTrips']) ?? 0;
    _activeTrips = _parseInt(kpiData['activeTrips']) ?? 0;
    _todayEarnings = _parseDouble(kpiData['todayEarnings']) ?? 
                     _parseDouble(kpiData['totalRevenue']) ?? 0.0;
  }

  /// Helper to safely parse integer values
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper to safely parse double values
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Refresh dashboard data
  Future<void> refresh({String? driverId}) async {
    await fetchDashboardKpis(driverId: driverId);
  }

  /// Clear dashboard data
  void clear() {
    _todayTrips = 0;
    _completedTrips = 0;
    _pendingTrips = 0;
    _activeTrips = 0;
    _todayEarnings = 0.0;
    _error = null;
    notifyListeners();
  }
}
