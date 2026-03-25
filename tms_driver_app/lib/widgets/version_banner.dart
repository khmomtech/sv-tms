import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tms_driver_app/models/version_info.dart';
import 'package:tms_driver_app/services/version_service.dart';

/// A compact banner you can drop anywhere (e.g., top of Dashboard).
/// Shows only when an optional update is available (never blocks).
class VersionBanner extends StatefulWidget {
  final VersionService service;
  final EdgeInsetsGeometry margin;

  const VersionBanner({
    super.key,
    required this.service,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  @override
  State<VersionBanner> createState() => _VersionBannerState();
}

class _VersionBannerState extends State<VersionBanner> {
  VersionInfo? _info;
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await widget.service.loadLatest();
    if (!mounted || info == null) return;

    // Do not show banner if this is a mandatory update (dialog elsewhere will handle it)
    final mustBlock = await widget.service.isMandatoryBlock(info);

    // Guard: if current == latest (normalized), never show
    final current = await widget.service.currentVersion();
    final isSame = _isSameVersion(current, info.latestVersion);

    final shouldShow =
        !mustBlock && !isSame && await widget.service.shouldShowUpdate(info);

    if (!mounted) return;
    setState(() {
      _info = info;
      _shouldShow = shouldShow;
    });
  }

  // Normalize and compare semantic versions like 1.2, 1.2.0, 1.2.0+5, 1.2.0-beta
  bool _isSameVersion(String a, String b) {
    final List<int> pa = _parseParts(a);
    final List<int> pb = _parseParts(b);
    for (int i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return false;
    }
    return true;
  }

  List<int> _parseParts(String v) {
    final core = v.split('-').first; // drop pre-release
    final left = core.split('+').first; // drop build metadata
    final parts = left.split('.');
    final out = <int>[];
    for (int i = 0; i < 3; i++) {
      if (i < parts.length) {
        out.add(int.tryParse(parts[i].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);
      } else {
        out.add(0);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow || _info == null) return const SizedBox.shrink();

    final isKm = context.locale.languageCode == 'km';
    final notes =
        isKm && _info!.noteKm.trim().isNotEmpty ? _info!.noteKm : _info!.noteEn;

    return Container(
      margin: widget.margin,
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
            onPressed: () => widget.service.openStore(_info!),
            child: Text(tr('update.now')),
          ),
          IconButton(
            tooltip: tr('common.dismiss'),
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (_info != null) await widget.service.snooze(_info!);
              if (!mounted) return;
              setState(() => _shouldShow = false);
            },
          ),
        ],
      ),
    );
  }
}
