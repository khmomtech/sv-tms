import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';
import 'package:tms_driver_app/models/maintenance_model.dart';

class MaintenanceProvider with ChangeNotifier {
  final DioClient _dio = DioClient();

  List<MaintenanceTaskModel> _tasks = [];
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  bool _disposed = false;

  List<MaintenanceTaskModel> get tasks => List.unmodifiable(_tasks);

  List<MaintenanceTaskModel> get overdueTasks =>
      _tasks.where((t) => t.isOverdue).toList();

  int get overdueCount => overdueTasks.length;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notifySafely() {
    if (_disposed) return;
    scheduleMicrotask(() {
      if (_disposed) return;
      notifyListeners();
    });
  }

  /// Fetch maintenance tasks for the driver's currently assigned vehicle.
  /// Calls GET /api/driver/maintenance/my-vehicle/tasks
  Future<void> fetchTasks() async {
    _loading = true;
    _error = null;
    _notifySafely();

    try {
      final response = await _dio.get<List<MaintenanceTaskModel>>(
        '/api/driver/maintenance/my-vehicle/tasks',
        converter: (data) {
          // Unwrap ApiResponse envelope: {success, message, data: [...]}
          List<dynamic> raw;
          if (data is Map<String, dynamic> && data['data'] is List) {
            raw = data['data'] as List;
          } else if (data is List) {
            raw = data;
          } else {
            raw = [];
          }
          return raw
              .whereType<Map<String, dynamic>>()
              .map((j) => MaintenanceTaskModel.fromJson(j))
              .toList();
        },
      );

      if (response.success && response.data != null) {
        _tasks = response.data!;
        _error = null;
      } else {
        _error = response.message ?? 'Failed to load maintenance tasks';
      }
    } catch (e) {
      _error = 'Failed to load maintenance tasks';
    } finally {
      _loading = false;
      _notifySafely();
    }
  }

  /// Submit a new maintenance request for the driver's vehicle.
  /// Calls POST /api/driver/maintenance/requests
  Future<bool> submitRequest({
    required String title,
    required String description,
    required String priority,
    required String requestType,
  }) async {
    _submitting = true;
    _error = null;
    _notifySafely();

    try {
      final payload = jsonEncode({
        'title': title,
        'description': description,
        'priority': priority,
        'requestType': requestType,
      });

      final response = await _dio.post<MaintenanceRequestModel>(
        '/api/driver/maintenance/requests',
        data: payload,
        parser: (raw) => raw is Map<String, dynamic> ? raw : {},
        converter: (data) {
          final map = data is Map<String, dynamic> && data['data'] is Map
              ? data['data'] as Map<String, dynamic>
              : data is Map<String, dynamic>
                  ? data
                  : <String, dynamic>{};
          return MaintenanceRequestModel.fromJson(map);
        },
      );

      if (response.success) {
        return true;
      } else {
        _error = response.message ?? 'Failed to submit request';
        return false;
      }
    } catch (e) {
      _error = 'Failed to submit maintenance request';
      return false;
    } finally {
      _submitting = false;
      _notifySafely();
    }
  }
}
