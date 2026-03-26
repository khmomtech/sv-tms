//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MarkAsUnloadedRequest {
  /// Returns a new [MarkAsUnloadedRequest] instance.
  MarkAsUnloadedRequest({
    this.images = const [],
    this.signature,
  });

  List<MultipartFile> images;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  MultipartFile? signature;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MarkAsUnloadedRequest &&
    _deepEquality.equals(other.images, images) &&
    other.signature == signature;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (images.hashCode) +
    (signature == null ? 0 : signature!.hashCode);

  @override
  String toString() => 'MarkAsUnloadedRequest[images=$images, signature=$signature]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'images'] = this.images;
    if (this.signature != null) {
      json[r'signature'] = this.signature;
    } else {
      json[r'signature'] = null;
    }
    return json;
  }

  /// Returns a new [MarkAsUnloadedRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MarkAsUnloadedRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return MarkAsUnloadedRequest(
        images: MultipartFile.listFromJson(json[r'images']),
        signature: null, // No support for decoding binary content from JSON
      );
    }
    return null;
  }

  static List<MarkAsUnloadedRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MarkAsUnloadedRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarkAsUnloadedRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MarkAsUnloadedRequest> mapFromJson(dynamic json) {
    final map = <String, MarkAsUnloadedRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MarkAsUnloadedRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MarkAsUnloadedRequest-objects as value to a dart map
  static Map<String, List<MarkAsUnloadedRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MarkAsUnloadedRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MarkAsUnloadedRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

