//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdateDocumentFileRequest {
  /// Returns a new [UpdateDocumentFileRequest] instance.
  UpdateDocumentFileRequest({
    required this.file,
  });

  MultipartFile file;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateDocumentFileRequest &&
    other.file == file;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (file.hashCode);

  @override
  String toString() => 'UpdateDocumentFileRequest[file=$file]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'file'] = this.file;
    return json;
  }

  /// Returns a new [UpdateDocumentFileRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateDocumentFileRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'file'), 'Required key "UpdateDocumentFileRequest[file]" is missing from JSON.');
        assert(json[r'file'] != null, 'Required key "UpdateDocumentFileRequest[file]" has a null value in JSON.');
        return true;
      }());

      return UpdateDocumentFileRequest(
        file: null, // No support for decoding binary content from JSON
      );
    }
    return null;
  }

  static List<UpdateDocumentFileRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateDocumentFileRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateDocumentFileRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateDocumentFileRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateDocumentFileRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateDocumentFileRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateDocumentFileRequest-objects as value to a dart map
  static Map<String, List<UpdateDocumentFileRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateDocumentFileRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateDocumentFileRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'file',
  };
}

