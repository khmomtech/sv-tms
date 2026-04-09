import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';

class ProfileVm {
  final String displayName;
  final String companyName;
  final String driverCode;
  final String? avatarUrl;
  final int safeDrivingPercent;
  final int onTimePercent;
  final String milesDrivenLabel;

  const ProfileVm({
    required this.displayName,
    required this.companyName,
    required this.driverCode,
    required this.avatarUrl,
    required this.safeDrivingPercent,
    required this.onTimePercent,
    required this.milesDrivenLabel,
  });

  factory ProfileVm.fromProvider(
    DriverProvider provider,
    BuildContext context,
  ) {
    final profile = provider.driverProfile ?? const <String, dynamic>{};
    return ProfileVm.fromMaps(
      profile: profile,
      monthly: provider.currentMonthPerformance ?? const <String, dynamic>{},
      providerDriverId: provider.driverId,
      driverFallback: context.tr('profile.driver_fallback'),
      companyFallback: context.tr('profile.company_fallback'),
      notAvailable: context.tr('profile.not_available'),
    );
  }

  factory ProfileVm.fromMaps({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> monthly,
    required String? providerDriverId,
    required String driverFallback,
    required String companyFallback,
    required String notAvailable,
  }) {
    final first = (profile['firstName'] ?? '').toString().trim();
    final last = (profile['lastName'] ?? '').toString().trim();
    final fullName = '$first $last'.trim();
    final displayName = fullName.isEmpty
        ? (profile['name'] ?? driverFallback).toString()
        : fullName;

    final rawDriverId = (profile['idCardNumber'] ??
                profile['id_card_number'] ??
                profile['driverCode'] ??
                profile['employeeCode'] ??
                profile['licenseNumber'] ??
                profile['id'])
            ?.toString() ??
        providerDriverId ??
        '--';
    final driverCode = '#$rawDriverId';

    final company = (profile['companyName'] ?? '').toString().trim();
    final safeDriving = _safeDrivingPercent(
      monthly['safetyScore'] ?? profile['safetyScore'],
    );
    final onTime =
        _toInt(monthly['onTimePercent'] ?? profile['onTimePercent']) ?? 0;

    final milesDrivenLabel = _formatMilesDriven(
      monthly: monthly,
      profile: profile,
      fallback: notAvailable,
    );

    final rawAvatar =
        (profile['profilePictureUrl'] ?? profile['profilePicture'])?.toString();
    final avatarUrl = (rawAvatar != null && rawAvatar.trim().isNotEmpty)
        ? ApiConstants.image(rawAvatar.trim())
        : null;

    return ProfileVm(
      displayName: displayName,
      companyName: company.isEmpty ? companyFallback : company,
      driverCode: driverCode,
      avatarUrl: (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null,
      safeDrivingPercent: safeDriving,
      onTimePercent: onTime,
      milesDrivenLabel: milesDrivenLabel,
    );
  }

  static int _safeDrivingPercent(dynamic raw) {
    final numeric = _toInt(raw);
    if (numeric != null) return numeric.clamp(0, 100);
    final text = raw?.toString().toLowerCase() ?? '';
    if (text.contains('excellent')) return 98;
    if (text.contains('good')) return 92;
    if (text.contains('fair')) return 85;
    if (text.contains('poor')) return 70;
    return 0;
  }

  static int? _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    return int.tryParse(raw?.toString() ?? '');
  }

  static double? _toDouble(dynamic raw) {
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  static String _formatMilesDriven({
    required Map<String, dynamic> monthly,
    required Map<String, dynamic> profile,
    required String fallback,
  }) {
    final miles = _toDouble(
      monthly['totalDistanceMiles'] ??
          profile['totalDistanceMiles'] ??
          profile['milesDriven'],
    );
    if (miles != null) {
      return miles >= 1000
          ? '${(miles / 1000).toStringAsFixed(1)}k'
          : miles.toStringAsFixed(0);
    }

    final km = _toDouble(
      monthly['totalDistanceKm'] ?? profile['totalDistanceKm'],
    );
    if (km == null) return fallback;
    final fromKmMiles = km * 0.621371;
    return fromKmMiles >= 1000
        ? '${(fromKmMiles / 1000).toStringAsFixed(1)}k'
        : fromKmMiles.toStringAsFixed(0);
  }
}
