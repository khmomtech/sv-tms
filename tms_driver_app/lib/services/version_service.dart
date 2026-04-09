// lib/services/version_service.dart (only the relevant bits)
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/models/version_info.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionService {
  final String apiBaseUrl;
  VersionService({required this.apiBaseUrl});

  Future<String> currentVersion() async =>
      (await PackageInfo.fromPlatform()).version;
  Future<String> currentBuild() async =>
      (await PackageInfo.fromPlatform()).buildNumber;

  // Fetch latest with simple cache (optional)
  Future<VersionInfo?> loadLatest({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'version_cache_json';
    if (!force) {
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          return VersionInfo.fromJson(jsonDecode(cached));
        } catch (_) {}
      }
    }
    try {
      final uri = Uri.parse('$apiBaseUrl/public/app-version/latest');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes);
        if (body.trim().isEmpty) {
          return null;
        }
        try {
          final json = jsonDecode(body);
          final info = VersionInfo.fromJson(json);
          await prefs.setString(cacheKey, jsonEncode(json));
          return info;
        } catch (_) {
          // Ignore malformed payloads to avoid noisy logs
          return null;
        }
      }
    } catch (e) {
      debugPrint('Version load failed: $e');
    }
    return null;
  }

  /// Mandatory block if backend says so OR current < minSupportedVersion
  Future<bool> isMandatoryBlock(VersionInfo info) async {
    if (info.mandatoryUpdate) return true;
    final cur = await currentVersion();
    return _isLower(cur, info.minSupportedVersion);
  }

  /// Optional banner if current < latest
  Future<bool> shouldShowUpdate(VersionInfo info) async {
    final cur = await currentVersion();
    return _isLower(cur, info.latestVersion);
  }

  Future<void> openStore(VersionInfo info) async {
    final url =
        info.playStoreUrl.isNotEmpty ? info.playStoreUrl : info.appStoreUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ------- semver-ish compare (major.minor.patch) -------
  bool _isLower(String a, String b) {
    List<int> p(String v) {
      final core = v.split('-').first;
      final s = core.split('.');
      return List<int>.generate(
          3,
          (i) =>
              (i < s.length
                  ? int.tryParse(s[i].replaceAll(RegExp(r'[^0-9]'), ''))
                  : 0) ??
              0);
    }

    try {
      final x = p(a), y = p(b);
      for (var i = 0; i < 3; i++) {
        if (x[i] != y[i]) return x[i] < y[i];
      }
      return false; // equal
    } catch (_) {
      return false;
    }
  }

  // Optional: prevent nagging (store last prompted timestamp/version)
  Future<void> snooze(VersionInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ver_last_prompt',
        '${info.latestVersion}|${DateTime.now().millisecondsSinceEpoch}');
  }
}
