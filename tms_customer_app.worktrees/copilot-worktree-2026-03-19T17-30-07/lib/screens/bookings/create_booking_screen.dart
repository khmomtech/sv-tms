// Clean CreateBookingScreen implementation
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/package.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import 'preview_booking_screen.dart';

class CreateBookingScreen extends StatefulWidget {
  final Booking? draft;
  const CreateBookingScreen({Key? key, this.draft}) : super(key: key);

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _pickupCompanyCtrl = TextEditingController();
  final _destinationCompanyCtrl = TextEditingController();
  final _totalWeightCtrl = TextEditingController();
  final _totalVolumeCtrl = TextEditingController();
  final _palletCountCtrl = TextEditingController();
  final _containerNoCtrl = TextEditingController();
  final _specialHandlingCtrl = TextEditingController();
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();

  List<PackageItem> _packages = [];
  bool _isSubmitting = false;
  String? _serviceType;
  String? _truckType;
  String? _cargoType;
  DateTime? _pickupDateTime;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    if (d != null) {
      _titleCtrl.text = d.title;
      _pickupCtrl.text = d.pickupAddress;
      _dropoffCtrl.text = d.dropoffAddress;
      _contactNameCtrl.text = d.contactName ?? '';
      _contactPhoneCtrl.text = d.contactPhone ?? '';
      _notesCtrl.text = d.notes ?? '';
      _serviceType = d.serviceType ?? d.vehicleType;
      _pickupCompanyCtrl.text = d.pickupCompany ?? '';
      _destinationCompanyCtrl.text = d.destinationCompany ?? '';
      _totalWeightCtrl.text = d.totalWeightTons?.toString() ?? '';
      _totalVolumeCtrl.text = d.totalVolumeCbm?.toString() ?? '';
      _palletCountCtrl.text = d.palletCount?.toString() ?? '';
      _containerNoCtrl.text = d.containerNo ?? '';
      _specialHandlingCtrl.text = d.specialHandlingNotes ?? '';
      _receiverNameCtrl.text = d.receiverName ?? '';
      _receiverPhoneCtrl.text = d.receiverPhone ?? '';
      _pickupDateTime = d.pickupDateTime;
      _packages = d.packages ?? [];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _notesCtrl.dispose();
    _pickupCompanyCtrl.dispose();
    _destinationCompanyCtrl.dispose();
    _totalWeightCtrl.dispose();
    _totalVolumeCtrl.dispose();
    _palletCountCtrl.dispose();
    _containerNoCtrl.dispose();
    _specialHandlingCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (time == null) return;
    setState(() => _pickupDateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _addPackage() {
    setState(() => _packages.add(
        PackageItem(itemType: 'PARCEL', qty: 1, weightKg: null, cod: 0.0)));
  }

  void _removePackage(int i) {
    setState(() => _packages.removeAt(i));
  }

  Future<void> _saveDraft() async {
    final provider = Provider.of<BookingsProvider>(context, listen: false);
    final draft = provider.createDraft(
      title: _titleCtrl.text.trim().isNotEmpty
          ? _titleCtrl.text.trim()
          : 'Booking',
      pickupAddress: _pickupCtrl.text.trim(),
      dropoffAddress: _dropoffCtrl.text.trim(),
      contactName: _contactNameCtrl.text.trim().isEmpty
          ? null
          : _contactNameCtrl.text.trim(),
      contactPhone: _contactPhoneCtrl.text.trim().isEmpty
          ? null
          : _contactPhoneCtrl.text.trim(),
      vehicleType: _serviceType,
      serviceType: _serviceType,
      truckType: _truckType,
      cargoType: _cargoType,
      totalWeightTons: _totalWeightCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_totalWeightCtrl.text.trim()),
      totalVolumeCbm: _totalVolumeCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_totalVolumeCtrl.text.trim()),
      palletCount: _palletCountCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_palletCountCtrl.text.trim()),
      containerNo: _containerNoCtrl.text.trim().isEmpty
          ? null
          : _containerNoCtrl.text.trim(),
      specialHandlingNotes: _specialHandlingCtrl.text.trim().isEmpty
          ? null
          : _specialHandlingCtrl.text.trim(),
      receiverName: _receiverNameCtrl.text.trim().isEmpty
          ? null
          : _receiverNameCtrl.text.trim(),
      receiverPhone: _receiverPhoneCtrl.text.trim().isEmpty
          ? null
          : _receiverPhoneCtrl.text.trim(),
      pickupDateTime: _pickupDateTime,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      packages: _packages,
    );
    await provider.saveDraft(draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('draft_saved'.tr())));
    Navigator.of(context).pop();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<BookingsProvider>(context, listen: false);
      final draft = provider.createDraft(
        title: _titleCtrl.text.trim().isNotEmpty
            ? _titleCtrl.text.trim()
            : 'Booking',
        pickupAddress: _pickupCtrl.text.trim(),
        dropoffAddress: _dropoffCtrl.text.trim(),
        contactName: _contactNameCtrl.text.trim().isEmpty
            ? null
            : _contactNameCtrl.text.trim(),
        contactPhone: _contactPhoneCtrl.text.trim().isEmpty
            ? null
            : _contactPhoneCtrl.text.trim(),
        vehicleType: _serviceType,
        serviceType: _serviceType,
        truckType: _truckType,
        cargoType: _cargoType,
        totalWeightTons: _totalWeightCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_totalWeightCtrl.text.trim()),
        totalVolumeCbm: _totalVolumeCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_totalVolumeCtrl.text.trim()),
        palletCount: _palletCountCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_palletCountCtrl.text.trim()),
        containerNo: _containerNoCtrl.text.trim().isEmpty
            ? null
            : _containerNoCtrl.text.trim(),
        specialHandlingNotes: _specialHandlingCtrl.text.trim().isEmpty
            ? null
            : _specialHandlingCtrl.text.trim(),
        receiverName: _receiverNameCtrl.text.trim().isEmpty
            ? null
            : _receiverNameCtrl.text.trim(),
        receiverPhone: _receiverPhoneCtrl.text.trim().isEmpty
            ? null
            : _receiverPhoneCtrl.text.trim(),
        pickupDateTime: _pickupDateTime,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        packages: _packages,
      );

      final confirmed = await Navigator.of(context).push<bool?>(
          MaterialPageRoute(
              builder: (_) => PreviewBookingScreen(booking: draft)));
      if (confirmed != true) {
        setState(() => _isSubmitting = false);
        return;
      }

      await provider.addBooking(
        title: draft.title,
        pickupAddress: draft.pickupAddress,
        pickupCompany: draft.pickupCompany,
        dropoffAddress: draft.dropoffAddress,
        destinationCompany: draft.destinationCompany,
        contactName: draft.contactName,
        contactPhone: draft.contactPhone,
        vehicleType: draft.vehicleType,
        serviceType: draft.serviceType,
        truckType: draft.truckType,
        cargoType: draft.cargoType,
        totalWeightTons: draft.totalWeightTons,
        totalVolumeCbm: draft.totalVolumeCbm,
        palletCount: draft.palletCount,
        containerNo: draft.containerNo,
        specialHandlingNotes: draft.specialHandlingNotes,
        receiverName: draft.receiverName,
        receiverPhone: draft.receiverPhone,
        pickupDateTime: draft.pickupDateTime,
        notes: draft.notes,
        packages: draft.packages,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('booking_created'.tr())));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Booking')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: const InputDecoration(labelText: 'Service'),
                items: ['FTL', 'LTL', 'Container', 'City']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _serviceType = v),
                validator: (v) =>
                    v == null || v.isEmpty ? 'required'.tr() : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _truckType,
                decoration: const InputDecoration(labelText: 'Truck Type'),
                items: [
                  '6-Wheel',
                  '10-Wheel',
                  'Trailer',
                  '20ft Container',
                  '40ft Container'
                ]
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _truckType = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _pickupCompanyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Pickup Company / Warehouse')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _pickupCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Pickup Address'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'required'.tr() : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _dropoffCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Dropoff Address'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'required'.tr() : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _destinationCompanyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Destination Company / Warehouse')),
              const SizedBox(height: 12),
              const SizedBox(height: 12),

              // Cargo details
              Text('Cargo Details', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _cargoType,
                decoration: const InputDecoration(labelText: 'Cargo Type'),
                items: [
                  'General Goods',
                  'Palletized',
                  'Bulk Cargo',
                  'Food & Beverage',
                  'Construction Material',
                  'Heavy Machinery',
                  'Fragile Goods'
                ]
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _cargoType = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _totalWeightCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Total Weight (tons)'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextFormField(
                          controller: _totalVolumeCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Total Volume (CBM)'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _palletCountCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Pallet Count'),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextFormField(
                          controller: _containerNoCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Container No (if any)'))),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _specialHandlingCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Special Handling Notes'),
                  maxLines: 2),
              const SizedBox(height: 12),

              // Packages list
              Text('Packages', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._packages.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(child: Text(p.itemType)),
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removePackage(i))
                        ]),
                        Row(children: [
                          Expanded(child: Text('Qty: ${p.qty}')),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Weight: ${p.weightKg ?? '-'}'))
                        ]),
                        Row(children: [Expanded(child: Text('COD: ${p.cod}'))]),
                      ],
                    ),
                  ),
                );
              }).toList(),
              TextButton.icon(
                  onPressed: _addPackage,
                  icon: const Icon(Icons.add),
                  label: const Text('Add package')),

              const SizedBox(height: 12),
              TextFormField(
                  controller: _receiverNameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Receiver Name')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _receiverPhoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Receiver Phone'),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _contactNameCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Name')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _contactPhoneCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Phone'),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              ListTile(
                  title: Text(_pickupDateTime == null
                      ? 'Pickup time'
                      : _pickupDateTime.toString()),
                  trailing: TextButton(
                      onPressed: _pickDateTime, child: const Text('Select'))),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3),

              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit')),
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: _isSubmitting ? null : _saveDraft,
                  child: const Text('Save Draft')),
            ],
          ),
        ),
      ),
    );
  }
}
