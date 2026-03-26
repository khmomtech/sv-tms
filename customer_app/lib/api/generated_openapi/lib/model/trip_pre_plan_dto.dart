//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TripPrePlanDto {
  /// Returns a new [TripPrePlanDto] instance.
  TripPrePlanDto({
    this.distributor,
    this.shipTo,
    this.zone,
    this.truck8,
    this.truck10,
    this.truck11,
    this.truck22,
    this.posm,
    this.totalPallet,
    this.plannedPallet,
    this.remainPallet,
    this.trips = const {},
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? distributor;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? shipTo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? zone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? truck8;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? truck10;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? truck11;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? truck22;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? posm;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? totalPallet;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? plannedPallet;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? remainPallet;

  Map<String, int> trips;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TripPrePlanDto &&
    other.distributor == distributor &&
    other.shipTo == shipTo &&
    other.zone == zone &&
    other.truck8 == truck8 &&
    other.truck10 == truck10 &&
    other.truck11 == truck11 &&
    other.truck22 == truck22 &&
    other.posm == posm &&
    other.totalPallet == totalPallet &&
    other.plannedPallet == plannedPallet &&
    other.remainPallet == remainPallet &&
    _deepEquality.equals(other.trips, trips);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (distributor == null ? 0 : distributor!.hashCode) +
    (shipTo == null ? 0 : shipTo!.hashCode) +
    (zone == null ? 0 : zone!.hashCode) +
    (truck8 == null ? 0 : truck8!.hashCode) +
    (truck10 == null ? 0 : truck10!.hashCode) +
    (truck11 == null ? 0 : truck11!.hashCode) +
    (truck22 == null ? 0 : truck22!.hashCode) +
    (posm == null ? 0 : posm!.hashCode) +
    (totalPallet == null ? 0 : totalPallet!.hashCode) +
    (plannedPallet == null ? 0 : plannedPallet!.hashCode) +
    (remainPallet == null ? 0 : remainPallet!.hashCode) +
    (trips.hashCode);

  @override
  String toString() => 'TripPrePlanDto[distributor=$distributor, shipTo=$shipTo, zone=$zone, truck8=$truck8, truck10=$truck10, truck11=$truck11, truck22=$truck22, posm=$posm, totalPallet=$totalPallet, plannedPallet=$plannedPallet, remainPallet=$remainPallet, trips=$trips]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.distributor != null) {
      json[r'distributor'] = this.distributor;
    } else {
      json[r'distributor'] = null;
    }
    if (this.shipTo != null) {
      json[r'shipTo'] = this.shipTo;
    } else {
      json[r'shipTo'] = null;
    }
    if (this.zone != null) {
      json[r'zone'] = this.zone;
    } else {
      json[r'zone'] = null;
    }
    if (this.truck8 != null) {
      json[r'truck8'] = this.truck8;
    } else {
      json[r'truck8'] = null;
    }
    if (this.truck10 != null) {
      json[r'truck10'] = this.truck10;
    } else {
      json[r'truck10'] = null;
    }
    if (this.truck11 != null) {
      json[r'truck11'] = this.truck11;
    } else {
      json[r'truck11'] = null;
    }
    if (this.truck22 != null) {
      json[r'truck22'] = this.truck22;
    } else {
      json[r'truck22'] = null;
    }
    if (this.posm != null) {
      json[r'posm'] = this.posm;
    } else {
      json[r'posm'] = null;
    }
    if (this.totalPallet != null) {
      json[r'totalPallet'] = this.totalPallet;
    } else {
      json[r'totalPallet'] = null;
    }
    if (this.plannedPallet != null) {
      json[r'plannedPallet'] = this.plannedPallet;
    } else {
      json[r'plannedPallet'] = null;
    }
    if (this.remainPallet != null) {
      json[r'remainPallet'] = this.remainPallet;
    } else {
      json[r'remainPallet'] = null;
    }
      json[r'trips'] = this.trips;
    return json;
  }

  /// Returns a new [TripPrePlanDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TripPrePlanDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TripPrePlanDto(
        distributor: mapValueOfType<String>(json, r'distributor'),
        shipTo: mapValueOfType<String>(json, r'shipTo'),
        zone: mapValueOfType<String>(json, r'zone'),
        truck8: mapValueOfType<int>(json, r'truck8'),
        truck10: mapValueOfType<int>(json, r'truck10'),
        truck11: mapValueOfType<int>(json, r'truck11'),
        truck22: mapValueOfType<int>(json, r'truck22'),
        posm: mapValueOfType<String>(json, r'posm'),
        totalPallet: mapValueOfType<int>(json, r'totalPallet'),
        plannedPallet: mapValueOfType<int>(json, r'plannedPallet'),
        remainPallet: mapValueOfType<int>(json, r'remainPallet'),
        trips: mapCastOfType<String, int>(json, r'trips') ?? const {},
      );
    }
    return null;
  }

  static List<TripPrePlanDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TripPrePlanDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TripPrePlanDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TripPrePlanDto> mapFromJson(dynamic json) {
    final map = <String, TripPrePlanDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TripPrePlanDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TripPrePlanDto-objects as value to a dart map
  static Map<String, List<TripPrePlanDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TripPrePlanDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TripPrePlanDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

