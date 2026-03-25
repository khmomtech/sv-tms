import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({
    required this.titleKey,
    required this.items,
    super.key,
  });

  final String titleKey;
  final List<ProfileMenuItemVm> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(titleKey),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD8E3F3)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(item.icon,
                          color: Theme.of(context).primaryColor),
                      title: Text(context.tr(item.titleKey)),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF94A3B8),
                      ),
                      onTap: item.onTap,
                    ),
                    if (index < items.length - 1)
                      const Divider(height: 1, color: Color(0xFFE5EAF2)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMenuItemVm {
  final IconData icon;
  final String titleKey;
  final VoidCallback onTap;

  const ProfileMenuItemVm({
    required this.icon,
    required this.titleKey,
    required this.onTap,
  });
}
