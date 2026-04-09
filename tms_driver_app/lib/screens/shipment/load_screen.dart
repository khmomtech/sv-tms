// imports remain unchanged
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:geolocator/geolocator.dart';

class LoadTaskDetailScreen extends StatefulWidget {
  final String dispatchId;

  const LoadTaskDetailScreen({super.key, required this.dispatchId});

  @override
  State<LoadTaskDetailScreen> createState() => _LoadTaskDetailScreenState();
}

class _LoadTaskDetailScreenState extends State<LoadTaskDetailScreen> {
  final List<File> _proofImages = [];
  bool _isPicking = false;
  Map<String, dynamic>? _dispatch;
  bool _isLoading = true;
  static const int _maxImages = 12; // hard cap to avoid memory spikes
  static const int _thumbWidth = 512; // thumbnail decode size for GridView
  bool _isSubmitting = false;
  String? _error;
  LatLng? _currentLatLng;
  final MapController _mapController = MapController();

  String _friendlyError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception:')) {
      return raw.substring('Exception:'.length).trim();
    }
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _fetchDispatchDetail();
    _fetchCurrentLocation();
  }

  Future<void> _fetchDispatchDetail() async {
    final provider = Provider.of<DispatchProvider>(context, listen: false);
    try {
      final data = await provider.getDispatchById(widget.dispatchId);
      if (!mounted) return;
      setState(() {
        _dispatch = data;
        _error = data == null ? 'load.dispatch.error'.tr() : null;
      });
    } catch (e) {
      debugPrint('Failed to load dispatch: $e');
      if (!mounted) return;
      setState(() {
        _error = 'load.dispatch.error'.tr();
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final remaining = _maxImages - _proofImages.length;
      if (remaining <= 0) {
        _showSnack('load.images.limit'.tr());
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // compress to speed up upload
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (pickedFile != null) {
        if (!mounted) return;
        setState(() => _proofImages.add(File(pickedFile.path)));
      }
    } catch (e) {
      debugPrint('Image pick failed: $e');
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      if (!mounted) return;
      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
      });
      // Recentering map on fresh location
      try {
        _mapController.move(_currentLatLng!, _mapController.camera.zoom);
      } catch (_) {}
    } catch (e) {
      debugPrint('Current location not available: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final remaining = _maxImages - _proofImages.length;
      if (remaining <= 0) {
        _showSnack('load.images.limit'.tr());
        return;
      }

      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );
        if (pickedFiles.isNotEmpty) {
          final files = pickedFiles.take(remaining).map((f) => File(f.path));
        if (!mounted) return;
        setState(() => _proofImages.addAll(files));
      }
    } catch (e) {
      debugPrint('Multi-image pick failed: $e');
    } finally {
      _isPicking = false;
    }
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _proofImages.length) return;
    if (!mounted) return;
    setState(() {
      _proofImages.removeAt(index);
    });
  }

  Future<void> _showProgressDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          // Intentionally ignore back navigation while submitting
        },
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

  Future<void> _submitLoadingProof() async {
      if (_proofImages.isEmpty || _isSubmitting) {
        if (_proofImages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('load.proof.empty'.tr())),
          );
      }
      return;
    }

    _isSubmitting = true;
    await _showProgressDialog('load.proof.uploading'.tr());

    try {
      final provider = Provider.of<DispatchProvider>(context, listen: false);
      await provider.submitLoadProof(
        dispatchId: widget.dispatchId,
        images: _proofImages,
        remarks: 'load.proof.remarks'.tr(),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('load.proof.sent'.tr())),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error submitting proof: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'load.proof.fail'.tr()}: ${_friendlyError(e)}',
            ),
          ),
        );
      }
    } finally {
      _isSubmitting = false;
    }
  }

  void _showStartConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('load.confirm_title'.tr()),
        content: Text('load.confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitLoadingProof();
            },
            child: Text('load.start'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dispatchId = widget.dispatchId;

    return Scaffold(
      appBar: AppBar(
        title: Text('load.title'.tr()),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2), // blue header
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined),
            tooltip: 'load.report_issue'.tr(),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.reportIssue,
                arguments: {'dispatchId': dispatchId},
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDispatchCard(),
                      const SizedBox(height: 24),
                      _buildProofSection(),
                    ],
                  ),
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isSubmitting ? null : _showStartConfirmDialog,
          icon: const Icon(Icons.local_shipping, color: Colors.white),
          label: Text('load.start'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('load.proof.title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        DottedBorder(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconOption(Icons.camera_alt_rounded, tr('load.proof.camera'), () {
                  _pickImage(source: ImageSource.camera);
                }),
                _buildIconOption(Icons.photo_library_rounded, tr('load.proof.gallery'), () {
                  _pickMultipleImages();
                }),
                Column(
                  children: [
                    Text(
                      '${_proofImages.length}/$_maxImages',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('load.proof.images'.tr(),
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_proofImages.isEmpty)
          Text('load.proof.empty'.tr(),
              style: TextStyle(color: Colors.black54.withOpacity(0.8))),
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
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: _thumbWidth,
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
                            size: 16, color: Colors.white),
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

  Widget _buildIconOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, size: 28, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List items) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Deduplicate by id/itemCode
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final it in items) {
      if (it is! Map) continue;
      final map = it.cast<String, dynamic>();
      final key = map['id']?.toString() ??
          map['itemId']?.toString() ??
          map['itemCode']?.toString() ??
          map['itemName']?.toString() ??
          UniqueKey().toString();
      if (seen.contains(key)) continue;
      seen.add(key);
      deduped.add(map);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('load.items'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: deduped.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final item = deduped[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['itemName']?.toString() ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        'QTY: ${item['quantity'] ?? '0'} ${item['unitOfMeasurement'] ?? ''}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      if (item['palletType'] != null)
                        Text(
                          'Pallets: ${item['palletType']}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      if (item['warehouse'] != null)
                        Text('WH: ${item['warehouse']}',
                            style: const TextStyle(color: Colors.black54)),
                      if (item['fromDestination'] != null &&
                          item['toDestination'] != null)
                        Text(
                            'From: ${item['fromDestination']} → ${item['toDestination']}',
                            style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatDate(dynamic raw) {
    try {
      if (raw == null) return 'N/A';
      if (raw is int) {
        return DateFormat('dd-MMM-yyyy HH:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(raw));
      }
      if (raw is double) {
        return DateFormat('dd-MMM-yyyy HH:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(raw.toInt()));
      }
      if (raw is List && raw.isNotEmpty) {
        final parts = List<int>.filled(6, 0);
        for (var i = 0; i < raw.length && i < 6; i++) {
          final v = raw[i];
          if (v is int) parts[i] = v;
          if (v is String) parts[i] = int.tryParse(v) ?? 0;
        }
        return DateFormat('dd-MMM-yyyy HH:mm')
            .format(DateTime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
      }
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return DateFormat('dd-MMM-yyyy HH:mm').format(parsed);
      }
      return raw.toString();
    } catch (_) {
      return raw?.toString() ?? 'N/A';
    }
  }

  Widget _buildDispatchCard() {
    final pickupLat = _toDouble(_dispatch?['pickupLat']);
    final pickupLng = _toDouble(_dispatch?['pickupLng']);
    final dropoffLat = _toDouble(_dispatch?['dropoffLat']);
    final dropoffLng = _toDouble(_dispatch?['dropoffLng']);
    final pickupTime = _formatDate(_dispatch?['pickupTime'] ?? _dispatch?['startTime']);
    final dropoffTime = _formatDate(_dispatch?['dropoffTime'] ?? _dispatch?['expectedDelivery']);

    // Use stop data (transport order stops preferred) to show names/addresses
    Map<String, dynamic>? _firstStopOfType(String type) {
      final stops = <Map<String, dynamic>>[];
      final toStops = (_dispatch?['transportOrder']?['stops'] as List?) ?? const [];
      final dispatchStops = (_dispatch?['stops'] as List?) ?? const [];
      for (final s in toStops) {
        if (s is Map<String, dynamic>) stops.add(s);
      }
      for (final s in dispatchStops) {
        if (s is Map<String, dynamic>) stops.add(s);
      }
      for (final stop in stops) {
        final t = (stop['type'] ?? stop['stopType'] ?? '').toString().toUpperCase();
        if (t == type.toUpperCase()) return stop;
      }
      return null;
    }

    String _resolveName(Map<String, dynamic>? stop) {
      if (stop == null) return '';
      final addr = stop['address'];
      if (addr is Map && addr['name'] != null && addr['name'].toString().isNotEmpty) {
        return addr['name'].toString();
      }
      if (stop['locationName'] != null) return stop['locationName'].toString();
      return '';
    }

    String _resolveAddress(Map<String, dynamic>? stop) {
      if (stop == null) return '';
      final addr = stop['address'];
      if (addr is Map && addr['address'] != null && addr['address'].toString().isNotEmpty) {
        return addr['address'].toString();
      }
      if (stop['address'] != null) return stop['address'].toString();
      if (stop['location'] != null) return stop['location'].toString();
      if (stop['pickupLocation'] != null) return stop['pickupLocation'].toString();
      if (stop['dropoffLocation'] != null) return stop['dropoffLocation'].toString();
      return '';
    }

    final pickupStop = _firstStopOfType('PICKUP');
    final dropStop = _firstStopOfType('DROP');
    final pickupName = _resolveName(pickupStop);
    final dropName = _resolveName(dropStop);
    final pickupAddr = _resolveAddress(pickupStop);
    final dropAddr = _resolveAddress(dropStop);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TASK ID:\n#${_dispatch?['id'] ?? ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("STATUS\n${_dispatch?['status'] ?? ''}",
                    textAlign: TextAlign.right,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 16),
            _buildStopInfo(
              icon: Icons.local_shipping,
              iconColor: Colors.green,
              label: 'load.pickup'.tr(),
              date: _formatDate(_dispatch?['startTime']),
              location: pickupAddr.isNotEmpty
                  ? '$pickupName ${pickupName.isNotEmpty ? "-" : ""}$pickupAddr'
                  : _dispatch?['pickupLocation'] ?? 'N/A',
              person: _dispatch?['driverName'] ?? 'N/A',
              phone: _dispatch?['driverPhone'],
            ),
            const Divider(),
            _buildStopInfo(
              icon: Icons.location_on,
              iconColor: Colors.blue,
              label: 'load.dropoff'.tr(),
              date: _formatDate(_dispatch?['estimatedArrival']),
              location: dropAddr.isNotEmpty
                  ? '$dropName ${dropName.isNotEmpty ? "-" : ""}$dropAddr'
                  : _dispatch?['dropoffLocation'] ?? 'N/A',
              person: _dispatch?['driverName'] ?? 'N/A',
              phone: _dispatch?['driverPhone'],
            ),
            const SizedBox(height: 12),
            _buildLabeledBox('កំណត់ចំណាំ', 'សូមប្រុងប្រយ័ត្នពេលដឹកជញ្ជូន'),
            const SizedBox(height: 16),
            _buildItemsSection(
                (_dispatch?['transportOrder']?['items'] as List?) ?? const []),
            const SizedBox(height: 16),
            const Text('ផែនទីទីតាំង',
            style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Stack(
              children: [
                SizedBox(
                  height: 200,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                      initialCenter: _currentLatLng ??
                          (pickupLat != null && pickupLng != null
                              ? LatLng(pickupLat, pickupLng)
                              : const LatLng(11.5621, 104.8885)),
                      initialZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.svtrucking.driverapp',
                        retinaMode: true,
                      ),
                      MarkerLayer(markers: [
                        if (pickupLat != null && pickupLng != null)
                          Marker(
                            point: LatLng(pickupLat, pickupLng),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.local_shipping,
                                color: Colors.green),
                          ),
                        if (dropoffLat != null && dropoffLng != null)
                          Marker(
                            point: LatLng(dropoffLat, dropoffLng),
                            width: 40,
                            height: 40,
                            child:
                                const Icon(Icons.location_on, color: Colors.blue),
                          ),
                        if (_currentLatLng != null)
                          Marker(
                            point: _currentLatLng!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location,
                                color: Colors.indigo),
                          ),
                      ]),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'recenter_current',
                        onPressed: _currentLatLng == null
                            ? null
                            : () => _mapController.move(
                                  _currentLatLng!,
                                  _mapController.camera.zoom,
                                ),
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'recenter_pickup',
                        onPressed: (pickupLat != null && pickupLng != null)
                            ? () => _mapController.move(
                                  LatLng(pickupLat, pickupLng),
                                  _mapController.camera.zoom,
                                )
                            : null,
                        child: const Icon(Icons.local_shipping),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
    String? phone,
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
            const Icon(Icons.info_outline, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(location)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(person)),
            IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () => _callPhone(phone),
            ),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? 'load.dispatch.error'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _fetchDispatchDetail();
            },
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(String? rawPhone) async {
    if (rawPhone == null || rawPhone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: rawPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnack('load.phone.failed'.tr());
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
