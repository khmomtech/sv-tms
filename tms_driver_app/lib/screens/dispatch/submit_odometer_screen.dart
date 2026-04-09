import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/dispatch_model.dart';
import '../../providers/dispatch_provider.dart';

class SubmitOdometerScreen extends StatefulWidget {
  final DispatchModel dispatch;

  const SubmitOdometerScreen({
    super.key,
    required this.dispatch,
  });

  @override
  State<SubmitOdometerScreen> createState() => _SubmitOdometerScreenState();
}

class _SubmitOdometerScreenState extends State<SubmitOdometerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startKmController = TextEditingController();
  final _endKmController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _startKmController.dispose();
    _endKmController.dispose();
    super.dispose();
  }

  Future<void> _submitOdometer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final startKm = double.parse(_startKmController.text);
      final endKm = double.parse(_endKmController.text);

      await context.read<DispatchProvider>().submitOdometer(
            dispatchId: widget.dispatch.id,
            startKm: startKm,
            endKm: endKm,
            recordedAt: DateTime.now(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Odometer log submitted successfully'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Odometer Reading'),
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
                        'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.dispatch.createdAt ?? DateTime.now())}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              // Start Odometer Reading
              TextFormField(
                controller: _startKmController,
                decoration: InputDecoration(
                  labelText: 'Start Odometer Reading (KM)',
                  hintText: 'e.g., 15000.5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.speed),
                  suffixText: 'KM',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Start reading is required';
                  }
                  try {
                    final km = double.parse(value!);
                    if (km < 0) return 'Reading cannot be negative';
                    return null;
                  } catch (_) {
                    return 'Please enter a valid number';
                  }
                },
              ),
              const SizedBox(height: 16.0),

              // End Odometer Reading
              TextFormField(
                controller: _endKmController,
                decoration: InputDecoration(
                  labelText: 'End Odometer Reading (KM)',
                  hintText: 'e.g., 15050.2',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.speed),
                  suffixText: 'KM',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'End reading is required';
                  }
                  try {
                    final endKm = double.parse(value!);
                    final startKm = double.tryParse(_startKmController.text);
                    if (endKm < 0) return 'Reading cannot be negative';
                    if (startKm != null && endKm < startKm) {
                      return 'End reading must be >= start reading';
                    }
                    return null;
                  } catch (_) {
                    return 'Please enter a valid number';
                  }
                },
              ),
              const SizedBox(height: 24.0),

              // Distance Calculation (if both fields filled)
              if (_startKmController.text.isNotEmpty &&
                  _endKmController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12.0),
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
                          'Distance: ${(double.parse(_endKmController.text) - double.parse(_startKmController.text)).toStringAsFixed(2)} KM',
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
              const SizedBox(height: 32.0),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitOdometer,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.check),
                  label:
                      Text(_isSubmitting ? 'Submitting...' : 'Submit Odometer'),
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
