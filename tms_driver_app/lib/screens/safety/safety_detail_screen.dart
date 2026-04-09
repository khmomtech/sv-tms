import 'package:flutter/material.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/safety_check_model.dart';

class SafetyDetailScreen extends StatelessWidget {
  final SafetyCheck safetyCheck;

  const SafetyDetailScreen({super.key, required this.safetyCheck});

  @override
  Widget build(BuildContext context) {
    final status = (safetyCheck.status ?? '').toUpperCase();
    final risk = safetyCheck.riskOverride ?? safetyCheck.riskLevel;

    return Scaffold(
      appBar: AppBar(title: const Text('លម្អិតត្រួតពិនិត្យសុវត្ថិភាព')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoRow('កាលបរិច្ឆេទ', _formatDate(safetyCheck.checkDate)),
          _infoRow('ស្ថានភាព', _statusKh(status)),
          if (risk != null) _infoRow('កម្រិតហានិភ័យ', risk.toUpperCase()),
          if (safetyCheck.rejectReason != null &&
              safetyCheck.rejectReason!.isNotEmpty)
            _infoRow('មូលហេតុបដិសេធ', safetyCheck.rejectReason!),
          if (safetyCheck.notes != null && safetyCheck.notes!.trim().isNotEmpty)
            _infoRow('កំណត់សម្គាល់', safetyCheck.notes!.trim()),
          const SizedBox(height: 12),
          const Text('បញ្ជីការត្រួតពិនិត្យ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...safetyCheck.items.map((item) => Card(
                child: ListTile(
                  title: Text(item.itemLabelKm ?? item.itemKey),
                  subtitle: Text(
                      'លទ្ធផល: ${item.result ?? '-'} | កម្រិត: ${item.severity ?? '-'}'),
                ),
              )),
          if (safetyCheck.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('រូបភាពភ្ជាប់',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...safetyCheck.attachments.map((att) {
              final url = ApiConstants.image(att.fileUrl ?? '');
              if (url.endsWith('.jpg') ||
                  url.endsWith('.png') ||
                  url.endsWith('.jpeg')) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Image.network(url, height: 160, fit: BoxFit.cover),
                );
              }
              return ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(att.fileName ?? 'ឯកសារ'),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _statusKh(String status) {
    switch (status) {
      case 'DRAFT':
        return 'កំពុងបំពេញ';
      case 'WAITING_APPROVAL':
        return 'រង់ចាំអនុម័ត';
      case 'APPROVED':
        return 'បានអនុម័ត';
      case 'REJECTED':
        return 'ត្រូវបានបដិសេធ';
      default:
        return 'មិនទាន់ចាប់ផ្តើម';
    }
  }
}
