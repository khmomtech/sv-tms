//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Pageablenull {
  /// Returns a new [Pageablenull] instance.
  Pageablenull({
    this.pageSize,
    this.paged,
    this.pageNumber,
    this.unpaged,
    this.offset,
    this.sort,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? pageSize;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? paged;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? pageNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? unpaged;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? offset;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Sortnull? sort;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Pageablenull &&
    other.pageSize == pageSize &&
    other.paged == paged &&
    other.pageNumber == pageNumber &&
    other.unpaged == unpaged &&
    other.offset == offset &&
    other.sort == sort;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (pageSize == null ? 0 : pageSize!.hashCode) +
    (paged == null ? 0 : paged!.hashCode) +
    (pageNumber == null ? 0 : pageNumber!.hashCode) +
    (unpaged == null ? 0 : unpaged!.hashCode) +
    (offset == null ? 0 : offset!.hashCode) +
    (sort == null ? 0 : sort!.hashCode);

  @override
  String toString() => 'Pageablenull[pageSize=$pageSize, paged=$paged, pageNumber=$pageNumber, unpaged=$unpaged, offset=$offset, sort=$sort]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.pageSize != null) {
      json[r'pageSize'] = this.pageSize;
    } else {
      json[r'pageSize'] = null;
    }
    if (this.paged != null) {
      json[r'paged'] = this.paged;
    } else {
      json[r'paged'] = null;
    }
    if (this.pageNumber != null) {
      json[r'pageNumber'] = this.pageNumber;
    } else {
      json[r'pageNumber'] = null;
    }
    if (this.unpaged != null) {
      json[r'unpaged'] = this.unpaged;
    } else {
      json[r'unpaged'] = null;
    }
    if (this.offset != null) {
      json[r'offset'] = this.offset;
    } else {
      json[r'offset'] = null;
    }
    if (this.sort != null) {
      json[r'sort'] = this.sort;
    } else {
      json[r'sort'] = null;
    }
    return json;
  }

  /// Returns a new [Pageablenull] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Pageablenull? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return Pageablenull(
        pageSize: mapValueOfType<int>(json, r'pageSize'),
        paged: mapValueOfType<bool>(json, r'paged'),
        pageNumber: mapValueOfType<int>(json, r'pageNumber'),
        unpaged: mapValueOfType<bool>(json, r'unpaged'),
        offset: mapValueOfType<int>(json, r'offset'),
        sort: Sortnull.fromJson(json[r'sort']),
      );
    }
    return null;
  }

  static List<Pageablenull> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Pageablenull>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Pageablenull.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Pageablenull> mapFromJson(dynamic json) {
    final map = <String, Pageablenull>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Pageablenull.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Pageablenull-objects as value to a dart map
  static Map<String, List<Pageablenull>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Pageablenull>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Pageablenull.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

