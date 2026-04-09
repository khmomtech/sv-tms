import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/user_provider.dart';
import '../../services/incident_service.dart';
import '../../widgets/common/index.dart';

/// Customer-facing incident list screen.
///
/// Follows the same structure as [OrderScreen]: a lightweight [StatelessWidget]
/// scaffold wraps a private [StatefulWidget] that owns the async load state.
class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('incidents'.tr())),
      body: const _IncidentListView(),
    );
  }
}

class _IncidentListView extends StatefulWidget {
  const _IncidentListView({Key? key}) : super(key: key);

  @override
  State<_IncidentListView> createState() => _IncidentListViewState();
}

class _IncidentListViewState extends State<_IncidentListView> {
  List<Map<String, dynamic>> _incidents = [];
  bool _loading = true;
  int? _lastCustomerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cid = context.read<UserProvider?>()?.customerId;
    if (cid != _lastCustomerId) {
      _lastCustomerId = cid;
      Future.microtask(() => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final cid = context.read<UserProvider>().customerId;
    if (cid == null) {
      if (!mounted) return;
      setState(() {
        _incidents = [];
        _loading = false;
      });
      return;
    }

    final raw = await IncidentService.fetchIncidents(cid);
    if (!mounted) return;

    if (raw == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load incidents')),
      );
      return;
    }

    setState(() {
      _incidents = raw;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_incidents.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.check_circle_outline,
        title: 'No incidents reported',
        subtitle: 'You have no active or past incidents.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _incidents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _IncidentCard(incident: _incidents[i]),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final title = incident['title']?.toString() ?? 'Incident';
    final status = incident['incidentStatus']?.toString() ?? 'NEW';
    final reportedAt = _formatDate(incident['reportedAt']);
    final tripRef = incident['tripReference']?.toString();

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (tripRef != null && tripRef.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Trip: $tripRef',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
                if (reportedAt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reportedAt,
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(
            label: status,
            color: _colorFor(status),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  Color _colorFor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return Colors.blueGrey;
      case 'VALIDATED':
        return Colors.orange;
      case 'CLOSED':
        return Colors.green;
      case 'LINKED_TO_CASE':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
