import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/driver_issue_model.dart';
import 'package:tms_driver_app/providers/driver_issue_provider.dart';

class IssueFormScreen extends StatefulWidget {
  final DriverIssue? existingIssue;

  const IssueFormScreen({super.key, this.existingIssue});

  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<File> _images = [];
  bool _isSubmitting = false;
  bool get _isEditMode => widget.existingIssue != null;
  static const int _maxImages = 5;
  static const int _maxImageSizeBytes = 10 * 1024 * 1024; // 10MB

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.existingIssue!.title;
      _descController.text = widget.existingIssue!.description;
    }
  }

  Future<void> _pickImageFrom(ImageSource source) async {
      if (_images.length >= _maxImages) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('issue_form.error_too_many'
                  .tr(args: [_maxImages.toString()])),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

    final picker = ImagePicker();
    try {
      if (source == ImageSource.gallery) {
        final picked = await picker.pickMultiImage();
        if (picked.isNotEmpty && mounted) {
          final validImages = <File>[];
          for (final xfile in picked) {
            if (_images.length + validImages.length >= _maxImages) break;
            final file = File(xfile.path);
            final size = await file.length();
            if (size <= _maxImageSizeBytes) {
              validImages.add(file);
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('issue_form.error_too_large'
                      .tr(args: [xfile.name])),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
          if (validImages.isNotEmpty) {
            setState(() => _images.addAll(validImages));
          }
        }
      } else {
        final picked = await picker.pickImage(source: ImageSource.camera);
        if (picked != null && mounted) {
          final file = File(picked.path);
          final size = await file.length();
          if (size <= _maxImageSizeBytes) {
            setState(() => _images.add(file));
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('issue_form.error_too_large'.tr(args: [picked.name])),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('issue_form.error_pick_failed'.tr(args: [e.toString()])),
            backgroundColor: const Color(0xFF2563eb),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<DriverIssueProvider>(context, listen: false);
      if (_isEditMode) {
        await provider.updateIssue(
          issueId: widget.existingIssue!.id,
          title: _titleController.text,
          description: _descController.text,
        );
      } else {
        await provider.submitIssue(
          title: _titleController.text,
          description: _descController.text,
          images: _images,
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('issue_form.submit_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('issue_form.submit_error'.tr(args: [e.toString()])),
            backgroundColor: const Color(0xFF2563eb),
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildImagePickerUI() {
    final canAddMore = _images.length < _maxImages;
    return Column(
      children: [
        if (_images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'issue_form.photos_counter'
                  .tr(args: [_images.length.toString(), _maxImages.toString()]),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    canAddMore ? () => _pickImageFrom(ImageSource.camera) : null,
                icon: const Icon(Icons.camera_alt),
                label: Text('issue_form.photos_camera'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    canAddMore ? () => _pickImageFrom(ImageSource.gallery) : null,
                icon: const Icon(Icons.photo_library),
                label: Text('issue_form.photos_gallery'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f7fc),
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? 'issue_form.edit_title'.tr()
              : 'issue_form.title'.tr(),
        ),
        backgroundColor: const Color(0xFF2563eb),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionCard(
                    title: '📋 ${'issue_form.details'.tr()}',
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: 'issue_form.title_label'.tr(),
                        hint: 'issue_form.title_hint'.tr(),
                        icon: Icons.title,
                        validator: (value) => value == null || value.isEmpty
                            ? 'issue_form.validation_required'.tr()
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descController,
                        label: 'issue_form.description_label'.tr(),
                        hint: 'issue_form.description_hint'.tr(),
                        icon: Icons.description,
                        maxLines: 4,
                        validator: (value) => value == null || value.isEmpty
                            ? 'issue_form.validation_required'.tr()
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_isEditMode && widget.existingIssue?.status != null)
                    _buildSectionCard(
                      title: 'issue_form.status'.tr(),
                      children: [
                        Text(
                          'issue_form.status_current'
                              .tr(args: [widget.existingIssue!.status]),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  if (!_isEditMode) ...[
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      title: '📸 ${'issue_form.photos_optional'.tr()}',
                      children: [
                        _buildImagePickerUI(),
                        if (_images.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildPhotoGrid(),
                        ],
                      ],
                    ),
                  ],
                  if (_isEditMode && widget.existingIssue!.images.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      title: '📸 ${'issue_form.photos_existing'.tr()}',
                      children: [
                        _buildExistingPhotoGrid(),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563eb),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isEditMode
                                ? 'issue_form.button_save'.tr()
                                : 'issue_form.button_submit'.tr(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFf5f7fc),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: Icon(icon, color: const Color(0xFF666666)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_images.length, (index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _images[index],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _images.removeAt(index)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildExistingPhotoGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.existingIssue!.images.map((img) {
        return GestureDetector(
        onTap: () => showDialog(
            context: context,
            builder: (_) => Dialog(
              child: Image.network(
                '${ApiConstants.imageUrl}/uploads/$img',
                fit: BoxFit.contain,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              '${ApiConstants.imageUrl}/uploads/$img',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }
}
