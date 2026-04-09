// battery_optimization_warning.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tms_driver_app/services/battery_optimization_service.dart';

class BatteryOptimizationWarning extends StatefulWidget {
  const BatteryOptimizationWarning({super.key});

  @override
  State<BatteryOptimizationWarning> createState() =>
      _BatteryOptimizationWarningState();
}

class _BatteryOptimizationWarningState
    extends State<BatteryOptimizationWarning> {
  bool _shouldShowWarning = false;

  @override
  void initState() {
    super.initState();
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    // Only relevant on Android; skip on other platforms
    if (!Platform.isAndroid) return;

    try {
      final ignoring =
          await BatteryOptimizationService.isIgnoringBatteryOptimizations();
      if (!ignoring && mounted) {
        setState(() => _shouldShowWarning = true);
      }
    } catch (e) {
      // If the channel/plugin is missing or throws, avoid spamming the UI
      // and logs by keeping the banner hidden.
      debugPrint('[BatteryOptimizationWarning] check failed: $e');
    }
  }

  void _requestDisableOptimization() async {
    try {
      await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
      // Give the system a brief moment to apply the change / return from settings
      await Future.delayed(const Duration(milliseconds: 800));
      final ignoring =
          await BatteryOptimizationService.isIgnoringBatteryOptimizations();
      if (ignoring && mounted) {
        setState(() => _shouldShowWarning = false);
      }
    } catch (e) {
      debugPrint('[BatteryOptimizationWarning] request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowWarning) return const SizedBox.shrink(); // nothing to show

    return Container(
      color: Colors.amber[700],
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.battery_alert, color: Colors.white),
          const SizedBox(width: 8.0),
          const Expanded(
            child: Text(
              'Battery optimization may affect location tracking!',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: _requestDisableOptimization,
            child: const Text(
              'Fix',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
