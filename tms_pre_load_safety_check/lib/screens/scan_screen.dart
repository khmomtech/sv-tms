import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/pending_queue_service.dart';
import '../services/safety_service.dart';
import '../services/stats_service.dart';
import '../widgets/primary_button.dart';
import 'driver_dispatch_list_screen.dart';
import 'safety_check_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.driverFirst = false});

  /// When true, show helper copy that prioritizes scanning driver cards.
  final bool driverFirst;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _processing = false;
  String? _error;
  Barcode? _lastBarcode;
  DateTime? _lastScanTime;
  final TextEditingController _manualController = TextEditingController();

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  int? _parseDispatchId(String raw) {
    final text = raw.trim();
    try {
      final parsed = jsonDecode(text);
      if (parsed is Map && parsed['dispatchId'] != null) {
        return int.tryParse(parsed['dispatchId'].toString());
      }
    } catch (_) {
      // Not JSON; proceed to other formats
    }
    if (text.toUpperCase().startsWith('DISPATCH:')) {
      return int.tryParse(text.split(':').last);
    }
    if (text.toLowerCase().startsWith('svtms://dispatch/')) {
      return int.tryParse(text.split('/').last);
    }
    return int.tryParse(text);
  }

  int? _parseDriverId(String raw) {
    final text = raw.trim();
    try {
      final parsed = jsonDecode(text);
      if (parsed is Map && parsed['driverId'] != null) {
        return int.tryParse(parsed['driverId'].toString());
      }
    } catch (_) {
      // not json
    }
    if (text.toUpperCase().startsWith('DRIVER:')) {
      final parts = text.split(':');
      // Driver app QR format: DRIVER:<id>:<name>:<phone>
      if (parts.length >= 2) {
        return int.tryParse(parts[1]);
      }
    }
    if (text.toLowerCase().startsWith('svtms://driver/')) {
      return int.tryParse(text.split('/').last);
    }
    // driver card codes like DR-10238 -> strip prefix and parse
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned);
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_processing) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final code = barcode?.rawValue;
    if (code == null) return;
    setState(() {
      _lastBarcode = barcode;
      _lastScanTime = DateTime.now();
    });
    final driverId = _parseDriverId(code);
    if (driverId != null) {
      _openDriverFlow(driverId);
      return;
    }
    final dispatchId = _parseDispatchId(code);
    if (dispatchId != null) {
      _openFlow(dispatchId);
    } else {
      setState(() => _error = 'qrParseError'.tr());
    }
  }

  Future<void> _openFlow(int dispatchId) async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final safetyService = Provider.of<SafetyService>(context, listen: false);
      final dispatch = await safetyService.fetchDispatch(dispatchId);
      if (dispatch != null && dispatch.driverId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverDispatchListScreen(
              driverId: dispatch.driverId!,
              initialDispatchId: dispatchId,
            ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SafetyCheckScreen(
              dispatchId: dispatchId,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _openDriverFlow(int driverId) async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverDispatchListScreen(
            driverId: driverId,
            initialDispatchId: null,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _retryPending() async {
    final pendingQueue = Provider.of<PendingQueueService>(context, listen: false);
    final safetyService = Provider.of<SafetyService>(context, listen: false);
    final stats = Provider.of<StatsService>(context, listen: false);
    final count = await pendingQueue.retryPending(safetyService, stats: stats);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0 ? 'retrySuccess'.tr() : 'offlineSaved'.tr(),
        ),
      ),
    );
  }

  void _restartScan() {
    setState(() {
      _error = null;
      _lastBarcode = null;
    });
    _scannerController.start();
  }

  String _formattedLastScan() {
    if (_lastScanTime == null) return '-';
    return DateFormat.yMMMd().add_Hm().format(_lastScanTime!);
  }

  Widget _summaryCard(int pendingCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'safetySummaryToday'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _summaryTile(
                    label: 'offlinePendingLabel'.tr(),
                    value: pendingCount.toString(),
                    icon: Icons.cloud_off_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryTile(
                    label: 'lastScanLabel'.tr(),
                    value: _formattedLastScan(),
                    icon: Icons.qr_code_scanner_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'apiMovedToSettings'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<PendingQueueService>().getPending().length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driverFirst ? 'driverArrival'.tr() : 'scanTitle'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _processing ? null : _retryPending,
            tooltip: 'retryPending'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryCard(pendingCount),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.driverFirst
                        ? 'scanDriverInstruction'.tr()
                        : 'scanInstruction'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'resetScanner'.tr(),
                  icon: const Icon(Icons.restart_alt),
                  onPressed: _processing
                      ? null
                      : () {
                          setState(() {
                            _error = null;
                            _lastBarcode = null;
                          });
                        },
                )
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleBarcode,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'scanId'.tr(),
              onPressed: _processing ? null : _restartScan,
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'enterDriverId'.tr(),
              icon: Icons.badge_outlined,
              onPressed: _processing
                  ? null
                  : () async {
                      _manualController.clear();
                      await showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        builder: (ctx) {
                          return Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                              top: 16,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('enterDriverIdTitle'.tr(),
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _manualController,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    labelText: 'driverId'.tr(),
                                    hintText: 'driverIdHint'.tr(),
                                    prefixIcon: const Icon(Icons.qr_code_2),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    final raw = _manualController.text.trim();
                                    final parsed = _parseDriverId(raw);
                                    if (parsed != null) {
                                      Navigator.pop(ctx);
                                      _openDriverFlow(parsed);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('invalidDriverId'.tr())),
                                      );
                                    }
                                  },
                                  child: Text('openDriverTrips'.tr()),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
            ),
            const SizedBox(height: 8),
            if (_lastBarcode != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.qr_code_2),
                  title: Text(_lastBarcode?.rawValue ?? ''),
                  subtitle: Text('lastScan'.tr()),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _lastBarcode = null),
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
