import 'dart:async';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/screens/shipment/fullscreen_image_viewer.dart';

class UnloadScreen extends StatefulWidget {
  final String dispatchId;
  const UnloadScreen({super.key, required this.dispatchId});

  @override
  State<UnloadScreen> createState() => _UnloadScreenState();
}

class _UnloadScreenState extends State<UnloadScreen> {
  final List<File> _proofImages = [];
  bool _isPicking = false;
  Map<String, dynamic>? _dispatch;
  bool _isLoading = true;
  String? _error;

  static const int _maxImages = 12;
  bool _isSubmitting = false;

  String _friendlyError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception:')) {
      return raw.substring('Exception:'.length).trim();
    }
    return raw;
  }

  bool _canAddMore() => _proofImages.length < _maxImages;

  @override
  void initState() {
    super.initState();
    _fetchDispatchDetail();
  }

  Future<void> _fetchDispatchDetail() async {
    final provider = Provider.of<DispatchProvider>(context, listen: false);
    try {
      final data = await provider.getDispatchById(widget.dispatchId);
      if (!mounted) return;
      setState(() {
        _dispatch = data;
        _error = data == null ? 'មិនអាចទាញទិន្នន័យបេសកកម្មបានទេ' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'មិនអាចទាញទិន្នន័យបេសកកម្មបានទេ';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    if (_isPicking || !_canAddMore()) return;
    _isPicking = true;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 75, // compress to ~75% quality
        maxWidth: 1600, // constrain dimensions to speed up uploads
        maxHeight: 1600,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (mounted) {
          setState(() {
            if (!_proofImages.any((f) => f.path == file.path)) {
              _proofImages.add(file);
              if (_proofImages.length > _maxImages) {
                _proofImages.removeRange(_maxImages, _proofImages.length);
              }
            }
          });
        }
      }
    } catch (e) {
      _showSnack('មិនអាចជ្រើសរូបភាពបានទេ: $e');
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _pickMultipleImages() async {
    if (_isPicking || !_canAddMore()) return;
    _isPicking = true;
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          for (final pf in pickedFiles) {
            if (!_canAddMore()) break;
            final file = File(pf.path);
            if (!_proofImages.any((f) => f.path == file.path)) {
              _proofImages.add(file);
            }
          }
        });
      }
    } catch (e) {
      _showSnack('មិនអាចជ្រើសរូបភាពបានទេ: $e');
    } finally {
      _isPicking = false;
    }
  }

  void _removeImage(int index) {
    if (!mounted || index < 0 || index >= _proofImages.length) return;
    setState(() => _proofImages.removeAt(index));
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showProgressDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('បញ្ជាក់ការទម្លាក់ទំនិញ'),
        content: const Text('តើអ្នកចង់ផ្ញើភស្តុតាងទម្លាក់ទំនិញឥឡូវនេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitUnloadProof();
            },
            child: const Text('បញ្ជាក់'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitUnloadProof() async {
    if (_isSubmitting) return;
    if (_proofImages.isEmpty) {
      _showSnack('សូមជ្រើសរូបភាពសំគាល់ទំលាក់ទំនិញជាមុនសិន');
      return;
    }
    final provider = Provider.of<DispatchProvider>(context, listen: false);
    _isSubmitting = true;
    if (mounted) {
      setState(() {});
      await _showProgressDialog('កំពុងផ្ញើភស្តុតាងទម្លាក់ទំនិញ...');
    }
    try {
      await provider.submitUnloadProof(
        dispatchId: widget.dispatchId,
        images: _proofImages,
        remarks: 'បញ្ជាក់ទំលាក់ទំនិញ',
        address: _dispatch?['dropoffLocation'],
        latitude: _dispatch?['dropoffLat'],
        longitude: _dispatch?['dropoffLng'],
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack('បានបញ្ជូនទម្លាក់ទំនិញរួចរាល់');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showSnack('បញ្ហា៖ ${_friendlyError(e)}');
    } finally {
      _isSubmitting = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        // Block back navigation while submitting; no action needed when didPop is false
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ទំលាក់ទំនិញ'),
          backgroundColor: Colors.blue,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDispatchInfo(),
                    const SizedBox(height: 16),
                    _buildProofSection(),
                    const SizedBox(height: 12),
                    Text(
                      'រូបភាព ${_proofImages.length}/$_maxImages',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Text(_isSubmitting ? 'កំពុងផ្ញើរ...' : 'បញ្ជាក់ទំលាក់ទំនិញ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isSubmitting ? null : _showSubmitConfirmDialog,
          ),
        ),
      ),
    );
  }

  Widget _buildDispatchInfo() {
    final dropoffLat = _dispatch?['dropoffLat'];
    final dropoffLng = _dispatch?['dropoffLng'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("TASK ID: #${_dispatch?['id'] ?? ''}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("កន្លែងទំលាក់: ${_dispatch?['dropoffLocation'] ?? ''}"),
            const SizedBox(height: 12),
            const Text('ផែនទីទីតាំង'),
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: dropoffLat != null && dropoffLng != null
                      ? LatLng(dropoffLat, dropoffLng)
                      : LatLng(11.5621, 104.8885),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.svtrucking.svdriverapp',
                    tileProvider: NetworkTileProvider(
                      headers: {
                        'User-Agent': 'SVDriverApp/1.0 (support@svtrucking.com)',
                      },
                    ),
                  ),
                  if (dropoffLat != null && dropoffLng != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(dropoffLat, dropoffLng),
                          width: 40,
                          height: 40,
                          child:
                              const Icon(Icons.location_on, color: Colors.blue),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofSection() {
    final atLimit = !_canAddMore();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('រូបភាពសំគាល់ទំលាក់ទំនិញ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        DottedBorder(
          dashPattern: const [6, 3],
          color: atLimit ? Colors.grey : Colors.blue,
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconOption(
                  Icons.camera_alt,
                  'Camera',
                  atLimit ? null : () => _pickImage(source: ImageSource.camera),
                ),
                _buildIconOption(
                  Icons.photo_library,
                  'Gallery',
                  atLimit ? null : _pickMultipleImages,
                ),
              ],
            ),
          ),
        ),
        if (atLimit)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('ឈានដល់កំណត់រូបភាព (12)',
                style: TextStyle(color: Colors.redAccent)),
          ),
        const SizedBox(height: 12),
        if (_proofImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _proofImages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final image = _proofImages[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullscreenImageViewer(
                          imageUrl: image.path,
                          isLocal: true,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(image, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildIconOption(IconData icon, String label, VoidCallback? onTap) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 32, color: disabled ? Colors.grey : Colors.blue),
            const SizedBox(height: 4),
            Text(label,
                style:
                    TextStyle(color: disabled ? Colors.grey : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
