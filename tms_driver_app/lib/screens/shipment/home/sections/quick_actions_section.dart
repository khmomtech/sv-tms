import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    required this.onTap,
    this.actionIds = const <String>[
      'my_trips',
      'incident_report',
      'report_issue',
      'documents',
      'trip_report',
      'help_center',
    ],
    super.key,
  });

  final void Function(String actionId) onTap;
  final List<String> actionIds;

  @override
  Widget build(BuildContext context) {
    final specs = <String, _QuickActionItemData>{
      'my_trips': _QuickActionItemData('my_trips', Icons.inventory_2_outlined,
          context.tr('quick_action.my_trips')),
      'incident_report': _QuickActionItemData(
          'incident_report',
          Icons.report_gmailerrorred,
          context.tr('quick_action.incident_report')),
      'report_issue': _QuickActionItemData(
          'report_issue',
          Icons.assignment_late_outlined,
          context.tr('quick_action.report_issue')),
      'documents': _QuickActionItemData('documents', Icons.description_outlined,
          context.tr('quick_action.documents')),
      'trip_report': _QuickActionItemData(
          'trip_report', Icons.history, context.tr('quick_action.trip_report')),
      'help_center': _QuickActionItemData(
          'help_center', Icons.support_agent, context.tr('quick_action.help')),
      'daily_summary': _QuickActionItemData('daily_summary',
          Icons.insert_chart_outlined, context.tr('daily_summary')),
      'more': _QuickActionItemData(
          'more', Icons.more_horiz, context.tr('bottom_nav.more')),
    };
    final actions = actionIds
        .map((id) => specs[id])
        .whereType<_QuickActionItemData>()
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('dashboard.quick_actions'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final item = actions[index];
              return InkWell(
                onTap: () => onTap(item.id),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE3EF)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 23,
                        backgroundColor:
                            Theme.of(context).primaryColor.withAlpha(31),
                        child: Icon(item.icon,
                            color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionItemData {
  final String id;
  final IconData icon;
  final String label;

  const _QuickActionItemData(this.id, this.icon, this.label);
}
