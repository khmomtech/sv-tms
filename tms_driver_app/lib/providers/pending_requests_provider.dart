import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

class PendingRequestsProvider with ChangeNotifier {
  List<Map<String, String>> _pendingRequests = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Map<String, String>> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchPendingRequests() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      final baseUrl = prefs.getString('apiUrl') ?? ApiConstants.baseUrl;
      final userId = prefs.getString('userId') ?? '';

      if (accessToken.isEmpty || userId.isEmpty) {
        _errorMessage = 'User not authenticated. Please log in.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/selfservice/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(utf8.decode(response.bodyBytes));

        if (jsonData is List) {
          _pendingRequests = jsonData.map((leave) {
            return {
              'type': leave['leaveType']?.toString() ?? 'Unknown',
              'startDate': leave['startDate']?.toString() ?? '--',
              'endDate': leave['endDate']?.toString() ?? '--',
              'status': leave['status']?.toString() ?? 'Pending',
            };
          }).toList();
        } else {
          _pendingRequests = [];
          debugPrint('Unexpected data format: ${json.encode(jsonData)}');
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage = 'Error fetching leave requests: ${response.statusCode}';
        debugPrint('API Error Response: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      debugPrint('Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
