//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverLocationUpdateDto {
  /// Returns a new [DriverLocationUpdateDto] instance.
  DriverLocationUpdateDto({
    required this.driverId,
    this.dispatchId,
    this.source_,
    this.appVersion,
    this.gpsOn,
    this.vehiclePlate,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.clientSpeedKmh,
    this.timestamp,
    this.clientTime,
    this.batteryLevel,
    this.locationName,
    this.version,
    this.netType,
    this.locationSource,
    this.accuracyMeters,
  });

  int driverId;

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
  String? source_;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? appVersion;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? gpsOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? vehiclePlate;

  /// Minimum value: -90.0
  /// Maximum value: 90.0
  double latitude;

  /// Minimum value: -180.0
  /// Maximum value: 180.0
  double longitude;

  /// Maximum value: 360
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? heading;

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
  double? clientSpeedKmh;

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
  int? clientTime;

  /// Minimum value: -1
  /// Maximum value: 100
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
  String? locationName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? version;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? netType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? locationSource;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? accuracyMeters;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverLocationUpdateDto &&
    other.driverId == driverId &&
    other.dispatchId == dispatchId &&
    other.source_ == source_ &&
    other.appVersion == appVersion &&
    other.gpsOn == gpsOn &&
    other.vehiclePlate == vehiclePlate &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.heading == heading &&
    other.speed == speed &&
    other.clientSpeedKmh == clientSpeedKmh &&
    other.timestamp == timestamp &&
    other.clientTime == clientTime &&
    other.batteryLevel == batteryLevel &&
    other.locationName == locationName &&
    other.version == version &&
    other.netType == netType &&
    other.locationSource == locationSource &&
    other.accuracyMeters == accuracyMeters;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (driverId.hashCode) +
    (dispatchId == null ? 0 : dispatchId!.hashCode) +
    (source_ == null ? 0 : source_!.hashCode) +
    (appVersion == null ? 0 : appVersion!.hashCode) +
    (gpsOn == null ? 0 : gpsOn!.hashCode) +
    (vehiclePlate == null ? 0 : vehiclePlate!.hashCode) +
    (latitude.hashCode) +
    (longitude.hashCode) +
    (heading == null ? 0 : heading!.hashCode) +
    (speed == null ? 0 : speed!.hashCode) +
    (clientSpeedKmh == null ? 0 : clientSpeedKmh!.hashCode) +
    (timestamp == null ? 0 : timestamp!.hashCode) +
    (clientTime == null ? 0 : clientTime!.hashCode) +
    (batteryLevel == null ? 0 : batteryLevel!.hashCode) +
    (locationName == null ? 0 : locationName!.hashCode) +
    (version == null ? 0 : version!.hashCode) +
    (netType == null ? 0 : netType!.hashCode) +
    (locationSource == null ? 0 : locationSource!.hashCode) +
    (accuracyMeters == null ? 0 : accuracyMeters!.hashCode);

  @override
  String toString() => 'DriverLocationUpdateDto[driverId=$driverId, dispatchId=$dispatchId, source_=$source_, appVersion=$appVersion, gpsOn=$gpsOn, vehiclePlate=$vehiclePlate, latitude=$latitude, longitude=$longitude, heading=$heading, speed=$speed, clientSpeedKmh=$clientSpeedKmh, timestamp=$timestamp, clientTime=$clientTime, batteryLevel=$batteryLevel, locationName=$locationName, version=$version, netType=$netType, locationSource=$locationSource, accuracyMeters=$accuracyMeters]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'driverId'] = this.driverId;
    if (this.dispatchId != null) {
      json[r'dispatchId'] = this.dispatchId;
    } else {
      json[r'dispatchId'] = null;
    }
    if (this.source_ != null) {
      json[r'source'] = this.source_;
    } else {
      json[r'source'] = null;
    }
    if (this.appVersion != null) {
      json[r'appVersion'] = this.appVersion;
    } else {
      json[r'appVersion'] = null;
    }
    if (this.gpsOn != null) {
      json[r'gpsOn'] = this.gpsOn;
    } else {
      json[r'gpsOn'] = null;
    }
    if (this.vehiclePlate != null) {
      json[r'vehiclePlate'] = this.vehiclePlate;
    } else {
      json[r'vehiclePlate'] = null;
    }
      json[r'latitude'] = this.latitude;
      json[r'longitude'] = this.longitude;
    if (this.heading != null) {
      json[r'heading'] = this.heading;
    } else {
      json[r'heading'] = null;
    }
    if (this.speed != null) {
      json[r'speed'] = this.speed;
    } else {
      json[r'speed'] = null;
    }
    if (this.clientSpeedKmh != null) {
      json[r'clientSpeedKmh'] = this.clientSpeedKmh;
    } else {
      json[r'clientSpeedKmh'] = null;
    }
    if (this.timestamp != null) {
      json[r'timestamp'] = this.timestamp!.toUtc().toIso8601String();
    } else {
      json[r'timestamp'] = null;
    }
    if (this.clientTime != null) {
      json[r'clientTime'] = this.clientTime;
    } else {
      json[r'clientTime'] = null;
    }
    if (this.batteryLevel != null) {
      json[r'batteryLevel'] = this.batteryLevel;
    } else {
      json[r'batteryLevel'] = null;
    }
    if (this.locationName != null) {
      json[r'locationName'] = this.locationName;
    } else {
      json[r'locationName'] = null;
    }
    if (this.version != null) {
      json[r'version'] = this.version;
    } else {
      json[r'version'] = null;
    }
    if (this.netType != null) {
      json[r'netType'] = this.netType;
    } else {
      json[r'netType'] = null;
    }
    if (this.locationSource != null) {
      json[r'locationSource'] = this.locationSource;
    } else {
      json[r'locationSource'] = null;
    }
    if (this.accuracyMeters != null) {
      json[r'accuracyMeters'] = this.accuracyMeters;
    } else {
      json[r'accuracyMeters'] = null;
    }
    return json;
  }

  /// Returns a new [DriverLocationUpdateDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverLocationUpdateDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'driverId'), 'Required key "DriverLocationUpdateDto[driverId]" is missing from JSON.');
        assert(json[r'driverId'] != null, 'Required key "DriverLocationUpdateDto[driverId]" has a null value in JSON.');
        assert(json.containsKey(r'latitude'), 'Required key "DriverLocationUpdateDto[latitude]" is missing from JSON.');
        assert(json[r'latitude'] != null, 'Required key "DriverLocationUpdateDto[latitude]" has a null value in JSON.');
        assert(json.containsKey(r'longitude'), 'Required key "DriverLocationUpdateDto[longitude]" is missing from JSON.');
        assert(json[r'longitude'] != null, 'Required key "DriverLocationUpdateDto[longitude]" has a null value in JSON.');
        return true;
      }());

      return DriverLocationUpdateDto(
        driverId: mapValueOfType<int>(json, r'driverId')!,
        dispatchId: mapValueOfType<int>(json, r'dispatchId'),
        source_: mapValueOfType<String>(json, r'source'),
        appVersion: mapValueOfType<String>(json, r'appVersion'),
        gpsOn: mapValueOfType<bool>(json, r'gpsOn'),
        vehiclePlate: mapValueOfType<String>(json, r'vehiclePlate'),
        latitude: mapValueOfType<double>(json, r'latitude')!,
        longitude: mapValueOfType<double>(json, r'longitude')!,
        heading: mapValueOfType<double>(json, r'heading'),
        speed: mapValueOfType<double>(json, r'speed'),
        clientSpeedKmh: mapValueOfType<double>(json, r'clientSpeedKmh'),
        timestamp: mapDateTime(json, r'timestamp', r''),
        clientTime: mapValueOfType<int>(json, r'clientTime'),
        batteryLevel: mapValueOfType<int>(json, r'batteryLevel'),
        locationName: mapValueOfType<String>(json, r'locationName'),
        version: mapValueOfType<int>(json, r'version'),
        netType: mapValueOfType<String>(json, r'netType'),
        locationSource: mapValueOfType<String>(json, r'locationSource'),
        accuracyMeters: mapValueOfType<double>(json, r'accuracyMeters'),
      );
    }
    return null;
  }

  static List<DriverLocationUpdateDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverLocationUpdateDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverLocationUpdateDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverLocationUpdateDto> mapFromJson(dynamic json) {
    final map = <String, DriverLocationUpdateDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverLocationUpdateDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverLocationUpdateDto-objects as value to a dart map
  static Map<String, List<DriverLocationUpdateDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverLocationUpdateDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverLocationUpdateDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'driverId',
    'latitude',
    'longitude',
  };
}

