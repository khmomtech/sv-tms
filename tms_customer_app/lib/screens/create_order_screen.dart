import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transport_order_service.dart';

class CreateOrderScreen extends StatefulWidget {
  final int customerId;
  const CreateOrderScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderRefCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  DateTime? _orderDate;
  DateTime? _deliveryDate;
  String _shipmentType = 'FTL';

  @override
  void dispose() {
    _orderRefCtrl.dispose();
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, bool isOrderDate) async {
    final initial = isOrderDate ? (_orderDate ?? DateTime.now()) : (_deliveryDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => isOrderDate ? _orderDate = picked : _deliveryDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'orderRef': _orderRefCtrl.text.trim(),
      'orderDate': _orderDate?.toIso8601String(),
      'deliveryDate': _deliveryDate?.toIso8601String(),
      'shipmentType': _shipmentType,
      'pickupAddress': {'address': _pickupCtrl.text.trim()},
      'dropAddress': {'address': _dropCtrl.text.trim()},
    };

    final result = await TransportOrderService.createOrder(widget.customerId, payload);
    final snack = result
        ? const SnackBar(content: Text('Order created'))
        : const SnackBar(content: Text('Failed to create order'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snack);
    if (result) Navigator.of(context).pop(true);
  }

  String _fmt(DateTime? d) => d == null ? 'Select' : DateFormat.yMd().format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _orderRefCtrl,
                decoration: const InputDecoration(labelText: 'Order Ref'),
                validator: (s) => (s == null || s.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Order Date'),
                      subtitle: Text(_fmt(_orderDate)),
                      onTap: () => _pickDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Delivery Date'),
                      subtitle: Text(_fmt(_deliveryDate)),
                      onTap: () => _pickDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _shipmentType,
                decoration: const InputDecoration(labelText: 'Shipment Type'),
                items: const [
                  DropdownMenuItem(value: 'FTL', child: Text('Full Truckload (FTL)')),
                  DropdownMenuItem(value: 'LTL', child: Text('Less than Truckload (LTL)')),
                ],
                onChanged: (v) => setState(() => _shipmentType = v ?? 'FTL'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pickupCtrl,
                decoration: const InputDecoration(labelText: 'Pickup Address'),
                validator: (s) => (s == null || s.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dropCtrl,
                decoration: const InputDecoration(labelText: 'Dropoff Address'),
                validator: (s) => (s == null || s.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _submit, child: const Text('Submit')),
            ],
          ),
        ),
      ),
    );
  }
}
