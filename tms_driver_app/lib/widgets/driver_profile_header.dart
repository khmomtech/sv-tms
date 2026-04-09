import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

import '../providers/driver_provider.dart';

/// Improved version of the old header:
/// - Accepts both JSON shapes: `{data:{...}}` or flattened `{...}`
/// - Handles relative/absolute profile pictures via `ApiConstants.image`
/// - Safer avatar fallback (no asset dependency) + initials
/// - Keeps your original layout and switch behavior
class DriverProfileHeader extends StatelessWidget {
  final DateTime selectedDate;
  final bool isOnline;
  final ValueChanged<bool>? onStatusChanged;

  const DriverProfileHeader({
    super.key,
    required this.selectedDate,
    this.isOnline = true,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    // Accept both shapes: {data:{...}} or already flattened {...}
    final Map<String, dynamic>? driver =
        (driverProvider.driverProfile?['data'] as Map<String, dynamic>?) ??
            driverProvider.driverProfile;

    if (driver == null) {
      // Skeleton loader using shimmer
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child:
                  const CircleAvatar(radius: 35, backgroundColor: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 18,
                      width: 120,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 14,
                      width: 80,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 36,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final String formattedDate =
        DateFormat('dd-MMM-yyyy', 'km_KH').format(selectedDate);

    // Name + initials
    final String name =
        (driver['name'] ?? driver['username'] ?? 'N/A').toString();
    final String initials = _toInitials(name, fallback: 'DR');

    // Picture may be absolute or relative
    final String? rawPic = (driver['profilePicture'] as String?);
    final String? imgUrl = (rawPic == null || rawPic.trim().isEmpty)
        ? null
        : ApiConstants.image(rawPic.trim());

    final vehicle = driverProvider.effectiveVehicle;
    final vehiclePlate = vehicle != null
        ? (vehicle['plateNumber'] ?? vehicle['licensePlate'] ?? '')
        : '';
    final vehicleType = vehicle != null
        ? (vehicle['type'] ?? vehicle['vehicleType'] ?? '')
        : '';
    final vehicleId =
        vehicle != null ? (vehicle['id'] ?? vehicle['vehicleId'] ?? '') : '';
    final driverId = driverProvider.driverId ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(url: imgUrl, initials: initials),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text('សម្រាប់ថ្ងៃ: ',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Vehicle info or prompt
                if (vehiclePlate.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.local_shipping,
                          size: 18, color: Colors.blueGrey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        vehiclePlate,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (vehicleType.toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '($vehicleType)',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                      ]
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'មិនទាន់មានរថយន្តបញ្ជាក់! សូមជ្រើសរើសរថយន្ត.',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                // Debug info (small, grey)
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('DriverID: ',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(driverId,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade700)),
                    if (vehicleId.toString().isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text('VehicleID: ',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(vehicleId.toString(),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
                    ]
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusSwitch(
            value: isOnline,
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

// ========================= Helpers & Subwidgets =========================

String _toInitials(String name, {String fallback = 'DR'}) {
  final n = name.trim();
  if (n.isEmpty || n == 'N/A') return fallback;
  final parts = n.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  final first = parts.isNotEmpty ? parts.first[0] : '';
  final last = parts.length > 1 ? parts.last[0] : '';
  final s = (first + last).toUpperCase();
  return s.isEmpty ? fallback : s;
}

class _StatusSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _StatusSwitch({
    required this.value,
    this.onChanged,
  }) : super();

  @override
  Widget build(BuildContext context) {
    final switchTheme = Theme.of(context).colorScheme;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: switchTheme.onPrimary,
      activeTrackColor: Colors.green,
      inactiveThumbColor: switchTheme.onSurface,
      inactiveTrackColor: Colors.red,
    );
  }
}

class _StatusAvatarPlaceholder extends StatelessWidget {
  const _StatusAvatarPlaceholder() : super();

  @override
  Widget build(BuildContext context) {
    const double size = 70;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade200,
      child: const Icon(Icons.person, color: Colors.grey, size: 32),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String initials;
  const _Avatar({required this.url, required this.initials});

  @override
  Widget build(BuildContext context) {
    const double size = 70;

    // Asset-free, robust fallback
    final Widget fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE0E0E0),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
    );

    if (url == null || url!.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Fallback to initials if image fails to load
        errorBuilder: (_, __, ___) => fallback,
        // Quick fade-in
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: child,
          );
        },
      ),
    );
  }
}
