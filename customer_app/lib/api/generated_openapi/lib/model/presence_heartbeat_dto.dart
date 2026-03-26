//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PresenceHeartbeatDto {
  /// Returns a new [PresenceHeartbeatDto] instance.
  PresenceHeartbeatDto({
    required this.driverId,
    this.device,
    this.battery,
    this.gpsEnabled,
    this.ts,
    this.reason,
  });

  int driverId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? device;

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
  bool? gpsEnabled;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? ts;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? reason;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PresenceHeartbeatDto &&
    other.driverId == driverId &&
    other.device == device &&
    other.battery == battery &&
    other.gpsEnabled == gpsEnabled &&
    other.ts == ts &&
    other.reason == reason;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (driverId.hashCode) +
    (device == null ? 0 : device!.hashCode) +
    (battery == null ? 0 : battery!.hashCode) +
    (gpsEnabled == null ? 0 : gpsEnabled!.hashCode) +
    (ts == null ? 0 : ts!.hashCode) +
    (reason == null ? 0 : reason!.hashCode);

  @override
  String toString() => 'PresenceHeartbeatDto[driverId=$driverId, device=$device, battery=$battery, gpsEnabled=$gpsEnabled, ts=$ts, reason=$reason]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'driverId'] = this.driverId;
    if (this.device != null) {
      json[r'device'] = this.device;
    } else {
      json[r'device'] = null;
    }
    if (this.battery != null) {
      json[r'battery'] = this.battery;
    } else {
      json[r'battery'] = null;
    }
    if (this.gpsEnabled != null) {
      json[r'gpsEnabled'] = this.gpsEnabled;
    } else {
      json[r'gpsEnabled'] = null;
    }
    if (this.ts != null) {
      json[r'ts'] = this.ts;
    } else {
      json[r'ts'] = null;
    }
    if (this.reason != null) {
      json[r'reason'] = this.reason;
    } else {
      json[r'reason'] = null;
    }
    return json;
  }

  /// Returns a new [PresenceHeartbeatDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PresenceHeartbeatDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'driverId'), 'Required key "PresenceHeartbeatDto[driverId]" is missing from JSON.');
        assert(json[r'driverId'] != null, 'Required key "PresenceHeartbeatDto[driverId]" has a null value in JSON.');
        return true;
      }());

      return PresenceHeartbeatDto(
        driverId: mapValueOfType<int>(json, r'driverId')!,
        device: mapValueOfType<String>(json, r'device'),
        battery: mapValueOfType<int>(json, r'battery'),
        gpsEnabled: mapValueOfType<bool>(json, r'gpsEnabled'),
        ts: mapValueOfType<int>(json, r'ts'),
        reason: mapValueOfType<String>(json, r'reason'),
      );
    }
    return null;
  }

  static List<PresenceHeartbeatDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PresenceHeartbeatDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PresenceHeartbeatDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PresenceHeartbeatDto> mapFromJson(dynamic json) {
    final map = <String, PresenceHeartbeatDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PresenceHeartbeatDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PresenceHeartbeatDto-objects as value to a dart map
  static Map<String, List<PresenceHeartbeatDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PresenceHeartbeatDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PresenceHeartbeatDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'driverId',
  };
}

