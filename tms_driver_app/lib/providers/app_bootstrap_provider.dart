import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/app_bootstrap_config.dart';

class AppBootstrapProvider with ChangeNotifier {
  static const _kBootstrapCache = 'app_bootstrap_cache_json';
  static const _kBootstrapCacheTs = 'app_bootstrap_cache_ts';
  static const _ttlMs = 10 * 60 * 1000; // 10 minutes

  AppBootstrapConfig? _config;
  bool _isLoading = false;

  AppBootstrapConfig? get config => _config;
  bool get isLoading => _isLoading;

  AppBootstrapProvider() {
    _loadCached();
  }

  bool isScreenVisible(String key, {bool fallback = true}) {
    return _config?.screens[key] ?? fallback;
  }

  bool isFeatureEnabled(String key, {bool fallback = true}) {
    return _config?.features[key] ?? fallback;
  }

  T policy<T>(String key, T fallback) {
    final raw = _config?.policies[key];
    if (raw == null) return fallback;
    if (raw is T) return raw;

    if (fallback is int) {
      final n = int.tryParse(raw.toString());
      if (n != null) return n as T;
    } else if (fallback is double) {
      final n = double.tryParse(raw.toString());
      if (n != null) return n as T;
    } else if (fallback is bool) {
      final lower = raw.toString().toLowerCase();
      final b = lower == 'true' || lower == '1';
      return b as T;
    } else if (fallback is String) {
      return raw.toString() as T;
    }
    return fallback;
  }

  List<String> policyStringList(String key,
      {List<String> fallback = const <String>[]}) {
    final raw = _config?.policies[key];
    if (raw == null) return fallback;

    if (raw is List) {
      final out = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return out.isEmpty ? fallback : out;
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return fallback;

    // Support JSON arrays and comma-separated lists.
    if (text.startsWith('[') && text.endsWith(']')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          final out = decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          return out.isEmpty ? fallback : out;
        }
      } catch (_) {}
    }

    final split = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return split.isEmpty ? fallback : split;
  }

  Future<void> clear() async {
    _config = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBootstrapCache);
      await prefs.remove(_kBootstrapCacheTs);
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> refreshFromServer({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final ts = prefs.getInt(_kBootstrapCacheTs) ?? 0;
      if (!force && (now - ts) < _ttlMs && _config != null) {
        return true;
      }

      final token = await ApiConstants.getAccessToken(logMiss: false);
      if (token == null || token.isEmpty) {
        return false;
      }

      _isLoading = true;
      notifyListeners();

      final uri = ApiConstants.endpoint('/driver-app/bootstrap');
      final response = await http
          .get(
            uri,
            headers: await ApiConstants.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final root = jsonDecode(utf8.decode(response.bodyBytes));
        if (root is Map<String, dynamic>) {
          _config = AppBootstrapConfig.fromJson(root);
          await _persistPolicyHints(prefs, _config!);
          await prefs.setString(
              _kBootstrapCache, jsonEncode(_config!.toJson()));
          await prefs.setInt(_kBootstrapCacheTs, now);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      debugPrint('[AppBootstrap] fetch failed: ${response.statusCode}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AppBootstrap] refresh error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kBootstrapCache);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _config = AppBootstrapConfig.fromJson(decoded);
          await _persistPolicyHints(prefs, _config!);
        }
      }
    } catch (e) {
      debugPrint('[AppBootstrap] cache load error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _persistPolicyHints(
      SharedPreferences prefs, AppBootstrapConfig config) async {
    final refreshSecRaw = config.policies['dashboard.refresh_sec'];
    final refreshSec = int.tryParse(refreshSecRaw?.toString() ?? '');
    if (refreshSec != null && refreshSec >= 10 && refreshSec <= 300) {
      await prefs.setInt('dashboardRefreshSec', refreshSec);
    }

    final mapType = config.policies['map.default_type']?.toString();
    if (mapType != null &&
        const {'normal', 'satellite', 'terrain', 'hybrid'}.contains(mapType)) {
      await prefs.setString('mapType', mapType);
    }

    final bioRaw = config.policies['biometric.quick_unlock_enabled'];
    if (bioRaw != null) {
      final b = bioRaw.toString().toLowerCase();
      await prefs.setBool('biometricQuickUnlock', b == 'true' || b == '1');
    }
  }
}
