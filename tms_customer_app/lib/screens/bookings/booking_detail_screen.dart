import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
// preview_booking_screen.dart is not used here

class BookingDetailScreen extends StatelessWidget {
  final Booking booking;
  const BookingDetailScreen({Key? key, required this.booking})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<BookingsProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text('booking_detail'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            Text(booking.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(children: [
              Chip(label: Text(booking.syncStatus)),
              const SizedBox(width: 8),
              if (booking.isDraft) Chip(label: Text('draft'.tr()))
            ]),
            const SizedBox(height: 12),
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
                title: Text('status'.tr()), subtitle: Text(booking.status)),
            if ((booking.remoteId ?? '').isNotEmpty)
              ListTile(
                  title: Text('remote_id'.tr()),
                  subtitle: Text(booking.remoteId!)),
            ListTile(
                title: Text('created'.tr()),
                subtitle: Text(booking.createdAt.toLocal().toString())),
            if (booking.pickupDateTime != null)
              ListTile(
                  title: Text('pickup_time'.tr()),
                  subtitle: Text(booking.pickupDateTime!.toLocal().toString())),
            const Divider(),
            Text('Cargo', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            if ((booking.cargoType ?? '').isNotEmpty)
              ListTile(
                  title: Text('cargo_type'.tr()),
                  subtitle: Text(booking.cargoType!)),
            ListTile(
                title: Text('total_weight'.tr()),
                subtitle: Text(booking.totalWeightTons?.toString() ?? '-')),
            ListTile(
                title: Text('total_volume'.tr()),
                subtitle: Text(booking.totalVolumeCbm?.toString() ?? '-')),
            ListTile(
                title: Text('pallet_count'.tr()),
                subtitle: Text(booking.palletCount?.toString() ?? '-')),
            if ((booking.containerNo ?? '').isNotEmpty)
              ListTile(
                  title: Text('container_no'.tr()),
                  subtitle: Text(booking.containerNo!)),
            if ((booking.specialHandlingNotes ?? '').isNotEmpty)
              ListTile(
                  title: Text('special_handling'.tr()),
                  subtitle: Text(booking.specialHandlingNotes!)),
            const Divider(),
            Text('Contact', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            if ((booking.contactName ?? '').isNotEmpty)
              ListTile(
                  title: Text('contact_name'.tr()),
                  subtitle: Text(booking.contactName!)),
            if ((booking.contactPhone ?? '').isNotEmpty)
              ListTile(
                  title: Text('contact_phone'.tr()),
                  subtitle: Text(booking.contactPhone!)),
            if ((booking.receiverName ?? '').isNotEmpty)
              ListTile(
                  title: Text('receiver_name'.tr()),
                  subtitle: Text(booking.receiverName!)),
            if ((booking.receiverPhone ?? '').isNotEmpty)
              ListTile(
                  title: Text('receiver_phone'.tr()),
                  subtitle: Text(booking.receiverPhone!)),
            const Divider(),
            if (booking.packages != null && booking.packages!.isNotEmpty) ...[
              Text('Packages', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              ...booking.packages!.map((p) => ListTile(
                    title: Text(p.itemType),
                    subtitle: Text(
                        'Qty: ${p.qty} • Weight: ${p.weightKg ?? '-'} • COD: ${p.cod.toStringAsFixed(2)}'),
                  ))
            ],
            if ((booking.notes ?? '').isNotEmpty) ...[
              const Divider(),
              Text('notes'.tr(), style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(booking.notes!),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: booking.isDraft
                      ? null
                      : () async {
                          final success = await provider.retrySync(booking);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(success
                                  ? 'sync_success'.tr()
                                  : 'sync_failed'.tr())));
                        },
                  child: Text('retry_sync'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                              title: Text('confirm'.tr()),
                              content: Text('delete_booking_confirm'.tr()),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text('cancel'.tr())),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('delete'.tr())),
                              ],
                            ));
                    if (confirmed == true) {
                      await provider.removeBooking(booking.id);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('delete'.tr()),
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
