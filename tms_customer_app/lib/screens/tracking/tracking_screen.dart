import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('tracking'.tr())),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('tracking'.tr(), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('enter_tracking_id'.tr(), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
