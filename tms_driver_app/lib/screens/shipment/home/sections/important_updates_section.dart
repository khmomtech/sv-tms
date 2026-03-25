import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tms_driver_app/screens/shipment/home/home_state.dart';
import 'package:tms_driver_app/widgets/important_updates_carousel.dart';

class ImportantUpdatesSection extends StatelessWidget {
  const ImportantUpdatesSection({
    required this.updates,
    required this.onTap,
    super.key,
  });

  final List<HomeUpdateVm> updates;
  final void Function(HomeUpdateVm item) onTap;

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.update_disabled, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No important updates at the moment.',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final carouselUpdates = updates
        .map(
          (u) => ImportantUpdate(
            title: u.title,
            subtitle: u.subtitle,
            imageUrl: u.imageUrl,
            onTap: () => onTap(u),
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.campaign, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                context.tr('home.updates.title'),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ImportantUpdatesCarousel(updates: carouselUpdates),
        ],
      ),
    );
  }
}
