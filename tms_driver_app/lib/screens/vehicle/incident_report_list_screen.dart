import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/driver_issue_model.dart';
import 'package:tms_driver_app/providers/driver_issue_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/screens/shipment/fullscreen_image_viewer.dart';

import '../../utils/date_range_picker.dart';

/// Paginated list of incident reports (driver issues) filtered to incident type.
class IncidentReportListScreen extends StatefulWidget {
  const IncidentReportListScreen({super.key});

  @override
  State<IncidentReportListScreen> createState() =>
      _IncidentReportListScreenState();
}

class _IncidentReportListScreenState extends State<IncidentReportListScreen> {
  final _scrollController = ScrollController();
  bool _firstFetchDone = false;
  String? _statusFilter;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch(refresh: true));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool refresh = false}) async {
    final provider = Provider.of<DriverIssueProvider>(context, listen: false);
    try {
      await provider.fetchDriverIssuesPaginated(
        refresh: refresh,
        type: null, // show all to include newly created reports until backend types are set
        status: _statusFilter,
        fromDate: _dateRange?.start,
        toDate: _dateRange?.end,
      );
    } catch (e) {
      debugPrint('Incident list fetch failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('error.data_load_failed'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _firstFetchDone = true);
      } else {
        _firstFetchDone = true;
      }
    }
  }

  void _onScroll() {
    final provider =
        Provider.of<DriverIssueProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        provider.hasMore &&
        !provider.isLoading) {
      _fetch();
    }
  }

  Future<void> _onRefresh() async {
    await _fetch(refresh: true);
  }

  Future<void> _refreshWithFilters() async {
    await context.read<DriverIssueProvider>().fetchDriverIssuesPaginated(
          refresh: true,
          status: _statusFilter,
          fromDate: _dateRange?.start,
          toDate: _dateRange?.end,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverIssueProvider>();
    final issues = provider.issues;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('incident.list_title')),
        backgroundColor: const Color(0xFF2563eb),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async {
          final res = await Navigator.pushNamed(
              context, AppRoutes.incidentReport);
          if (res == true) {
            setState(() {
              _dateRange = null;
              _statusFilter = null;
              _firstFetchDone = false;
            });
            await _fetch(refresh: true);
          }
        },
        backgroundColor: const Color(0xFF2563eb),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr('incident.add_report')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: issues.isEmpty && !_firstFetchDone
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _FilterBar(
                      status: _statusFilter,
                      dateRange: _dateRange,
                      onStatusChanged: (value) async {
                        setState(() => _statusFilter = value);
                        await _fetch(refresh: true);
                      },
                      onDateRangeChanged: (range) async {
                        setState(() => _dateRange = range);
                        await _fetch(refresh: true);
                      },
                      onClear: () async {
                        setState(() {
                          _statusFilter = null;
                          _dateRange = null;
                        });
                        await _fetch(refresh: true);
                      },
                    ),
                    if (provider.hasError)
                      Container(
                        width: double.infinity,
                        color: Colors.red.shade50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.errorMessage ??
                                    tr('error.data_load_failed'),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: _onRefresh,
                              child: Text(tr('common.retry')),
                            ),
                          ],
                        ),
                    ),
                    if (issues.isEmpty && _firstFetchDone)
                      _buildEmptyState(context)
                    else
                      ...issues.map((issue) => _IncidentCard(
                            issue: issue,
                            onRefresh: _refreshWithFilters,
                          )),
                    if (provider.isLoading && provider.hasMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.issue,
    this.onRefresh,
  });

  final DriverIssue issue;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final thumbUrl =
        _buildThumbUrl(issue.images.isNotEmpty ? issue.images.first : null);
    final statusLabel = _statusLabel(issue.status);
    final statusColor = _badgeColor(issue.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: ListTile(
        leading: thumbUrl == null
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.report, color: Colors.redAccent),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  thumbUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.report, color: Colors.redAccent),
                ),
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                issue.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                statusLabel,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: statusColor,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month,
                    size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  _formatDate(context, issue.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              issue.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF374151)),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            final provider = context.read<DriverIssueProvider>();
            try {
              if (action == 'EDIT') {
                final updated = await Navigator.pushNamed(
                  context,
                  AppRoutes.incidentReportEdit,
                  arguments: {'incidentId': issue.id},
                );
                if (!context.mounted) return;
                if (updated == true && onRefresh != null) {
                  await onRefresh!();
                }
              } else if (action == 'DELETE') {
                final confirmed = await _confirmDelete(context);
                if (confirmed == true) {
                  await provider.deleteIssue(issue.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Issue deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } else {
                await provider.updateIssueStatus(issue.id, action);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status updated to $action'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                if (onRefresh != null) await onRefresh!();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Action failed: $e'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'OPEN', child: Text('Mark as Open')),
            const PopupMenuItem(
                value: 'IN_PROGRESS', child: Text('Mark In Progress')),
            const PopupMenuItem(
                value: 'RESOLVED', child: Text('Mark Resolved')),
            const PopupMenuItem(value: 'CLOSED', child: Text('Mark Closed')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'EDIT', child: Text('Edit details')),
            const PopupMenuItem(value: 'DELETE', child: Text('Delete')),
          ],
          child: Chip(
            label: Text(
              statusLabel,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: _badgeColor(issue.status),
          ),
        ),
        onTap: () async {
          final res = await Navigator.pushNamed(
            context,
            AppRoutes.incidentReportDetail,
            arguments: {'incidentId': issue.id},
          );
          if (!context.mounted) return;
          if (res == true) {
            if (onRefresh != null) {
              await onRefresh!();
            }
          }
        },
      ),
    );
  }

  String? _buildThumbUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final normalized = path.startsWith('/uploads/')
        ? path
        : (path.startsWith('/'))
            ? '/uploads$path'
            : '/uploads/$path';
    return '${ApiConstants.imageUrl}${Uri.encodeFull(normalized)}';
  }

}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.status,
    required this.dateRange,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onClear,
  });

  final String? status;
  final DateTimeRange? dateRange;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final statuses = <String?>[null, 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
    final dateLabel = dateRange == null
        ? tr('incident.any_date')
        : '${DateFormat('dd/MM/yy', context.locale.toString()).format(dateRange!.start)} - ${DateFormat('dd/MM/yy', context.locale.toString()).format(dateRange!.end)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: tr('incident.status_label'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: statuses
                      .map(
                        (s) => DropdownMenuItem<String?>(
                          value: s,
                          child: Text(s ?? tr('incident.all')),
                        ),
                      )
                      .toList(),
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showStableDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: dateRange,
                    );
                    onDateRangeChanged(picked);
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(dateLabel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh),
                label: Text(tr('incident.reset_filters')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildEmptyState(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF2563eb).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.fact_check, size: 36, color: Color(0xFF2563eb)),
        ),
        const SizedBox(height: 12),
        Text(
          tr('incident.empty_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          tr('incident.empty_subtitle'),
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.incidentReport),
          icon: const Icon(Icons.add),
          label: Text(tr('incident.report_cta')),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563eb),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        )
      ],
    ),
  );
}

String _formatDate(BuildContext context, DateTime date) {
  final locale = context.locale.toString();
  return DateFormat('dd-MM-yyyy', locale).format(date);
}

String _statusLabel(String raw) => raw.replaceAll('_', ' ');
Color _badgeColor(String status) {
  switch (status.toUpperCase()) {
    case 'NEW':
    case 'OPEN':
      return Colors.deepOrange;
    case 'IN_PROGRESS':
    case 'VALIDATED':
    case 'RESOLVED':
      return Colors.blue;
    case 'CLOSED':
      return Colors.green;
    default:
      return Colors.grey.shade700;
  }
}

Future<bool?> _confirmDelete(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('incident.delete_title')),
      content: Text(tr('incident.delete_message')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(tr('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(tr('delete')),
        ),
      ],
    ),
  );
}
