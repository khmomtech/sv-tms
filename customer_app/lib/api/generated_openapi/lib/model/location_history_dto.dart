//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LocationHistoryDto {
  /// Returns a new [LocationHistoryDto] instance.
  LocationHistoryDto({
    this.id,
    this.driverId,
    this.dispatchId,
    this.latitude,
    this.longitude,
    this.locationName,
    this.timestamp,
    this.lastUpdated,
    this.isOnline,
    this.batteryLevel,
    this.speed,
    this.source_,
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
  int? driverId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? dispatchId;

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
  DateTime? timestamp;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastUpdated;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isOnline;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? batteryLevel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? speed;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? source_;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  PartialDispatchDto? dispatch;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LocationHistoryDto &&
    other.id == id &&
    other.driverId == driverId &&
    other.dispatchId == dispatchId &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.locationName == locationName &&
    other.timestamp == timestamp &&
    other.lastUpdated == lastUpdated &&
    other.isOnline == isOnline &&
    other.batteryLevel == batteryLevel &&
    other.speed == speed &&
    other.source_ == source_ &&
    other.dispatch == dispatch;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (driverId == null ? 0 : driverId!.hashCode) +
    (dispatchId == null ? 0 : dispatchId!.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (locationName == null ? 0 : locationName!.hashCode) +
    (timestamp == null ? 0 : timestamp!.hashCode) +
    (lastUpdated == null ? 0 : lastUpdated!.hashCode) +
    (isOnline == null ? 0 : isOnline!.hashCode) +
    (batteryLevel == null ? 0 : batteryLevel!.hashCode) +
    (speed == null ? 0 : speed!.hashCode) +
    (source_ == null ? 0 : source_!.hashCode) +
    (dispatch == null ? 0 : dispatch!.hashCode);

  @override
  String toString() => 'LocationHistoryDto[id=$id, driverId=$driverId, dispatchId=$dispatchId, latitude=$latitude, longitude=$longitude, locationName=$locationName, timestamp=$timestamp, lastUpdated=$lastUpdated, isOnline=$isOnline, batteryLevel=$batteryLevel, speed=$speed, source_=$source_, dispatch=$dispatch]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.driverId != null) {
      json[r'driverId'] = this.driverId;
    } else {
      json[r'driverId'] = null;
    }
    if (this.dispatchId != null) {
      json[r'dispatchId'] = this.dispatchId;
    } else {
      json[r'dispatchId'] = null;
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
    if (this.locationName != null) {
      json[r'locationName'] = this.locationName;
    } else {
      json[r'locationName'] = null;
    }
    if (this.timestamp != null) {
      json[r'timestamp'] = this.timestamp!.toUtc().toIso8601String();
    } else {
      json[r'timestamp'] = null;
    }
    if (this.lastUpdated != null) {
      json[r'lastUpdated'] = this.lastUpdated!.toUtc().toIso8601String();
    } else {
      json[r'lastUpdated'] = null;
    }
    if (this.isOnline != null) {
      json[r'isOnline'] = this.isOnline;
    } else {
      json[r'isOnline'] = null;
    }
    if (this.batteryLevel != null) {
      json[r'batteryLevel'] = this.batteryLevel;
    } else {
      json[r'batteryLevel'] = null;
    }
    if (this.speed != null) {
      json[r'speed'] = this.speed;
    } else {
      json[r'speed'] = null;
    }
    if (this.source_ != null) {
      json[r'source'] = this.source_;
    } else {
      json[r'source'] = null;
    }
    if (this.dispatch != null) {
      json[r'dispatch'] = this.dispatch;
    } else {
      json[r'dispatch'] = null;
    }
    return json;
  }

  /// Returns a new [LocationHistoryDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LocationHistoryDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LocationHistoryDto(
        id: mapValueOfType<int>(json, r'id'),
        driverId: mapValueOfType<int>(json, r'driverId'),
        dispatchId: mapValueOfType<int>(json, r'dispatchId'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        locationName: mapValueOfType<String>(json, r'locationName'),
        timestamp: mapDateTime(json, r'timestamp', r''),
        lastUpdated: mapDateTime(json, r'lastUpdated', r''),
        isOnline: mapValueOfType<bool>(json, r'isOnline'),
        batteryLevel: mapValueOfType<int>(json, r'batteryLevel'),
        speed: mapValueOfType<double>(json, r'speed'),
        source_: mapValueOfType<String>(json, r'source'),
        dispatch: PartialDispatchDto.fromJson(json[r'dispatch']),
      );
    }
    return null;
  }

  static List<LocationHistoryDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LocationHistoryDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LocationHistoryDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LocationHistoryDto> mapFromJson(dynamic json) {
    final map = <String, LocationHistoryDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LocationHistoryDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LocationHistoryDto-objects as value to a dart map
  static Map<String, List<LocationHistoryDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LocationHistoryDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LocationHistoryDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

