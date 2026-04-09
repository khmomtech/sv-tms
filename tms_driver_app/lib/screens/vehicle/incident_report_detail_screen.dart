import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/driver_issue_model.dart';
import 'package:tms_driver_app/providers/driver_issue_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/screens/shipment/fullscreen_image_viewer.dart';

class IncidentReportDetailScreen extends StatefulWidget {
  const IncidentReportDetailScreen({super.key, required this.incidentId});

  final int incidentId;

  @override
  State<IncidentReportDetailScreen> createState() =>
      _IncidentReportDetailScreenState();
}

class _IncidentReportDetailScreenState
    extends State<IncidentReportDetailScreen> {
  DriverIssue? _issue;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final issue = await context
          .read<DriverIssueProvider>()
          .getIssueById(widget.incidentId);
      if (mounted) setState(() => _issue = issue);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Incident Detail'),
        backgroundColor: const Color(0xFF2563eb),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _issue == null
                ? null
                : () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.incidentReportEdit,
                      arguments: {'incidentId': widget.incidentId},
                    );
                    if (result == true) {
                      await _load();
                      Navigator.pop(context, true);
                    }
                  },
          ),
          PopupMenuButton<String>(
            onSelected: _issue == null ? null : _handleStatusChange,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'OPEN', child: Text('Mark as Open')),
              PopupMenuItem(
                  value: 'IN_PROGRESS', child: Text('Mark In Progress')),
              PopupMenuItem(value: 'RESOLVED', child: Text('Mark Resolved')),
              PopupMenuItem(value: 'CLOSED', child: Text('Mark Closed')),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 36),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }
    final issue = _issue!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              issue.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              _statusLabel(issue.status),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _badgeColor(issue.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm',
                                    context.locale.toString())
                                .format(issue.createdAt),
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                      if (issue.orderReference != null &&
                          issue.orderReference!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Ref: ${issue.orderReference}',
                            style: const TextStyle(
                                color: Color(0xFF374151), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  issue.description.isEmpty
                      ? 'No description provided'
                      : issue.description,
                  style: const TextStyle(color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
          if (issue.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Photos',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: issue.images.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final url = _imgUrl(issue.images[index]);
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(
                              imageUrl: url,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade200),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await _confirmDelete(context);
                    if (confirmed != true) return;
                    try {
                      await context
                          .read<DriverIssueProvider>()
                          .deleteIssue(issue.id);
                      if (mounted) {
                        Navigator.pop(context, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Incident deleted'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Delete failed: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.incidentReportEdit,
                      arguments: {'incidentId': issue.id},
                    );
                    if (res == true) {
                      await _load();
                      if (mounted) Navigator.pop(context, true);
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete incident'),
        content: const Text('Are you sure you want to delete this incident?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  String _imgUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    // Preserve path segments while ensuring /uploads prefix
    final path = raw.startsWith('/uploads/')
        ? raw
        : (raw.startsWith('/'))
            ? '/uploads$raw'
            : '/uploads/$raw';
    return '${ApiConstants.imageUrl}${Uri.encodeFull(path)}';
  }

  Future<void> _handleStatusChange(String status) async {
    if (_issue == null) return;
    try {
      await context
          .read<DriverIssueProvider>()
          .updateIssueStatus(_issue!.id, status);
      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }
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
