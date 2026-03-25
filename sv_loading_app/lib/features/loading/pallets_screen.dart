import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../state/connectivity_provider.dart';
import '../../state/g_management_context_provider.dart';
import '../../state/loading_provider.dart';
import '../../state/trip_provider.dart';
import '../../widgets/app_scaffold.dart';

class PalletsScreen extends StatefulWidget {
  const PalletsScreen({super.key});

  @override
  State<PalletsScreen> createState() => _PalletsScreenState();
}

class _PalletsScreenState extends State<PalletsScreen> {
  final List<_PalletRow> rows = [
    _PalletRow(
        materialCode: '4401010112',
        description: 'CAMBEER CAN 330ML',
        qtyCases: '1452',
        pallets: '22'),
  ];

  final _notes = TextEditingController();

  @override
  void dispose() {
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
      titleKey: 'pallets',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text('${'trip_id'.tr()}: ${dispatchId ?? '-'}')),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) => _rowCard(rows[i],
                    onDelete: () => setState(() => rows.removeAt(i))),
              ),
            ),
            TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: 'notes'.tr())),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => rows.add(_PalletRow(
                        materialCode: '',
                        description: '',
                        qtyCases: '',
                        pallets: ''))),
                    icon: const Icon(Icons.add),
                    label: Text('add_item'.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            final dispatchId =
                                gContext.activeDispatchId ?? trip?.dispatchId;
                            if (dispatchId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'error_dispatch_required'.tr())));
                              return;
                            }
                            final payload = {
                              'dispatchId': dispatchId,
                              'items': rows.map((r) => r.toJson()).toList(),
                              'notes': _notes.text.trim(),
                              'timestamp': DateTime.now().toIso8601String(),
                            };
                            await context
                                .read<LoadingProvider>()
                                .submitPallets(payload, online: conn.isOnline);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(conn.isOnline
                                    ? 'msg_submitted'.tr()
                                    : 'save_offline'.tr())));
                          },
                    icon: const Icon(Icons.check),
                    label: Text('submit'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowCard(_PalletRow row, {required VoidCallback onDelete}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: row.materialCodeCtrl,
                  decoration: InputDecoration(labelText: 'material_code'.tr()),
                )),
                IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline)),
              ],
            ),
            TextField(
                controller: row.descriptionCtrl,
                decoration: InputDecoration(labelText: 'description'.tr())),
            Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: row.qtyCasesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'qty_cases'.tr()),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: row.palletsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'pallets_count'.tr()),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PalletRow {
  final TextEditingController materialCodeCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController qtyCasesCtrl;
  final TextEditingController palletsCtrl;

  _PalletRow({
    required String materialCode,
    required String description,
    required String qtyCases,
    required String pallets,
  })  : materialCodeCtrl = TextEditingController(text: materialCode),
        descriptionCtrl = TextEditingController(text: description),
        qtyCasesCtrl = TextEditingController(text: qtyCases),
        palletsCtrl = TextEditingController(text: pallets);

  Map<String, dynamic> toJson() => {
        'itemDescription':
            '${materialCodeCtrl.text.trim()} ${descriptionCtrl.text.trim()}'
                .trim(),
        'quantity': int.tryParse(palletsCtrl.text.trim()) ?? 0,
        'unit': 'PALLET',
        'conditionNote': 'Cases: ${qtyCasesCtrl.text.trim()}',
        'verifiedOk': true,
      };
}
