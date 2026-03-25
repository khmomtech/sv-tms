import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'local_storage.dart';

class TransportOrderService {
  static Future<bool> createOrder(int customerId, Map<String, dynamic> payload) async {
    const base = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');
    final url = Uri.parse('$base/api/customers/$customerId/orders');
    try {
      final token = await LocalStorage().getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final res = await http.post(url, headers: headers, body: jsonEncode(payload));
      if (kDebugMode) debugPrint('CreateOrderService: ${res.statusCode} ${res.body}');
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      if (kDebugMode) debugPrint('CreateOrderService error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>?> fetchOrders(int customerId) async {
    const base = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');
    final url = Uri.parse('$base/api/customers/$customerId/orders');
    try {
      final token = await LocalStorage().getToken();
      final headers = {'Accept': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final res = await http.get(url, headers: headers);
      if (kDebugMode) debugPrint('FetchOrders: ${res.statusCode} ${res.body}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> arr = jsonDecode(res.body) as List<dynamic>;
        return arr.map((e) => e as Map<String, dynamic>).toList();
      }
      // Non-success status - surface as null to caller
      if (kDebugMode) debugPrint('FetchOrders non-200: ${res.statusCode}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('FetchOrders error: $e');
      return null;
    }
  }
}
