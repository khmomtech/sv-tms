// Lightweight HTTP wrapper to replace the generated OpenAPI client.
// Provides small compatibility surface used by the app (auth header, list/get orders).

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class GeneratedApiService {
  final String basePath;
  String? _authToken;
  final http.Client _client;
  AuthService? _authService;

  GeneratedApiService({String? basePath})
      : basePath = basePath ?? ApiConstants.baseUrl,
        _client = http.Client();

  void setAuthToken(String? token) {
    _authToken = (token == null || token.isEmpty) ? null : token;
  }

  /// Inject the [AuthService] so that 401 responses can trigger a token refresh.
  void setAuthService(AuthService service) => _authService = service;

  Map<String, String> _defaultHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': ApiConstants.contentTypeJson,
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  /// Performs a GET request and automatically retries once after refreshing
  /// the access token when a 401 Unauthorized response is received.
  Future<http.Response> _getWithRefresh(Uri url) async {
    var resp = await _client
        .get(url, headers: _defaultHeaders())
        .timeout(ApiConstants.receiveTimeout);
    if (resp.statusCode == 401 && _authService != null) {
      final refreshed = await _authService!.refreshAccessToken();
      if (refreshed) {
        _authToken = await _authService!.getToken();
        resp = await _client
            .get(url, headers: _defaultHeaders())
            .timeout(ApiConstants.receiveTimeout);
      }
    }
    return resp;
  }

  /// GET list of orders for a customer. Returns parsed JSON list or null.
  Future<List<dynamic>?> listOrdersForCustomer(int customerId) async {
    final url =
        Uri.parse('$basePath${ApiConstants.customerOrders(customerId)}');
    final resp = await _getWithRefresh(url);
    if (resp.statusCode == 200) {
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) return decoded.cast<dynamic>();
        // Handle wrapped response: {"data": [...]}
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          return (decoded['data'] as List).cast<dynamic>();
        }
      } catch (_) {}
    }
    return null;
  }

  /// GET single order for a customer. Returns parsed JSON map or null.
  Future<Map<String, dynamic>?> getOrder(int customerId, int orderId) async {
    final url = Uri.parse(
        '$basePath${ApiConstants.customerOrder(customerId, orderId)}');
    final resp = await _getWithRefresh(url);
    if (resp.statusCode == 200) {
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }
}
