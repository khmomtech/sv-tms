import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../state/g_management_context_provider.dart';
import '../../state/g_management_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../docs/docs_upload_screen.dart';
import '../empties/empties_screen.dart';
import '../loading/loading_screen.dart';
import '../loading/pallets_screen.dart';
import '../queue/queue_screen.dart';

class LoadingManagementScreen extends StatefulWidget {
  const LoadingManagementScreen({super.key});

  @override
  State<LoadingManagementScreen> createState() =>
      _LoadingManagementScreenState();
}

class _LoadingManagementScreenState extends State<LoadingManagementScreen> {
  String _warehouse = 'KHB';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final selected =
          context.read<GManagementContextProvider>().selectedWarehouse;
      _warehouse = selected == 'ALL' ? 'KHB' : selected;
      await context
          .read<GManagementProvider>()
          .fetchQueueByWarehouse(_warehouse);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GManagementProvider>();
    final gctx = context.watch<GManagementContextProvider>();
    return AppScaffold(
      titleKey: 'loading_management',
      actions: [
        IconButton(
          onPressed: provider.isLoading
              ? null
              : () => provider.fetchQueueByWarehouse(_warehouse),
          icon: const Icon(Icons.refresh),
        )
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('loading_management'.tr(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  _warehouseDropdown(provider),
                  const SizedBox(height: 10),
                  Text(
                      '${'active_dispatch'.tr()}: ${gctx.activeDispatchId ?? '-'}'),
                  Text(
                      '${'active_queue_id'.tr()}: ${gctx.activeQueueId ?? '-'}'),
                  Text(
                      '${'active_session_id'.tr()}: ${gctx.activeSessionId ?? '-'}'),
                ],
              ),
            ),
          ),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(provider.error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 10),
          _quickActionTile(
            icon: Icons.playlist_add_check_circle,
            title: '1) ${'queue_registration'.tr()}',
            subtitle: 'queue_registration_subtitle'.tr(),
            onTap: () => _open(const QueueScreen()),
          ),
          _quickActionTile(
            icon: Icons.local_shipping,
            title: '2) ${'start_complete_loading'.tr()}',
            subtitle: 'start_complete_loading_subtitle'.tr(),
            onTap: () => _open(const LoadingScreen()),
          ),
          _quickActionTile(
            icon: Icons.inventory_2,
            title: '3) ${'pallets'.tr()}',
            subtitle: 'pallets_subtitle'.tr(),
            onTap: () => _open(const PalletsScreen()),
          ),
          _quickActionTile(
            icon: Icons.recycling,
            title: '4) ${'empties'.tr()}',
            subtitle: 'empties_subtitle'.tr(),
            onTap: () => _open(const EmptiesScreen()),
          ),
          _quickActionTile(
            icon: Icons.upload_file,
            title: '5) ${'upload_documents'.tr()}',
            subtitle: 'upload_documents_subtitle'.tr(),
            onTap: () => _open(const DocsUploadScreen()),
          ),
          const SizedBox(height: 10),
          Text('queue_snapshot'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...provider.queueRows.map((row) {
            final dispatchId =
                int.tryParse(row['dispatchId']?.toString() ?? '');
            final queueId = int.tryParse(row['id']?.toString() ?? '');
            return Card(
              child: ListTile(
                title: Text('Dispatch #${row['dispatchId'] ?? '-'}'),
                subtitle: Text(
                  'Queue #${row['id'] ?? '-'} | ${row['status'] ?? '-'} | Bay ${row['bay'] ?? '-'}',
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: dispatchId == null
                    ? null
                    : () async {
                        final gContext =
                            context.read<GManagementContextProvider>();
                        await provider.fetchLoadingDispatchDetail(dispatchId);
                        if (queueId != null) {
                          await gContext.setActiveQueueId(queueId);
                        }
                        if (!mounted) return;
                        _showDetail(provider.loadingDispatchDetail);
                      },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _warehouseDropdown(GManagementProvider provider) {
    const items = [
      DropdownMenuItem(value: 'KHB', child: Text('KHB')),
      DropdownMenuItem(value: 'W2', child: Text('W2')),
      DropdownMenuItem(value: 'W3', child: Text('W3')),
    ];
    Future<void> onChanged(String? v) async {
      if (v == null) return;
      setState(() => _warehouse = v);
      await provider.fetchQueueByWarehouse(v);
    }

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

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showDetail(Map<String, dynamic>? detail) {
    if (detail == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${'dispatch'.tr()} #${detail['dispatchId'] ?? '-'}'),
        content: Text(
          '${'pre_entry_safety'.tr()}: ${detail['preEntrySafetyStatus'] ?? '-'}\n'
          '${'loading_safety'.tr()}: ${detail['loadingSafetyStatus'] ?? '-'}\n'
          '${'active_queue_id'.tr()}: ${(detail['queue'] as Map?)?['id'] ?? '-'}\n'
          '${'active_session_id'.tr()}: ${(detail['session'] as Map?)?['id'] ?? '-'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }
}
