import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/safety_check.dart';
import '../services/safety_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dispatchIdController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _loading = false;
  String? _error;
  PreLoadingSafetyCheck? _latest;
  List<PreLoadingSafetyCheck> _history = const [];

  @override
  void dispose() {
    _dispatchIdController.dispose();
    super.dispose();
  }

  List<PreLoadingSafetyCheck> _filterByDate(List<PreLoadingSafetyCheck> list) {
    if (_fromDate == null && _toDate == null) return list;
    return list.where((item) {
      final ts = item.checkedAt ?? item.createdDate;
      if (ts == null) return false;
      final day = DateTime(ts.year, ts.month, ts.day);
      if (_fromDate != null && day.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day))) {
        return false;
      }
      if (_toDate != null && day.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day))) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _loadHistory() async {
    final id = int.tryParse(_dispatchIdController.text.trim());
    if (id == null) {
      setState(() => _error = 'invalidDispatchId'.tr());
      return;
    }
    if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
      setState(() => _error = 'dateRangeInvalid'.tr());
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _latest = null;
      _history = const [];
    });
    try {
      final service = Provider.of<SafetyService>(context, listen: false);
      final latest = await service.fetchLatest(id);
      final history = await service.fetchHistory(id);
      final filtered = _filterByDate(history);
      if (!mounted) return;
      setState(() {
        _latest = latest;
        _history = filtered;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('historyTitle'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _inputCard(),
            const SizedBox(height: 12),
            if (_loading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (!_loading && _latest != null) _insightCard(),
            if (!_loading && _history.isNotEmpty) _historyList(),
            if (!_loading && _latest == null && _history.isEmpty && _error == null)
              _emptyState(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inputCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('lookupDispatchHistory'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _dispatchIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'dispatchId'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dateField(
                    label: 'fromDate'.tr(),
                    value: _fromDate,
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateField(
                    label: 'toDate'.tr(),
                    value: _toDate,
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _loadHistory,
              child: Text(_loading ? 'loading'.tr() : 'viewHistory'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightCard() {
    final passFail = _latest?.result == SafetyResult.pass ? 'pass'.tr() : 'fail'.tr();
    return Card(
      color: _latest?.result == SafetyResult.pass
          ? Colors.green.shade50
          : Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'insights'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('latestResultLabel'.tr(args: [passFail])),
            if (_latest?.checkedByName != null)
              Text('checkedByLabel'.tr(args: [_latest!.checkedByName!])),
            if (_latest?.formattedTimestamp().isNotEmpty == true)
              Text('timestampLabel'.tr(args: [_latest!.formattedTimestamp()])),
            const SizedBox(height: 6),
            Text('totalChecks'.tr(args: [_history.length.toString()])),
          ],
        ),
      ),
    );
  }

  Widget _historyList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'history'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._history.map(
              (h) => Card(
                color: h.result == SafetyResult.pass
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(
                    h.result == SafetyResult.pass ? Icons.check_circle : Icons.error,
                    color: h.result == SafetyResult.pass ? Colors.green : Colors.red,
                  ),
                  title: Text(h.result == SafetyResult.pass ? 'pass'.tr() : 'fail'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (h.checkedByName != null) Text(h.checkedByName!),
                      if (h.formattedTimestamp().isNotEmpty) Text(h.formattedTimestamp()),
                      if (h.failReason != null && h.failReason!.isNotEmpty)
                        Text('reasonLabel'.tr(args: [h.failReason!])),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_fromDate ?? now) : (_toDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Widget _dateField({required String label, required DateTime? value, required VoidCallback onTap}) {
    final text = value != null ? DateFormat('yyyy-MM-dd').format(value) : 'select'.tr();
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.date_range),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text('$label: $text'),
      ),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8)),
    );
  }

  Widget _emptyState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        Text('noHistory'.tr(), style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
