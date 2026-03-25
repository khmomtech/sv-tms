import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/booking.dart';

class PreviewBookingScreen extends StatelessWidget {
  final Booking booking;
  const PreviewBookingScreen({Key? key, required this.booking})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('create_booking'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(title: Text('title'.tr()), subtitle: Text(booking.title)),
            ListTile(
                title: Text('vehicle_type'.tr()),
                subtitle: Text(booking.vehicleType ?? '-')),
            ListTile(
                title: Text('truck_type'.tr()),
                subtitle: Text(booking.truckType ?? '-')),
            ListTile(
                title: Text('capacity'.tr()),
                subtitle: Text(booking.capacity?.toString() ?? '-')),
            ListTile(
                title: Text('pickup'.tr()),
                subtitle: Text(booking.pickupAddress)),
            if ((booking.pickupCompany ?? '').isNotEmpty)
              ListTile(
                  title: Text('pickup_company'.tr()),
                  subtitle: Text(booking.pickupCompany!)),
            ListTile(
                title: Text('delivery'.tr()),
                subtitle: Text(booking.dropoffAddress)),
            if ((booking.destinationCompany ?? '').isNotEmpty)
              ListTile(
                  title: Text('destination_company'.tr()),
                  subtitle: Text(booking.destinationCompany!)),
            ListTile(
                title: Text('pickup_time'.tr()),
                subtitle: Text(booking.pickupDateTime?.toString() ?? '-')),
            const Divider(),
            Text('Cargo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            ListTile(
                title: Text('cargo_type'.tr()),
                subtitle: Text(booking.cargoType ?? '-')),
            ListTile(
                title: Text('total_weight'.tr()),
                subtitle: Text(booking.totalWeightTons?.toString() ?? '-')),
            ListTile(
                title: Text('total_volume'.tr()),
                subtitle: Text(booking.totalVolumeCbm?.toString() ?? '-')),
            ListTile(
                title: Text('pallet_count'.tr()),
                subtitle: Text(booking.palletCount?.toString() ?? '-')),
            ListTile(
                title: Text('container_no'.tr()),
                subtitle: Text(booking.containerNo ?? '-')),
            if ((booking.specialHandlingNotes ?? '').isNotEmpty)
              ListTile(
                  title: Text('special_handling'.tr()),
                  subtitle: Text(booking.specialHandlingNotes!)),
            ListTile(
                title: Text('contact_name'.tr()),
                subtitle: Text(booking.contactName ?? '-')),
            ListTile(
                title: Text('contact_phone'.tr()),
                subtitle: Text(booking.contactPhone ?? '-')),
            if ((booking.receiverName ?? '').isNotEmpty)
              ListTile(
                  title: Text('receiver_name'.tr()),
                  subtitle: Text(booking.receiverName!)),
            if ((booking.receiverPhone ?? '').isNotEmpty)
              ListTile(
                  title: Text('receiver_phone'.tr()),
                  subtitle: Text(booking.receiverPhone!)),
            const SizedBox(height: 12),
            if (booking.packages != null && booking.packages!.isNotEmpty) ...[
              const Divider(),
              Text('Packages', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...booking.packages!.map((p) => ListTile(
                    title: Text(p.itemType),
                    subtitle: Text(
                        'Qty: ${p.qty} • Weight: ${p.weightKg ?? '-'} • COD: ${p.cod.toStringAsFixed(2)}'),
                  )),
            ],
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const Divider(),
              Text('notes'.tr(),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(booking.notes!),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('close'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('create'.tr()),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
