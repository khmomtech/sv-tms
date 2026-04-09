class DriverIssue {
  final int id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final List<String> images;
  final String? driverName;
  final String? orderReference;

  DriverIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.images = const [],
    this.driverName,
    this.orderReference,
  });

  factory DriverIssue.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      if (raw is List && raw.length >= 3) {
        return DateTime(
          raw[0],
          raw[1],
          raw[2],
          raw.length > 3 ? raw[3] : 0,
          raw.length > 4 ? raw[4] : 0,
          raw.length > 5 ? raw[5] : 0,
        );
      }
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      if (raw is double) {
        return DateTime.fromMillisecondsSinceEpoch((raw * 1000).toInt());
      }
      return DateTime.now();
    }

    List<String> parseImages(dynamic raw) {
      final List<String> items = [];
      if (raw is List) {
        for (final item in raw) {
          if (item == null) continue;
          String val = item.toString().trim();
          if (val.isEmpty) continue;
          // Normalize to match UI expectation of `uploads/<path>`
          if (val.startsWith('http://') || val.startsWith('https://')) {
            items.add(val);
            continue;
          }
          if (val.startsWith('/uploads/')) {
            val = val.substring('/uploads/'.length);
          } else if (val.startsWith('uploads/')) {
            val = val.substring('uploads/'.length);
          }
          items.add(val);
        }
      }
      return items;
    }

    String normalizeStatus(String? raw) {
      final value = (raw ?? 'UNKNOWN').toUpperCase();
      switch (value) {
        case 'NEW':
          return 'OPEN';
        case 'VALIDATED':
        case 'LINKED_TO_CASE':
          return 'IN_PROGRESS';
        case 'CLOSED':
          return 'CLOSED';
        case 'RESOLVED':
          return 'RESOLVED';
        case 'OPEN':
          return 'OPEN';
        default:
          return value;
      }
    }

    final created = json.containsKey('reportedAt')
        ? parseCreatedAt(json['reportedAt'])
        : parseCreatedAt(json['createdAt']);

    final images = parseImages(json['images'] ?? json['photoUrls']);

    return DriverIssue(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: normalizeStatus(json['status']),
      createdAt: created,
      images: images,
      driverName: json['driverName'],
      orderReference: json['orderReference'],
    );
  }

  DriverIssue copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
    List<String>? images,
    String? driverName,
    String? orderReference,
  }) {
    return DriverIssue(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      driverName: driverName ?? this.driverName,
      orderReference: orderReference ?? this.orderReference,
    );
  }
}
