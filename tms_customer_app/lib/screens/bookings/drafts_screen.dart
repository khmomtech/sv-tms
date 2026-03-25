import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../providers/bookings_provider.dart';
import '../../models/booking.dart';
import 'create_booking_screen.dart';

class DraftsScreen extends StatelessWidget {
  const DraftsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('drafts'.tr())),
      body: Consumer<BookingsProvider>(builder: (context, prov, _) {
        final drafts = prov.bookings.where((b) => b.isDraft).toList();
        if (drafts.isEmpty) {
          return Center(child: Text('no_drafts'.tr()));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: drafts.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final Booking d = drafts[i];
            return ListTile(
              leading: const Icon(Icons.drafts),
              title: Text(d.title),
              subtitle: Text('${d.pickupAddress} → ${d.dropoffAddress}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: 'edit'.tr(),
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CreateBookingScreen(draft: d)));
                  },
                ),
                IconButton(
                  tooltip: 'delete'.tr(),
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('delete'.tr()),
                        content: Text('confirm_delete_draft'.tr()),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text('cancel'.tr())),
                          TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text('delete'.tr())),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await prov.removeBooking(d.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('draft_deleted'.tr())));
                      }
                    }
                  },
                ),
              ]),
            );
          },
        );
      }),
    );
  }
}
