extension StringExtensions on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}

extension DateTimeExtensions on DateTime {
  String toReadable() => '$day-$month-$year';
}
