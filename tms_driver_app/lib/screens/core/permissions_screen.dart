// 📁 lib/screen/permissions_screen.dart
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/services/battery_optimization_service.dart';
import 'package:tms_driver_app/services/location_service.dart';
import 'package:tms_driver_app/services/native_service_bridge.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  // Native channels
  static const MethodChannel _batteryChannel =
      MethodChannel('battery_optimization');
  static const MethodChannel _nativeSvc = MethodChannel('sv/native_service');

  String _status = 'Checking…';
  bool _hasFine = false;
  bool _hasBackground = false;
  bool _hasNotif = false;
  bool _ignoringBattery = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void> _checkAll() async {
    try {
      final fineGranted =
          (await Permission.locationWhenInUse.status).isGranted ||
              (await Permission.location.status).isGranted;

      bool bgGranted = true;
      if (Platform.isAndroid) {
        final bg = await Permission.locationAlways.status;
        bgGranted = bg.isGranted;
      }

      final notifGranted = (await Permission.notification.status).isGranted;

      bool ignoring = false;
      if (Platform.isAndroid) {
        try {
          ignoring = await _batteryChannel
                  .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
              false;
        } catch (_) {
          ignoring = false;
        }
      }

      if (!mounted) return;
      setState(() {
        _hasFine = fineGranted;
        _hasBackground = bgGranted;
        _hasNotif = notifGranted;
        _ignoringBattery = ignoring;
        _status = 'Updated';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _requestFine() async {
    final r = await Permission.locationWhenInUse.request();
    if (!r.isGranted && mounted) {
      _snack('Location (while using) denied');
    }
    await _checkAll();
  }

  Future<void> _requestBackground() async {
    if (!Platform.isAndroid) return;
    final r = await Permission.locationAlways.request();
    if (!r.isGranted && mounted) {
      _snack('Background location denied');
    }
    await _checkAll();
  }

  Future<void> _requestNotifications() async {
    final r = await Permission.notification.request();
    if (!r.isGranted && mounted) {
      _snack('Notifications permission denied');
    }
    await _checkAll();
  }

  Future<void> _requestIgnoreBattery() async {
    if (!Platform.isAndroid) return;
    try {
      await _batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      _snack('Battery optimization request failed: $e');
    }
    await _checkAll();
  }

  // (Optional) OEM pages for AutoStart/Whitelist — may not exist on all devices
  Future<void> _openOemAutoStart() async {
    if (!Platform.isAndroid) return;
    try {
      final ok = await _batteryChannel.invokeMethod<bool>('openOemAutoStart');
      if (ok != true) _snack('AutoStart settings not available on this device');
    } catch (_) {
      _snack('AutoStart settings not available on this device');
    }
  }

  Future<void> _openOemWhitelist() async {
    if (!Platform.isAndroid) return;
    try {
      final ok = await _batteryChannel.invokeMethod<bool>('openOemWhitelist');
      if (ok != true) _snack('OEM whitelist page not available on this device');
    } catch (_) {
      _snack('OEM whitelist page not available on this device');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// === Unified flow: request perms → battery ignore → push config → start native FGS → (optional) start Dart sender ===
  Future<void> requestAlwaysLocationPermissionAndStartServices() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // 1) Request foreground location first
      final fg = await Permission.locationWhenInUse.request();
      if (fg.isPermanentlyDenied) {
        if (!mounted) return;
        await _showGoToSettingsDialog(
          title: 'permissions.location_required_title'.tr(),
          message: 'permissions.location_required_message'.tr(),
        );
        return;
      }
      if (!fg.isGranted) {
        _snack('permissions.while_in_use_required'.tr());
        return;
      }

      // 2) Request ALWAYS / background (Android)
      if (Platform.isAndroid) {
        PermissionStatus always = await Permission.locationAlways.request();
        if (always.isDenied) {
          final showRationale =
              await Permission.locationAlways.shouldShowRequestRationale;
          if (showRationale && mounted) {
            final retry = await _showAllowDialog();
            if (retry == true) {
              always = await Permission.locationAlways.request();
            }
          }
        }
        if (always.isPermanentlyDenied) {
          if (!mounted) return;
          await _showGoToSettingsDialog(
            title: 'permissions.background_required_title'.tr(),
            message: 'permissions.background_required_message'.tr(),
          );
          return;
        }
        if (!always.isGranted) {
          _snack('permissions.background_required_snack'.tr());
          return;
        }
      }

      // 3) Notifications (for heads-up + persistent notif channel)
      await Permission.notification.request();

      // 4) Battery optimization
      final ignoring =
          await BatteryOptimizationService.isIgnoringBatteryOptimizations();
      if (!ignoring) {
        await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
      }

      // 5) Push native config (token, api, ws, driver meta)
      await _pushNativeConfig();

      // 6) Start native foreground service (idempotent)
      await _startNativeServiceOnce();

      // 7) (Optional) Start Dart in-app sender too, for redundancy
      await _startDartLocationSender();

      await _checkAll();
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      _snack('permissions.start_flow_failed'.tr(args: [e.toString()]));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pushNativeConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await ApiConstants.ensureFreshAccessToken();
      final driverId = prefs.getString('driverId');

      if (token == null ||
          token.isEmpty ||
          driverId == null ||
          driverId.isEmpty) {
        _snack('Missing driver session — please sign in again.');
        return;
      }

      final baseApi =
          (prefs.getString('apiUrl') ?? ApiConstants.baseUrl).trim();
      final wsPref = (prefs.getString('wsUrl') ?? '').trim();
      String wsUrl;
      if (wsPref.isNotEmpty) {
        final uri = Uri.parse(wsPref);
        final nextParams = Map<String, String>.from(uri.queryParameters)
          ..remove('token')
          ..['token'] = token;
        wsUrl = uri.replace(queryParameters: nextParams).toString();
      } else {
        wsUrl =
            await ApiConstants.getDriverLocationWebSocketUrlWithToken(token);
      }

      final driverName = prefs.getString('driverName');
      final vehiclePlate = prefs.getString('vehiclePlate');

      try {
        await _nativeSvc.invokeMethod('updateConfig', {
          'token': token,
          'driverId': driverId,
          'wsUrl': wsUrl,
          'baseApiUrl': baseApi,
          'driverName': driverName,
          'vehiclePlate': vehiclePlate,
        });
      } on PlatformException {
        // Fallback for older native builds
        await _nativeSvc.invokeMethod('startService', {
          'token': token,
          'driverId': driverId,
          'wsUrl': wsUrl,
          'baseApiUrl': baseApi,
          'driverName': driverName,
          'vehiclePlate': vehiclePlate,
        });
      }
    } catch (e) {
      _snack('Config push failed: $e');
    }
  }

  Future<void> _startNativeServiceOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driverId');
      final token = await ApiConstants.ensureFreshAccessToken();
      if (driverId == null ||
          driverId.isEmpty ||
          token == null ||
          token.isEmpty) {
        _snack('Missing driver session — please sign in again.');
        return;
      }
      final ok = await NativeServiceBridge.startServiceOnce();
      if (ok != true) {
        _snack('Native service did not start');
      }
    } catch (e) {
      _snack('Failed to start native service: $e');
    }
  }

  Future<void> _startDartLocationSender() async {
    // Mirror your in-app Dart sender (optional redundancy)
    try {
      final service = LocationService();
      await service.start(
          accuracy: LocationAccuracy.high, distanceFilterMeters: 10);
    } catch (e) {
      // Non-fatal; native FGS still active
      debugPrint('Dart sender start failed: $e');
    }
  }

  // Legacy WS derivation removed; we rely on ApiConstants for WS URLs

  @override
  Widget build(BuildContext context) {
    final okAll = _hasFine && _hasBackground && _hasNotif && _ignoringBattery;
    return Scaffold(
      appBar: AppBar(title: const Text('Background Tracking Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Status: $_status'),
          const SizedBox(height: 12),

          // Clear guidance card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'When prompted for location permission, choose '
                      '“Allow all the time” (Android) so trips can be tracked while the app is closed.',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          _Tile(
            title: 'Location (While Using the App)',
            ok: _hasFine,
            action: _requestFine,
            subtitle: 'Required for GPS tracking.',
            buttonText: 'Grant',
          ),
          const SizedBox(height: 8),
          _Tile(
            title: 'Background Location (“Allow all the time”)',
            ok: _hasBackground,
            action: _requestBackground,
            subtitle: 'Required to track when the app is closed.',
            buttonText: 'Grant',
          ),
          const SizedBox(height: 8),
          _Tile(
            title: 'Notifications',
            ok: _hasNotif,
            action: _requestNotifications,
            subtitle:
                'Needed for alerts and the persistent tracking notification.',
            buttonText: 'Grant',
          ),
          const SizedBox(height: 8),
          _Tile(
            title: 'Ignore Battery Optimizations',
            ok: _ignoringBattery,
            action: _requestIgnoreBattery,
            subtitle:
                'Prevents the OS from pausing background location updates.',
            buttonText: 'Allow',
          ),

          if (Platform.isAndroid) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openOemAutoStart,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Open AutoStart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openOemWhitelist,
                    icon: const Icon(Icons.format_list_bulleted_add),
                    label: const Text('OEM Whitelist'),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    await requestAlwaysLocationPermissionAndStartServices();
                  },
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_circle_fill),
            label: Text('permissions.continue_start'.tr()),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed:
                okAll && !_busy ? () => Navigator.of(context).maybePop() : null,
            icon: const Icon(Icons.check_circle),
            label: Text('permissions.all_set_continue'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showGoToSettingsDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('permissions.later'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('permissions.open_settings'.tr()),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showAllowDialog() {
    if (!mounted) return Future.value(false);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('permissions.allow_background_title'.tr()),
        content: Text(
          'permissions.allow_background_message'.tr(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('permissions.not_now'.tr())),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('permissions.allow'.tr())),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool ok;
  final VoidCallback action;
  final String buttonText;

  const _Tile({
    required this.title,
    required this.subtitle,
    required this.ok,
    required this.action,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(ok ? Icons.check_circle : Icons.error_outline,
            color: ok ? Colors.green : Colors.orange),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: ok ? null : action,
          child: Text(buttonText),
        ),
      ),
    );
  }
}
