//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LoadProof {
  /// Returns a new [LoadProof] instance.
  LoadProof({
    this.id,
    this.remarks,
    this.proofImagePaths = const [],
    this.signaturePath,
    this.uploadedAt,
    this.dispatch,
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
  String? remarks;

  List<String> proofImagePaths;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? signaturePath;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? uploadedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Dispatch? dispatch;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LoadProof &&
    other.id == id &&
    other.remarks == remarks &&
    _deepEquality.equals(other.proofImagePaths, proofImagePaths) &&
    other.signaturePath == signaturePath &&
    other.uploadedAt == uploadedAt &&
    other.dispatch == dispatch;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (proofImagePaths.hashCode) +
    (signaturePath == null ? 0 : signaturePath!.hashCode) +
    (uploadedAt == null ? 0 : uploadedAt!.hashCode) +
    (dispatch == null ? 0 : dispatch!.hashCode);

  @override
  String toString() => 'LoadProof[id=$id, remarks=$remarks, proofImagePaths=$proofImagePaths, signaturePath=$signaturePath, uploadedAt=$uploadedAt, dispatch=$dispatch]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.remarks != null) {
      json[r'remarks'] = this.remarks;
    } else {
      json[r'remarks'] = null;
    }
      json[r'proofImagePaths'] = this.proofImagePaths;
    if (this.signaturePath != null) {
      json[r'signaturePath'] = this.signaturePath;
    } else {
      json[r'signaturePath'] = null;
    }
    if (this.uploadedAt != null) {
      json[r'uploadedAt'] = this.uploadedAt!.toUtc().toIso8601String();
    } else {
      json[r'uploadedAt'] = null;
    }
    if (this.dispatch != null) {
      json[r'dispatch'] = this.dispatch;
    } else {
      json[r'dispatch'] = null;
    }
    return json;
  }

  /// Returns a new [LoadProof] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LoadProof? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LoadProof(
        id: mapValueOfType<int>(json, r'id'),
        remarks: mapValueOfType<String>(json, r'remarks'),
        proofImagePaths: json[r'proofImagePaths'] is Iterable
            ? (json[r'proofImagePaths'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        signaturePath: mapValueOfType<String>(json, r'signaturePath'),
        uploadedAt: mapDateTime(json, r'uploadedAt', r''),
        dispatch: Dispatch.fromJson(json[r'dispatch']),
      );
    }
    return null;
  }

  static List<LoadProof> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LoadProof>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LoadProof.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LoadProof> mapFromJson(dynamic json) {
    final map = <String, LoadProof>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LoadProof.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LoadProof-objects as value to a dart map
  static Map<String, List<LoadProof>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LoadProof>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LoadProof.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

