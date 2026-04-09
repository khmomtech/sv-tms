import 'package:flutter/material.dart';

import '../../models/dispatch_model.dart';
import 'submit_cod_settlement_screen.dart';
import 'submit_fuel_request_screen.dart';
import 'submit_odometer_screen.dart';

class DispatchFinanceActionsSheet extends StatelessWidget {
  final DispatchModel dispatch;
  final VoidCallback? onSubmitted;

  const DispatchFinanceActionsSheet({
    super.key,
    required this.dispatch,
    this.onSubmitted,
  });

  void _showScreen(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (_) => screen),
    )
        .then((result) {
      if (!context.mounted) return;
      if (result == true && onSubmitted != null) {
        onSubmitted!();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            const SizedBox(height: 16.0),

            Text(
              'Dispatch Finance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Submit documents for ${dispatch.id}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24.0),

            // Action Buttons
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 1.1,
              children: [
                // Odometer
                _FinanceActionButton(
                  icon: Icons.speed,
                  label: 'Odometer',
                  description: 'KM Reading',
                  onTap: () => _showScreen(
                    context,
                    SubmitOdometerScreen(dispatch: dispatch),
                  ),
                ),

                // Fuel
                _FinanceActionButton(
                  icon: Icons.local_gas_station,
                  label: 'Fuel',
                  description: 'Request',
                  onTap: () => _showScreen(
                    context,
                    SubmitFuelRequestScreen(dispatch: dispatch),
                  ),
                ),

                // COD
                _FinanceActionButton(
                  icon: Icons.payment,
                  label: 'COD',
                  description: 'Settlement',
                  onTap: () => _showScreen(
                    context,
                    SubmitCodSettlementScreen(dispatch: dispatch),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _FinanceActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: Colors.blue.shade200,
            width: 1.5,
          ),
          color: Colors.blue.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32.0,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 8.0),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2.0),
            Text(
              description,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.blue.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
