import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/transport_order_service.dart';
import '../../models/transport_order_dto.dart';
import '../../providers/user_provider.dart';
import 'order_detail_screen.dart';

/// Orders list screen used by customers.
///
/// Kept intentionally simple: fetches orders for the current
/// `UserProvider.customerId` and displays either an empty state
/// or a scrollable list. Network calls are routed via
/// `TransportOrderService` and UI updates guard `mounted`.
class OrderScreen extends StatelessWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: const _OrderListView(),
    );
  }
}

class _OrderListView extends StatefulWidget {
  const _OrderListView({Key? key}) : super(key: key);

  @override
  State<_OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends State<_OrderListView> {
  List<TransportOrderDto> _orders = <TransportOrderDto>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Initial load is handled in didChangeDependencies so that
    // the widget reacts to changes in authentication state.
  }

  int? _lastCustomerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cid = context.read<UserProvider?>()?.customerId;
    if (cid != _lastCustomerId) {
      _lastCustomerId = cid;
      // Defer load to next microtask to ensure widget is fully mounted
      Future.microtask(() => _load());
    }
  }

  /// Loads orders for the current customer id.
  ///
  /// This method guards `mounted` before mutating state after
  /// `await` points so it is safe when the widget is disposed
  /// while a network call is in flight.
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final up = context.read<UserProvider>();
    final cid = up.customerId;

    if (cid == null) {
      if (!mounted) return;
      setState(() {
        _orders = <TransportOrderDto>[];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to see your orders')),
      );
      return;
    }

    final raw = await TransportOrderService.fetchOrders(cid);
    if (!mounted) return;

    if (raw == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load orders')),
      );
      return;
    }

    final list = raw.map((m) => TransportOrderDto.fromJson(m)).toList();
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No orders found'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final cid = context.read<UserProvider>().customerId;
              if (cid != null) {
                Navigator.of(context).pushNamed(
                  '/orders/create',
                  arguments: {'customerId': cid},
                );
              }
            },
            child: const Text('Create Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, TransportOrderDto o, int index) {
    final title = o.orderRef ?? 'Order #${o.id ?? (index + 1)}';
    final subtitle = o.status ?? o.shipmentType ?? '';
    final trailing = o.orderDate ?? '';
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(trailing),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: o),
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) => _buildListItem(ctx, _orders[i], i),
      ),
    );
  }
}
