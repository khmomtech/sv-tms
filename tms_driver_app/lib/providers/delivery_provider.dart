import 'package:flutter/material.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/network/api_response.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';

class DeliveryProvider with ChangeNotifier {
  List<Map<String, dynamic>> _deliveries = [];
  final DioClient _client = DioClient();

  List<Map<String, dynamic>> get deliveries => _deliveries;

  Future<void> fetchDeliveries(String driverId) async {
    final path = ApiConstants.endpoint('/deliveries').path;
    try {
      final ApiResponse<List<dynamic>> res = await _client.get<List<dynamic>>(
        path,
        queryParameters: {'driverId': driverId},
        converter: (data) => (data as List?) ?? <dynamic>[],
      );
      if (res.success) {
        _deliveries =
            res.data!.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        notifyListeners();
      } else {
        debugPrint('Failed to fetch deliveries: ${res.statusCode} ${res.message}');
      }
    } catch (e) {
      debugPrint('Error fetching deliveries: $e');
    }
  }

  Future<void> updateDeliveryStatus(String taskId, String newStatus) async {
    try {
      final ApiResponse<Map<String, dynamic>> res =
          await _client.post<Map<String, dynamic>>(
        ApiConstants.endpoint('/deliveries/update_status').path,
        data: {'taskId': taskId, 'status': newStatus},
        parser: (raw) => (raw as Map?)?.cast<String, dynamic>() ?? {},
      );
      if (res.success) {
        final index =
            _deliveries.indexWhere((delivery) => delivery['taskId'] == taskId);
        if (index != -1) {
          _deliveries[index]['status'] = newStatus;
          notifyListeners();
        }
      } else {
        debugPrint('Failed to update delivery status: ${res.statusCode} ${res.message}');
      }
    } catch (e) {
      debugPrint('Error updating delivery status: $e');
    }
  }
}
