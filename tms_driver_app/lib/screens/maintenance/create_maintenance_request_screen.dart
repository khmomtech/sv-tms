import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/maintenance_provider.dart';

class CreateMaintenanceRequestScreen extends StatefulWidget {
  const CreateMaintenanceRequestScreen({super.key});

  @override
  State<CreateMaintenanceRequestScreen> createState() =>
      _CreateMaintenanceRequestScreenState();
}

class _CreateMaintenanceRequestScreenState
    extends State<CreateMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _priority = 'MEDIUM';
  String _requestType = 'REPAIR';

  static const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
  static const _requestTypes = [
    'REPAIR',
    'PREVENTIVE',
    'INSPECTION',
    'EMERGENCY'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<MaintenanceProvider>().submitRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          requestType: _requestType,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maintenance request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      final error = context.read<MaintenanceProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to submit request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Submit Maintenance Request'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                children: [
                  _buildLabel('Title *'),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Describe the issue briefly'),
                    maxLength: 120,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Description'),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _inputDecoration(
                        'Provide additional details (optional)'),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                children: [
                  _buildLabel('Priority'),
                  _buildDropdown(
                    value: _priority,
                    items: _priorities,
                    onChanged: (v) => setState(() => _priority = v!),
                    itemColor: _priorityColor,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Request Type'),
                  _buildDropdown(
                    value: _requestType,
                    items: _requestTypes,
                    onChanged: (v) => setState(() => _requestType = v!),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Consumer<MaintenanceProvider>(
                builder: (_, provider, __) => ElevatedButton(
                  onPressed: provider.submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: provider.submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1A1A2E)),
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    Color Function(String)? itemColor,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(''),
      items: items
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(
                  s,
                  style: TextStyle(
                    color: itemColor != null ? itemColor(s) : null,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.amber.shade700;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
