import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../state/connectivity_provider.dart';
import '../../state/g_management_context_provider.dart';
import '../../state/loading_provider.dart';
import '../../state/trip_provider.dart';
import '../../widgets/app_scaffold.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final _warehouse = TextEditingController(text: 'KHB');
  final _bay = TextEditingController(text: 'G1');
  final _sessionId = TextEditingController();
  final _seal = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _warehouse.dispose();
    _bay.dispose();
    _sessionId.dispose();
    _seal.dispose();
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
    final messenger = ScaffoldMessenger.of(context);

    Future<void> start() async {
      final loadingProvider = context.read<LoadingProvider>();
      final gContext = context.read<GManagementContextProvider>();
      final dispatchId = gContext.activeDispatchId ?? trip?.dispatchId;
      if (dispatchId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_dispatch_required'.tr())),
        );
        return;
      }
      final queueId = gContext.activeQueueId ?? loadingProvider.currentQueueId;
      if (queueId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_queue_required_start'.tr())),
        );
        return;
      }
      final payload = {
        'dispatchId': dispatchId,
        'queueId': queueId,
        'warehouseCode': _warehouse.text.trim(),
        'bay': _bay.text.trim(),
        'startedAt': DateTime.now().toIso8601String(),
        'remarks': _notes.text.trim(),
      };
      await loadingProvider.startLoading(payload, online: conn.isOnline);
      if (!context.mounted) return;
      await gContext.setActiveDispatchId(dispatchId);
      await gContext.setWarehouse(_warehouse.text.trim());
      if (conn.isOnline) {
        final id = loadingProvider.currentSessionId;
        if (id != null) {
          _sessionId.text = id.toString();
          await gContext.setActiveSessionId(id);
        }
      }
      messenger.showSnackBar(SnackBar(
          content: Text(conn.isOnline
              ? 'msg_start_loading_ok'.tr()
              : 'save_offline'.tr())));
    }

    Future<void> end() async {
      final gContext = context.read<GManagementContextProvider>();
      final parsedSessionId = int.tryParse(_sessionId.text.trim());
      final sessionId = parsedSessionId ??
          gContext.activeSessionId ??
          provider.currentSessionId;
      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_session_required'.tr())),
        );
        return;
      }
      final payload = {
        'sessionId': sessionId,
        'endedAt': DateTime.now().toIso8601String(),
        'remarks': [
          if (_seal.text.trim().isNotEmpty) 'Seal: ${_seal.text.trim()}',
          if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
        ].join(' | '),
      };
      await context
          .read<LoadingProvider>()
          .endLoading(payload, online: conn.isOnline);
      await gContext.setActiveSessionId(sessionId);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(conn.isOnline
              ? 'msg_end_loading_ok'.tr()
              : 'save_offline'.tr())));
    }

    return AppScaffold(
      titleKey: 'loading',
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
                controller: _bay,
                decoration: InputDecoration(labelText: 'loading_bay'.tr())),
            const SizedBox(height: 10),
            TextField(
              controller: _sessionId,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'session_id_auto'.tr()),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _seal,
                decoration: InputDecoration(labelText: 'seal_number'.tr())),
            const SizedBox(height: 10),
            TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: 'notes'.tr())),
            const SizedBox(height: 14),
            if (provider.error != null)
              Text(provider.error!, style: const TextStyle(color: Colors.red)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : start,
                    icon: const Icon(Icons.play_arrow),
                    label: Text('start_loading'.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : end,
                    icon: const Icon(Icons.stop),
                    label: Text('end_loading'.tr()),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
