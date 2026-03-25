// lib/driver_setup_flow.dart
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// One-time setup screen for reliable background tracking.
/// - Requests location (fine) + background location
/// - Requests ignore battery optimizations (via MethodChannel)
/// - Opens OEM auto-start / special access pages (best-effort)
///
/// Usage:
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => DriverSetupFlow(onAllGood: () {
///     Navigator.pop(context); // or go to your Home/Dashboard
///   }),
/// ));
class DriverSetupFlow extends StatefulWidget {
  final VoidCallback onAllGood;
  const DriverSetupFlow({super.key, required this.onAllGood});

  @override
  State<DriverSetupFlow> createState() => _DriverSetupFlowState();
}

class _DriverSetupFlowState extends State<DriverSetupFlow> {
  // Matches your MainActivity channel
  static const MethodChannel _ch = MethodChannel('battery_optimization');

  bool _locFine = false;
  bool _locBg = false;
  bool _batOptOk = false;
  bool _checking = true;

  String _oem = 'Android';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!Platform.isAndroid) {
      setState(() {
        _locFine = _locBg = _batOptOk = true;
        _checking = false;
      });
      widget.onAllGood();
      return;
    }

    final di = DeviceInfoPlugin();
    final and = await di.androidInfo;
    _oem = and.manufacturer;

    // Fine location
    final fine = await Permission.location.status;
    _locFine = fine.isGranted;

    // Background location (Android 10+)
    _locBg = await Permission.locationAlways.isGranted;

    // Battery optimization ignore
    bool ignoring = true;
    try {
      ignoring =
          await _ch.invokeMethod<bool>('isIgnoringBatteryOptimization') ?? true;
    } catch (_) {
      ignoring = true;
    }
    _batOptOk = ignoring;

    setState(() => _checking = false);

    if (_allGood) widget.onAllGood();
  }

  bool get _allGood => _locFine && _locBg && _batOptOk;

  Future<void> _reqFine() async {
    final st = await Permission.location.request();
    if (st.isGranted) {
      setState(() => _locFine = true);
    } else if (st.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _reqBg() async {
    // Android requires: first Fine, then Always
    if (!await Permission.location.isGranted) {
      final st = await Permission.location.request();
      if (!st.isGranted) return;
    }
    final st2 = await Permission.locationAlways.request();
    if (st2.isGranted) {
      setState(() => _locBg = true);
    } else if (st2.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _reqIgnoreBatteryOptimizations() async {
    try {
      // Either method name is supported per your MainActivity patch
      await _ch.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {
      try {
        await _ch.invokeMethod('disableBatteryOptimization');
      } catch (_) {}
    }
    // Optionally open the system list for manual toggle
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      await _ch.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 1));
    await _refresh();
  }

  Future<void> _openOemAutostart() async {
    // Ask native to try OEM pages first
    try {
      await _ch.invokeMethod('openAutoStartSettings');
    } catch (_) {}

    // Fallback intents in Dart if needed:
    final intents = <AndroidIntent>[
      AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS'),
      AndroidIntent(action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM'),
      AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data:
              'package:${Platform.isAndroid ? (const String.fromEnvironment("APPLICATION_ID", defaultValue: "")) : ""}'),
    ];
    for (final i in intents) {
      try {
        await i.launch();
        return;
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        appBar: AppBar(title: const Text('Setup / ការកំណត់')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_allGood) {
      // Parent will pop via onAllGood, but render placeholder to be safe.
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enable Reliable Tracking / បើកការតាមដាន'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(oem: _oem),
          const SizedBox(height: 12),
          _StepTile(
            ok: _locFine,
            title: 'Allow Location (While Using App)',
            titleKm: 'អនុញ្ញាតទីតាំង (ពេលប្រើប្រាស់កម្មវិធី)',
            description: 'We need GPS for live driver tracking.',
            descriptionKm: 'ត្រូវការ GPS សម្រាប់តាមដានអ្នកបើកបរ​នៅពេលពិត។',
            actionText: _locFine ? 'Granted / អនុញ្ញាតរួច' : 'Grant / អនុញ្ញាត',
            onTap: _locFine ? null : _reqFine,
          ),
          _StepTile(
            ok: _locBg,
            title: 'Allow Background Location',
            titleKm: 'អនុញ្ញាតទីតាំងនៅផ្ទៃក្រោយ',
            description: 'Keeps sharing your location when the app is closed.',
            descriptionKm: 'បន្តចែករំលែកទីតាំង ទោះបីបិទកម្មវិធីក៏ដោយ។',
            actionText: _locBg ? 'Granted / អនុញ្ញាតរួច' : 'Grant / អនុញ្ញាត',
            onTap: _locBg ? null : _reqBg,
          ),
          _StepTile(
            ok: _batOptOk,
            title: 'Allow “Ignore Battery Optimizations”',
            titleKm: 'អនុញ្ញាត “មិនគិតបញ្ហាថាមពល”',
            description: 'Prevents Android from pausing GPS in background.',
            descriptionKm: 'ការពារកុំឲ្យ Android ផ្អាក GPS ពេលនៅផ្ទៃក្រោយ។',
            actionText:
                _batOptOk ? 'Allowed / អនុញ្ញាតរួច' : 'Allow / អនុញ្ញាត',
            onTap: _batOptOk ? null : _reqIgnoreBatteryOptimizations,
          ),
          const SizedBox(height: 12),
          _OemHelp(oem: _oem, onOpen: _openOemAutostart),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-check / ពិនិត្យម្ដងទៀត'),
                  onPressed: _refresh,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Continue / បន្ត'),
                  onPressed: _allGood ? widget.onAllGood : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String oem;
  const _Header({required this.oem});

  @override
  Widget build(BuildContext context) {
    final title = 'One-time setup for reliable background tracking on $oem.';
    final titleKm =
        'ការកំណត់ម្តងតែប៉ុណ្ណោះ សម្រាប់ការតាមដានជាប្រចាំ នៅលើ $oem.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.security, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text('$title\n$titleKm')),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String title;
  final String titleKm;
  final String description;
  final String descriptionKm;
  final bool ok;
  final String actionText;
  final VoidCallback? onTap;

  const _StepTile({
    required this.title,
    required this.titleKm,
    required this.description,
    required this.descriptionKm,
    required this.ok,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.green : Colors.orange;
    return Card(
      child: ListTile(
        leading: Icon(ok ? Icons.check_circle : Icons.error, color: color),
        title: Text('$title\n$titleKm'),
        subtitle: Text('$description\n$descriptionKm'),
        trailing: TextButton(onPressed: onTap, child: Text(actionText)),
      ),
    );
  }
}

class _OemHelp extends StatelessWidget {
  final String oem;
  final Future<void> Function() onOpen;
  const _OemHelp({required this.oem, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final lower = oem.toLowerCase();
    final isTranssionFamily =
        ['transsion', 'tecno', 'infinix', 'itel'].contains(lower);

    final steps = isTranssionFamily
        ? [
            'Open **Phone Manager / Power Manager**.',
            'Find **Auto-start / Startup Manager**.',
            'Enable **Smart Truck Driver** to start automatically.',
            'Also allow **Run in background / No restrictions**.',
            // Khmer
            'បើក **Phone Manager / Power Manager**',
            'រក **Auto-start / Startup Manager**',
            'បើក **Smart Truck Driver** ឲ្យចាប់ផ្ដើមស្វ័យប្រវត្តិ',
            'អនុញ្ញាត **Run in background / No restrictions** ផងដែរ',
          ]
        : [
            'Open **Settings → Apps**.',
            'Tap **Special access / Auto-start** (name varies).',
            'Allow **Smart Truck Driver** to auto-start and run in background.',
            // Khmer
            'បើក **Settings → Apps**',
            'ចុច **Special access / Auto-start** (ឈ្មោះអាចខុស)',
            'អនុញ្ញាត **Smart Truck Driver** ចាប់ផ្តើមស្វ័យប្រវត្តិ និងរត់ផ្ទៃក្រោយ',
          ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Icon(Icons.power_settings_new),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OEM Auto-start (recommended) / ការចាប់ផ្តើមស្វ័យប្រវត្តិ (ណែនាំ)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OutlinedButton(
                  onPressed: onOpen, child: const Text('Open / បើក')),
            ],
          ),
          const SizedBox(height: 8),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(s)),
                  ],
                ),
              )),
        ]),
      ),
    );
  }
}
