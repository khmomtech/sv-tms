import 'package:flutter/material.dart';

/// Opens a date-range picker with safer defaults for small screens and older devices.
/// - Forces Material 2 picker (more stable on cramped layouts).
/// - Uses calendar-only mode to avoid the text-field input header that can overflow.
/// - Wraps in SafeArea and returns `null` if the picker fails to build.
Future<DateTimeRange?> showStableDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  Color? accentColor,
}) async {
  try {
    final theme = Theme.of(context);
    final colorScheme = accentColor != null
        ? theme.colorScheme.copyWith(
            primary: accentColor,
            surfaceTint: accentColor,
          )
        : theme.colorScheme;

    return await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialDateRange,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();
        return SafeArea(
          child: Theme(
            data: theme.copyWith(
              useMaterial3: false,
              colorScheme: colorScheme,
            ),
            child: child,
          ),
        );
      },
    );
  } catch (e, st) {
    debugPrint('Date range picker failed: $e\n$st');
    return null;
  }
}
