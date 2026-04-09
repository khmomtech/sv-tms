// lib/providers/about_app_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/constants/app_constants.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/about_app_info.dart';

class AboutAppProvider with ChangeNotifier {
  static const String _cacheKey = 'about_app_info_cache';
  AboutAppInfo? _aboutInfo;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUsingFallback = false;

  AboutAppInfo? get aboutInfo => _aboutInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUsingFallback => _isUsingFallback;

  Future<void> fetchAboutInfo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await ApiConstants.getHeaders();
      final uris = [
        ApiConstants.endpoint('/about-app'),
        // Public compatibility route (explicitly allowed on many deployments).
        ApiConstants.endpoint('/public/about-app'),
      ];

      http.Response? response;
      for (final uri in uris) {
        final res = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          response = res;
          break;
        }
        if (res.statusCode == 401 || res.statusCode == 403) {
          // Try next fallback route, if any.
          continue;
        }
      }

      if (response != null && response.statusCode == 200) {
        final decoded = jsonDecode(
            utf8.decode(response.bodyBytes)); // safe decode Khmer text
        final raw = _extractPayload(decoded);
        if (raw != null) {
          _aboutInfo = AboutAppInfo.fromJson(raw);
          _isUsingFallback = false;
          await _saveToCache(_aboutInfo!);
        } else {
          _setFallback('Invalid about payload from server');
        }
      } else {
        _setFallback('No accessible about endpoint');
      }
    } catch (e) {
      _setFallback('Exception fetching about info: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic>? _extractPayload(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      // Support both direct payload and ApiResponse-style wrapper.
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      return decoded;
    }
    return null;
  }

  Future<void> _setFallback(String reason) async {
    debugPrint('Error loading About Info: $reason');
    _errorMessage = reason;

    final cached = await _loadFromCache();
    if (cached != null) {
      _aboutInfo = cached;
      _isUsingFallback = true;
      return;
    }

    _aboutInfo = _defaultFallbackInfo();
    _isUsingFallback = true;
  }

  AboutAppInfo _defaultFallbackInfo() {
    return AboutAppInfo(
      appNameKm: 'កម្មវិធីបើកបរ SV TMS',
      appNameEn: AppConstants.appName,
      androidVersion: AppConstants.appVersion,
      iosVersion: AppConstants.appVersion,
      contactEmail: 'support@svtrucking.biz',
      privacyPolicyUrlKm: 'https://svtrucking.biz/privacy',
      privacyPolicyUrlEn: 'https://svtrucking.biz/privacy',
      termsConditionsUrlKm: 'https://svtrucking.biz/terms',
      termsConditionsUrlEn: 'https://svtrucking.biz/terms',
    );
  }

  Future<void> _saveToCache(AboutAppInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(info.toJson()));
  }

  Future<AboutAppInfo?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AboutAppInfo.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
