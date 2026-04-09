import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class HomeLocaleStrings {
  final bool isKhmer;
  final String accountNotLinked;
  final String fallbackUpdateTitle;
  final String fallbackUpdateSubtitle;
  final String loadPrefix;
  final String tripEmpty;
  final String progressFallback;
  final String progressTemplate;
  final String shiftStart;
  final String shiftEnd;
  final String loadFailed;
  final String Function(String parts) loadFailedWithParts;
  final String partsSession;
  final String partsNotifications;
  final String partsWebSocket;
  final String partsDispatches;
  final String partsBanners;
  final String partsTripMap;
  final String partsSafety;
  final String partsVehicle;

  const HomeLocaleStrings({
    required this.isKhmer,
    required this.accountNotLinked,
    required this.fallbackUpdateTitle,
    required this.fallbackUpdateSubtitle,
    required this.loadPrefix,
    required this.tripEmpty,
    required this.progressFallback,
    required this.progressTemplate,
    required this.shiftStart,
    required this.shiftEnd,
    required this.loadFailed,
    required this.loadFailedWithParts,
    required this.partsSession,
    required this.partsNotifications,
    required this.partsWebSocket,
    required this.partsDispatches,
    required this.partsBanners,
    required this.partsTripMap,
    required this.partsSafety,
    required this.partsVehicle,
  });

  factory HomeLocaleStrings.fromContext(BuildContext context) {
    return HomeLocaleStrings(
      isKhmer: context.locale.languageCode == 'km',
      accountNotLinked: context.tr('home.errors.account_not_linked'),
      fallbackUpdateTitle: context.tr('home.updates.fallback_1_title'),
      fallbackUpdateSubtitle: context.tr('home.updates.fallback_1_subtitle'),
      loadPrefix: context.tr('home.trip.load_prefix'),
      tripEmpty: context.tr('home.trip.empty'),
      progressFallback: context.tr('home.trip.progress_sample'),
      progressTemplate: context.tr('home.trip.progress_template'),
      shiftStart: context.tr('home.shift.sample_start_time'),
      shiftEnd: context.tr('home.shift.sample_end_time'),
      loadFailed: context.tr('home.errors.load_failed'),
      loadFailedWithParts: (parts) => context.tr(
        'home.errors.load_failed_with_parts',
        namedArgs: {'parts': parts},
      ),
      partsSession: context.tr('home.errors.parts.session'),
      partsNotifications: context.tr('home.errors.parts.notifications'),
      partsWebSocket: context.tr('home.errors.parts.websocket'),
      partsDispatches: context.tr('home.errors.parts.dispatches'),
      partsBanners: context.tr('home.errors.parts.banners'),
      partsTripMap: context.tr('home.errors.parts.trip_map'),
      partsSafety: context.tr('home.errors.parts.safety'),
      partsVehicle: context.tr('home.errors.parts.vehicle'),
    );
  }
}
