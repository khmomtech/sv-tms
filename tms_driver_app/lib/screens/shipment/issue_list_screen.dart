// Legacy shim to preserve imports. Re-export the new snake_case file.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/driver_issue_model.dart';
import 'package:tms_driver_app/providers/driver_issue_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/screens/shipment/fullscreen_image_viewer1.dart';
import 'package:tms_driver_app/screens/shipment/issue_form_screen.dart';

class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key});

  @override
  State<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends State<IssueListScreen> {
  final ScrollController _scrollController = ScrollController();
  String? selectedStatus;
  String? selectedType;
  String? _driverId; // will be loaded from DriverProvider

  bool _scrollListenerAttached = false;
  bool _firstPageRequested = false;

  final statusOptions = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
  final typeOptions = [
    'Mechanical Issue',
    'Accident',
    'Flat Tire',
    'Engine Problem',
    'Damage to Vehicle',
    'Theft/Vandalism',
    'Hit and Run',
    'Late Delivery',
    'Road Block',
    'Other',
  ];

  String _issueTypeOf(DriverIssue i) {
    // Backend uses 'title' field for issue type
    return i.title;
  }

  @override
  void initState() {
    super.initState();
    // Initial fetch happens after first frame to ensure providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAttachScrollListener();
      _maybeFetchFirstPage();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If driverId becomes available later (e.g., after async init), schedule fetch after frame.
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final newId = driverProvider.driverId;
    if (newId != _driverId) {
      _driverId = newId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeFetchFirstPage();
      });
    }
  }

  void _maybeAttachScrollListener() {
    if (_scrollListenerAttached) return;
    _scrollController.addListener(_onScroll);
    _scrollListenerAttached = true;
  }

  void _onScroll() {
    final issueProvider =
        Provider.of<DriverIssueProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        issueProvider.hasMore &&
        !issueProvider.isLoading &&
        _driverId != null &&
        _driverId!.isNotEmpty) {
      issueProvider.fetchDriverIssuesPaginated();
    }
  }

  void _maybeFetchFirstPage() {
    final issueProvider =
        Provider.of<DriverIssueProvider>(context, listen: false);
    if (_driverId != null &&
        _driverId!.isNotEmpty &&
        issueProvider.issues.isEmpty &&
        !issueProvider.isLoading &&
        !_firstPageRequested) {
      _firstPageRequested = true;
      // Defer to the microtask queue so this never runs within the current build phase.
      Future.microtask(() => issueProvider.fetchDriverIssuesPaginated());
    }
  }

  Future<void> _refresh() async {
    final id = _driverId;
    if (id == null || id.isEmpty) return;
    await Provider.of<DriverIssueProvider>(context, listen: false)
        .fetchDriverIssuesPaginated(refresh: true);
    if (!mounted) return;
  }

  Widget _leadingFor(DriverIssue issue) {
    if (issue.images.isNotEmpty) {
      final thumbUrl =
          '${ApiConstants.imageUrl}/uploads/${Uri.encodeComponent(issue.images.first)}';
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          thumbUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.report, color: _getStatusColor(issue.status)),
        ),
      );
    }
    return Icon(Icons.report, color: _getStatusColor(issue.status), size: 28);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverIssueProvider>();
    final noDriver = (_driverId == null || _driverId!.isEmpty);
    final issues = provider.issues.where((i) {
      final matchStatus = selectedStatus == null || i.status == selectedStatus;
      final issueType = _issueTypeOf(i);
      final matchType = selectedType == null || issueType == selectedType;
      return matchStatus && matchType;
    }).toList();

    final showLoaderRow =
        provider.isLoading && provider.hasMore && provider.issues.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFeef2fb),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563eb),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'issues.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildPill(
                    label: selectedStatus ?? 'issues.filter.all_status'.tr(),
                    icon: Icons.filter_list_rounded,
                    onTap: () => _openFilterDialog(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPill(
                    label: selectedType ?? 'issues.filter.all_types'.tr(),
                    icon: Icons.category_rounded,
                    onTap: () => _openFilterDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'issues_new_fab',
        elevation: 4,
        backgroundColor: const Color(0xFF2563eb),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IssueFormScreen(),
            ),
          );
          if (result == true) _refresh();
        },
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'issues.new'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        tooltip: 'issues.new_tooltip'.tr(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (provider.hasError)
              Container(
                width: double.infinity,
                color: Colors.red.shade50,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(provider.errorMessage ?? 'issues.error_unknown'.tr(),
                            style: const TextStyle(color: Colors.red))),
                    TextButton(
                      onPressed: _refresh,
                      child: Text('issues.retry'.tr()),
                    ),
                  ],
                ),
              ),
            if (noDriver)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_off,
                          size: 40, color: Colors.black45),
                      const SizedBox(height: 8),
                      Text('issues.no_driver'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: Text('issues.retry'.tr()),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: issues.isEmpty
                      // When there is no data yet, keep the list scrollable for pull-to-refresh
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            if (provider.isLoading) ...[
                              const Center(child: CircularProgressIndicator()),
                              const SizedBox(height: 16),
                              Center(child: Text('loading'.tr())),
                            ] else ...[
                              _buildEmptyState(context),
                            ],
                            const SizedBox(height: 80),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: issues.length + (showLoaderRow ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < issues.length) {
                              final issue = issues[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6.0, horizontal: 12.0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12.0),
                                  leading: _leadingFor(issue),
                                  title: Text(issue.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                          '${'issues.date'.tr()}: ${DateFormat('dd-MM-yyyy').format(issue.createdAt)}'),
                                      const SizedBox(height: 2),
                                      Text(
                                        issue.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (action) async {
                                      if (action == 'EDIT') {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                IssueFormScreen(
                                              existingIssue: issue,
                                            ),
                                          ),
                                        );
                                        if (result == true) _refresh();
                                      } else if (action == 'DELETE') {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('issues.actions.delete_title'.tr()),
                                            content: Text('issues.actions.delete_confirm'.tr()),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: Text('cancel'.tr())),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: Text('issues.actions.delete'.tr())),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await provider.deleteIssue(issue.id);
                                          _refresh();
                                        }
                                      } else {
                                        await provider.updateIssueStatus(
                                            issue.id, action);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                          value: 'RESOLVED',
                                          child: Text('issues.actions.resolved'.tr())),
                                      PopupMenuItem(
                                          value: 'CLOSED',
                                          child: Text('issues.actions.closed'.tr())),
                                      PopupMenuItem(
                                          value: 'EDIT', child: Text('issues.actions.edit'.tr())),
                                      PopupMenuItem(
                                          value: 'DELETE', child: Text('issues.actions.delete'.tr())),
                                    ],
                                    child: Chip(
                                      label: Text(
                                        issue.status,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      backgroundColor:
                                          _getStatusColor(issue.status),
                                    ),
                                  ),
                                  onTap: () => _showDetails(context, issue),
                                ),
                              );
                            } else {
                              // Loader row only when actively loading more
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                          },
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Widget _buildPill(
      {required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2563eb)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterDialog(BuildContext context) async {
    String? tempStatus = selectedStatus;
    String? tempType = selectedType;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'issues.filter.sheet_title'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: tempStatus,
                isExpanded: true,
                hint: Text('issues.filter.status'.tr()),
                items: statusOptions
                    .map((s) =>
                        DropdownMenuItem<String?>(value: s, child: Text(s)))
                    .toList()
                  ..insert(
                      0,
                      DropdownMenuItem<String?>(
                          value: null,
                          child: Text('issues.filter.all_status'.tr()))),
                onChanged: (v) => tempStatus = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                  value: tempType,
                isExpanded: true,
                hint: Text('issues.filter.type'.tr()),
                items: typeOptions
                    .map((t) =>
                        DropdownMenuItem<String?>(value: t, child: Text(t)))
                    .toList()
                  ..insert(
                      0,
                      DropdownMenuItem<String?>(
                          value: null,
                          child: Text('issues.filter.all_types'.tr()))),
                onChanged: (v) => tempType = v,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        tempStatus = null;
                        tempType = null;
                        Navigator.pop(context);
                        setState(() {
                          selectedStatus = null;
                          selectedType = null;
                        });
                      },
                      child: Text('issues.filter.reset'.tr()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedStatus = tempStatus;
                          selectedType = tempType;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563eb),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('issues.filter.apply'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.inbox, size: 48, color: Colors.black45),
        const SizedBox(height: 8),
        Text(
          'issues.empty.title'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'issues.empty.subtitle'.tr(),
          style: const TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          label: Text('issues.empty.refresh'.tr()),
        ),
      ],
    );
  }

  @override
  void dispose() {
    if (_scrollListenerAttached) {
      _scrollController.removeListener(_onScroll);
    }
    _scrollController.dispose();
    super.dispose();
  }
}

void _showDetails(BuildContext context, DriverIssue issue) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(issue.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${'issues.filter.status'.tr()}: ${issue.status}'),
          Text(
              '${'issues.date'.tr()}: ${DateFormat('dd-MM-yyyy').format(issue.createdAt)}'),
          const SizedBox(height: 8),
          Text(issue.description),
          if (issue.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: issue.images.length,
                itemBuilder: (context, index) {
                  final imageUrl =
                      '${ApiConstants.imageUrl}/uploads/${Uri.encodeComponent(issue.images[index])}';
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullscreenImageViewer(
                            imageUrls: issue.images
                                .map((img) =>
                                    '${ApiConstants.imageUrl}/uploads/${Uri.encodeComponent(img)}')
                                .toList(),
                            initialIndex: index,
                            isLocal: false,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('close'.tr()),
        ),
      ],
    ),
  );
}
