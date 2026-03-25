import 'package:flutter/material.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('តម្លើងរបស់អ្នក'),
        backgroundColor: const Color(0xFF2563eb),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task ID
                Center(
                  child: Text('TASK ID:\n# $taskId',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 16),

                /// Pickup Section
                Row(
                  children: const [
                    Icon(Icons.arrow_circle_up, color: Colors.green),
                    SizedBox(width: 8),
                    Text('ចូលទំនិញ៖ ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('16.01.2024', style: TextStyle(color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.location_on_outlined),
                    SizedBox(width: 8),
                    Expanded(child: Text('27B QL1A, Phnom Penh, Cambodia')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('អត្ថិរ៉េត')),
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {},
                    ),
                  ],
                ),
                const Divider(height: 32),

                /// Drop-off Section
                Row(
                  children: const [
                    Icon(Icons.arrow_circle_down, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('ផ្ទេរទំនិញ៖ ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('16.01.2024', style: TextStyle(color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.location_on_outlined),
                    SizedBox(width: 8),
                    Expanded(child: Text('162A Battambang')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('បុគ្គលិក')),
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// COD + Notes
                const Text('តម្លៃសេវា',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('សរុប 9000 រៀល\nប្រាក់សាច់ 9000 រៀល'),
                ),
                const SizedBox(height: 16),
                const Text('កំណត់ចំណាំ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('សូមប្រុងប្រយ័ត្នពេលដឹកជញ្ជូន'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            // Handle start delivery logic
          },
          icon: const Icon(Icons.motorcycle, color: Colors.white),
          label: const Text(
            'ម៉ានដឹកទំនិញ',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
