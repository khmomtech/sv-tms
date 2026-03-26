//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LocationPoint {
  /// Returns a new [LocationPoint] instance.
  LocationPoint({
    this.locationName,
    this.lat,
    this.lng,
  });

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
  double? lat;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? lng;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LocationPoint &&
    other.locationName == locationName &&
    other.lat == lat &&
    other.lng == lng;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (locationName == null ? 0 : locationName!.hashCode) +
    (lat == null ? 0 : lat!.hashCode) +
    (lng == null ? 0 : lng!.hashCode);

  @override
  String toString() => 'LocationPoint[locationName=$locationName, lat=$lat, lng=$lng]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.locationName != null) {
      json[r'locationName'] = this.locationName;
    } else {
      json[r'locationName'] = null;
    }
    if (this.lat != null) {
      json[r'lat'] = this.lat;
    } else {
      json[r'lat'] = null;
    }
    if (this.lng != null) {
      json[r'lng'] = this.lng;
    } else {
      json[r'lng'] = null;
    }
    return json;
  }

  /// Returns a new [LocationPoint] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LocationPoint? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LocationPoint(
        locationName: mapValueOfType<String>(json, r'locationName'),
        lat: mapValueOfType<double>(json, r'lat'),
        lng: mapValueOfType<double>(json, r'lng'),
      );
    }
    return null;
  }

  static List<LocationPoint> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LocationPoint>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LocationPoint.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LocationPoint> mapFromJson(dynamic json) {
    final map = <String, LocationPoint>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LocationPoint.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LocationPoint-objects as value to a dart map
  static Map<String, List<LocationPoint>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LocationPoint>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LocationPoint.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

