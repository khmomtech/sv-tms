// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _loading = false;
  String? _error;
  List<Booking> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<BookingsProvider>(context, listen: false);
      final list = await provider.fetchAdminOrders();
      setState(() {
        _items = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('admin_orders'.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final b = _items[i];
                      return ListTile(
                        title: Text(b.title),
                        subtitle:
                            Text('${b.pickupAddress} → ${b.dropoffAddress}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(b.status),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_note),
                              tooltip: 'change_status'.tr(),
                              onPressed: () async {
                                final prov = Provider.of<BookingsProvider>(
                                    context,
                                    listen: false);
                                final newStatus = await showDialog<String?>(
                                    context: context,
                                    builder: (ctx) => SimpleDialog(
                                          title: Text('change_status'.tr()),
                                          children: [
                                            'pending',
                                            'accepted',
                                            'in_transit',
                                            'delivered',
                                            'cancelled'
                                          ]
                                              .map((s) => SimpleDialogOption(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, s),
                                                    child: Text(s.tr()),
                                                  ))
                                              .toList(),
                                        ));
                                if (newStatus != null) {
                                  final updated = b.copyWith(status: newStatus);
                                  final ok = await prov.updateBooking(updated);
                                  if (!mounted) return;
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('updated'.tr())));
                                    await _load();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('update_failed'.tr())));
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'retry'.tr(),
                              onPressed: () async {
                                final prov = Provider.of<BookingsProvider>(
                                    context,
                                    listen: false);
                                await prov.retrySync(b);
                                if (!mounted) return;
                                await _load();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'delete'.tr(),
                              onPressed: () async {
                                final prov = Provider.of<BookingsProvider>(
                                    context,
                                    listen: false);
                                final ok = await prov.deleteBookingRemote(b);
                                if (!mounted) return;
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('deleted'.tr())));
                                  await _load();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('delete_failed'.tr())));
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
