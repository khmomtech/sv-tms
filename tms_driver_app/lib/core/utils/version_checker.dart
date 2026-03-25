import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/core.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionChecker extends StatefulWidget {
  final String apiBaseUrl;
  final Duration delayBeforeCheck;

  const VersionChecker(
      {super.key,
      required this.apiBaseUrl,
      this.delayBeforeCheck = const Duration(seconds: 2)});

  @override
  State<VersionChecker> createState() => _VersionCheckerState();
}

class _VersionCheckerState extends State<VersionChecker> {
  static const String _lastCheckKey = 'last_version_check';

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delayBeforeCheck, _checkVersionIfNeeded);
  }

  Future<void> _checkVersionIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastCheck > const Duration(hours: 24).inMilliseconds) {
      await _checkVersion();
      await prefs.setInt(_lastCheckKey, now);
    }
  }

  Future<void> _checkVersion() async {
    final latest = await _fetchLatestVersion();
    if (latest != null) {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      late String latestVersion;
      late bool mandatoryUpdate;
      late String storeUrl;
      late String releaseNoteEn;
      late String releaseNoteKm;

      if (defaultTargetPlatform == TargetPlatform.android) {
        latestVersion = latest['androidLatestVersion'] ?? '';
        mandatoryUpdate = latest['androidMandatoryUpdate'] ?? false;
        storeUrl = latest['playstoreUrl'] ?? '';
        releaseNoteEn = latest['androidReleaseNoteEn'] ?? '';
        releaseNoteKm = latest['androidReleaseNoteKm'] ?? '';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        latestVersion = latest['iosLatestVersion'] ?? '';
        mandatoryUpdate = latest['iosMandatoryUpdate'] ?? false;
        storeUrl = latest['appstoreUrl'] ?? '';
        releaseNoteEn = latest['iosReleaseNoteEn'] ?? '';
        releaseNoteKm = latest['iosReleaseNoteKm'] ?? '';
      }

      if (latestVersion.isNotEmpty &&
          _isVersionLower(currentVersion, latestVersion)) {
        _showUpdateDialog(
            mandatoryUpdate, storeUrl, releaseNoteEn, releaseNoteKm);
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestVersion() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/public/app-version/latest'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to fetch latest version: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching version: $e');
    }
    return null;
  }

  bool _isVersionLower(String current, String latest) {
    final List<int> c = current.split('.').map(int.parse).toList();
    final List<int> l = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < l.length; i++) {
      if (i >= c.length || c[i] < l[i]) return true;
      if (c[i] > l[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(bool mandatoryUpdate, String storeUrl,
      String releaseNoteEn, String releaseNoteKm) {
    showDialog(
      context: context,
      barrierDismissible: !mandatoryUpdate,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A new version of the app is available.\n'),
                const Text('Release Notes (EN):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(releaseNoteEn),
                const SizedBox(height: 8),
                const Text('Release Notes (KH):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(releaseNoteKm),
              ],
            ),
          ),
          actions: [
            if (!mandatoryUpdate)
              TextButton(
                child: const Text('Later'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            TextButton(
              child: const Text('Update Now'),
              onPressed: () {
                Navigator.of(context).pop();
                launchUrl(Uri.parse(storeUrl));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
