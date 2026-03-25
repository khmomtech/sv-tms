import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../state/connectivity_provider.dart';
import '../../state/g_management_context_provider.dart';
import '../../state/loading_provider.dart';
import '../../state/trip_provider.dart';
import '../../widgets/app_scaffold.dart';

class EmptiesScreen extends StatefulWidget {
  const EmptiesScreen({super.key});

  @override
  State<EmptiesScreen> createState() => _EmptiesScreenState();
}

class _EmptiesScreenState extends State<EmptiesScreen> {
  final _itemType = TextEditingController(text: 'Plastic Pallet');
  final _expected = TextEditingController(text: '100');
  final _returned = TextEditingController(text: '100');
  final _notes = TextEditingController();

  @override
  void dispose() {
    _itemType.dispose();
    _expected.dispose();
    _returned.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().currentTrip;
    final conn = context.watch<ConnectivityProvider>();
    final provider = context.watch<LoadingProvider>();
    final gContext = context.watch<GManagementContextProvider>();
    final dispatchId = gContext.activeDispatchId ?? trip?.dispatchId;

    return AppScaffold(
      titleKey: 'empties',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('${'trip_id'.tr()}: ${dispatchId ?? '-'}'),
            const SizedBox(height: 12),
            TextField(
                controller: _itemType,
                decoration: InputDecoration(labelText: 'item_type'.tr())),
            const SizedBox(height: 10),
            TextField(
                controller: _expected,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'qty_expected'.tr())),
            const SizedBox(height: 10),
            TextField(
                controller: _returned,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'qty_returned'.tr())),
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
                icon: const Icon(Icons.check),
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final dispatchId =
                            gContext.activeDispatchId ?? trip?.dispatchId;
                        if (dispatchId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('error_dispatch_required'.tr())));
                          return;
                        }
                        final expected = int.tryParse(_expected.text) ?? 0;
                        final returned = int.tryParse(_returned.text) ?? 0;
                        final payload = {
                          'dispatchId': dispatchId,
                          'items': [
                            {
                              'itemName': _itemType.text.trim(),
                              'quantity': returned,
                              'unit': 'PCS',
                              'conditionNote':
                                  'Expected: $expected, Variance: ${returned - expected}',
                              'recordedAt': DateTime.now().toIso8601String(),
                            }
                          ],
                          'notes': _notes.text.trim(),
                          'timestamp': DateTime.now().toIso8601String(),
                        };
                        await context
                            .read<LoadingProvider>()
                            .submitEmpties(payload, online: conn.isOnline);
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
