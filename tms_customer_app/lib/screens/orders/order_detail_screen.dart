import 'package:flutter/material.dart';
import '../../models/transport_order_dto.dart';

class OrderDetailScreen extends StatelessWidget {
  final TransportOrderDto order;
  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(order.orderRef ?? 'Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(title: const Text('ID'), subtitle: Text('${order.id ?? ''}')),
            ListTile(title: const Text('Reference'), subtitle: Text(order.orderRef ?? '')),
            ListTile(title: const Text('Status'), subtitle: Text(order.status ?? '')),
            ListTile(title: const Text('Shipment'), subtitle: Text(order.shipmentType ?? '')),
            ListTile(title: const Text('Order Date'), subtitle: Text(order.orderDate ?? '')),
            ListTile(title: const Text('Delivery Date'), subtitle: Text(order.deliveryDate ?? '')),
            const Divider(),
            const Text('Pickup Address', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(order.pickupAddress?.toString() ?? ''),
            const SizedBox(height: 12),
            const Text('Dropoff Address', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(order.dropAddress?.toString() ?? ''),
          ],
        ),
      ),
    );
  }
}
