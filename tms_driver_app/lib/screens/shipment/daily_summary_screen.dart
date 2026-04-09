import 'package:flutter/material.dart';

class DailySummaryScreen extends StatelessWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accept optional summary data via route arguments (Map) or fall back to sample values.
    final args = ModalRoute.of(context)?.settings.arguments;
    final data = (args is Map) ? args : const {};

    final String date = data['date']?.toString() ?? '26 មីនា 2025';
    final int completedTasks = data['completedTasks'] as int? ?? 6;
    final double totalCOD =
        data['totalCOD'] is num ? (data['totalCOD'] as num).toDouble() : 124500.0;
    final String startTime = data['startTime']?.toString() ?? '07:30 AM';
    final String endTime = data['endTime']?.toString() ?? '05:45 PM';

    final int tripsToday = data['tripsToday'] as int? ?? completedTasks;
    final int tripsWeek = data['tripsWeek'] as int? ?? 18;
    final double onTimeRate = data['onTimeRate'] as double? ?? 92.0;

    final String vehiclePlate = data['vehiclePlate']?.toString() ?? 'គ្មាន';
    final String vehicleStatus = data['vehicleStatus']?.toString() ?? 'N/A';
    final String vehicleHealth = data['vehicleHealth']?.toString() ?? 'Good';
    final String nextMaintenance = data['nextMaintenance']?.toString() ?? 'N/A';

    final int openIssues = data['openIssues'] as int? ?? 2;
    final int closedIssues = data['closedIssues'] as int? ?? 5;
    final int complaints = data['complaints'] as int? ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFFeef2fb),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563eb),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'របាយការណ៍ប្រចាំថ្ងៃ',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('កាលបរិច្ឆេទ', date),
                  const SizedBox(height: 16),
                  _buildSummaryItem(
                    'ចំនួនការងារដែលបានបញ្ចប់',
                    '$completedTasks ការងារ',
                    Icons.task_alt,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryItem(
                    'ចំនួនប្រាក់ COD',
                    '${totalCOD.toStringAsFixed(0)} រៀល',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryItem(
                    'ម៉ោងចាប់ផ្តើម',
                    startTime,
                    Icons.access_time,
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryItem(
                    'ម៉ោងបញ្ចប់',
                    endTime,
                    Icons.timelapse_outlined,
                    Colors.deepPurple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _sectionCard(
              title: 'ត្រឡប់',
              subtitle: 'Trips & On-time',
              child: Row(
                children: [
                  Expanded(
                    child: _metricTile(
                      label: 'ថ្ងៃនេះ',
                      value: '$tripsToday',
                      icon: Icons.local_shipping_outlined,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricTile(
                      label: 'សប្តាហ៍នេះ',
                      value: '$tripsWeek',
                      icon: Icons.date_range,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricTile(
                      label: 'On-Time %',
                      value: '${onTimeRate.toStringAsFixed(0)}%',
                      icon: Icons.timer_outlined,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _sectionCard(
              title: 'យានយន្ត',
              subtitle: 'Vehicle & Maintenance',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          label: 'Plate',
                          value: vehiclePlate,
                          icon: Icons.directions_car,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricTile(
                          label: 'Status',
                          value: vehicleStatus,
                          icon: Icons.speed,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          label: 'Health',
                          value: vehicleHealth,
                          icon: Icons.health_and_safety,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricTile(
                          label: 'បន្ទាប់',
                          value: nextMaintenance,
                          icon: Icons.build_circle_outlined,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _sectionCard(
              title: 'បញ្ហា & របាយការណ៍',
              subtitle: 'Issues / Complaints',
              child: Row(
                children: [
                  Expanded(
                    child: _metricTile(
                      label: 'កំពុងបើក',
                      value: '$openIssues',
                      icon: Icons.report_problem,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricTile(
                      label: 'បានបិទ',
                      value: '$closedIssues',
                      icon: Icons.verified,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricTile(
                      label: 'ពាក្យបណ្ដឹង',
                      value: '$complaints',
                      icon: Icons.feedback_outlined,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text('ត្រឡប់ទៅទំព័រដើម',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563eb),
                minimumSize: const Size(double.infinity, 50),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: const TextStyle(fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
      String title, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricTile(
      {required String label,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6b7280),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
      {String? title, String? subtitle, required Widget child}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6b7280))),
              ],
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
