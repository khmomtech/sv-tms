import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tms_driver_app/screens/shipment/profile/profile_vm.dart';

class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({required this.vm, super.key});

  final ProfileVm vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('profile.performance_stats'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _StatCard(
            icon: Icons.verified_user_outlined,
            label: context.tr('profile.safe_driving'),
            value: '${vm.safeDrivingPercent}%',
          ),
          const SizedBox(height: 10),
          _StatCard(
            icon: Icons.access_time,
            label: context.tr('profile.on_time_delivery'),
            value: '${vm.onTimePercent}%',
          ),
          const SizedBox(height: 10),
          _StatCard(
            icon: Icons.local_shipping_outlined,
            label: context.tr('profile.miles_driven'),
            value: vm.milesDrivenLabel,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8E3F3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
