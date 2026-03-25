import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../state/connectivity_provider.dart';
import '../../state/g_management_context_provider.dart';
import '../../state/loading_provider.dart';
import '../../state/trip_provider.dart';
import '../../widgets/app_scaffold.dart';

class GateCheckScreen extends StatefulWidget {
  const GateCheckScreen({super.key});

  @override
  State<GateCheckScreen> createState() => _GateCheckScreenState();
}

class _GateCheckScreenState extends State<GateCheckScreen> {
  final _vehicleId = TextEditingController();
  final _driverId = TextEditingController();
  final _warehouseCode = TextEditingController(text: 'KHB');
  final _notes = TextEditingController();

  bool ppeOk = true;
  bool leakageOk = true;
  bool extinguisherOk = true;
  bool wheelChockOk = true;
  bool pass = true;

  @override
  void dispose() {
    _vehicleId.dispose();
    _driverId.dispose();
    _warehouseCode.dispose();
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
      titleKey: 'gate_check',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('${'trip_id'.tr()}: ${activeDispatchId ?? '-'}'),
            const SizedBox(height: 12),
            TextField(
              controller: _vehicleId,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'vehicle_id'.tr()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _driverId,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'driver_id'.tr()),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _warehouseCode,
                decoration: InputDecoration(labelText: 'warehouse'.tr())),
            const SizedBox(height: 16),
            SwitchListTile(
                title: Text('check_ppe_ok'.tr()),
                value: ppeOk,
                onChanged: (v) => setState(() => ppeOk = v)),
            SwitchListTile(
                title: Text('check_no_leakage'.tr()),
                value: leakageOk,
                onChanged: (v) => setState(() => leakageOk = v)),
            SwitchListTile(
                title: Text('check_extinguisher_ok'.tr()),
                value: extinguisherOk,
                onChanged: (v) => setState(() => extinguisherOk = v)),
            SwitchListTile(
                title: Text('check_wheel_chock_ok'.tr()),
                value: wheelChockOk,
                onChanged: (v) => setState(() => wheelChockOk = v)),
            const Divider(),
            SwitchListTile(
                title: Text('check_pass'.tr()),
                value: pass,
                onChanged: (v) => setState(() => pass = v)),
            const SizedBox(height: 8),
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
                        final gContext =
                            context.read<GManagementContextProvider>();
                        final dispatchId =
                            gContext.activeDispatchId ?? trip?.dispatchId;
                        final vehicleId = int.tryParse(_vehicleId.text.trim());
                        final driverId = int.tryParse(_driverId.text.trim());
                        if (dispatchId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('error_dispatch_required'.tr())),
                          );
                          return;
                        }
                        if (vehicleId == null || driverId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('error_vehicle_driver_required'.tr())),
                          );
                          return;
                        }
                        final payload = {
                          'dispatchId': dispatchId,
                          'vehicleId': vehicleId,
                          'driverId': driverId,
                          'warehouseCode': _warehouseCode.text.trim(),
                          'remarks': _notes.text.trim(),
                          'items': [
                            {
                              'category': 'DOCUMENTS',
                              'itemName': 'PPE',
                              'status': ppeOk ? 'OK' : 'FAILED'
                            },
                            {
                              'category': 'LOAD',
                              'itemName': 'No Leakage',
                              'status': leakageOk ? 'OK' : 'FAILED'
                            },
                            {
                              'category': 'DOCUMENTS',
                              'itemName': 'Fire Extinguisher',
                              'status': extinguisherOk ? 'OK' : 'FAILED'
                            },
                            {
                              'category': 'LOAD',
                              'itemName': 'Wheel Chock',
                              'status': wheelChockOk ? 'OK' : 'FAILED'
                            },
                            {
                              'category': 'DOCUMENTS',
                              'itemName': 'Overall Check',
                              'status': pass ? 'OK' : 'FAILED',
                              'remarks': _notes.text.trim(),
                            },
                          ],
                        };
                        await context
                            .read<LoadingProvider>()
                            .submitGateCheck(payload, online: conn.isOnline);
                        await gContext.setActiveDispatchId(dispatchId);
                        await gContext.setWarehouse(_warehouseCode.text.trim());
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
