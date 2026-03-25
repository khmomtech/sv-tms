import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';

import '../../utils/date_range_picker.dart';

class TripReportScreen extends StatefulWidget {
  const TripReportScreen({super.key});

  @override
  State<TripReportScreen> createState() => _TripReportScreenState();
}

class _TripReportScreenState extends State<TripReportScreen> {
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
  late DateTime _from;
  late DateTime _to;
  String? _error;
  _QuickRange? _selectedQuickRange = _QuickRange.last7Days;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 6));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrips());
  }

  Future<void> _loadTrips() async {
    final driverId = context.read<DriverProvider>().driverId;
    if (driverId == null || driverId.isEmpty) {
      if (!mounted) return;
      setState(() => _error = tr('trip_report.driver_id_missing'));
      return;
    }

    if (!mounted) return;
    setState(() => _error = null);
    try {
      await context
          .read<DispatchProvider>()
          .fetchCompletedDispatchesByDateToDate(
            driverId: driverId,
            startDate: _from,
            endDate: _to,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showStableDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _from =
            DateTime(picked.start.year, picked.start.month, picked.start.day);
        _to = DateTime(picked.end.year, picked.end.month, picked.end.day);
        _selectedQuickRange = null;
      });
      await _loadTrips();
    }
  }

  Future<void> _setQuickRange(Duration duration, _QuickRange quickRange) async {
    final today = DateTime.now();
    if (!mounted) return;
    setState(() {
      _to = DateTime(today.year, today.month, today.day);
      _from = _to.subtract(duration);
      _selectedQuickRange = quickRange;
    });
    await _loadTrips();
  }

  Future<void> _setThisMonth() async {
    final now = DateTime.now();
    if (!mounted) return;
    setState(() {
      _from = DateTime(now.year, now.month, 1);
      _to = DateTime(now.year, now.month + 1, 0);
      _selectedQuickRange = _QuickRange.thisMonth;
    });
    await _loadTrips();
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DateTime? _parseServerDate(dynamic raw) {
    try {
      if (raw == null) return null;
      if (raw is String) {
        final s = raw.trim();
        if (s.isEmpty) return null;
        return DateTime.tryParse(
            s.contains('T') ? s : s.replaceFirst(' ', 'T'));
      }
      if (raw is List && raw.length >= 3) {
        final list = raw.cast<num>();
        final y = list[0].toInt();
        final m = list[1].toInt();
        final d = list[2].toInt();
        final hh = list.length > 3 ? list[3].toInt() : 0;
        final mm = list.length > 4 ? list[4].toInt() : 0;
        final ss = list.length > 5 ? list[5].toInt() : 0;
        return DateTime(y, m, d, hh, mm, ss);
      }
      if (raw is int) {
        final epochMillis = raw < 1000000000000 ? raw * 1000 : raw;
        return DateTime.fromMillisecondsSinceEpoch(epochMillis);
      }
      if (raw is double) {
        final intValue = raw.toInt();
        final epochMillis =
            intValue < 1000000000000 ? intValue * 1000 : intValue;
        return DateTime.fromMillisecondsSinceEpoch(epochMillis);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _formatServerDate(dynamic raw) {
    final dt = _parseServerDate(raw);
    if (dt == null) return tr('trip_report.not_available');
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  String _friendlyError(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) return tr('trip_report.fetch_failed');
    final lowered = raw.toLowerCase();
    if (lowered.contains('socket') ||
        lowered.contains('timed out') ||
        lowered.contains('network') ||
        lowered.contains('connection')) {
      return tr('trip_report.network_error');
    }
    if (lowered.contains('unauthorized') || lowered.contains('401')) {
      return tr('dispatch.unauthorized');
    }
    return tr('trip_report.fetch_failed');
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return const Color(0xFF16a34a);
      case 'CANCELLED':
        return const Color(0xFFdc2626);
      default:
        return const Color(0xFF2563eb);
    }
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toUpperCase().replaceAll('-', '_');
    if (!_knownDispatchStatusKeys.contains(normalized)) {
      return normalized.isEmpty ? 'Unknown' : normalized.replaceAll('_', ' ');
    }
    final key = 'dispatch.status.$normalized';
    final localized = tr(key);
    if (localized == key) return normalized.isEmpty ? 'Unknown' : normalized;
    return localized;
  }

  Map<String, dynamic>? _firstByType(List<dynamic> stops, String type) {
    for (final raw in stops) {
      if (raw is Map<String, dynamic>) {
        final candidate = (raw['type'] ?? '').toString().toUpperCase();
        if (candidate == type.toUpperCase()) return raw;
      }
    }
    return null;
  }

  List<dynamic> _normalizeStops(List<dynamic> raw) {
    if (raw.isEmpty) return const [];
    final deduped = <String, dynamic>{};

    int parseSequence(Map<String, dynamic> stop) {
      final value = stop['sequence'] ?? stop['stopSequence'];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 9999;
      return 9999;
    }

    int parseId(Map<String, dynamic> stop) {
      final value = stop['id'];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    for (final s in raw) {
      if (s is! Map<String, dynamic>) continue;
      final stop = Map<String, dynamic>.from(s);
      final type = (stop['type'] ?? '').toString();
      final address = stop['address'];
      final addressMap = address is Map<String, dynamic> ? address : null;
      final addrId = stop['addressId']?.toString() ??
          (addressMap?['id']?.toString() ?? '');
      final seq = parseSequence(stop).toString();
      final key = '$type|$addrId|$seq';
      deduped[key] = stop;
    }

    final list = deduped.values.cast<Map<String, dynamic>>().toList();
    list.sort((a, b) {
      final sa = parseSequence(a);
      final sb = parseSequence(b);
      if (sa != sb) return sa.compareTo(sb);
      final ia = parseId(a);
      final ib = parseId(b);
      return ia.compareTo(ib);
    });
    return list;
  }

  String _codeForStop(dynamic stop) {
    if (stop is Map<String, dynamic>) {
      final addr = stop['address'];
      if (addr is Map<String, dynamic>) {
        return (addr['code'] ?? addr['name'] ?? '').toString();
      }
      return (stop['code'] ?? stop['name'] ?? '').toString();
    }
    return stop?.toString() ?? '';
  }

  String _nameForStop(dynamic stop) {
    if (stop is Map<String, dynamic>) {
      final addr = stop['address'];
      if (addr is Map<String, dynamic>) {
        return (addr['name'] ?? addr['displayName'] ?? '').toString();
      }
      return (stop['name'] ?? '').toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: Text(tr('menu.trip_report')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr('common.refresh'),
            onPressed: context.watch<DispatchProvider>().isLoadingCompleted
                ? null
                : _loadTrips,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: tr('common.select_date_range'),
            onPressed: context.watch<DispatchProvider>().isLoadingCompleted
                ? null
                : _pickDateRange,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: Consumer<DispatchProvider>(
          builder: (context, dispatchProvider, _) {
            final trips = dispatchProvider.completedDispatches;
            final isLoading = dispatchProvider.isLoadingCompleted;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFilterCard(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (trips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          tr('trip_report.empty_title'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr('trip_report.empty_subtitle'),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      tr('trip_report.trips_found', args: ['${trips.length}']),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ),
                  ...trips.map(_buildTripCard),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    final rangeText = '${_formatDate(_from)}  →  ${_formatDate(_to)}';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('common.select_date_range'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      context.watch<DispatchProvider>().isLoadingCompleted
                          ? null
                          : _pickDateRange,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(rangeText),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(
                  tr('trip_report.quick.last_7_days'),
                  isSelected: _selectedQuickRange == _QuickRange.last7Days,
                  onTap: context.watch<DispatchProvider>().isLoadingCompleted
                      ? null
                      : () => _setQuickRange(
                          const Duration(days: 6), _QuickRange.last7Days),
                ),
                _pill(
                  tr('trip_report.quick.last_30_days'),
                  isSelected: _selectedQuickRange == _QuickRange.last30Days,
                  onTap: context.watch<DispatchProvider>().isLoadingCompleted
                      ? null
                      : () => _setQuickRange(
                          const Duration(days: 29), _QuickRange.last30Days),
                ),
                _pill(
                  tr('trip_report.quick.this_month'),
                  isSelected: _selectedQuickRange == _QuickRange.thisMonth,
                  onTap: context.watch<DispatchProvider>().isLoadingCompleted
                      ? null
                      : _setThisMonth,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(
    String label, {
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    final bg = isSelected ? const Color(0xFF1d4ed8) : const Color(0xFFe8f0ff);
    final fg = isSelected ? Colors.white : const Color(0xFF1d4ed8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> dispatch) {
    final status = (dispatch['status'] ?? '').toString();
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);
    final dispatchId = dispatch['id'] ?? '';
    final start = dispatch['startTime'];
    final startLabel = _formatServerDate(start);

    final transportOrder = dispatch['transportOrder'] as Map<String, dynamic>?;
    List<dynamic> stops = (dispatch['stops'] as List<dynamic>?) ?? const [];
    if (stops.isEmpty) {
      stops = (transportOrder?['stops'] as List<dynamic>?) ?? const [];
    }
    stops = _normalizeStops(stops);

    dynamic origin = dispatch['from'] ??
        _firstByType(stops, 'PICKUP') ??
        (stops.isNotEmpty ? stops.first : null);
    dynamic dest = dispatch['to'] ??
        _firstByType(stops, 'DROP') ??
        (stops.length > 1 ? stops.last : null);

    origin ??= transportOrder?['pickupAddress'];
    dest ??= transportOrder?['dropAddress'];

    final originCode = _codeForStop(origin);
    final destCode = _codeForStop(dest);
    final originName = _nameForStop(origin);
    final destName = _nameForStop(dest);

    final customer =
        (transportOrder?['customerName'] ?? dispatch['customerName'] ?? '')
            .toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#$dispatchId',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/dispatchDetail',
                    arguments: {'dispatchId': dispatchId},
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      originCode.isEmpty
                          ? tr('trip_report.origin')
                          : originCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1d4ed8),
                      ),
                    ),
                    if (originName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          originName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.blue),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      destCode.isEmpty
                          ? tr('trip_report.destination')
                          : destCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFdc2626),
                      ),
                    ),
                    if (destName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          destName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                startLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          if (customer.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.business_center, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customer,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _QuickRange {
  last7Days,
  last30Days,
  thisMonth,
}
