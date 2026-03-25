import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../state/connectivity_provider.dart';
import '../../state/g_management_context_provider.dart';
import '../../state/loading_provider.dart';
import '../../state/trip_provider.dart';
import '../../widgets/app_scaffold.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final _warehouse = TextEditingController(text: 'KHB');
  final _notes = TextEditingController();

  @override
  void dispose() {
    _warehouse.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().currentTrip;
    final conn = context.watch<ConnectivityProvider>();
    final provider = context.watch<LoadingProvider>();
    final gContext = context.watch<GManagementContextProvider>();
    final activeDispatchId = gContext.activeDispatchId ?? trip?.dispatchId;

    return AppScaffold(
      titleKey: 'queue',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('${'trip_id'.tr()}: ${activeDispatchId ?? '-'}'),
            const SizedBox(height: 12),
            TextField(
                controller: _warehouse,
                decoration: InputDecoration(labelText: 'warehouse'.tr())),
            const SizedBox(height: 10),
            TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: 'notes'.tr())),
            const SizedBox(height: 14),
            if (provider.error != null)
              Text(provider.error!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.queue),
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final gContext =
                            context.read<GManagementContextProvider>();
                        final loadingProvider = context.read<LoadingProvider>();
                        final dispatchId =
                            gContext.activeDispatchId ?? trip?.dispatchId;
                        if (dispatchId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('error_dispatch_required'.tr())),
                          );
                          return;
                        }
                        final payload = {
                          'dispatchId': dispatchId,
                          'warehouseCode': _warehouse.text.trim(),
                          'remarks': _notes.text.trim(),
                        };
                        await loadingProvider.registerQueue(payload,
                            online: conn.isOnline);
                        await gContext.setActiveDispatchId(dispatchId);
                        await gContext.setWarehouse(_warehouse.text.trim());
                        await gContext
                            .setActiveQueueId(loadingProvider.currentQueueId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(conn.isOnline
                                ? 'msg_submitted'.tr()
                                : 'save_offline'.tr())));
                      },
                label: provider.isLoading
                    ? const Text('...')
                    : Text('submit'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
