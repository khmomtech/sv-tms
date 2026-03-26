//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VehicleStatisticsDto {
  /// Returns a new [VehicleStatisticsDto] instance.
  VehicleStatisticsDto({
    this.totalVehicles,
    this.availableVehicles,
    this.inUseVehicles,
    this.maintenanceVehicles,
    this.outOfServiceVehicles,
    this.assignedVehicles,
    this.unassignedVehicles,
    this.assignmentRate,
    this.vehiclesRequiringService,
    this.vehiclesDueForInspection,
    this.vehiclesByStatus = const {},
    this.vehiclesByType = const {},
    this.vehiclesByTruckSize = const {},
    this.vehiclesByZone = const {},
    this.averageMileage,
    this.averageFuelConsumption,
    this.averageVehicleAge,
    this.vehiclesWithGPS,
    this.vehiclesWithoutGPS,
    this.totalTrailers,
    this.assignedTrailers,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? totalVehicles;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? availableVehicles;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? inUseVehicles;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? maintenanceVehicles;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? outOfServiceVehicles;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? assignedVehicles;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? unassignedVehicles;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? assignmentRate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vehiclesRequiringService;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vehiclesDueForInspection;

  Map<String, int> vehiclesByStatus;

  Map<String, int> vehiclesByType;

  Map<String, int> vehiclesByTruckSize;

  Map<String, int> vehiclesByZone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? averageMileage;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? averageFuelConsumption;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? averageVehicleAge;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vehiclesWithGPS;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vehiclesWithoutGPS;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? totalTrailers;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? assignedTrailers;

  @override
  bool operator ==(Object other) => identical(this, other) || other is VehicleStatisticsDto &&
    other.totalVehicles == totalVehicles &&
    other.availableVehicles == availableVehicles &&
    other.inUseVehicles == inUseVehicles &&
    other.maintenanceVehicles == maintenanceVehicles &&
    other.outOfServiceVehicles == outOfServiceVehicles &&
    other.assignedVehicles == assignedVehicles &&
    other.unassignedVehicles == unassignedVehicles &&
    other.assignmentRate == assignmentRate &&
    other.vehiclesRequiringService == vehiclesRequiringService &&
    other.vehiclesDueForInspection == vehiclesDueForInspection &&
    _deepEquality.equals(other.vehiclesByStatus, vehiclesByStatus) &&
    _deepEquality.equals(other.vehiclesByType, vehiclesByType) &&
    _deepEquality.equals(other.vehiclesByTruckSize, vehiclesByTruckSize) &&
    _deepEquality.equals(other.vehiclesByZone, vehiclesByZone) &&
    other.averageMileage == averageMileage &&
    other.averageFuelConsumption == averageFuelConsumption &&
    other.averageVehicleAge == averageVehicleAge &&
    other.vehiclesWithGPS == vehiclesWithGPS &&
    other.vehiclesWithoutGPS == vehiclesWithoutGPS &&
    other.totalTrailers == totalTrailers &&
    other.assignedTrailers == assignedTrailers;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (totalVehicles == null ? 0 : totalVehicles!.hashCode) +
    (availableVehicles == null ? 0 : availableVehicles!.hashCode) +
    (inUseVehicles == null ? 0 : inUseVehicles!.hashCode) +
    (maintenanceVehicles == null ? 0 : maintenanceVehicles!.hashCode) +
    (outOfServiceVehicles == null ? 0 : outOfServiceVehicles!.hashCode) +
    (assignedVehicles == null ? 0 : assignedVehicles!.hashCode) +
    (unassignedVehicles == null ? 0 : unassignedVehicles!.hashCode) +
    (assignmentRate == null ? 0 : assignmentRate!.hashCode) +
    (vehiclesRequiringService == null ? 0 : vehiclesRequiringService!.hashCode) +
    (vehiclesDueForInspection == null ? 0 : vehiclesDueForInspection!.hashCode) +
    (vehiclesByStatus.hashCode) +
    (vehiclesByType.hashCode) +
    (vehiclesByTruckSize.hashCode) +
    (vehiclesByZone.hashCode) +
    (averageMileage == null ? 0 : averageMileage!.hashCode) +
    (averageFuelConsumption == null ? 0 : averageFuelConsumption!.hashCode) +
    (averageVehicleAge == null ? 0 : averageVehicleAge!.hashCode) +
    (vehiclesWithGPS == null ? 0 : vehiclesWithGPS!.hashCode) +
    (vehiclesWithoutGPS == null ? 0 : vehiclesWithoutGPS!.hashCode) +
    (totalTrailers == null ? 0 : totalTrailers!.hashCode) +
    (assignedTrailers == null ? 0 : assignedTrailers!.hashCode);

  @override
  String toString() => 'VehicleStatisticsDto[totalVehicles=$totalVehicles, availableVehicles=$availableVehicles, inUseVehicles=$inUseVehicles, maintenanceVehicles=$maintenanceVehicles, outOfServiceVehicles=$outOfServiceVehicles, assignedVehicles=$assignedVehicles, unassignedVehicles=$unassignedVehicles, assignmentRate=$assignmentRate, vehiclesRequiringService=$vehiclesRequiringService, vehiclesDueForInspection=$vehiclesDueForInspection, vehiclesByStatus=$vehiclesByStatus, vehiclesByType=$vehiclesByType, vehiclesByTruckSize=$vehiclesByTruckSize, vehiclesByZone=$vehiclesByZone, averageMileage=$averageMileage, averageFuelConsumption=$averageFuelConsumption, averageVehicleAge=$averageVehicleAge, vehiclesWithGPS=$vehiclesWithGPS, vehiclesWithoutGPS=$vehiclesWithoutGPS, totalTrailers=$totalTrailers, assignedTrailers=$assignedTrailers]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.totalVehicles != null) {
      json[r'totalVehicles'] = this.totalVehicles;
    } else {
      json[r'totalVehicles'] = null;
    }
    if (this.availableVehicles != null) {
      json[r'availableVehicles'] = this.availableVehicles;
    } else {
      json[r'availableVehicles'] = null;
    }
    if (this.inUseVehicles != null) {
      json[r'inUseVehicles'] = this.inUseVehicles;
    } else {
      json[r'inUseVehicles'] = null;
    }
    if (this.maintenanceVehicles != null) {
      json[r'maintenanceVehicles'] = this.maintenanceVehicles;
    } else {
      json[r'maintenanceVehicles'] = null;
    }
    if (this.outOfServiceVehicles != null) {
      json[r'outOfServiceVehicles'] = this.outOfServiceVehicles;
    } else {
      json[r'outOfServiceVehicles'] = null;
    }
    if (this.assignedVehicles != null) {
      json[r'assignedVehicles'] = this.assignedVehicles;
    } else {
      json[r'assignedVehicles'] = null;
    }
    if (this.unassignedVehicles != null) {
      json[r'unassignedVehicles'] = this.unassignedVehicles;
    } else {
      json[r'unassignedVehicles'] = null;
    }
    if (this.assignmentRate != null) {
      json[r'assignmentRate'] = this.assignmentRate;
    } else {
      json[r'assignmentRate'] = null;
    }
    if (this.vehiclesRequiringService != null) {
      json[r'vehiclesRequiringService'] = this.vehiclesRequiringService;
    } else {
      json[r'vehiclesRequiringService'] = null;
    }
    if (this.vehiclesDueForInspection != null) {
      json[r'vehiclesDueForInspection'] = this.vehiclesDueForInspection;
    } else {
      json[r'vehiclesDueForInspection'] = null;
    }
      json[r'vehiclesByStatus'] = this.vehiclesByStatus;
      json[r'vehiclesByType'] = this.vehiclesByType;
      json[r'vehiclesByTruckSize'] = this.vehiclesByTruckSize;
      json[r'vehiclesByZone'] = this.vehiclesByZone;
    if (this.averageMileage != null) {
      json[r'averageMileage'] = this.averageMileage;
    } else {
      json[r'averageMileage'] = null;
    }
    if (this.averageFuelConsumption != null) {
      json[r'averageFuelConsumption'] = this.averageFuelConsumption;
    } else {
      json[r'averageFuelConsumption'] = null;
    }
    if (this.averageVehicleAge != null) {
      json[r'averageVehicleAge'] = this.averageVehicleAge;
    } else {
      json[r'averageVehicleAge'] = null;
    }
    if (this.vehiclesWithGPS != null) {
      json[r'vehiclesWithGPS'] = this.vehiclesWithGPS;
    } else {
      json[r'vehiclesWithGPS'] = null;
    }
    if (this.vehiclesWithoutGPS != null) {
      json[r'vehiclesWithoutGPS'] = this.vehiclesWithoutGPS;
    } else {
      json[r'vehiclesWithoutGPS'] = null;
    }
    if (this.totalTrailers != null) {
      json[r'totalTrailers'] = this.totalTrailers;
    } else {
      json[r'totalTrailers'] = null;
    }
    if (this.assignedTrailers != null) {
      json[r'assignedTrailers'] = this.assignedTrailers;
    } else {
      json[r'assignedTrailers'] = null;
    }
    return json;
  }

  /// Returns a new [VehicleStatisticsDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VehicleStatisticsDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return VehicleStatisticsDto(
        totalVehicles: mapValueOfType<int>(json, r'totalVehicles'),
        availableVehicles: mapValueOfType<int>(json, r'availableVehicles'),
        inUseVehicles: mapValueOfType<int>(json, r'inUseVehicles'),
        maintenanceVehicles: mapValueOfType<int>(json, r'maintenanceVehicles'),
        outOfServiceVehicles: mapValueOfType<int>(json, r'outOfServiceVehicles'),
        assignedVehicles: mapValueOfType<int>(json, r'assignedVehicles'),
        unassignedVehicles: mapValueOfType<int>(json, r'unassignedVehicles'),
        assignmentRate: mapValueOfType<double>(json, r'assignmentRate'),
        vehiclesRequiringService: mapValueOfType<int>(json, r'vehiclesRequiringService'),
        vehiclesDueForInspection: mapValueOfType<int>(json, r'vehiclesDueForInspection'),
        vehiclesByStatus: mapCastOfType<String, int>(json, r'vehiclesByStatus') ?? const {},
        vehiclesByType: mapCastOfType<String, int>(json, r'vehiclesByType') ?? const {},
        vehiclesByTruckSize: mapCastOfType<String, int>(json, r'vehiclesByTruckSize') ?? const {},
        vehiclesByZone: mapCastOfType<String, int>(json, r'vehiclesByZone') ?? const {},
        averageMileage: num.parse('${json[r'averageMileage']}'),
        averageFuelConsumption: num.parse('${json[r'averageFuelConsumption']}'),
        averageVehicleAge: mapValueOfType<int>(json, r'averageVehicleAge'),
        vehiclesWithGPS: mapValueOfType<int>(json, r'vehiclesWithGPS'),
        vehiclesWithoutGPS: mapValueOfType<int>(json, r'vehiclesWithoutGPS'),
        totalTrailers: mapValueOfType<int>(json, r'totalTrailers'),
        assignedTrailers: mapValueOfType<int>(json, r'assignedTrailers'),
      );
    }
    return null;
  }

  static List<VehicleStatisticsDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VehicleStatisticsDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VehicleStatisticsDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VehicleStatisticsDto> mapFromJson(dynamic json) {
    final map = <String, VehicleStatisticsDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VehicleStatisticsDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VehicleStatisticsDto-objects as value to a dart map
  static Map<String, List<VehicleStatisticsDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<VehicleStatisticsDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VehicleStatisticsDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

