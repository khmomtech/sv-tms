import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:signature/signature.dart';

class LoadingScreen extends StatefulWidget {
  final String taskId;
  const LoadingScreen(
      {super.key, required this.taskId, required List tasks, required String dispatchId});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final List<File> _proofImages = [];

  Future<void> _pickImage() async {
    if (_proofImages.length >= 4) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _proofImages.add(File(picked.path));
      });
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563eb),
        title: const Text('ឡើងទំនិញ'),
        centerTitle: true,
      ),
      body: isWide ? _buildWideLayout() : _buildMobileLayout(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            final signatureBytes = await _signatureController.toPngBytes();
            if (!mounted) return;
            if (signatureBytes == null || _proofImages.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please provide proof and signature.')),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proof submitted successfully!')),
            );
          },
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: const Text('បញ្ជាក់ឡើងទំនិញ',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(flex: 6, child: _buildMainContent()),
        Expanded(flex: 4, child: _buildMapView()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMainContent(),
        const SizedBox(height: 16),
        SizedBox(height: 300, child: _buildMapView()),
      ],
    );
  }

  Widget _buildMainContent() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TASK ID:\n# ${widget.taskId}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('STATUS\nកំពុងឡើង',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 16),
            _buildStopInfo(
              icon: Icons.arrow_circle_up,
              iconColor: Colors.green,
              label: 'ចូលទំនិញ៖ ',
              date: '16.01.2024',
              location: '27B QL1A, Phnom Penh, Cambodia',
              person: 'អត្ថិរ៉េត',
            ),
            const Divider(),
            _buildStopInfo(
              icon: Icons.arrow_circle_down,
              iconColor: Colors.blue,
              label: 'ផ្ទេរទំនិញ៖ ',
              date: '16.01.2024',
              location: '162A Battambang',
              person: 'បុគ្គលិក',
            ),
            const SizedBox(height: 24),
            _buildLabeledBox('តម្លៃសេវា', 'សរុប 9000 រៀល\nប្រាក់សាច់ 9000 រៀល'),
            const SizedBox(height: 16),
            _buildLabeledBox('កំណត់ចំណាំ', 'សូមប្រុងប្រយ័ត្នពេលដឹកជញ្ជូន'),
            const SizedBox(height: 24),
            const Text('រូបភាពបញ្ជាក់',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final img in _proofImages)
                  Image.file(img, width: 80, height: 80, fit: BoxFit.cover),
                if (_proofImages.length < 4)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('ហត្ថលេខា',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(border: Border.all()),
              child: Signature(controller: _signatureController),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _signatureController.clear(),
                  child: const Text('Clear Signature'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(11.562108, 104.888535),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: [
            Marker(
              point: LatLng(11.562108, 104.888535),
              width: 40,
              height: 40,
              rotate: true,
              child: const Icon(Icons.location_on, color: Colors.red),
            )
          ])
        ],
      ),
    );
  }

  Widget _buildStopInfo({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String date,
    required String location,
    required String person,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(date, style: TextStyle(color: iconColor)),
            const Spacer(),
            const Icon(Icons.settings, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined),
            const SizedBox(width: 8),
            Expanded(child: Text(location)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person_outline),
            const SizedBox(width: 8),
            Expanded(child: Text(person)),
            IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildLabeledBox(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(content),
        ),
      ],
    );
  }
}
