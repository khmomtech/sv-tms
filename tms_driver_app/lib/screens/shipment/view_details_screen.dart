import 'package:flutter/material.dart';

// view_details_screen.dart

class ViewDetailsScreen extends StatelessWidget {
  final String taskId;

  const ViewDetailsScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ព័ត៌មានលម្អិត'),
        backgroundColor: const Color(0xFF2563eb),
      ),
      body: Center(
        child: Text(
          'ព័ត៌មានលម្អិតសម្រាប់ Task ID: $taskId',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
