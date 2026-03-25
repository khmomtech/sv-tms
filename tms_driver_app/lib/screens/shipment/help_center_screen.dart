import 'package:flutter/material.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('មជ្ឈមណ្ឌលជំនួយ', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563eb),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpCard(
            title: 'តើធ្វើដូចម្តេចដើម្បីទទួលការងារ?',
            content:
                "ចូលទៅកាន់ផ្ទាំងសកម្មភាព រួចចុចប៊ូតុង 'ទទួល' នៅលើបញ្ជីការងារ។",
          ),
          _buildHelpCard(
            title: 'តើធ្វើដូចម្តេចបញ្ជូនបញ្ហា?',
            content:
                "ចុចលើប៊ូតុង 'រាយការណ៍បញ្ហា' នៅក្នុងការងារ ហើយបំពេញព័ត៌មាន។",
          ),
          _buildHelpCard(
            title: 'តើធ្វើដូចម្តេចដើម្បីឡើងរូបភាពបញ្ជាក់?',
            content:
                'នៅលើផ្ទាំង task បញ្ចូលរូបភាពដោយប្រើម៉ាស៊ីនថតឬជ្រើសពី Gallery។',
          ),
          const SizedBox(height: 24),
          const Text('ទំនាក់ទំនងជំនួយ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: const Text('ទូរស័ព្ទ: 010 123 456'),
            onTap: () => launchUrl(Uri.parse('tel:010123456')),
          ),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.blue),
            title: const Text('អ៊ីមែល: support@svapp.com'),
            onTap: () => launchUrl(Uri.parse('mailto:support@svapp.com')),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:010123456')),
            icon: const Icon(Icons.phone),
            label: const Text('ទាក់ទងភ្លាមៗ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563eb),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.messagesChat,
                arguments: const ChatRouteArgs(
                  entryPoint: 'support_center',
                  initialDraft: 'Hi support, I need help with ',
                ),
              );
            },
            icon: const Icon(Icons.chat),
            label: const Text('Contact Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard({required String title, required String content}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(content),
        ),
        leading: const Icon(Icons.support_agent, color: Colors.red),
      ),
    );
  }
}
