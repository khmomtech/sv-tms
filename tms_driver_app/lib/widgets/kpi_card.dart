import 'package:flutter/material.dart';

/// KPI Card Widget
/// Displays key performance indicators with icon, value, label, and optional trend
class KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? trend;
  final bool? trendPositive;
  final VoidCallback? onTap;
  final String? subLabel;
  final IconData? watermarkIcon;

  const KpiCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = Colors.blue,
    this.trend,
    this.trendPositive,
    this.onTap,
    this.subLabel,
    this.watermarkIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Respect text scale to maintain layout without overflow
    final textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight <= 120 || constraints.maxWidth <= 150;
        final showSubtitle = !compact && subLabel != null && subLabel!.isNotEmpty;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // title
            Flexible(child: Text(label, style: TextStyle(fontSize: 12 * textScale, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(height: 8),
            // value (primary)
            Flexible(child: Text(value, style: TextStyle(fontSize: 26 * textScale, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (showSubtitle) const SizedBox(height: 8),
            // optional subtitle or trailing info
            if (showSubtitle)
              Flexible(child: Text(subLabel!, style: TextStyle(fontSize: 10 * textScale, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        );

        // Wrap in SingleChildScrollView only when extremely tight to avoid overflow artifacts
        final maybeScrollable = compact
            ? SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: content)
            : content;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: maybeScrollable,
        );
      },
    );
  }
}
