//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VehicleWithDriverDto {
  /// Returns a new [VehicleWithDriverDto] instance.
  VehicleWithDriverDto({
    this.vehicleId,
    this.vehiclePlateNumber,
    this.driverId,
    this.driverName,
    this.driverPhone,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vehicleId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? vehiclePlateNumber;

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

  @override
  bool operator ==(Object other) => identical(this, other) || other is VehicleWithDriverDto &&
    other.vehicleId == vehicleId &&
    other.vehiclePlateNumber == vehiclePlateNumber &&
    other.driverId == driverId &&
    other.driverName == driverName &&
    other.driverPhone == driverPhone;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (vehicleId == null ? 0 : vehicleId!.hashCode) +
    (vehiclePlateNumber == null ? 0 : vehiclePlateNumber!.hashCode) +
    (driverId == null ? 0 : driverId!.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (driverPhone == null ? 0 : driverPhone!.hashCode);

  @override
  String toString() => 'VehicleWithDriverDto[vehicleId=$vehicleId, vehiclePlateNumber=$vehiclePlateNumber, driverId=$driverId, driverName=$driverName, driverPhone=$driverPhone]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.vehicleId != null) {
      json[r'vehicleId'] = this.vehicleId;
    } else {
      json[r'vehicleId'] = null;
    }
    if (this.vehiclePlateNumber != null) {
      json[r'vehiclePlateNumber'] = this.vehiclePlateNumber;
    } else {
      json[r'vehiclePlateNumber'] = null;
    }
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
    return json;
  }

  /// Returns a new [VehicleWithDriverDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VehicleWithDriverDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return VehicleWithDriverDto(
        vehicleId: mapValueOfType<int>(json, r'vehicleId'),
        vehiclePlateNumber: mapValueOfType<String>(json, r'vehiclePlateNumber'),
        driverId: mapValueOfType<int>(json, r'driverId'),
        driverName: mapValueOfType<String>(json, r'driverName'),
        driverPhone: mapValueOfType<String>(json, r'driverPhone'),
      );
    }
    return null;
  }

  static List<VehicleWithDriverDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VehicleWithDriverDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VehicleWithDriverDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VehicleWithDriverDto> mapFromJson(dynamic json) {
    final map = <String, VehicleWithDriverDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VehicleWithDriverDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VehicleWithDriverDto-objects as value to a dart map
  static Map<String, List<VehicleWithDriverDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<VehicleWithDriverDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VehicleWithDriverDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

