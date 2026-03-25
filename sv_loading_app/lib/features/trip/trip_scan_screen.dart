import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../state/g_management_context_provider.dart';
import '../../state/trip_provider.dart';
import '../../widgets/app_scaffold.dart';

class TripScanScreen extends StatefulWidget {
  const TripScanScreen({super.key});

  @override
  State<TripScanScreen> createState() => _TripScanScreenState();
}

class _TripScanScreenState extends State<TripScanScreen> {
  final _manual = TextEditingController();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool _showScanner = false;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _setTrip(String tripId) async {
    if (tripId.trim().isEmpty) return;
    final tripProvider = context.read<TripProvider>();
    final gContext = context.read<GManagementContextProvider>();
    await tripProvider.setTrip(tripId.trim());
    final dispatchId = int.tryParse(tripId.trim());
    await gContext.setActiveDispatchId(dispatchId);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${'trip_set'.tr()}: $tripId')));
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().currentTrip;
    return AppScaffold(
      titleKey: 'trip_scan',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (trip != null)
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${'trip_id'.tr()}: ${trip.tripId}')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manual,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'trip_id'.tr(),
                        hintText: 'dispatch_id_hint'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _setTrip(_manual.text),
                  child: Text('submit'.tr()),
                )
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showScanner = !_showScanner),
                icon: const Icon(Icons.qr_code),
                label: Text(
                    _showScanner ? 'hide_scanner'.tr() : 'open_scanner'.tr()),
              ),
            ),
            const SizedBox(height: 8),
            if (_showScanner)
              Expanded(
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: (controller) {
                    controller.scannedDataStream.listen((scanData) async {
                      final val = scanData.code ?? '';
                      if (val.isNotEmpty) {
                        await _setTrip(val);
                        await controller.pauseCamera();
                      }
                    });
                  },
                ),
              )
            else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}
