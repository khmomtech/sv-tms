//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DeviceApprovalRequest {
  /// Returns a new [DeviceApprovalRequest] instance.
  DeviceApprovalRequest({
    required this.username,
    required this.password,
    required this.deviceId,
    required this.deviceName,
    required this.os,
    required this.version,
    this.appVersion,
    this.manufacturer,
    this.model,
    this.ipAddress,
    this.location,
  });

  String username;

  String password;

  String deviceId;

  String deviceName;

  String os;

  String version;

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
  String? manufacturer;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? model;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? ipAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? location;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DeviceApprovalRequest &&
    other.username == username &&
    other.password == password &&
    other.deviceId == deviceId &&
    other.deviceName == deviceName &&
    other.os == os &&
    other.version == version &&
    other.appVersion == appVersion &&
    other.manufacturer == manufacturer &&
    other.model == model &&
    other.ipAddress == ipAddress &&
    other.location == location;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (username.hashCode) +
    (password.hashCode) +
    (deviceId.hashCode) +
    (deviceName.hashCode) +
    (os.hashCode) +
    (version.hashCode) +
    (appVersion == null ? 0 : appVersion!.hashCode) +
    (manufacturer == null ? 0 : manufacturer!.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (ipAddress == null ? 0 : ipAddress!.hashCode) +
    (location == null ? 0 : location!.hashCode);

  @override
  String toString() => 'DeviceApprovalRequest[username=$username, password=$password, deviceId=$deviceId, deviceName=$deviceName, os=$os, version=$version, appVersion=$appVersion, manufacturer=$manufacturer, model=$model, ipAddress=$ipAddress, location=$location]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'username'] = this.username;
      json[r'password'] = this.password;
      json[r'deviceId'] = this.deviceId;
      json[r'deviceName'] = this.deviceName;
      json[r'os'] = this.os;
      json[r'version'] = this.version;
    if (this.appVersion != null) {
      json[r'appVersion'] = this.appVersion;
    } else {
      json[r'appVersion'] = null;
    }
    if (this.manufacturer != null) {
      json[r'manufacturer'] = this.manufacturer;
    } else {
      json[r'manufacturer'] = null;
    }
    if (this.model != null) {
      json[r'model'] = this.model;
    } else {
      json[r'model'] = null;
    }
    if (this.ipAddress != null) {
      json[r'ipAddress'] = this.ipAddress;
    } else {
      json[r'ipAddress'] = null;
    }
    if (this.location != null) {
      json[r'location'] = this.location;
    } else {
      json[r'location'] = null;
    }
    return json;
  }

  /// Returns a new [DeviceApprovalRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeviceApprovalRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'username'), 'Required key "DeviceApprovalRequest[username]" is missing from JSON.');
        assert(json[r'username'] != null, 'Required key "DeviceApprovalRequest[username]" has a null value in JSON.');
        assert(json.containsKey(r'password'), 'Required key "DeviceApprovalRequest[password]" is missing from JSON.');
        assert(json[r'password'] != null, 'Required key "DeviceApprovalRequest[password]" has a null value in JSON.');
        assert(json.containsKey(r'deviceId'), 'Required key "DeviceApprovalRequest[deviceId]" is missing from JSON.');
        assert(json[r'deviceId'] != null, 'Required key "DeviceApprovalRequest[deviceId]" has a null value in JSON.');
        assert(json.containsKey(r'deviceName'), 'Required key "DeviceApprovalRequest[deviceName]" is missing from JSON.');
        assert(json[r'deviceName'] != null, 'Required key "DeviceApprovalRequest[deviceName]" has a null value in JSON.');
        assert(json.containsKey(r'os'), 'Required key "DeviceApprovalRequest[os]" is missing from JSON.');
        assert(json[r'os'] != null, 'Required key "DeviceApprovalRequest[os]" has a null value in JSON.');
        assert(json.containsKey(r'version'), 'Required key "DeviceApprovalRequest[version]" is missing from JSON.');
        assert(json[r'version'] != null, 'Required key "DeviceApprovalRequest[version]" has a null value in JSON.');
        return true;
      }());

      return DeviceApprovalRequest(
        username: mapValueOfType<String>(json, r'username')!,
        password: mapValueOfType<String>(json, r'password')!,
        deviceId: mapValueOfType<String>(json, r'deviceId')!,
        deviceName: mapValueOfType<String>(json, r'deviceName')!,
        os: mapValueOfType<String>(json, r'os')!,
        version: mapValueOfType<String>(json, r'version')!,
        appVersion: mapValueOfType<String>(json, r'appVersion'),
        manufacturer: mapValueOfType<String>(json, r'manufacturer'),
        model: mapValueOfType<String>(json, r'model'),
        ipAddress: mapValueOfType<String>(json, r'ipAddress'),
        location: mapValueOfType<String>(json, r'location'),
      );
    }
    return null;
  }

  static List<DeviceApprovalRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceApprovalRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceApprovalRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeviceApprovalRequest> mapFromJson(dynamic json) {
    final map = <String, DeviceApprovalRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeviceApprovalRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeviceApprovalRequest-objects as value to a dart map
  static Map<String, List<DeviceApprovalRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DeviceApprovalRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeviceApprovalRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'username',
    'password',
    'deviceId',
    'deviceName',
    'os',
    'version',
  };
}

