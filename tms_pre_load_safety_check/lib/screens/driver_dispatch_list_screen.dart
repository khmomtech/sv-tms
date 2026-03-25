import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dispatch.dart';
import '../services/safety_service.dart';
import 'safety_check_screen.dart';

class DriverDispatchListScreen extends StatefulWidget {
  const DriverDispatchListScreen({
    super.key,
    required this.driverId,
    this.initialDispatchId,
  });

  final int driverId;
  final int? initialDispatchId;

  @override
  State<DriverDispatchListScreen> createState() => _DriverDispatchListScreenState();
}

class _DriverDispatchListScreenState extends State<DriverDispatchListScreen> {
  bool loading = true;
  String? error;
  List<DispatchInfo> dispatches = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final safetyService = Provider.of<SafetyService>(context, listen: false);
      final list = await safetyService.fetchDispatchesForDriver(widget.driverId);
      setState(() {
        dispatches = list;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => loading = true);
    await _load();
  }

  void _openSafety(DispatchInfo info) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SafetyCheckScreen(dispatchId: info.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('dispatchesTitle'.tr()),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : dispatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('noDispatches'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: Text('refresh'.tr()),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: dispatches.length,
                        itemBuilder: (context, index) {
                          final d = dispatches[index];
                          final isScanned =
                              widget.initialDispatchId != null && d.id == widget.initialDispatchId;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            isScanned ? Colors.green.shade100 : Colors.blue.shade100,
                                        foregroundColor: Colors.black87,
                                        child: Text(d.id.toString()),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              d.routeCode ?? 'Dispatch ${d.id}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                if (d.status != null) _chip(d.status!, isScanned),
                                                if (d.licensePlate != null)
                                                  _chip(d.licensePlate!, false),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _locationTile(
                                          icon: Icons.factory_outlined,
                                          label: 'dispatchLoading'.tr(),
                                          value: d.loadingLocation ?? '-',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _locationTile(
                                          icon: Icons.local_shipping_outlined,
                                          label: 'dispatchUnloading'.tr(),
                                          value: d.unloadingLocation ?? '-',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _openSafety(d),
                                      child: Text('safetyChecklist'.tr()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _chip(String label, bool highlight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlight ? Colors.green.shade800 : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _locationTile({required IconData icon, required String label, required String value}) {
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
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.grey.shade700)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
