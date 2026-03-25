import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('shipments'.tr())),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('shipments'.tr(), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('coming_soon'.tr(), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
