//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UnloadProof {
  /// Returns a new [UnloadProof] instance.
  UnloadProof({
    this.id,
    this.remarks,
    this.address,
    this.latitude,
    this.longitude,
    this.proofImagePaths = const [],
    this.signaturePath,
    this.submittedAt,
    this.unloadDetail,
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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? address;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? latitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? longitude;

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
  DateTime? submittedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UnloadDetail? unloadDetail;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Dispatch? dispatch;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UnloadProof &&
    other.id == id &&
    other.remarks == remarks &&
    other.address == address &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    _deepEquality.equals(other.proofImagePaths, proofImagePaths) &&
    other.signaturePath == signaturePath &&
    other.submittedAt == submittedAt &&
    other.unloadDetail == unloadDetail &&
    other.dispatch == dispatch;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (proofImagePaths.hashCode) +
    (signaturePath == null ? 0 : signaturePath!.hashCode) +
    (submittedAt == null ? 0 : submittedAt!.hashCode) +
    (unloadDetail == null ? 0 : unloadDetail!.hashCode) +
    (dispatch == null ? 0 : dispatch!.hashCode);

  @override
  String toString() => 'UnloadProof[id=$id, remarks=$remarks, address=$address, latitude=$latitude, longitude=$longitude, proofImagePaths=$proofImagePaths, signaturePath=$signaturePath, submittedAt=$submittedAt, unloadDetail=$unloadDetail, dispatch=$dispatch]';

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
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
      json[r'proofImagePaths'] = this.proofImagePaths;
    if (this.signaturePath != null) {
      json[r'signaturePath'] = this.signaturePath;
    } else {
      json[r'signaturePath'] = null;
    }
    if (this.submittedAt != null) {
      json[r'submittedAt'] = this.submittedAt!.toUtc().toIso8601String();
    } else {
      json[r'submittedAt'] = null;
    }
    if (this.unloadDetail != null) {
      json[r'unloadDetail'] = this.unloadDetail;
    } else {
      json[r'unloadDetail'] = null;
    }
    if (this.dispatch != null) {
      json[r'dispatch'] = this.dispatch;
    } else {
      json[r'dispatch'] = null;
    }
    return json;
  }

  /// Returns a new [UnloadProof] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UnloadProof? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UnloadProof(
        id: mapValueOfType<int>(json, r'id'),
        remarks: mapValueOfType<String>(json, r'remarks'),
        address: mapValueOfType<String>(json, r'address'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        proofImagePaths: json[r'proofImagePaths'] is Iterable
            ? (json[r'proofImagePaths'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        signaturePath: mapValueOfType<String>(json, r'signaturePath'),
        submittedAt: mapDateTime(json, r'submittedAt', r''),
        unloadDetail: UnloadDetail.fromJson(json[r'unloadDetail']),
        dispatch: Dispatch.fromJson(json[r'dispatch']),
      );
    }
    return null;
  }

  static List<UnloadProof> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnloadProof>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnloadProof.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UnloadProof> mapFromJson(dynamic json) {
    final map = <String, UnloadProof>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UnloadProof.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UnloadProof-objects as value to a dart map
  static Map<String, List<UnloadProof>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UnloadProof>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UnloadProof.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

