import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../features/auth/login_screen.dart';
import '../../state/auth_provider.dart';
import '../../state/g_management_context_provider.dart';
import '../../state/g_management_provider.dart';
import '../../widgets/app_scaffold.dart';

class PreEntrySafetyManagementScreen extends StatefulWidget {
  const PreEntrySafetyManagementScreen({super.key});

  @override
  State<PreEntrySafetyManagementScreen> createState() =>
      _PreEntrySafetyManagementScreenState();
}

class _PreEntrySafetyManagementScreenState
    extends State<PreEntrySafetyManagementScreen> {
  String _warehouse = 'ALL';
  String _stage = 'ALL';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final provider = context.read<GManagementProvider>();

    await provider.fetchDispatches(
      filter: DispatchMonitorFilter(
        page: 0,
        size: 100,
        status: _stage == 'ALL' ? null : _stage,
      ),
    );

    await provider.fetchSafetyList(
      warehouseCode: _warehouse == 'ALL' ? null : _warehouse,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GManagementProvider>();
    final monitorRows = provider.monitorRows;

    final completedCount = provider.safetyRows.where((e) {
      final status = provider.canonicalSafetyStatus(e['status']);
      return status == 'PASSED' || status == 'CONDITIONAL';
    }).length;

    final pendingCount = monitorRows.where((e) {
      final safety = provider.canonicalSafetyStatus(e['preEntrySafetyStatus']);
      return safety == 'NOT_STARTED';
    }).length;

    final awaitingTicketCount = monitorRows.where((e) {
      final stage = (e['status'] ?? '').toString().toUpperCase();
      return stage != 'IN_QUEUE';
    }).length;

    return AppScaffold(
      titleKey: 'pre_entry_safety_management',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          Text(
            'g_management'.tr(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'pre_entry_safety_management'.tr(),
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'pre_entry_help'.tr(),
            style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 14),
          _filters(provider),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D5DB)),
              color: const Color(0xFFF8FAFC),
            ),
            child: Text(
              'pre_entry_flow'.tr(),
              style: const TextStyle(fontSize: 17, color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _statCard(
                      'pending'.tr(), pendingCount, const Color(0xFFB45309))),
              const SizedBox(width: 8),
              Expanded(
                  child: _statCard('completed'.tr(), completedCount,
                      const Color(0xFF047857))),
              const SizedBox(width: 8),
              Expanded(
                  child: _statCard('awaiting_ticket'.tr(), awaitingTicketCount,
                      const Color(0xFFC2410C))),
            ],
          ),
          const SizedBox(height: 12),
          _dispatchList(provider),
          if (provider.error != null) ...[
            const SizedBox(height: 10),
            _errorBlock(provider.error!),
          ],
        ],
      ),
    );
  }

  Widget _errorBlock(String message) {
    final expired = _isTokenExpired(message);
    if (!expired) {
      return Text(message, style: const TextStyle(color: Colors.red));
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'session_expired_signin'.tr(),
            style: const TextStyle(
                color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.login),
            label: Text('go_to_login'.tr()),
          ),
        ],
      ),
    );
  }

  bool _isTokenExpired(String message) {
    final m = message.toLowerCase();
    return m.contains('token expired') ||
        m.contains('access token expired') ||
        m.contains('jwt expired') ||
        m.contains('401') ||
        m.contains('unauthorized');
  }

  Widget _filters(GManagementProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _warehouse,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'warehouse'.tr()),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('ALL')),
              DropdownMenuItem(value: 'KHB', child: Text('KHB')),
              DropdownMenuItem(value: 'W2', child: Text('W2')),
              DropdownMenuItem(value: 'W3', child: Text('W3')),
            ],
            onChanged: (v) => setState(() => _warehouse = v ?? 'ALL'),
          ),
        ),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _stage,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'stage'.tr()),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('ALL')),
              DropdownMenuItem(
                  value: 'ARRIVED_LOADING', child: Text('ARRIVED_LOADING')),
              DropdownMenuItem(value: 'IN_QUEUE', child: Text('IN_QUEUE')),
              DropdownMenuItem(value: 'LOADED', child: Text('LOADED')),
            ],
            onChanged: (v) => setState(() => _stage = v ?? 'ALL'),
          ),
        ),
        SizedBox(
          width: 170,
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fromDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _fromDate = picked);
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(
                _fromDate == null ? 'from_date'.tr() : _fmtDate(_fromDate!)),
          ),
        ),
        SizedBox(
          width: 170,
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _toDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _toDate = picked);
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(_toDate == null ? 'to_date'.tr() : _fmtDate(_toDate!)),
          ),
        ),
        SizedBox(
          width: 130,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _refresh,
            child: Text('refresh'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, int value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
                fontSize: 38, fontWeight: FontWeight.w800, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _dispatchList(GManagementProvider provider) {
    final rows = provider.monitorRows;
    final safetyByDispatch = <int, Map<String, dynamic>>{};
    for (final s in provider.safetyRows) {
      final did = _asInt(s['dispatchId']);
      if (did != null) {
        safetyByDispatch[did] = s;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF334155)),
          columns: [
            DataColumn(label: Text('dispatch'.tr())),
            DataColumn(label: Text('driver'.tr())),
            DataColumn(label: Text('truck'.tr())),
            DataColumn(label: Text('stage'.tr())),
            DataColumn(label: Text('warehouse'.tr())),
            DataColumn(label: Text('pre_entry_safety'.tr())),
            DataColumn(label: Text('loading_safety'.tr())),
            DataColumn(label: Text('next_step'.tr())),
            DataColumn(label: Text('actions'.tr())),
          ],
          rows: rows.map((row) {
            final dispatchId = _asInt(row['id'] ?? row['dispatchId']);
            final driverName = (row['driverName'] ?? '-').toString();
            final truck =
                (row['truckPlate'] ?? row['vehiclePlate'] ?? '-').toString();
            final stage = (row['status'] ?? '-').toString();
            final warehouse = (row['warehouseCode'] ?? '-').toString();
            final preEntry =
                provider.canonicalSafetyStatus(row['preEntrySafetyStatus']);
            final loadingSafety =
                (row['loadingSafetyStatus'] ?? 'PENDING').toString();

            return DataRow(cells: [
              DataCell(Text(dispatchId == null ? '-' : '#$dispatchId')),
              DataCell(Text(driverName)),
              DataCell(Text(truck)),
              DataCell(_stageChip(stage)),
              DataCell(Text(warehouse)),
              DataCell(_statusChip(preEntry)),
              DataCell(Text(loadingSafety)),
              const DataCell(Text('-')),
              DataCell(
                  _actionsCell(provider, dispatchId, row, safetyByDispatch)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _actionsCell(
    GManagementProvider provider,
    int? dispatchId,
    Map<String, dynamic> row,
    Map<int, Map<String, dynamic>> safetyByDispatch,
  ) {
    if (dispatchId == null) {
      return const Text('-');
    }
    final existingSafety = safetyByDispatch[dispatchId];
    final checkId = _asInt(existingSafety?['id'] ?? existingSafety?['checkId']);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        if (action == 'create') {
          await _openChecklistForm(dispatchId, row);
          return;
        }
        if (action == 'edit') {
          await _openChecklistForm(
            dispatchId,
            row,
            existingSafety: existingSafety,
          );
          return;
        }
        if (action == 'view') {
          if (checkId == null) return;
          await provider.fetchSafetyById(checkId);
          if (!mounted) return;
          await _showSafetyDetailDialog(provider.safetyDetail);
          return;
        }
        if (action == 'delete') {
          if (checkId == null) return;
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('delete_checklist'.tr()),
              content: Text('${'delete_checklist_confirm'.tr()} #$dispatchId?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('cancel'.tr()),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('delete'.tr()),
                ),
              ],
            ),
          );
          if (ok != true) return;
          await provider.deleteSafetyChecklist(checkId);
          if (!mounted) return;
          if (provider.error == null) {
            await _refresh();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('checklist_deleted'.tr())),
            );
          }
        }
      },
      itemBuilder: (_) {
        return [
          if (checkId == null)
            PopupMenuItem(
                value: 'create', child: Text('create_checklist'.tr())),
          if (checkId != null)
            PopupMenuItem(value: 'edit', child: Text('edit_checklist'.tr())),
          if (checkId != null)
            PopupMenuItem(value: 'view', child: Text('view_checklist'.tr())),
          if (checkId != null)
            PopupMenuItem(
                value: 'delete', child: Text('delete_checklist'.tr())),
        ];
      },
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toUpperCase();
    final color = switch (normalized) {
      'PASSED' => const Color(0xFF059669),
      'CONDITIONAL' => const Color(0xFFB45309),
      'FAILED' => const Color(0xFFDC2626),
      _ => const Color(0xFF64748B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        normalized,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _stageChip(String stage) {
    final normalized = stage.toUpperCase();
    final color = switch (normalized) {
      'LOADED' => const Color(0xFF059669),
      'IN_QUEUE' => const Color(0xFF2563EB),
      _ => const Color(0xFF64748B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(normalized,
          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }

  Future<void> _openChecklistForm(
    int dispatchId,
    Map<String, dynamic> row, {
    Map<String, dynamic>? existingSafety,
  }) async {
    await context.read<GManagementProvider>().fetchSafetyByDispatch(dispatchId);
    if (!mounted) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ChecklistFormScreen(
          dispatchId: dispatchId,
          dispatchRow: row,
          existingSafety: existingSafety,
        ),
      ),
    );
    if (ok == true) {
      await _refresh();
    }
  }

  Future<void> _showSafetyDetailDialog(Map<String, dynamic>? detail) async {
    if (detail == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('${'dispatch'.tr()} #${detail['dispatchId'] ?? '-'}'),
          content: Text(
            '${'status'.tr()}: ${detail['status'] ?? '-'}\n'
            '${'vehicle_id'.tr()}: ${detail['vehicleId'] ?? '-'}\n'
            '${'driver_id'.tr()}: ${detail['driverId'] ?? '-'}\n'
            '${'warehouse'.tr()}: ${detail['warehouseCode'] ?? '-'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('close'.tr()),
            ),
          ],
        );
      },
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  String _fmtDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _ChecklistFormScreen extends StatefulWidget {
  final int dispatchId;
  final Map<String, dynamic> dispatchRow;
  final Map<String, dynamic>? existingSafety;

  const _ChecklistFormScreen({
    required this.dispatchId,
    required this.dispatchRow,
    this.existingSafety,
  });

  @override
  State<_ChecklistFormScreen> createState() => _ChecklistFormScreenState();
}

class _ChecklistFormScreenState extends State<_ChecklistFormScreen> {
  final _vehicleId = TextEditingController();
  final _driverId = TextEditingController();
  final _warehouse = TextEditingController(text: 'KHB');
  final _overallNote = TextEditingController();
  final _picker = ImagePicker();

  late final List<_ChecklistRowModel> _rows = _buildDefaultRows();

  @override
  void initState() {
    super.initState();
    final row = widget.dispatchRow;
    _driverId.text = _asStringInt(row['driverId']);
    _vehicleId.text = _asStringInt(row['vehicleId']);
    _warehouse.text = (row['warehouseCode'] ?? 'KHB').toString();
    _prefillFromExisting(widget.existingSafety);
  }

  @override
  void dispose() {
    _vehicleId.dispose();
    _driverId.dispose();
    _warehouse.dispose();
    _overallNote.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GManagementProvider>();
    final safety = provider.safetyDetail ?? const <String, dynamic>{};
    final currentStatus = (safety['status'] ?? 'NOT_STARTED').toString();
    final driverName = (widget.dispatchRow['driverName'] ?? '-').toString();
    final isEdit = widget.existingSafety != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? 'edit_pre_entry_checklist'.tr()
            : 'create_pre_entry_checklist'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        children: [
          Text(
            '${'dispatch'.tr()} #${widget.dispatchId}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 18),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('${'dispatch'.tr()}: #${widget.dispatchId}'),
                Text(
                    '${'truck'.tr()}: ${_vehicleId.text.isEmpty ? '-' : _vehicleId.text}'),
                Text('${'driver'.tr()}: $driverName'),
                Text('${'warehouse'.tr()}: ${_warehouse.text}'),
                Text('${'current_status'.tr()}: $currentStatus'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    for (final row in _rows) {
                      row.status = 'OK';
                    }
                  });
                },
                child: Text('set_all_ok'.tr()),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    for (final row in _rows) {
                      row.clearStatus();
                    }
                  });
                },
                child: Text('clear_all_statuses'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _checklistTable(provider),
          const SizedBox(height: 12),
          TextField(
            controller: _overallNote,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'overall_note'.tr(),
              hintText: 'operation_note'.tr(),
            ),
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 8),
            Text(provider.error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('cancel'.tr()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  child: Text(isEdit
                      ? 'update_checklist'.tr()
                      : 'submit_checklist'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checklistTable(GManagementProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 980),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  SizedBox(
                      width: 150,
                      child: Text('category'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 220,
                      child: Text('item_name'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 160,
                      child: Text('status'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 260,
                      child: Text('remarks'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 220,
                      child: Text('photo'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 100,
                      child: Text('action'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Column(
                children: _rows.map((row) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(row.category,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(width: 220, child: Text(row.itemName)),
                        SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: row.status,
                            decoration: const InputDecoration(isDense: true),
                            items: const [
                              DropdownMenuItem(
                                  value: '', child: Text('Select')),
                              DropdownMenuItem(value: 'OK', child: Text('OK')),
                              DropdownMenuItem(
                                  value: 'FAILED', child: Text('FAILED')),
                            ],
                            onChanged: (v) {
                              setState(() => row.status = v ?? '');
                            },
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: TextField(
                            controller: row.remarksController,
                            decoration: InputDecoration(
                              hintText: 'remarks_optional'.tr(),
                              isDense: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: Row(
                            children: [
                              OutlinedButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : () => _pickRowPhoto(row),
                                child: Text('choose_file'.tr()),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  row.photoName ?? 'no_file_chosen'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: OutlinedButton(
                            onPressed: () => setState(row.reset),
                            child: Text('reset'.tr()),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ChecklistRowModel> _buildDefaultRows() {
    return [
      _ChecklistRowModel(category: 'Tires', itemName: 'Tires check'),
      _ChecklistRowModel(category: 'Lights', itemName: 'Lights check'),
      _ChecklistRowModel(
          category: 'Load & Securing', itemName: 'Load & Securing check'),
      _ChecklistRowModel(category: 'Documents', itemName: 'Documents check'),
      _ChecklistRowModel(category: 'Weight', itemName: 'Weight check'),
      _ChecklistRowModel(category: 'Brakes', itemName: 'Brakes check'),
      _ChecklistRowModel(category: 'Windshield', itemName: 'Windshield check'),
    ];
  }

  String _categoryCode(String category) {
    if (category == 'Documents') return 'DOCUMENTS';
    return 'LOAD';
  }

  Future<void> _pickRowPhoto(_ChecklistRowModel row) async {
    final provider = context.read<GManagementProvider>();
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final uploadedUrl = await provider.uploadSafetyPhoto(File(picked.path));
    if (!mounted) return;
    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
      setState(() {
        row.photoUrl = uploadedUrl;
        row.photoName = picked.name;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('photo_uploaded'.tr())));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'photo_upload_failed'.tr())));
  }

  Future<void> _submit() async {
    final provider = context.read<GManagementProvider>();
    final gContext = context.read<GManagementContextProvider>();
    final checkId = _asInt(
        widget.existingSafety?['id'] ?? widget.existingSafety?['checkId']);

    final vehicleId = int.tryParse(_vehicleId.text.trim());
    final driverId = int.tryParse(_driverId.text.trim());
    if (vehicleId == null || driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_vehicle_driver_numeric'.tr())),
      );
      return;
    }

    if (_rows.any((r) => r.status.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_select_status_all_rows'.tr())),
      );
      return;
    }

    final failedWithoutRemarks = _rows
        .where((r) =>
            r.status == 'FAILED' && r.remarksController.text.trim().isEmpty)
        .map((r) => r.itemName)
        .toList();
    if (failedWithoutRemarks.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${'error_failed_items_require_remarks'.tr()}: ${failedWithoutRemarks.join(', ')}',
          ),
        ),
      );
      return;
    }

    final items = _rows.map((r) {
      return {
        'category': _categoryCode(r.category),
        'itemName': r.itemName,
        'status': r.status,
        if (r.remarksController.text.trim().isNotEmpty)
          'remarks': r.remarksController.text.trim(),
        if (r.photoUrl != null) 'photoUrl': r.photoUrl,
      };
    }).toList();

    final submission = SafetyChecklistSubmission(
      dispatchId: widget.dispatchId,
      vehicleId: vehicleId,
      driverId: driverId,
      warehouseCode: _warehouse.text.trim(),
      remarks: _overallNote.text.trim(),
      items: items,
    );

    if (checkId == null) {
      await provider.submitSafetyChecklist(submission);
    } else {
      await provider.updateSafetyChecklist(checkId, submission);
    }

    if (!mounted) return;
    if (provider.error == null) {
      await gContext.setActiveDispatchId(widget.dispatchId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  String _asStringInt(dynamic value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    return int.tryParse(value.toString())?.toString() ?? '';
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  void _prefillFromExisting(Map<String, dynamic>? existing) {
    if (existing == null) return;
    final existingRemarks = existing['remarks']?.toString();
    if (existingRemarks != null && existingRemarks.isNotEmpty) {
      _overallNote.text = existingRemarks;
    }
    final items = existing['items'];
    if (items is! List) return;
    for (final raw in items.whereType<Map>()) {
      final map = raw.map((k, v) => MapEntry(k.toString(), v));
      final itemName = map['itemName']?.toString().trim().toLowerCase();
      if (itemName == null || itemName.isEmpty) continue;
      _ChecklistRowModel? row;
      for (final candidate in _rows) {
        if (candidate.itemName.toLowerCase() == itemName) {
          row = candidate;
          break;
        }
      }
      if (row == null) continue;
      row.status =
          map['status']?.toString().toUpperCase() == 'OK' ? 'OK' : 'FAILED';
      final rowRemarks = map['remarks']?.toString();
      if (rowRemarks != null && rowRemarks.isNotEmpty) {
        row.remarksController.text = rowRemarks;
      }
      final photoUrl = map['photoUrl']?.toString();
      if (photoUrl != null && photoUrl.isNotEmpty) {
        row.photoUrl = photoUrl;
        row.photoName = 'uploaded';
      }
    }
  }
}

class _ChecklistRowModel {
  final String category;
  final String itemName;
  final TextEditingController remarksController = TextEditingController();
  String status = '';
  String? photoName;
  String? photoUrl;

  _ChecklistRowModel({required this.category, required this.itemName});

  void clearStatus() {
    status = '';
  }

  void reset() {
    status = '';
    remarksController.clear();
    photoName = null;
    photoUrl = null;
  }

  void dispose() {
    remarksController.dispose();
  }
}
