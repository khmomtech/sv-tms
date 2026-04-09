import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String safetyStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'DRAFT':
      return context.tr('home.safety.status.draft');
    case 'WAITING_APPROVAL':
      return context.tr('home.safety.status.waiting_approval');
    case 'APPROVED':
      return context.tr('home.safety.status.approved');
    case 'REJECTED':
      return context.tr('home.safety.status.rejected');
    default:
      return context.tr('home.safety.status.not_started');
  }
}

String safetyCtaLabel(BuildContext context, String status) {
  switch (status) {
    case 'DRAFT':
      return context.tr('home.safety.cta.continue_check');
    case 'WAITING_APPROVAL':
    case 'APPROVED':
      return context.tr('home.safety.cta.view_detail');
    case 'REJECTED':
      return context.tr('home.safety.cta.fix_and_retry');
    default:
      return context.tr('home.safety.cta.start_check');
  }
}

Color safetyStatusColor(String status) {
  switch (status) {
    case 'DRAFT':
      return Colors.blue;
    case 'WAITING_APPROVAL':
      return Colors.orange;
    case 'APPROVED':
      return Colors.green;
    case 'REJECTED':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

Color safetyRiskColor(String risk) {
  switch (risk.toUpperCase()) {
    case 'HIGH':
      return Colors.red;
    case 'MEDIUM':
      return Colors.orange;
    default:
      return Colors.green;
  }
}
