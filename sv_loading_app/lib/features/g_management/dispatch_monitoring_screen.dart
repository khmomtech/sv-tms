import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/g_management_context_provider.dart';
import '../../state/g_management_provider.dart';
import '../../widgets/app_scaffold.dart';

class DispatchMonitoringScreen extends StatefulWidget {
  const DispatchMonitoringScreen({super.key});

  @override
  State<DispatchMonitoringScreen> createState() =>
      _DispatchMonitoringScreenState();
}

class _DispatchMonitoringScreenState extends State<DispatchMonitoringScreen> {
  final _status = TextEditingController();
  final _driverName = TextEditingController();
  final _routeCode = TextEditingController();
  final _customerName = TextEditingController();
  final _destination = TextEditingController();
  final _truckPlate = TextEditingController();
  final _tripNo = TextEditingController();
  String _warehouse = 'ALL';

  bool _autoRefresh = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = context.read<GManagementContextProvider>();
      _warehouse = ctx.selectedWarehouse;
      _startAutoRefresh();
      await _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _status.dispose();
    _driverName.dispose();
    _routeCode.dispose();
    _customerName.dispose();
    _destination.dispose();
    _truckPlate.dispose();
    _tripNo.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    if (!_autoRefresh) return;
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final provider = context.read<GManagementProvider>();
    await provider.fetchQueueByWarehouse(_warehouse);
    await provider.fetchDispatches(
      filter: DispatchMonitorFilter(
        status: _status.text,
        driverName: _driverName.text,
        routeCode: _routeCode.text,
        customerName: _customerName.text,
        destinationTo: _destination.text,
        truckPlate: _truckPlate.text,
        tripNo: _tripNo.text,
        page: 0,
        size: 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GManagementProvider>();
    final gctx = context.watch<GManagementContextProvider>();
    final rows = provider.monitorRows;

    return AppScaffold(
      titleKey: 'dispatch_monitoring',
      actions: [
        IconButton(
          tooltip: 'refresh'.tr(),
          onPressed: provider.isLoading ? null : _refresh,
          icon: const Icon(Icons.refresh),
        )
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _buildFilterCard(provider),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('auto_refresh'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Checkbox(
                value: _autoRefresh,
                onChanged: (v) {
                  setState(() => _autoRefresh = v ?? true);
                  _startAutoRefresh();
                },
              ),
              const Spacer(),
              Text(
                '${'active_dispatch'.tr()}: ${gctx.activeDispatchId ?? '-'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                provider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Text(
            '${'showing_dispatches'.tr()}: ${rows.length}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...rows.map((row) => _buildDispatchCard(context, provider, row)),
        ],
      ),
    );
  }

  Widget _buildFilterCard(GManagementProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('monitor_trip'.tr(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _smallInput('status'.tr(), _status),
                _smallInput('driver_name'.tr(), _driverName),
                _smallInput('route_code'.tr(), _routeCode),
                _smallInput('customer'.tr(), _customerName),
                _smallInput('to'.tr(), _destination),
                _smallInput('truck_plate'.tr(), _truckPlate),
                _smallInput('trip_no'.tr(), _tripNo),
                SizedBox(
                  width: 140,
                  child: _warehouseDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: provider.isLoading ? null : _refresh,
                  icon: const Icon(Icons.search),
                  label: Text('apply'.tr()),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    _status.clear();
                    _driverName.clear();
                    _routeCode.clear();
                    _customerName.clear();
                    _destination.clear();
                    _truckPlate.clear();
                    _tripNo.clear();
                    setState(() => _warehouse = 'ALL');
                    _refresh();
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: Text('reset'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _warehouseDropdown() {
    const items = [
      DropdownMenuItem(value: 'ALL', child: Text('ALL')),
      DropdownMenuItem(value: 'KHB', child: Text('KHB')),
      DropdownMenuItem(value: 'W2', child: Text('W2')),
      DropdownMenuItem(value: 'W3', child: Text('W3')),
    ];
    void onChanged(String? v) => setState(() => _warehouse = v ?? 'ALL');
    const ctor = DropdownButtonFormField<String>.new;
    try {
      return Function.apply(
        ctor,
        const [],
        {
          #initialValue: _warehouse,
          #decoration: const InputDecoration(labelText: 'Warehouse'),
          #items: items,
          #onChanged: onChanged,
        },
      ) as Widget;
    } catch (_) {
      return DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _warehouse,
        decoration: const InputDecoration(labelText: 'Warehouse'),
        items: items,
        onChanged: onChanged,
      );
    }
  }

  Widget _smallInput(String label, TextEditingController controller) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDispatchCard(
    BuildContext context,
    GManagementProvider provider,
    Map<String, dynamic> row,
  ) {
    final dispatchId = int.tryParse(
        row['id']?.toString() ?? row['dispatchId']?.toString() ?? '');
    final status = row['status']?.toString() ?? '-';
    final customer =
        row['customerName']?.toString() ?? row['customer']?.toString() ?? '-';
    final from = row['origin']?.toString() ?? '-';
    final to = row['destination']?.toString() ?? row['to']?.toString() ?? '-';
    final truck =
        row['vehiclePlate']?.toString() ?? row['truckPlate']?.toString() ?? '-';
    final driver = row['driverName']?.toString() ?? '-';
    final tripNo = row['tripNo']?.toString() ?? '-';

    final actions = dispatchId == null
        ? const <Map<String, dynamic>>[]
        : (provider.actionByDispatch[dispatchId] ?? const []);
    final rowError = dispatchId == null ? null : provider.rowErrors[dispatchId];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${dispatchId ?? '-'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(status)),
                const Spacer(),
                if (dispatchId != null)
                  IconButton(
                    tooltip: 'Actions',
                    onPressed: () async {
                      await provider.fetchDispatchActions(dispatchId);
                      await provider.fetchLoadingDispatchDetail(dispatchId);
                    },
                    icon: const Icon(Icons.more_horiz),
                  ),
              ],
            ),
            Text('$customer | Trip: $tripNo'),
            const SizedBox(height: 6),
            Text('$from  ->  $to'),
            const SizedBox(height: 6),
            Text('Truck: $truck | Driver: $driver'),
            const SizedBox(height: 8),
            if (dispatchId != null && actions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions.map((a) {
                  final target = a['targetStatus']?.toString() ?? '';
                  final label = a['actionLabel']?.toString() ?? target;
                  return FilledButton.tonal(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            await provider.runDispatchAction(
                              dispatchId: dispatchId,
                              targetStatus: target,
                            );
                          },
                    child: Text(label),
                  );
                }).toList(),
              ),
            if (rowError != null)
              Text(
                rowError,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
