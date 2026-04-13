// lib/widgets/version_checker.dart
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tms_driver_app/models/version_info.dart';
import 'package:tms_driver_app/services/version_service.dart';

class VersionChecker extends StatefulWidget {
  final VersionService service;
  final Duration delay;
  final bool checkOnResume;
  final bool showBannerForOptional;
  final bool checkInitially;

  const VersionChecker({
    super.key,
    required this.service,
    this.delay = const Duration(seconds: 2),
    this.checkOnResume = true,
    this.showBannerForOptional = true,
    this.checkInitially = true,
  });

  @override
  State<VersionChecker> createState() => _VersionCheckerState();
}

class _VersionCheckerState extends State<VersionChecker>
    with WidgetsBindingObserver {
  VersionInfo? _latest;
  bool _showOptionalBanner = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.checkInitially) {
      // delayed check (let first frame render)
      Future.delayed(widget.delay, _check);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.checkOnResume) return;
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    try {
      final info = await widget.service.loadLatest();
      if (!mounted) return;
      _latest = info;

      if (info == null) return;

      final maintenanceBlock = await widget.service.isMaintenanceBlockActive(info);
      final mustBlock = await widget.service.isMandatoryBlock(info);
      final shouldShow = await widget.service.shouldShowUpdate(info);

      if (maintenanceBlock) {
        _openMaintenanceDialog(info);
      } else if (mustBlock) {
        _openMandatoryDialog(info);
      } else if (shouldShow && widget.showBannerForOptional) {
        setState(() => _showOptionalBanner = true);
      }
    } catch (_) {
      // silent — never crash UI for version checks
    }
  }

  Future<void> _openMandatoryDialog(VersionInfo info) async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    final isKm = context.locale.languageCode == 'km';
    final notes = info.effectiveReleaseNote(isKhmer: isKm);

    final curVer = await widget.service.currentVersion();
    final curBuild = await widget.service.currentBuild();

    if (!mounted) return;

    // Non-dismissible, blocks back navigation
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          // Prevent dismissal until store action completes
        },
        child: AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('update.required')), // add to your i18n
              const SizedBox(height: 4),
              Text('v$curVer ($curBuild) → ${info.effectiveLatestVersion}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('update.release_notes'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(notes.isEmpty ? '—' : notes),
                const SizedBox(height: 12),
                Text(
                  tr('update.mandatory_block_hint'),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await widget.service.openStore(info);
                // Keep dialog open until user actually leaves app or installs
                // (If you want to re-check after returning, keep checkOnResume=true)
              },
              child: Text(tr('update.now')),
            ),
          ],
        ),
      ),
    );

    _dialogOpen = false;
  }

  Future<void> _openMaintenanceDialog(VersionInfo info) async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    final isKm = context.locale.languageCode == 'km';
    final message = isKm && info.maintenanceMessageKm.trim().isNotEmpty
        ? info.maintenanceMessageKm.trim()
        : info.maintenanceMessageEn.trim();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: AlertDialog(
          title: const Text('Maintenance'),
          content: Text(message.isEmpty ? 'System is under maintenance.' : message),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _dialogOpen = false;
                await _check();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );

    _dialogOpen = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showOptionalBanner || _latest == null) {
      return const SizedBox.shrink();
    }

    final info = _latest!;
    final isKm = context.locale.languageCode == 'km';
    final notes = info.effectiveReleaseNote(isKhmer: isKm);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update_alt),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('update.available'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(notes.isEmpty ? '—' : notes,
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => widget.service.openStore(info),
            child: Text(tr('update.now')),
          ),
        ],
      ),
    );
  }
}
