import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

class DriverIdScreen extends StatefulWidget {
  const DriverIdScreen({super.key});

  @override
  State<DriverIdScreen> createState() => _DriverIdScreenState();
}

class _DriverIdScreenState extends State<DriverIdScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDriverProfile();
    });
  }

  Future<void> _loadDriverProfile() async {
    final isLoggedIn = await ApiConstants.isLoggedIn();
    if (!mounted) return;
    if (!isLoggedIn) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.signin, (_) => false);
      return;
    }

    final provider = context.read<DriverProvider>();
    try {
      await provider.initializeDriverSession();
      await provider.fetchDriverProfile();
      await provider.fetchCurrentAssignment();
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final driver = _buildDriverCardData(provider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr('profile.id_card.title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (driver != null)
            PopupMenuButton<String>(
              tooltip: context.tr('profile.id_card.options'),
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) => _handleMenu(value, driver),
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'share',
                  child: Text(context.tr('profile.id_card.share')),
                ),
                PopupMenuItem<String>(
                  value: 'save',
                  child: Text(context.tr('profile.id_card.save')),
                ),
                PopupMenuItem<String>(
                  value: 'print',
                  child: Text(context.tr('profile.id_card.print')),
                ),
              ],
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              nav.pushReplacementNamed(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: _buildBody(driver),
    );
  }

  Widget _buildBody(Map<String, dynamic>? driver) {
    if (_isLoadingProfile && driver == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (driver == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('profile.id_card.no_data'),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoadingProfile = true);
                  _loadDriverProfile();
                },
                child: Text(context.tr('common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE7F0FF), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCardHeader(),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Text(
                          _getDriverName(driver),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('profile.id_card.subtitle'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(child: _buildAvatar(driver)),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          context.tr('profile.id_card.role'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCell(
                                  context.tr('profile.id_card.field.id'),
                                  _getDriverId(driver),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCell(
                                  context.tr('profile.id_card.field.phone'),
                                  _phone(driver),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCell(
                                  context.tr('profile.id_card.field.group'),
                                  _driverGroup(driver),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCell(
                                  context.tr('profile.id_card.field.vehicle'),
                                  _getVehiclePlate(driver),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: _buildInfoCell(
                          //         context
                          //             .tr('profile.id_card.field.issued_date'),
                          //         _formatIssueDate(_extractIssueDate(driver)),
                          //       ),
                          //     ),
                          //     const SizedBox(width: 12),
                          //     Expanded(
                          //       child: _buildInfoCell(
                          //         context.tr('profile.id_card.field.status'),
                          //         _idCardStatus(driver),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrPayload(driver),
                          version: QrVersions.auto,
                          size: 170,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        context.tr('profile.id_card.scan_hint'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        _formatExpiry(_extractExpiry(driver)),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExporting)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(13),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'SV',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('profile.id_card.company'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('profile.id_card.card_label'),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.4,
                      color: Color(0xFFE0E7FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.verified_user, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildInfoCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getDriverName(Map<String, dynamic> driver) {
    final name = driver['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;

    final firstName = driver['firstName']?.toString() ?? '';
    final lastName = driver['lastName']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    return context.tr('profile.driver_fallback');
  }

  String _getInitials(Map<String, dynamic> driver) {
    final name = _getDriverName(driver);
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return 'DR';
  }

  String _getDriverId(Map<String, dynamic> driver) {
    final id = _firstNonBlank(driver, const [
      'idCardNumber',
      'id_card_number',
      'idCardNo',
      'nationalId',
      'national_id',
      'driverCode',
      'employeeCode',
      'licenseNumber',
      'license_number',
    ]);
    if (id != null) {
      return id;
    }

    final fallbackId = driver['id']?.toString();
    if (fallbackId != null && fallbackId.isNotEmpty) {
      return 'DR-${fallbackId.padLeft(5, '0')}';
    }
    return context.tr('profile.not_available');
  }

  String _phone(Map<String, dynamic> driver) {
    final value =
        driver['phoneNumber']?.toString() ?? driver['phone']?.toString();
    if (value == null || value.trim().isEmpty) {
      return context.tr('profile.not_available');
    }
    return value;
  }

  String _driverGroup(Map<String, dynamic> driver) {
    final value = driver['driverGroupName']?.toString();
    if (value == null || value.trim().isEmpty) {
      return context.tr('profile.not_available');
    }
    return value;
  }

  String _getVehiclePlate(Map<String, dynamic> driver) {
    final directPlate = _firstNonBlank(driver, const [
      'assignedVehiclePlate',
      'licensePlate',
      'plateNumber',
      'truckNumber',
      'vehiclePlate',
      'plate',
    ]);
    if (directPlate != null) {
      return directPlate;
    }

    if (driver['assignedVehicle'] is Map) {
      final vehicle = driver['assignedVehicle'] as Map<String, dynamic>;
      final plate = _firstNonBlank(vehicle, const [
        'licensePlate',
        'plateNumber',
        'truckNumber',
        'vehiclePlate',
        'plate',
      ]);
      if (plate != null) {
        return plate;
      }
    }

    if (driver['effectiveVehicle'] is Map) {
      final vehicle = driver['effectiveVehicle'] as Map<String, dynamic>;
      final plate = _firstNonBlank(vehicle, const [
        'licensePlate',
        'plateNumber',
        'truckNumber',
        'vehiclePlate',
        'plate',
      ]);
      if (plate != null) {
        return plate;
      }
    }

    return context.tr('profile.not_available');
  }

  String _qrPayload(Map<String, dynamic> driver) {
    final idValue = driver['id']?.toString() ?? '';
    if (idValue.isNotEmpty) {
      return 'svtms://driver/$idValue';
    }
    return 'DRIVER:${_getDriverName(driver)}:${_phone(driver)}';
  }

  String _formatExpiry(dynamic raw) {
    final parsed = _parseDate(raw);
    if (parsed == null) {
      return context.tr('profile.id_card.expiry_not_set');
    }
    final localeName = context.locale.toLanguageTag();
    final dateText = DateFormat.yMMMd(localeName).format(parsed);
    return context.tr('profile.id_card.expiry', namedArgs: {'date': dateText});
  }

  String _formatIssueDate(dynamic raw) {
    final parsed = _parseDate(raw);
    if (parsed == null) {
      return context.tr('profile.not_available');
    }
    final localeName = context.locale.toLanguageTag();
    return DateFormat.yMMMd(localeName).format(parsed);
  }

  String _idCardStatus(Map<String, dynamic> driver) {
    final issueDate = _parseDate(_extractIssueDate(driver));
    final expiryDate = _parseDate(_extractExpiry(driver));

    if (issueDate == null && expiryDate == null) {
      return context.tr('profile.id_card.status.not_issued');
    }
    if (expiryDate == null) {
      return context.tr('profile.id_card.status.active');
    }
    if (expiryDate.isBefore(DateTime.now())) {
      return context.tr('profile.id_card.status.expired');
    }
    return context.tr('profile.id_card.status.active');
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is List && raw.length >= 3) {
      final y = raw[0].toString();
      final m = raw[1].toString().padLeft(2, '0');
      final d = raw[2].toString().padLeft(2, '0');
      return DateTime.tryParse('$y-$m-$d');
    }
    return null;
  }

  Future<Uint8List> _captureCardBytes() async {
    final encodeFailed = context.tr('profile.id_card.encode_failed');
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception(context.tr('profile.id_card.card_not_ready'));
    }
    final pixelRatio =
        MediaQuery.of(context).devicePixelRatio.clamp(2.0, 3.0).toDouble();
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception(encodeFailed);
    }
    return byteData.buffer.asUint8List();
  }

  Future<File> _writeImage(
    Uint8List bytes, {
    bool persistent = false,
    String? name,
  }) async {
    final dir = persistent
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();
    final fileName =
        name ?? 'driver_id_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _safeFileName(String raw) {
    final cleaned = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _shareCard(Map<String, dynamic> driver,
      {String? subject}) async {
    final shareSubject = subject ?? context.tr('profile.id_card.share_subject');
    try {
      setState(() => _isExporting = true);
      final bytes = await _captureCardBytes();
      final file = await _writeImage(
        bytes,
        name: 'driver_id_${_safeFileName(_getDriverName(driver))}.png',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: _shareText(driver),
          subject: shareSubject,
          sharePositionOrigin: _shareOriginRect(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(
        context.tr(
          'profile.id_card.share_failed',
          namedArgs: {'error': e.toString()},
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveCard(Map<String, dynamic> driver) async {
    try {
      setState(() => _isExporting = true);
      final bytes = await _captureCardBytes();
      final file = await _writeImage(
        bytes,
        persistent: true,
        name: 'driver_id_${_safeFileName(_getDriverName(driver))}.png',
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('profile.id_card.saved_to', namedArgs: {
              'path': file.path,
            }),
          ),
          action: SnackBarAction(
            label: context.tr('profile.id_card.open'),
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    } catch (e) {
      _showError(
        context.tr(
          'profile.id_card.save_failed',
          namedArgs: {'error': e.toString()},
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _printCard(Map<String, dynamic> driver) async {
    await _shareCard(
      driver,
      subject: context.tr('profile.id_card.print_subject'),
    );
  }

  void _handleMenu(String value, Map<String, dynamic> driver) {
    switch (value) {
      case 'share':
        _shareCard(driver);
        break;
      case 'print':
        _printCard(driver);
        break;
      case 'save':
        _saveCard(driver);
        break;
      default:
        break;
    }
  }

  Widget _buildAvatar(Map<String, dynamic> driver) {
    final photo = _extractPhotoUrl(driver);
    final fallback = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 4),
        color: const Color(0xFFE5E7EB),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(driver),
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4B5563),
        ),
      ),
    );

    if (photo == null || photo.isEmpty) return fallback;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        photo,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFE5E7EB),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Rect? _shareOriginRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  String _shareText(Map<String, dynamic> driver) {
    final name = _getDriverName(driver);
    final id = _getDriverId(driver);
    final phone = _phone(driver);
    final vehicle = _getVehiclePlate(driver);
    final group = _driverGroup(driver);
    final issued = _formatIssueDate(_extractIssueDate(driver));
    final status = _idCardStatus(driver);
    final expiry = _formatExpiry(_extractExpiry(driver));
    return '''
${context.tr('profile.id_card.share_subject')}
${context.tr('profile.id_card.field.id')}: $id
${context.tr('profile.id_card.field.phone')}: $phone
${context.tr('profile.id_card.field.group')}: $group
${context.tr('profile.id_card.field.vehicle')}: $vehicle
${context.tr('profile.id_card.field.issued_date')}: $issued
${context.tr('profile.id_card.field.status')}: $status
$expiry
${context.tr('profile.driver_fallback')}: $name
'''
        .trim();
  }

  String? _extractPhotoUrl(Map<String, dynamic> driver) {
    final keys = [
      'profilePictureUrl',
      'profilePicture',
      'profile_picture',
      'photoUrl',
      'photo_url',
      'avatar',
    ];
    for (final k in keys) {
      final value = driver[k]?.toString();
      if (value != null && value.trim().isNotEmpty) {
        return ApiConstants.image(value.trim());
      }
    }
    if (driver['user'] is Map) {
      final user = driver['user'] as Map;
      final nested =
          user['avatar'] ?? user['profilePicture'] ?? user['photoUrl'];
      if (nested != null && nested.toString().trim().isNotEmpty) {
        return ApiConstants.image(nested.toString().trim());
      }
    }
    return null;
  }

  String? _firstNonBlank(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString();
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  dynamic _extractExpiry(Map<String, dynamic> driver) {
    const keys = [
      'idCardExpiry',
      'id_card_expiry',
      'idCardExpiryDate',
      'idCardExpiryDateString',
    ];
    for (final k in keys) {
      if (driver.containsKey(k) && driver[k] != null) {
        return driver[k];
      }
    }
    if (driver['idCardExpiry'] is List) return driver['idCardExpiry'];
    if (driver['idCardExpiryDate'] is List) return driver['idCardExpiryDate'];
    return null;
  }

  dynamic _extractIssueDate(Map<String, dynamic> driver) {
    const keys = [
      'idCardIssuedDate',
      'id_card_issued_date',
      'idCardIssuedAt',
      'issuedDate',
    ];
    for (final k in keys) {
      if (driver.containsKey(k) && driver[k] != null) {
        return driver[k];
      }
    }
    return null;
  }

  Map<String, dynamic>? _buildDriverCardData(DriverProvider provider) {
    final profile = provider.driverProfile;
    final assignment = provider.currentAssignment;
    final effectiveVehicle =
        provider.vehicleCardData ?? provider.effectiveVehicle;

    if (profile == null && effectiveVehicle == null && assignment == null) {
      return null;
    }

    final merged = <String, dynamic>{};
    if (profile != null) {
      merged.addAll(profile);
    }
    if (assignment != null) {
      merged['effectiveType'] = assignment['effectiveType'];
      merged['temporaryExpiry'] = assignment['temporaryExpiry'];
      merged['temporaryExpiryParsed'] = assignment['temporaryExpiryParsed'];
    }
    if (effectiveVehicle != null) {
      merged['effectiveVehicle'] = Map<String, dynamic>.from(effectiveVehicle);
      merged['assignedVehicle'] = Map<String, dynamic>.from(effectiveVehicle);
      merged['assignedVehiclePlate'] = effectiveVehicle['licensePlate'] ??
          effectiveVehicle['plateNumber'] ??
          effectiveVehicle['truckNumber'] ??
          effectiveVehicle['plate'] ??
          effectiveVehicle['vehiclePlate'];
    }
    return merged;
  }
}
