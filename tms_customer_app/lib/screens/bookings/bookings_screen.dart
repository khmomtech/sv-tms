import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../providers/bookings_provider.dart';
import '../../models/booking.dart';
import '../../routes/app_routes.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('bookings'.tr()), actions: [
        IconButton(
          tooltip: 'drafts'.tr(),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.bookingDrafts),
          icon: const Icon(Icons.drafts),
        ),
        IconButton(
          tooltip: 'retry'.tr(),
          onPressed: () async {
            final prov = Provider.of<BookingsProvider>(context, listen: false);
            final messenger = ScaffoldMessenger.of(context);
            await prov.retryAllFailed();
            messenger.showSnackBar(SnackBar(content: Text('retry'.tr())));
          },
          icon: const Icon(Icons.refresh),
        )
      ]),
      body: Consumer<BookingsProvider>(
        builder: (context, provider, _) {
          final banner = provider.errorMessage;
          final children = <Widget>[];
          if (banner != null && banner.isNotEmpty) {
            children.add(MaterialBanner(
              content: Text(banner),
              actions: [
                TextButton(
                    onPressed: provider.refresh, child: Text('retry'.tr())),
              ],
            ));
          }
          if (provider.isLoading) {
            return Column(children: [
              ...children,
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ]);
          }
          final items = provider.bookings;
          final widgets = <Widget>[];
          if (banner != null && banner.isNotEmpty) widgets.add(Container());
          if (provider.errorMessage != null) {
            return Column(children: [
              ...children,
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('error_loading_bookings'.tr()),
                      const SizedBox(height: 8),
                      Text(provider.errorMessage!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: provider.refresh,
                        child: Text('retry'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            ]);
          }

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.list_alt,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Center(
                      child: Text('bookings'.tr(),
                          style: theme.textTheme.titleLarge)),
                  const SizedBox(height: 8),
                  Center(
                      child: Text('no_bookings'.tr(),
                          style: theme.textTheme.bodyMedium)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final Booking b = items[i];
                return _BookingCard(booking: b);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.bookingCreate),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = booking.status.toLowerCase();
    final rightTop = booking.containerNo != null ||
            (booking.vehicleType != null && booking.vehicleType!.isNotEmpty)
        ? (booking.containerNo != null
            ? 'Container'
            : (booking.vehicleType ?? 'FTL'))
        : 'FTL';
    final rightBottom = booking.palletCount != null
        ? '${booking.palletCount} pallets'
        : (booking.totalWeightTons != null
            ? '${booking.totalWeightTons?.toStringAsFixed(0)}T'
            : '-');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(30)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('${booking.pickupAddress} → ${booking.dropoffAddress}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(200))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'dispatched'
                      ? const Color(0xFFEAF2FF)
                      : const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(booking.status.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: status == 'dispatched'
                            ? Colors.blue
                            : const Color(0xFFB85C00))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceType ?? 'Service',
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(booking.cargoType ?? 'Cargo',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rightTop,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(rightBottom,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Buttons
          if (status == 'dispatched')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.bookingDetail,
                    arguments: {'booking': booking}),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.description, color: Colors.white),
                    ),
                    Text('detail'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.tracking,
                        arguments: booking),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text('🌍', style: TextStyle(fontSize: 18)),
                        ),
                        Text('track'.tr(),
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.bookingDetail,
                        arguments: {'booking': booking}),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.description, color: Colors.black54),
                        ),
                        Text('detail'.tr(),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
