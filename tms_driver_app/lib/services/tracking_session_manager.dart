import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

class TrackingSessionManager {
  TrackingSessionManager._();
  static final TrackingSessionManager instance = TrackingSessionManager._();

  Future<bool> ensureTrackingSession({String? deviceIdOverride}) async {
    final token = await ApiConstants.ensureFreshTrackingToken();
    if (token != null && token.isNotEmpty) {
      return true;
    }
    return await startTrackingSession(deviceIdOverride: deviceIdOverride);
  }

  Future<bool> startTrackingSession({String? deviceIdOverride}) async {
    final access = await ApiConstants.ensureFreshAccessToken();
    if (access == null || access.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceId =
        (deviceIdOverride ?? prefs.getString('deviceId') ?? '').trim();
    if (deviceId.isEmpty) {
      debugPrint('[Tracking] missing deviceId for start session');
      return false;
    }

    final uri = ApiConstants.endpoint('/driver/tracking/session/start');
    try {
      final res = await http
          .post(
            uri,
            headers: {
              ...ApiConstants.defaultHeaders,
              'Authorization': 'Bearer $access',
            },
            body: jsonEncode({
              'deviceId': deviceId,
              'appVersion': packageInfo.version,
              'platform': Platform.operatingSystem,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('[Tracking] start failed: ${res.statusCode} ${res.body}');
        return false;
      }
      final raw = json.decode(res.body);
      final payload = (raw is Map && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : (raw is Map<String, dynamic> ? raw : <String, dynamic>{});
      final token =
          (payload['trackingToken'] ?? payload['tracking_token']) as String?;
      final sessionId =
          (payload['sessionId'] ?? payload['session_id']) as String?;
      final expiresAt = payload['expiresAtEpochMs'] ?? payload['expiresAt'];
      final expiresAtMs =
          expiresAt is int ? expiresAt : int.tryParse('$expiresAt');
      if (token == null ||
          token.isEmpty ||
          sessionId == null ||
          sessionId.isEmpty ||
          expiresAtMs == null) {
        return false;
      }
      await ApiConstants.saveTrackingSession(
        trackingToken: token,
        sessionId: sessionId,
        expiresAtMs: expiresAtMs,
      );
      return true;
    } catch (e) {
      debugPrint('[Tracking] start exception: $e');
      return false;
    }
  }

  Future<void> stopTrackingSession() async {
    final token = await ApiConstants.getTrackingToken();
    if (token == null || token.isEmpty) return;
    try {
      final uri = ApiConstants.endpoint('/driver/tracking/session/stop');
      await http.post(
        uri,
        headers: {
          ...ApiConstants.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
