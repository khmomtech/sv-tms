//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DispatchStop {
  /// Returns a new [DispatchStop] instance.
  DispatchStop({
    this.id,
    this.stopSequence,
    this.locationName,
    this.address,
    this.coordinates,
    this.arrivalTime,
    this.departureTime,
    this.isCompleted,
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
  int? stopSequence;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? locationName;

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
  String? coordinates;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? arrivalTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? departureTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isCompleted;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Dispatch? dispatch;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DispatchStop &&
    other.id == id &&
    other.stopSequence == stopSequence &&
    other.locationName == locationName &&
    other.address == address &&
    other.coordinates == coordinates &&
    other.arrivalTime == arrivalTime &&
    other.departureTime == departureTime &&
    other.isCompleted == isCompleted &&
    other.dispatch == dispatch;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (stopSequence == null ? 0 : stopSequence!.hashCode) +
    (locationName == null ? 0 : locationName!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (coordinates == null ? 0 : coordinates!.hashCode) +
    (arrivalTime == null ? 0 : arrivalTime!.hashCode) +
    (departureTime == null ? 0 : departureTime!.hashCode) +
    (isCompleted == null ? 0 : isCompleted!.hashCode) +
    (dispatch == null ? 0 : dispatch!.hashCode);

  @override
  String toString() => 'DispatchStop[id=$id, stopSequence=$stopSequence, locationName=$locationName, address=$address, coordinates=$coordinates, arrivalTime=$arrivalTime, departureTime=$departureTime, isCompleted=$isCompleted, dispatch=$dispatch]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.stopSequence != null) {
      json[r'stopSequence'] = this.stopSequence;
    } else {
      json[r'stopSequence'] = null;
    }
    if (this.locationName != null) {
      json[r'locationName'] = this.locationName;
    } else {
      json[r'locationName'] = null;
    }
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.coordinates != null) {
      json[r'coordinates'] = this.coordinates;
    } else {
      json[r'coordinates'] = null;
    }
    if (this.arrivalTime != null) {
      json[r'arrivalTime'] = this.arrivalTime!.toUtc().toIso8601String();
    } else {
      json[r'arrivalTime'] = null;
    }
    if (this.departureTime != null) {
      json[r'departureTime'] = this.departureTime!.toUtc().toIso8601String();
    } else {
      json[r'departureTime'] = null;
    }
    if (this.isCompleted != null) {
      json[r'isCompleted'] = this.isCompleted;
    } else {
      json[r'isCompleted'] = null;
    }
    if (this.dispatch != null) {
      json[r'dispatch'] = this.dispatch;
    } else {
      json[r'dispatch'] = null;
    }
    return json;
  }

  /// Returns a new [DispatchStop] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DispatchStop? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DispatchStop(
        id: mapValueOfType<int>(json, r'id'),
        stopSequence: mapValueOfType<int>(json, r'stopSequence'),
        locationName: mapValueOfType<String>(json, r'locationName'),
        address: mapValueOfType<String>(json, r'address'),
        coordinates: mapValueOfType<String>(json, r'coordinates'),
        arrivalTime: mapDateTime(json, r'arrivalTime', r''),
        departureTime: mapDateTime(json, r'departureTime', r''),
        isCompleted: mapValueOfType<bool>(json, r'isCompleted'),
        dispatch: Dispatch.fromJson(json[r'dispatch']),
      );
    }
    return null;
  }

  static List<DispatchStop> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DispatchStop>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DispatchStop.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DispatchStop> mapFromJson(dynamic json) {
    final map = <String, DispatchStop>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DispatchStop.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DispatchStop-objects as value to a dart map
  static Map<String, List<DispatchStop>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DispatchStop>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DispatchStop.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

