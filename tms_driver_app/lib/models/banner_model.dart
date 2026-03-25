class BannerModel {
  final int id;
  final String title;
  final String? titleKh;
  final String? subtitle;
  final String? subtitleKh;
  final String? imageUrl;
  final String? targetUrl;
  final String category;
  final int displayOrder;
  final bool active;
  final DateTime? startDate;
  final DateTime? endDate;
  final int viewCount;
  final int clickCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BannerModel({
    required this.id,
    required this.title,
    this.titleKh,
    this.subtitle,
    this.subtitleKh,
    this.imageUrl,
    this.targetUrl,
    required this.category,
    required this.displayOrder,
    required this.active,
    this.startDate,
    this.endDate,
    required this.viewCount,
    required this.clickCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    String _asString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is List && v.isNotEmpty) {
        // If server returns a list of strings, pick the first
        final first = v.first;
        return first is String ? first : '$first';
      }
      return '$v';
    }

    int _asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      final s = '$v';
      return int.tryParse(s) ?? 0;
    }

    bool _asBool(dynamic v) {
      if (v is bool) return v;
      final s = ('$v').toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }

    DateTime? _asDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) {
        try { return DateTime.parse(v); } catch (_) { return null; }
      }
      if (v is List && v.length >= 3) {
        // Handle Java LocalDateTime arrays: [year, month, day, hour?, minute?, second?]
        try {
          final y = _asInt(v[0]);
          final m = _asInt(v[1]).clamp(1, 12);
          final d = _asInt(v[2]).clamp(1, 31);
          final hh = v.length > 3 ? _asInt(v[3]).clamp(0, 23) : 0;
          final mm = v.length > 4 ? _asInt(v[4]).clamp(0, 59) : 0;
          final ss = v.length > 5 ? _asInt(v[5]).clamp(0, 59) : 0;
          return DateTime(y, m, d, hh, mm, ss);
        } catch (_) { return null; }
      }
      return null;
    }

    final createdAtVal = json['createdAt'];
    final updatedAtVal = json['updatedAt'];

    return BannerModel(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      titleKh: _asString(json['titleKh']).isNotEmpty ? _asString(json['titleKh']) : null,
      subtitle: _asString(json['subtitle']).isNotEmpty ? _asString(json['subtitle']) : null,
      subtitleKh: _asString(json['subtitleKh']).isNotEmpty ? _asString(json['subtitleKh']) : null,
      imageUrl: _asString(json['imageUrl']).isNotEmpty ? _asString(json['imageUrl']) : null,
      targetUrl: _asString(json['targetUrl']).isNotEmpty ? _asString(json['targetUrl']) : null,
      category: _asString(json['category']),
      displayOrder: _asInt(json['displayOrder']),
      active: _asBool(json['active']),
      startDate: _asDate(json['startDate']),
      endDate: _asDate(json['endDate']),
      viewCount: _asInt(json['viewCount']),
      clickCount: _asInt(json['clickCount']),
      createdAt: _asDate(createdAtVal) ?? DateTime.now(),
      updatedAt: _asDate(updatedAtVal) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titleKh': titleKh,
      'subtitle': subtitle,
      'subtitleKh': subtitleKh,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'category': category,
      'displayOrder': displayOrder,
      'active': active,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'viewCount': viewCount,
      'clickCount': clickCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get localized title based on current locale
  String getLocalizedTitle(String locale) {
    if (locale.startsWith('km') && titleKh != null && titleKh!.isNotEmpty) {
      return titleKh!;
    }
    return title;
  }

  /// Get localized subtitle based on current locale
  String? getLocalizedSubtitle(String locale) {
    if (locale.startsWith('km') && subtitleKh != null && subtitleKh!.isNotEmpty) {
      return subtitleKh;
    }
    return subtitle;
  }

  /// Calculate click-through rate
  double get clickThroughRate {
    if (viewCount == 0) return 0.0;
    return (clickCount / viewCount) * 100;
  }
}
