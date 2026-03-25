import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/models/driver_issue_model.dart';
import 'package:tms_driver_app/providers/driver_issue_provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

class IncidentReportEditScreen extends StatefulWidget {
  const IncidentReportEditScreen({super.key, required this.incidentId});

  final int incidentId;

  @override
  State<IncidentReportEditScreen> createState() =>
      _IncidentReportEditScreenState();
}

class _IncidentReportEditScreenState extends State<IncidentReportEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DriverIssue? _issue;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final data = await context
          .read<DriverIssueProvider>()
          .getIssueById(widget.incidentId);
      _titleCtrl.text = data.title;
      _descCtrl.text = data.description;
      setState(() => _issue = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<DriverIssueProvider>().updateIssue(
            issueId: widget.incidentId,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Edit Incident'),
        backgroundColor: const Color(0xFF2563eb),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _card(
                        title: 'Issue details',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Issue title',
                                filled: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Title is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Issue description',
                                alignLabelWithHint: true,
                                filled: true,
                              ),
                              minLines: 3,
                              maxLines: 6,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Description is required'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                      _card(
                        title: 'Status',
                        child: Row(
                          children: [
                            const Text('Current status: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4B5563))),
                            Chip(
                              label: Text(
                                _issue == null
                                    ? '-'
                                    : _issue!.status.replaceAll('_', ' '),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor:
                                  _badgeColor(_issue?.status ?? 'OPEN'),
                            )
                          ],
                        ),
                      ),
                      if (_issue != null && _issue!.images.isNotEmpty)
                        _card(
                          title: 'Existing photos',
                          child: SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _issue!.images.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, index) {
                                final url = _imgUrl(_issue!.images[index]);
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    url,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(
                                      width: 96,
                                      height: 96,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _saving ? null : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563eb),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  String _imgUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final path = raw.startsWith('/uploads/')
        ? raw
        : (raw.startsWith('/'))
            ? '/uploads$raw'
            : '/uploads/$raw';
    return '${ApiConstants.imageUrl}${Uri.encodeFull(path)}';
  }
}

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
