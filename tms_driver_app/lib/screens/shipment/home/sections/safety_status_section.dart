import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/safety_provider.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/home_safety_utils.dart';

class SafetyStatusSection extends StatelessWidget {
  const SafetyStatusSection({
    required this.onOpenSafetyCheck,
    required this.onOpenSafetyDetail,
    required this.mapApiError,
    super.key,
  });

  final VoidCallback onOpenSafetyCheck;
  final void Function(dynamic safety) onOpenSafetyDetail;
  final String Function(String raw) mapApiError;

  @override
  Widget build(BuildContext context) {
    return Consumer<SafetyProvider>(
      builder: (context, sp, _) {
        final isLoading = sp.isLoading && sp.today == null;
        final status = sp.status ?? 'NOT_STARTED';
        final risk = sp.today?.riskOverride ?? sp.today?.riskLevel;
        final error = sp.errorMessage;

        final cta = isLoading
            ? context.tr('home.safety.please_wait')
            : safetyCtaLabel(context, status);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: safetyStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('home.safety.daily_check'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (risk != null && risk.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: safetyRiskColor(risk),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          risk.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isLoading
                      ? context.tr('home.safety.loading')
                      : safetyStatusLabel(context, status),
                  style: TextStyle(
                    color: safetyStatusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('home.safety.optional_note'),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                if (!isLoading && error != null && error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      mapApiError(error),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if ((status == 'WAITING_APPROVAL' ||
                                    status == 'APPROVED') &&
                                sp.today != null) {
                              onOpenSafetyDetail(sp.today);
                              return;
                            }
                            onOpenSafetyCheck();
                          },
                    child: Text(cta),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
