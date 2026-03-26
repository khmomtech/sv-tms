//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UnloadDetail {
  /// Returns a new [UnloadDetail] instance.
  UnloadDetail({
    this.id,
    this.startTime,
    this.endTime,
    this.proofs = const [],
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
  DateTime? startTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? endTime;

  List<UnloadProof> proofs;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Dispatch? dispatch;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UnloadDetail &&
    other.id == id &&
    other.startTime == startTime &&
    other.endTime == endTime &&
    _deepEquality.equals(other.proofs, proofs) &&
    other.dispatch == dispatch;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (startTime == null ? 0 : startTime!.hashCode) +
    (endTime == null ? 0 : endTime!.hashCode) +
    (proofs.hashCode) +
    (dispatch == null ? 0 : dispatch!.hashCode);

  @override
  String toString() => 'UnloadDetail[id=$id, startTime=$startTime, endTime=$endTime, proofs=$proofs, dispatch=$dispatch]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.startTime != null) {
      json[r'startTime'] = this.startTime!.toUtc().toIso8601String();
    } else {
      json[r'startTime'] = null;
    }
    if (this.endTime != null) {
      json[r'endTime'] = this.endTime!.toUtc().toIso8601String();
    } else {
      json[r'endTime'] = null;
    }
      json[r'proofs'] = this.proofs;
    if (this.dispatch != null) {
      json[r'dispatch'] = this.dispatch;
    } else {
      json[r'dispatch'] = null;
    }
    return json;
  }

  /// Returns a new [UnloadDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UnloadDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UnloadDetail(
        id: mapValueOfType<int>(json, r'id'),
        startTime: mapDateTime(json, r'startTime', r''),
        endTime: mapDateTime(json, r'endTime', r''),
        proofs: UnloadProof.listFromJson(json[r'proofs']),
        dispatch: Dispatch.fromJson(json[r'dispatch']),
      );
    }
    return null;
  }

  static List<UnloadDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnloadDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnloadDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UnloadDetail> mapFromJson(dynamic json) {
    final map = <String, UnloadDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UnloadDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UnloadDetail-objects as value to a dart map
  static Map<String, List<UnloadDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UnloadDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UnloadDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

