import 'package:flutter/material.dart';

class ReportModel {
  final String taskId;
  final String issueType;
  final String description;
  final DateTime reportedAt;
  final String status;

  ReportModel({
    required this.taskId,
    required this.issueType,
    required this.description,
    required this.reportedAt,
    required this.status,
  });
}

class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mocked list of reports – replace with provider or API
    final List<ReportModel> reportList = [
      ReportModel(
        taskId: 'BAQENPX-24FT',
        issueType: 'Package Damaged',
        description: 'Box was torn when picked up.',
        reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'Pending',
      ),
      ReportModel(
        taskId: 'AX34VWT-92ZK',
        issueType: 'Late Delivery',
        description: 'Traffic caused delay.',
        reportedAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'Resolved',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ប្រវត្តិការរាយការណ៍'),
        backgroundColor: const Color(0xFF2563eb),
        centerTitle: true,
      ),
      body: reportList.isEmpty
          ? const Center(child: Text('មិនមានប្រវត្តិរាយការណ៍'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reportList.length,
              itemBuilder: (context, index) {
                final report = reportList[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TASK ID: #${report.taskId}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('ប្រភេទបញ្ហា: ${report.issueType}'),
                        const SizedBox(height: 4),
                        Text('ពិពណ៌នា: ${report.description}'),
                        const SizedBox(height: 4),
                        Text(
                          "ថ្ងៃរាយការណ៍: ${report.reportedAt.toLocal().toString().split(".").first}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ស្ថានភាព: ${report.status}',
                          style: TextStyle(
                            color: report.status == 'Resolved'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
