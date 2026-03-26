//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HeartbeatDto {
  /// Returns a new [HeartbeatDto] instance.
  HeartbeatDto({
    this.epochMs,
    required this.netType,
    this.battery,
    this.gpsOn,
    this.appVersion,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? epochMs;

  String netType;

  /// Minimum value: 0
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? battery;

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
  String? appVersion;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HeartbeatDto &&
    other.epochMs == epochMs &&
    other.netType == netType &&
    other.battery == battery &&
    other.gpsOn == gpsOn &&
    other.appVersion == appVersion;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (epochMs == null ? 0 : epochMs!.hashCode) +
    (netType.hashCode) +
    (battery == null ? 0 : battery!.hashCode) +
    (gpsOn == null ? 0 : gpsOn!.hashCode) +
    (appVersion == null ? 0 : appVersion!.hashCode);

  @override
  String toString() => 'HeartbeatDto[epochMs=$epochMs, netType=$netType, battery=$battery, gpsOn=$gpsOn, appVersion=$appVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.epochMs != null) {
      json[r'epochMs'] = this.epochMs;
    } else {
      json[r'epochMs'] = null;
    }
      json[r'netType'] = this.netType;
    if (this.battery != null) {
      json[r'battery'] = this.battery;
    } else {
      json[r'battery'] = null;
    }
    if (this.gpsOn != null) {
      json[r'gpsOn'] = this.gpsOn;
    } else {
      json[r'gpsOn'] = null;
    }
    if (this.appVersion != null) {
      json[r'appVersion'] = this.appVersion;
    } else {
      json[r'appVersion'] = null;
    }
    return json;
  }

  /// Returns a new [HeartbeatDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HeartbeatDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'netType'), 'Required key "HeartbeatDto[netType]" is missing from JSON.');
        assert(json[r'netType'] != null, 'Required key "HeartbeatDto[netType]" has a null value in JSON.');
        return true;
      }());

      return HeartbeatDto(
        epochMs: mapValueOfType<int>(json, r'epochMs'),
        netType: mapValueOfType<String>(json, r'netType')!,
        battery: mapValueOfType<int>(json, r'battery'),
        gpsOn: mapValueOfType<bool>(json, r'gpsOn'),
        appVersion: mapValueOfType<String>(json, r'appVersion'),
      );
    }
    return null;
  }

  static List<HeartbeatDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HeartbeatDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HeartbeatDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HeartbeatDto> mapFromJson(dynamic json) {
    final map = <String, HeartbeatDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HeartbeatDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HeartbeatDto-objects as value to a dart map
  static Map<String, List<HeartbeatDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HeartbeatDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HeartbeatDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'netType',
  };
}

