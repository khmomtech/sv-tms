//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LiveDriverDto {
  /// Returns a new [LiveDriverDto] instance.
  LiveDriverDto({
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.latitude,
    this.longitude,
    this.speed,
    this.heading,
    this.batteryLevel,
    this.locationName,
    this.online,
    this.dispatchId,
    this.vehiclePlate,
    this.updatedAt,
    this.source_,
  });

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
  String? driverName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? driverPhone;

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
  double? speed;

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
  bool? online;

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
  String? vehiclePlate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? source_;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LiveDriverDto &&
    other.driverId == driverId &&
    other.driverName == driverName &&
    other.driverPhone == driverPhone &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.speed == speed &&
    other.heading == heading &&
    other.batteryLevel == batteryLevel &&
    other.locationName == locationName &&
    other.online == online &&
    other.dispatchId == dispatchId &&
    other.vehiclePlate == vehiclePlate &&
    other.updatedAt == updatedAt &&
    other.source_ == source_;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (driverId == null ? 0 : driverId!.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (driverPhone == null ? 0 : driverPhone!.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (speed == null ? 0 : speed!.hashCode) +
    (heading == null ? 0 : heading!.hashCode) +
    (batteryLevel == null ? 0 : batteryLevel!.hashCode) +
    (locationName == null ? 0 : locationName!.hashCode) +
    (online == null ? 0 : online!.hashCode) +
    (dispatchId == null ? 0 : dispatchId!.hashCode) +
    (vehiclePlate == null ? 0 : vehiclePlate!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (source_ == null ? 0 : source_!.hashCode);

  @override
  String toString() => 'LiveDriverDto[driverId=$driverId, driverName=$driverName, driverPhone=$driverPhone, latitude=$latitude, longitude=$longitude, speed=$speed, heading=$heading, batteryLevel=$batteryLevel, locationName=$locationName, online=$online, dispatchId=$dispatchId, vehiclePlate=$vehiclePlate, updatedAt=$updatedAt, source_=$source_]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.driverId != null) {
      json[r'driverId'] = this.driverId;
    } else {
      json[r'driverId'] = null;
    }
    if (this.driverName != null) {
      json[r'driverName'] = this.driverName;
    } else {
      json[r'driverName'] = null;
    }
    if (this.driverPhone != null) {
      json[r'driverPhone'] = this.driverPhone;
    } else {
      json[r'driverPhone'] = null;
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
    if (this.speed != null) {
      json[r'speed'] = this.speed;
    } else {
      json[r'speed'] = null;
    }
    if (this.heading != null) {
      json[r'heading'] = this.heading;
    } else {
      json[r'heading'] = null;
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
    if (this.online != null) {
      json[r'online'] = this.online;
    } else {
      json[r'online'] = null;
    }
    if (this.dispatchId != null) {
      json[r'dispatchId'] = this.dispatchId;
    } else {
      json[r'dispatchId'] = null;
    }
    if (this.vehiclePlate != null) {
      json[r'vehiclePlate'] = this.vehiclePlate;
    } else {
      json[r'vehiclePlate'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updatedAt'] = null;
    }
    if (this.source_ != null) {
      json[r'source'] = this.source_;
    } else {
      json[r'source'] = null;
    }
    return json;
  }

  /// Returns a new [LiveDriverDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LiveDriverDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LiveDriverDto(
        driverId: mapValueOfType<int>(json, r'driverId'),
        driverName: mapValueOfType<String>(json, r'driverName'),
        driverPhone: mapValueOfType<String>(json, r'driverPhone'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        speed: mapValueOfType<double>(json, r'speed'),
        heading: mapValueOfType<double>(json, r'heading'),
        batteryLevel: mapValueOfType<int>(json, r'batteryLevel'),
        locationName: mapValueOfType<String>(json, r'locationName'),
        online: mapValueOfType<bool>(json, r'online'),
        dispatchId: mapValueOfType<int>(json, r'dispatchId'),
        vehiclePlate: mapValueOfType<String>(json, r'vehiclePlate'),
        updatedAt: mapDateTime(json, r'updatedAt', r''),
        source_: mapValueOfType<String>(json, r'source'),
      );
    }
    return null;
  }

  static List<LiveDriverDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LiveDriverDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LiveDriverDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LiveDriverDto> mapFromJson(dynamic json) {
    final map = <String, LiveDriverDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LiveDriverDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LiveDriverDto-objects as value to a dart map
  static Map<String, List<LiveDriverDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LiveDriverDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LiveDriverDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

