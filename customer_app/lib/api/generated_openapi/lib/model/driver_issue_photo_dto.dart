//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverIssuePhotoDto {
  /// Returns a new [DriverIssuePhotoDto] instance.
  DriverIssuePhotoDto({
    this.id,
    required this.issueId,
    required this.photoUrl,
    this.uploadedAt,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  int issueId;

  String photoUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? uploadedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverIssuePhotoDto &&
    other.id == id &&
    other.issueId == issueId &&
    other.photoUrl == photoUrl &&
    other.uploadedAt == uploadedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (issueId.hashCode) +
    (photoUrl.hashCode) +
    (uploadedAt == null ? 0 : uploadedAt!.hashCode);

  @override
  String toString() => 'DriverIssuePhotoDto[id=$id, issueId=$issueId, photoUrl=$photoUrl, uploadedAt=$uploadedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'issueId'] = this.issueId;
      json[r'photoUrl'] = this.photoUrl;
    if (this.uploadedAt != null) {
      json[r'uploadedAt'] = this.uploadedAt!.toUtc().toIso8601String();
    } else {
      json[r'uploadedAt'] = null;
    }
    return json;
  }

  /// Returns a new [DriverIssuePhotoDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverIssuePhotoDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'issueId'), 'Required key "DriverIssuePhotoDto[issueId]" is missing from JSON.');
        assert(json[r'issueId'] != null, 'Required key "DriverIssuePhotoDto[issueId]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'), 'Required key "DriverIssuePhotoDto[photoUrl]" is missing from JSON.');
        assert(json[r'photoUrl'] != null, 'Required key "DriverIssuePhotoDto[photoUrl]" has a null value in JSON.');
        return true;
      }());

      return DriverIssuePhotoDto(
        id: mapValueOfType<int>(json, r'id'),
        issueId: mapValueOfType<int>(json, r'issueId')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl')!,
        uploadedAt: mapDateTime(json, r'uploadedAt', r''),
      );
    }
    return null;
  }

  static List<DriverIssuePhotoDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverIssuePhotoDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverIssuePhotoDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverIssuePhotoDto> mapFromJson(dynamic json) {
    final map = <String, DriverIssuePhotoDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverIssuePhotoDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverIssuePhotoDto-objects as value to a dart map
  static Map<String, List<DriverIssuePhotoDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverIssuePhotoDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverIssuePhotoDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'issueId',
    'photoUrl',
  };
}

