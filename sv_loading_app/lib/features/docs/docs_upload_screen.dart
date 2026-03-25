// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../state/connectivity_provider.dart';
import '../../state/g_management_context_provider.dart';
import '../../state/loading_provider.dart';
import '../../state/trip_provider.dart';
import '../../widgets/app_scaffold.dart';

class DocsUploadScreen extends StatefulWidget {
  const DocsUploadScreen({super.key});

  @override
  State<DocsUploadScreen> createState() => _DocsUploadScreenState();
}

class _DocsUploadScreenState extends State<DocsUploadScreen> {
  final _picker = ImagePicker();
  final _notes = TextEditingController();
  final _sessionId = TextEditingController();
  String docType = 'OTHER';
  final List<File> files = [];

  @override
  void dispose() {
    _notes.dispose();
    _sessionId.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() {
      files.addAll(picked.map((x) => File(x.path)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().currentTrip;
    final conn = context.watch<ConnectivityProvider>();
    final provider = context.watch<LoadingProvider>();
    final gContext = context.watch<GManagementContextProvider>();

    return AppScaffold(
      titleKey: 'docs',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
                '${'trip_id'.tr()}: ${gContext.activeDispatchId ?? trip?.dispatchId ?? '-'}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: docType,
              items: const [
                DropdownMenuItem(value: 'INVOICE', child: Text('INVOICE')),
                DropdownMenuItem(
                    value: 'PACKING_LIST', child: Text('PACKING_LIST')),
                DropdownMenuItem(
                    value: 'PROOF_OF_DELIVERY',
                    child: Text('PROOF_OF_DELIVERY')),
                DropdownMenuItem(value: 'OTHER', child: Text('OTHER')),
              ],
              onChanged: (v) => setState(() => docType = v ?? 'OTHER'),
              decoration: InputDecoration(labelText: 'document_type'.tr()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sessionId,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'session_id_auto'.tr(),
                helperText:
                    '${'current'.tr()}: ${gContext.activeSessionId ?? provider.currentSessionId ?? '-'}',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: 'notes'.tr())),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text('pick_images'.tr()),
            ),
            const SizedBox(height: 8),
            if (files.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: files
                    .map((f) => Chip(label: Text(f.uri.pathSegments.last)))
                    .toList(),
              ),
            const SizedBox(height: 14),
            if (provider.error != null)
              Text(provider.error!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final gContext =
                            context.read<GManagementContextProvider>();
                        final sessionId =
                            int.tryParse(_sessionId.text.trim()) ??
                                gContext.activeSessionId ??
                                provider.currentSessionId;
                        if (sessionId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('error_session_upload_required'.tr())),
                          );
                          return;
                        }
                        if (files.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('error_pick_image'.tr())));
                          return;
                        }
                        await context.read<LoadingProvider>().uploadDocs(
                              sessionId: sessionId,
                              documentType: docType,
                              files: files,
                              extra: {'notes': _notes.text.trim()},
                              online: conn.isOnline,
                            );
                        await gContext.setActiveSessionId(sessionId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(conn.isOnline
                                ? 'msg_uploaded'.tr()
                                : 'save_offline'.tr())));
                      },
                label: provider.isLoading
                    ? const Text('...')
                    : Text('upload'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
