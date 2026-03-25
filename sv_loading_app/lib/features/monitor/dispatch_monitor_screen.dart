import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../state/loading_provider.dart';
import '../../widgets/app_scaffold.dart';

class DispatchMonitorScreen extends StatefulWidget {
  const DispatchMonitorScreen({super.key});

  @override
  State<DispatchMonitorScreen> createState() => _DispatchMonitorScreenState();
}

class _DispatchMonitorScreenState extends State<DispatchMonitorScreen> {
  final _warehouse = TextEditingController(text: 'ALL');

  @override
  void dispose() {
    _warehouse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoadingProvider>();
    return AppScaffold(
      titleKey: 'timeline',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _warehouse,
                    decoration:
                        InputDecoration(labelText: 'warehouse_hint'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => context
                          .read<LoadingProvider>()
                          .fetchQueueByWarehouse(_warehouse.text.trim()),
                  icon: const Icon(Icons.refresh),
                  label: Text('load'.tr()),
                )
              ],
            ),
            const SizedBox(height: 10),
            if (provider.error != null)
              Text(provider.error!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: ListView.builder(
                itemCount: provider.monitorQueue.length,
                itemBuilder: (_, i) {
                  final row = provider.monitorQueue[i];
                  final dispatchId =
                      int.tryParse(row['dispatchId']?.toString() ?? '');
                  return Card(
                    child: ListTile(
                      title: Text(
                          '${'dispatch'.tr()} #${row['dispatchId'] ?? '-'}'),
                      subtitle: Text(
                        'Warehouse: ${row['warehouseCode'] ?? '-'} | Queue: ${row['status'] ?? '-'} | Bay: ${row['bay'] ?? '-'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: dispatchId == null
                          ? null
                          : () async {
                              await context
                                  .read<LoadingProvider>()
                                  .fetchDispatchDetail(dispatchId);
                              if (!context.mounted) return;
                              final detail = context
                                  .read<LoadingProvider>()
                                  .monitorDispatchDetail;
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Dispatch #$dispatchId'),
                                  content: Text(
                                    '${'pre_entry_safety'.tr()}: ${detail?['preEntrySafetyStatus'] ?? '-'}\n'
                                    '${'loading_safety'.tr()}: ${detail?['loadingSafetyStatus'] ?? '-'}\n'
                                    '${'active_session_id'.tr()}: ${(detail?['session'] as Map?)?['id'] ?? '-'}\n'
                                    '${'active_queue_id'.tr()}: ${(detail?['queue'] as Map?)?['id'] ?? '-'}',
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('close'.tr())),
                                  ],
                                ),
                              );
                            },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
