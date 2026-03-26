//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BannerDto {
  /// Returns a new [BannerDto] instance.
  BannerDto({
    this.id,
    this.title,
    this.titleKh,
    this.subtitle,
    this.subtitleKh,
    this.imageUrl,
    this.category,
    this.targetUrl,
    this.displayOrder,
    this.startDate,
    this.endDate,
    this.active,
    this.clickCount,
    this.viewCount,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? titleKh;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? subtitle;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? subtitleKh;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? imageUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? category;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? targetUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? displayOrder;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? startDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? endDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? active;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? clickCount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? viewCount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? createdBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BannerDto &&
    other.id == id &&
    other.title == title &&
    other.titleKh == titleKh &&
    other.subtitle == subtitle &&
    other.subtitleKh == subtitleKh &&
    other.imageUrl == imageUrl &&
    other.category == category &&
    other.targetUrl == targetUrl &&
    other.displayOrder == displayOrder &&
    other.startDate == startDate &&
    other.endDate == endDate &&
    other.active == active &&
    other.clickCount == clickCount &&
    other.viewCount == viewCount &&
    other.createdBy == createdBy &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (title == null ? 0 : title!.hashCode) +
    (titleKh == null ? 0 : titleKh!.hashCode) +
    (subtitle == null ? 0 : subtitle!.hashCode) +
    (subtitleKh == null ? 0 : subtitleKh!.hashCode) +
    (imageUrl == null ? 0 : imageUrl!.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (targetUrl == null ? 0 : targetUrl!.hashCode) +
    (displayOrder == null ? 0 : displayOrder!.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode) +
    (endDate == null ? 0 : endDate!.hashCode) +
    (active == null ? 0 : active!.hashCode) +
    (clickCount == null ? 0 : clickCount!.hashCode) +
    (viewCount == null ? 0 : viewCount!.hashCode) +
    (createdBy == null ? 0 : createdBy!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode);

  @override
  String toString() => 'BannerDto[id=$id, title=$title, titleKh=$titleKh, subtitle=$subtitle, subtitleKh=$subtitleKh, imageUrl=$imageUrl, category=$category, targetUrl=$targetUrl, displayOrder=$displayOrder, startDate=$startDate, endDate=$endDate, active=$active, clickCount=$clickCount, viewCount=$viewCount, createdBy=$createdBy, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.titleKh != null) {
      json[r'titleKh'] = this.titleKh;
    } else {
      json[r'titleKh'] = null;
    }
    if (this.subtitle != null) {
      json[r'subtitle'] = this.subtitle;
    } else {
      json[r'subtitle'] = null;
    }
    if (this.subtitleKh != null) {
      json[r'subtitleKh'] = this.subtitleKh;
    } else {
      json[r'subtitleKh'] = null;
    }
    if (this.imageUrl != null) {
      json[r'imageUrl'] = this.imageUrl;
    } else {
      json[r'imageUrl'] = null;
    }
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
    if (this.targetUrl != null) {
      json[r'targetUrl'] = this.targetUrl;
    } else {
      json[r'targetUrl'] = null;
    }
    if (this.displayOrder != null) {
      json[r'displayOrder'] = this.displayOrder;
    } else {
      json[r'displayOrder'] = null;
    }
    if (this.startDate != null) {
      json[r'startDate'] = this.startDate!.toUtc().toIso8601String();
    } else {
      json[r'startDate'] = null;
    }
    if (this.endDate != null) {
      json[r'endDate'] = this.endDate!.toUtc().toIso8601String();
    } else {
      json[r'endDate'] = null;
    }
    if (this.active != null) {
      json[r'active'] = this.active;
    } else {
      json[r'active'] = null;
    }
    if (this.clickCount != null) {
      json[r'clickCount'] = this.clickCount;
    } else {
      json[r'clickCount'] = null;
    }
    if (this.viewCount != null) {
      json[r'viewCount'] = this.viewCount;
    } else {
      json[r'viewCount'] = null;
    }
    if (this.createdBy != null) {
      json[r'createdBy'] = this.createdBy;
    } else {
      json[r'createdBy'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updatedAt'] = null;
    }
    return json;
  }

  /// Returns a new [BannerDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BannerDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return BannerDto(
        id: mapValueOfType<int>(json, r'id'),
        title: mapValueOfType<String>(json, r'title'),
        titleKh: mapValueOfType<String>(json, r'titleKh'),
        subtitle: mapValueOfType<String>(json, r'subtitle'),
        subtitleKh: mapValueOfType<String>(json, r'subtitleKh'),
        imageUrl: mapValueOfType<String>(json, r'imageUrl'),
        category: mapValueOfType<String>(json, r'category'),
        targetUrl: mapValueOfType<String>(json, r'targetUrl'),
        displayOrder: mapValueOfType<int>(json, r'displayOrder'),
        startDate: mapDateTime(json, r'startDate', r''),
        endDate: mapDateTime(json, r'endDate', r''),
        active: mapValueOfType<bool>(json, r'active'),
        clickCount: mapValueOfType<int>(json, r'clickCount'),
        viewCount: mapValueOfType<int>(json, r'viewCount'),
        createdBy: mapValueOfType<String>(json, r'createdBy'),
        createdAt: mapDateTime(json, r'createdAt', r''),
        updatedAt: mapDateTime(json, r'updatedAt', r''),
      );
    }
    return null;
  }

  static List<BannerDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BannerDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BannerDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BannerDto> mapFromJson(dynamic json) {
    final map = <String, BannerDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BannerDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BannerDto-objects as value to a dart map
  static Map<String, List<BannerDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BannerDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BannerDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

