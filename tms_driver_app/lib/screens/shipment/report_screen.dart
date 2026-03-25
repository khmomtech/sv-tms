// lib/screen/shipment/report_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

import '../../utils/date_range_picker.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const Set<String> _knownDispatchStatusKeys = {
    'PLANNED',
    'PENDING',
    'ASSIGNED',
    'DRIVER_CONFIRMED',
    'APPROVED',
    'REJECTED',
    'SCHEDULED',
    'ARRIVED_LOADING',
    'LOADING',
    'LOADED',
    'SAFETY_PASSED',
    'SAFETY_FAILED',
    'IN_QUEUE',
    'IN_TRANSIT',
    'ARRIVED_UNLOADING',
    'UNLOADING',
    'UNLOADED',
    'DELIVERED',
    'COMPLETED',
    'CANCELLED',
  };
  DateTimeRange? _range;
  bool _loading = false;

  // ---- helpers ----
  String _formatRangeLabel(DateTimeRange? range) {
    if (range == null) return tr('common.select_date_range');
    final fmt = DateFormat('dd-MMM-yyyy');
    return '${fmt.format(range.start)} — ${fmt.format(range.end)}';
  }

  Color _statusColor(String raw) {
    final s = raw.toUpperCase();
    switch (s) {
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      case 'ASSIGNED':
      case 'APPROVED':
        return Colors.teal;
      case 'DRIVER_CONFIRMED':
        return Colors.indigo;
      case 'ARRIVED_LOADING':
      case 'LOADING':
        return Colors.deepPurple;
      case 'LOADED':
        return Colors.blueAccent;
      case 'IN_TRANSIT':
        return Colors.blue;
      case 'ARRIVED_UNLOADING':
      case 'UNLOADING':
        return Colors.cyan;
      case 'UNLOADED':
        return Colors.green.shade700;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String raw) {
    final key = raw.trim().toUpperCase().replaceAll('-', '_');
    return _knownDispatchStatusKeys.contains(key)
        ? tr('dispatch.status.$key')
        : key.replaceAll('_', ' ');
  }

  DateTime? _parseTime(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _initRangeAndLoad();
  }

  Future<void> _initRangeAndLoad() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    setState(() => _range = DateTimeRange(start: start, end: end));
    await _load();
  }

  Future<void> _load() async {
    if (!mounted || _range == null) return;
    final driverProvider = context.read<DriverProvider>();
    final dispatchProvider = context.read<DispatchProvider>();
    if (driverProvider.driverId == null) return;

    setState(() => _loading = true);
    try {
      await dispatchProvider.fetchDispatchesByDriver(
        driverProvider.driverId!,
        fromDate: _range!.start,
        toDate: _range!.end,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, int> _statusCounts(List<Map<String, dynamic>> items) {
    final m = <String, int>{};
    for (final d in items) {
      final s = (d['status'] ?? '').toString().toUpperCase();
      m[s] = (m[s] ?? 0) + 1;
    }
    return m;
  }

  int _i(num? n) => (n ?? 0).toInt();

  @override
  Widget build(BuildContext context) {
    final dispatches =
        context.select<DispatchProvider, List<Map<String, dynamic>>>(
      (p) => p.dispatches,
    );
    final counts = _statusCounts(dispatches);
    final total = dispatches.length;
    final completed = _i(counts['DELIVERED']);
    final cancelled = _i(counts['CANCELLED']);
    final inProgress = _i(counts['DRIVER_CONFIRMED']) +
        _i(counts['ARRIVED_LOADING']) +
        _i(counts['LOADED']) +
        _i(counts['IN_TRANSIT']) +
        _i(counts['ARRIVED_UNLOADING']) +
        _i(counts['UNLOADED']);
    final pending = _i(counts['PENDING']) + _i(counts['ASSIGNED']);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563eb),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(tr('reports.title'),
            style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _filters(context),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: Scrollbar(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _kpiGrid(total, completed, inProgress, pending, cancelled),
                    const SizedBox(height: 12),
                    _statusBreakdown(counts),
                    const SizedBox(height: 12),
                    _recentTrips(dispatches),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(BuildContext context) {
    final label = _formatRangeLabel(_range);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(label),
              onPressed: () async {
                final picked = await showStableDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020, 1, 1),
                  lastDate: DateTime(2100, 12, 31),
                  initialDateRange: _range,
                  accentColor: Colors.red,
                );
                if (picked != null) {
                  setState(() => _range = picked);
                  await _load();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: tr('common.refresh'),
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: tr('common.reset'),
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month, 1);
              final end = DateTime(now.year, now.month + 1, 0);
              setState(() => _range = DateTimeRange(start: start, end: end));
              await _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _kpiGrid(
      int total, int completed, int inProgress, int pending, int cancelled) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      children: [
        _kpiCard(tr('reports.total_trips'), '$total', Icons.list_alt),
        _kpiCard(
            tr('reports.completed'), '$completed', Icons.check_circle_outline),
        _kpiCard(
            tr('reports.in_progress'), '$inProgress', Icons.local_shipping),
        _kpiCard(tr('reports.pending'), '$pending', Icons.pending_outlined),
        _kpiCard(tr('reports.cancelled'), '$cancelled', Icons.cancel_outlined),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBreakdown(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('reports.status_breakdown'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(tr('reports.no_data'),
                    style: const TextStyle(color: Colors.grey)),
              )
            else
              ...entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(_statusLabel(e.key))),
                      Chip(
                        backgroundColor: _statusColor(e.key).withOpacity(0.15),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        label: Text('${e.value}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        side: BorderSide(
                            color: _statusColor(e.key).withOpacity(0.35)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _recentTrips(List<Map<String, dynamic>> list) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(tr('reports.recent_trips'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(tr('dispatch.empty_list'),
                  style: const TextStyle(color: Colors.grey)),
            )
          else
            Builder(
              builder: (_) {
                final sorted = List<Map<String, dynamic>>.from(list)
                  ..sort((a, b) {
                    final da = _parseTime(a['startTime']) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final db = _parseTime(b['startTime']) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return db.compareTo(da);
                  });
                return Column(
                  children: [
                    ...sorted.take(20).map((d) {
                      final id = d['id'];
                      final status = (d['status'] ?? '').toString();
                      final startIso = d['startTime']?.toString();
                      final fmt = DateFormat('dd-MMM-yyyy HH:mm');
                      String when = '-';
                      if (startIso != null) {
                        try {
                          when = fmt.format(DateTime.parse(startIso));
                        } catch (_) {}
                      }
                      return ListTile(
                        leading: const Icon(Icons.event_note),
                        title: Text('#$id',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(when),
                        trailing: Chip(
                            backgroundColor:
                              _statusColor(status).withOpacity(0.15),
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          label: Text(_statusLabel(status)),
                          side: BorderSide(
                              color: _statusColor(status).withOpacity(0.35)),
                        ),
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.dispatchDetail,
                            arguments: {'dispatchId': id}),
                      );
                    }),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
