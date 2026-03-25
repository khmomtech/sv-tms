import 'dart:io';

import 'package:dio/dio.dart';

import '../models/dispatch.dart';
import '../models/safety_check.dart';
import 'api_client.dart';

class SafetyService {
  SafetyService(this._client);

  final ApiClient _client;

  Map<String, dynamic>? _unwrapData(Response response) {
    final body = response.data;
    if (body is Map) {
      if (body.containsKey('success') && body['success'] == false) {
        final msg = body['message']?.toString() ?? 'API error';
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: msg,
          message: msg,
        );
      }
      if (body.containsKey('data')) {
        return body['data'] as Map<String, dynamic>?;
      }
      return Map<String, dynamic>.from(body);
    }
    return null;
  }

  Future<DispatchInfo?> fetchDispatch(int dispatchId) async {
    try {
      final response =
          await _client.dio.get('/api/driver/dispatches/$dispatchId');
      final data = _unwrapData(response);
      if (data == null) return null;
      return DispatchInfo.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<DispatchInfo>> fetchDispatchesForDriver(int driverId) async {
    final response = await _client.dio.get(
      '/api/driver/dispatches/filter',
      queryParameters: {'driverId': driverId},
    );
    final body = response.data;
    final List<dynamic> content;
    if (body is Map && body['data'] is Map && body['data']['content'] is List) {
      content = body['data']['content'] as List<dynamic>;
    } else if (body is Map && body['data'] is List) {
      content = body['data'] as List<dynamic>;
    } else {
      content = <dynamic>[];
    }
    final disallowedStatuses = <String>{
      'DELIVERED',
      'COMPLETED',
      'CANCELLED',
      'CANCELED'
    };

    bool _isActive(DispatchInfo d) {
      final status = d.status?.trim().toUpperCase();
      if (status == null || status.isEmpty) return true;
      return !disallowedStatuses.contains(status);
    }

    return content
        .whereType<Map>()
        .map((e) => DispatchInfo.fromJson(Map<String, dynamic>.from(e)))
        .where(_isActive)
        .toList();
  }

  Future<PreLoadingSafetyCheck?> fetchLatest(int dispatchId) async {
    try {
      final response =
          await _client.dio.get('/api/pre-loading-safety/latest/$dispatchId');
      final data = _unwrapData(response);
      if (data == null) return null;
      return PreLoadingSafetyCheck.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(e.message ?? e.toString());
    }
  }

  Future<List<PreLoadingSafetyCheck>> fetchHistory(int dispatchId) async {
    try {
      final response =
          await _client.dio.get('/api/pre-loading-safety/dispatch/$dispatchId');
      final body = response.data;
      final list = (body is Map && body['data'] is List)
          ? body['data'] as List<dynamic>
          : <dynamic>[];
      return list
          .whereType<Map>()
          .map((e) =>
              PreLoadingSafetyCheck.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? e.toString());
    }
  }

  Future<PreLoadingSafetyCheck> submitSafetyCheck(
    SafetyCheckRequest request, {
    List<String>? photoPaths,
  }) async {
    try {
      final response = await _client.dio
          .post('/api/pre-loading-safety', data: request.toJson());
      final data = _unwrapData(response) ?? <String, dynamic>{};
      final saved = PreLoadingSafetyCheck.fromJson(data);

      final files = photoPaths ?? const <String>[];
      for (final path in files) {
        try {
          await uploadPhotoProof(saved.id, path);
        } catch (_) {
          // Photo upload is optional; ignore failures and keep the safety result.
        }
      }
      return saved;
    } on DioException {
      rethrow;
    }
  }

  Future<void> uploadPhotoProof(int safetyCheckId, String photoPath) async {
    final file = File(photoPath);
    if (!file.existsSync()) return;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(photoPath,
          filename: 'safety-proof-$safetyCheckId.jpg'),
    });
    // Endpoint needs backend support; implemented as stub-friendly contract.
    await _client.dio
        .post('/api/pre-loading-safety/$safetyCheckId/proof', data: formData);
  }
}
