import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tms_driver_app/screens/shipment/profile/profile_vm.dart';

class ProfileHeaderSection extends StatelessWidget {
  const ProfileHeaderSection({
    required this.vm,
    required this.onEditTap,
    required this.onShareTap,
    super.key,
  });

  final ProfileVm vm;
  final VoidCallback onEditTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    final initials = vm.displayName
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1C4E84), width: 2),
              color: const Color(0xFFE5EBF5),
            ),
            child: ClipOval(
              child: vm.avatarUrl == null
                  ? Center(
                      child: Text(
                        initials.isEmpty ? 'D' : initials,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    )
                  : Image.network(
                      vm.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          initials.isEmpty ? 'D' : initials,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            vm.displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            vm.companyName,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${context.tr('profile.driver_id')}: ${vm.driverCode}',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                onTap: onEditTap,
                label: context.tr('profile.edit_profile'),
                background: Theme.of(context).primaryColor,
                foreground: Colors.white,
              ),
              const SizedBox(width: 10),
              _ActionButton(
                onTap: onShareTap,
                label: context.tr('profile.share_id'),
                background: const Color(0xFFE2E8F0),
                foreground: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final VoidCallback onTap;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
