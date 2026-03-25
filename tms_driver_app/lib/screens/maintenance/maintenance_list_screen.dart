import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/models/maintenance_model.dart';
import 'package:tms_driver_app/providers/maintenance_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MaintenanceProvider>().fetchTasks();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<MaintenanceProvider>().fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Maintenance Tasks'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          Consumer<MaintenanceProvider>(
            builder: (_, mp, __) => mp.overdueCount > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Chip(
                      label: Text(
                        '${mp.overdueCount} Overdue',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.maintenanceCreate)
                .then((_) => _onRefresh()),
        icon: const Icon(Icons.add),
        label: const Text('Request'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Consumer<MaintenanceProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(provider.error!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _onRefresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final tasks = provider.tasks;

          if (tasks.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.build_circle_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No maintenance tasks',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort: overdue first, then by dueDate ascending
          final sorted = [...tasks]..sort((a, b) {
              if (a.isOverdue && !b.isOverdue) return -1;
              if (!a.isOverdue && b.isOverdue) return 1;
              if (a.dueDate == null && b.dueDate == null) return 0;
              if (a.dueDate == null) return 1;
              if (b.dueDate == null) return -1;
              return a.dueDate!.compareTo(b.dueDate!);
            });

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _TaskCard(task: sorted[index]),
            ),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final MaintenanceTaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(color: Colors.red.shade300, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator dot
          Container(
            margin: const EdgeInsets.only(top: 4, right: 12),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(task.status, isOverdue),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isOverdue
                              ? Colors.red.shade700
                              : const Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOverdue)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.warning_amber_rounded,
                            color: Colors.red, size: 18),
                      ),
                  ],
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _StatusChip(
                        label: task.status,
                        color: _statusColor(task.status, isOverdue)),
                    if (task.taskType != null)
                      _StatusChip(
                          label: task.taskType!, color: Colors.blueGrey),
                    if (task.dueDate != null)
                      _StatusChip(
                        label: 'Due ${_formatDate(task.dueDate!)}',
                        color: isOverdue ? Colors.red : Colors.grey.shade600,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status, bool isOverdue) {
    if (isOverdue) return Colors.red;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'PENDING':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
