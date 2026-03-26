//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdateIssueRequest {
  /// Returns a new [UpdateIssueRequest] instance.
  UpdateIssueRequest({
    required this.title,
    required this.description,
  });

  String title;

  String description;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateIssueRequest &&
    other.title == title &&
    other.description == description;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (title.hashCode) +
    (description.hashCode);

  @override
  String toString() => 'UpdateIssueRequest[title=$title, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'title'] = this.title;
      json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [UpdateIssueRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateIssueRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'title'), 'Required key "UpdateIssueRequest[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "UpdateIssueRequest[title]" has a null value in JSON.');
        assert(json.containsKey(r'description'), 'Required key "UpdateIssueRequest[description]" is missing from JSON.');
        assert(json[r'description'] != null, 'Required key "UpdateIssueRequest[description]" has a null value in JSON.');
        return true;
      }());

      return UpdateIssueRequest(
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<UpdateIssueRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateIssueRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateIssueRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateIssueRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateIssueRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateIssueRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateIssueRequest-objects as value to a dart map
  static Map<String, List<UpdateIssueRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateIssueRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateIssueRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'title',
    'description',
  };
}

