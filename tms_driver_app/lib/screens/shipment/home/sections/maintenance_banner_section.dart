import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MaintenanceBannerSection extends StatelessWidget {
  const MaintenanceBannerSection({
    required this.message,
    required this.isMaintenance,
    required this.hasInfo,
    required this.onClose,
    required this.onInfoTap,
    super.key,
  });

  final String? message;
  final bool isMaintenance;
  final bool hasInfo;
  final VoidCallback onClose;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color accentColor =
        isMaintenance ? const Color(0xFFE65100) : const Color(0xFF1565C0);
    final Color bgColor =
        isMaintenance ? const Color(0xFFFFF8F1) : const Color(0xFFF0F4FF);
    final Color borderColor =
        isMaintenance ? const Color(0xFFFFCC80) : const Color(0xFFBBD0FF);
    final IconData icon =
        isMaintenance ? Icons.build_circle_rounded : Icons.info_rounded;
    final String titleKey = isMaintenance ? 'maintenance.title' : 'about.update_info';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1.5),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Thin accent top bar
          Container(height: 3, color: accentColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.tr(titleKey),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message!,
                        style: TextStyle(
                          color: accentColor.withOpacity(0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action row at the bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (hasInfo)
                  TextButton.icon(
                    onPressed: onInfoTap,
                    style: TextButton.styleFrom(
                      foregroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text(
                      context.tr('about.update_info'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                TextButton.icon(
                  onPressed: onClose,
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor.withOpacity(0.65),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: Text(
                    context.tr('button.close'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
