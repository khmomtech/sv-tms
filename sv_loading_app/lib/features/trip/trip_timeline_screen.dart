import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../state/trip_provider.dart';
import '../../widgets/app_scaffold.dart';

class TripTimelineScreen extends StatelessWidget {
  const TripTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.currentTrip;

    return AppScaffold(
      titleKey: 'timeline',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text('${'trip_id'.tr()}: ${trip?.tripId ?? '-'}')),
            const SizedBox(height: 12),
            if (tripProvider.error != null)
              Text(tripProvider.error!,
                  style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: trip == null
                    ? null
                    : () => tripProvider.fetchTimeline(trip.tripId),
                icon: const Icon(Icons.refresh),
                label: Text('fetch_dispatch_detail'.tr()),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (tripProvider.dispatchDetail == null)
                    ListTile(title: Text('no_data'.tr())),
                  if (tripProvider.dispatchDetail != null) ...[
                    ListTile(
                      leading: const Icon(Icons.local_shipping),
                      title: Text(
                          '${'dispatch'.tr()}: ${tripProvider.dispatchDetail!['dispatchId'] ?? '-'}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.verified_user),
                      title: Text(
                          '${'pre_entry_safety'.tr()}: ${tripProvider.dispatchDetail!['preEntrySafetyStatus'] ?? '-'}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.safety_check),
                      title: Text(
                          '${'loading_safety'.tr()}: ${tripProvider.dispatchDetail!['loadingSafetyStatus'] ?? '-'}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.queue),
                      title: Text(
                          '${'queue_status'.tr()}: ${_nested(tripProvider.dispatchDetail, 'queue', 'status')}'),
                      subtitle: Text(
                          '${'active_queue_id'.tr()}: ${_nested(tripProvider.dispatchDetail, 'queue', 'id')}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.play_circle),
                      title: Text(
                          '${'active_session_id'.tr()}: ${_nested(tripProvider.dispatchDetail, 'session', 'id')}'),
                      subtitle: Text(
                          '${'started'.tr()}: ${_nested(tripProvider.dispatchDetail, 'session', 'startedAt')}'),
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _nested(Map<String, dynamic>? root, String l1, String l2) {
    final one = root?[l1];
    if (one is Map<String, dynamic>) {
      return one[l2]?.toString() ?? '-';
    }
    return '-';
  }
}
