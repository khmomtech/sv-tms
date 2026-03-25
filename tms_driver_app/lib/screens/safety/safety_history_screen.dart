import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/safety_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

class SafetyHistoryScreen extends StatefulWidget {
  const SafetyHistoryScreen({super.key});

  @override
  State<SafetyHistoryScreen> createState() => _SafetyHistoryScreenState();
}

class _SafetyHistoryScreenState extends State<SafetyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SafetyProvider>();
      provider.loadHistory(
        from: DateTime.now().subtract(const Duration(days: 30)),
        to: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ប្រវត្តិត្រួតពិនិត្យសុវត្ថិភាព')),
      body: Consumer<SafetyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = provider.history;
          if (history.isEmpty) {
            return const Center(child: Text('គ្មានប្រវត្តិ'));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadHistory(
              from: DateTime.now().subtract(const Duration(days: 30)),
              to: DateTime.now(),
            ),
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                  title: Text(_formatDate(item.checkDate)),
                  subtitle: Text('ស្ថានភាព: ${_statusKh(item.status)}'),
                  trailing: _riskBadge(item.riskOverride ?? item.riskLevel),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.safetyDetail,
                      arguments: {'safety': item},
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _statusKh(String? status) {
    switch ((status ?? '').toUpperCase()) {
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

  Widget _riskBadge(String? risk) {
    if (risk == null || risk.isEmpty) return const SizedBox.shrink();
    final level = risk.toUpperCase();
    Color bg;
    switch (level) {
      case 'HIGH':
        bg = Colors.red;
        break;
      case 'MEDIUM':
        bg = Colors.orange;
        break;
      default:
        bg = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(level,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
