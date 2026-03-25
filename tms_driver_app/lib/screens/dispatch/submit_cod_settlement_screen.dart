import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/dispatch_model.dart';
import '../../providers/dispatch_provider.dart';

class SubmitCodSettlementScreen extends StatefulWidget {
  final DispatchModel dispatch;
  final double? expectedAmount;

  const SubmitCodSettlementScreen({
    super.key,
    required this.dispatch,
    this.expectedAmount,
  });

  @override
  State<SubmitCodSettlementScreen> createState() =>
      _SubmitCodSettlementScreenState();
}

class _SubmitCodSettlementScreenState extends State<SubmitCodSettlementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _currency = 'USD';
  bool _isSubmitting = false;

  final List<String> _currencies = ['USD', 'KHR', 'THB', 'VND'];

  @override
  void initState() {
    super.initState();
    if (widget.expectedAmount != null) {
      _amountController.text = widget.expectedAmount.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitSettlement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);

      await context.read<DispatchProvider>().submitCodSettlement(
            dispatchId: widget.dispatch.id,
            amount: amount,
            currency: _currency,
            collectedAt: DateTime.now(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('COD settlement submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDifferent = widget.expectedAmount != null &&
        _amountController.text.isNotEmpty &&
        (double.tryParse(_amountController.text) ?? 0) != widget.expectedAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('COD Settlement'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dispatch Info Card
              Card(
                margin: const EdgeInsets.only(bottom: 24.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'ID: ${widget.dispatch.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Status: ${widget.dispatch.status}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Delivered: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.dispatch.createdAt ?? DateTime.now())}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              // Expected vs Actual Info
              if (widget.expectedAmount != null)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(bottom: 24.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          'Expected: $_currency ${widget.expectedAmount!.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Currency Selector
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.currency_pound),
                  ),
                  items: _currencies
                      .map((currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _currency = value);
                    }
                  },
                ),
              ),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount Collected',
                  hintText: 'e.g., 50.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: _currency,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}), // Refresh UI for mismatch
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Amount is required';
                  try {
                    final amount = double.parse(value!);
                    if (amount < 0) return 'Amount cannot be negative';
                    return null;
                  } catch (_) {
                    return 'Please enter a valid amount';
                  }
                },
              ),
              const SizedBox(height: 16.0),

              // Discrepancy Warning
              if (isDifferent)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount Mismatch',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Expected: $_currency ${widget.expectedAmount!.toStringAsFixed(2)} | Actual: $_currency ${double.parse(_amountController.text).toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24.0),

              // Info Text
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settlement Notes:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      '• Verify the amount before submission\n'
                      '• Include any applicable discounts\n'
                      '• Report any discrepancies to support',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitSettlement,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Settlement'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
