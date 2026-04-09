import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:tms_driver_app/widgets/debug_api_override.dart';

/// Quick Action Menu Grid
/// Displays common driver actions in a grid layout
class QuickActionMenu extends StatelessWidget {
  final Function(QuickAction)? onActionTap;

  const QuickActionMenu({
    super.key,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _getQuickActions(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DebugApiOverride(),
              ));
            },
            child: Text(
              tr('dashboard.quick_actions'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              // Responsive columns: 3 on very small, 4 on phones, 5+ on tablets
              final crossAxisCount = width >= 900
                  ? 6
                  : width >= 720
                      ? 5
                      : width >= 420
                          ? 4
                          : 3;
              final crossAxisSpacing = 12.0;
              final mainAxisSpacing = 16.0;
              final tileWidth =
                  (width - crossAxisSpacing * (crossAxisCount - 1)) /
                      crossAxisCount;
              // Keep icons comfortable and labels readable; adjust with text scale
              // Use new MediaQuery.textScaler API (textScaleFactor deprecated)
              final textScale = MediaQuery.of(context).textScaler.scale(1.0);
              final nominalHeight = 96.0 +
                  (textScale - 1.0) * 20.0; // grow a bit with larger fonts
              final childAspectRatio = tileWidth / nominalHeight;

              // If we only have up to 4 actions, render them in a single slim row
              if (actions.length <= 4) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: actions.map((action) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: _QuickActionItem(
                          action: action,
                          onTap: () => onActionTap?.call(action),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }

              // Fallback to responsive grid for more actions
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  childAspectRatio: childAspectRatio.clamp(0.8, 1.6),
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return _QuickActionItem(
                    action: action,
                    onTap: () => onActionTap?.call(action),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<QuickAction> _getQuickActions(BuildContext context) {
    // Keep only the primary quick actions to match the design:
    // Shipments, Alerts, Documents, Daily Summary, Trip Report, More
    return [
      QuickAction(
        id: 'my_trips',
        icon: Icons.local_shipping,
        label: tr('quick_action.my_trips'),
        color: Colors.blue,
      ),
      QuickAction(
        id: 'report_issue',
        icon: Icons.warning_amber_rounded,
        label: tr('quick_action.report_issue'),
        color: Colors.amber,
      ),
      QuickAction(
        id: 'incident_report',
        icon: Icons.report_problem_outlined,
        label: tr('quick_action.incident_report'),
        color: Colors.redAccent,
      ),
      QuickAction(
        id: 'documents',
        icon: Icons.folder,
        label: tr('quick_action.documents'),
        color: Colors.green,
      ),
      QuickAction(
        id: 'daily_summary',
        icon: Icons.insert_chart_outlined,
        label: tr('daily_summary'),
        color: Colors.indigo,
      ),
      QuickAction(
        id: 'trip_report',
        icon: Icons.history,
        label: tr('quick_action.trip_report'),
        color: Colors.teal,
      ),
      QuickAction(
        id: 'more',
        icon: Icons.more_horiz,
        // use an existing localization key if available, otherwise fall back
        label: tr('quick_action.more'),
        color: Colors.blueGrey,
      ),
    ];
  }
}

class _QuickActionItem extends StatelessWidget {
  final QuickAction action;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: Tooltip(
        message: action.label,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (onTap != null) {
              onTap!();
              return;
            }
            if (action.id == 'debug') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DebugApiOverride(),
              ));
              return;
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96, minWidth: 72),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action.icon,
                    color: action.color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick Action Model
class QuickAction {
  final String id;
  final IconData icon;
  final String label;
  final Color color;

  QuickAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });
}
