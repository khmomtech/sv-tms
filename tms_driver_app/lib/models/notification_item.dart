class NotificationItem {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool read;
  final bool isImportant;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.isImportant = false,
  });

  static String _asMessage(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is List) {
      return raw.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).join('\n');
    }
    if (raw is Map) {
      return raw.values.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).join('\n');
    }
    return raw.toString();
  }

  static DateTime _asDateTime(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    if (raw is List && raw.length >= 6) {
      final values = raw.map((e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0).toList();
      final year = values[0];
      final month = values[1];
      final day = values[2];
      final hour = values[3];
      final minute = values[4];
      final second = values[5];
      final nanos = values.length > 6 ? values[6] : 0;
      final millis = (nanos / 1000000).floor();
      try {
        return DateTime(year, month, day, hour, minute, second, millis);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is num ? idRaw.toInt() : int.tryParse('$idRaw') ?? 0;
    return NotificationItem(
      id: id,
      title: json['title'] as String? ?? 'Notification',
      message: _asMessage(json['message'] ?? json['body']),
      createdAt: _asDateTime(json['createdAt']),
      read: json['read'] as bool? ?? false,
      isImportant: json['isImportant'] as bool? ?? false,
    );
  }
}
