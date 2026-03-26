//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TripPrePlanResponseDto {
  /// Returns a new [TripPrePlanResponseDto] instance.
  TripPrePlanResponseDto({
    this.distributorCode,
    this.shipToParty,
    this.zone,
    this.totalPallet,
    this.plannedPallet,
    this.remainPallet,
    this.truck8,
    this.truck10,
    this.truck11,
    this.truck22,
    this.posm,
    this.trips = const {},
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? distributorCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? shipToParty;

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
  double? totalPallet;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? plannedPallet;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? remainPallet;

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

  Map<String, int> trips;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TripPrePlanResponseDto &&
    other.distributorCode == distributorCode &&
    other.shipToParty == shipToParty &&
    other.zone == zone &&
    other.totalPallet == totalPallet &&
    other.plannedPallet == plannedPallet &&
    other.remainPallet == remainPallet &&
    other.truck8 == truck8 &&
    other.truck10 == truck10 &&
    other.truck11 == truck11 &&
    other.truck22 == truck22 &&
    other.posm == posm &&
    _deepEquality.equals(other.trips, trips);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (distributorCode == null ? 0 : distributorCode!.hashCode) +
    (shipToParty == null ? 0 : shipToParty!.hashCode) +
    (zone == null ? 0 : zone!.hashCode) +
    (totalPallet == null ? 0 : totalPallet!.hashCode) +
    (plannedPallet == null ? 0 : plannedPallet!.hashCode) +
    (remainPallet == null ? 0 : remainPallet!.hashCode) +
    (truck8 == null ? 0 : truck8!.hashCode) +
    (truck10 == null ? 0 : truck10!.hashCode) +
    (truck11 == null ? 0 : truck11!.hashCode) +
    (truck22 == null ? 0 : truck22!.hashCode) +
    (posm == null ? 0 : posm!.hashCode) +
    (trips.hashCode);

  @override
  String toString() => 'TripPrePlanResponseDto[distributorCode=$distributorCode, shipToParty=$shipToParty, zone=$zone, totalPallet=$totalPallet, plannedPallet=$plannedPallet, remainPallet=$remainPallet, truck8=$truck8, truck10=$truck10, truck11=$truck11, truck22=$truck22, posm=$posm, trips=$trips]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.distributorCode != null) {
      json[r'distributorCode'] = this.distributorCode;
    } else {
      json[r'distributorCode'] = null;
    }
    if (this.shipToParty != null) {
      json[r'shipToParty'] = this.shipToParty;
    } else {
      json[r'shipToParty'] = null;
    }
    if (this.zone != null) {
      json[r'zone'] = this.zone;
    } else {
      json[r'zone'] = null;
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
      json[r'trips'] = this.trips;
    return json;
  }

  /// Returns a new [TripPrePlanResponseDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TripPrePlanResponseDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TripPrePlanResponseDto(
        distributorCode: mapValueOfType<String>(json, r'distributorCode'),
        shipToParty: mapValueOfType<String>(json, r'shipToParty'),
        zone: mapValueOfType<String>(json, r'zone'),
        totalPallet: mapValueOfType<double>(json, r'totalPallet'),
        plannedPallet: mapValueOfType<double>(json, r'plannedPallet'),
        remainPallet: mapValueOfType<double>(json, r'remainPallet'),
        truck8: mapValueOfType<int>(json, r'truck8'),
        truck10: mapValueOfType<int>(json, r'truck10'),
        truck11: mapValueOfType<int>(json, r'truck11'),
        truck22: mapValueOfType<int>(json, r'truck22'),
        posm: mapValueOfType<String>(json, r'posm'),
        trips: mapCastOfType<String, int>(json, r'trips') ?? const {},
      );
    }
    return null;
  }

  static List<TripPrePlanResponseDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TripPrePlanResponseDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TripPrePlanResponseDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TripPrePlanResponseDto> mapFromJson(dynamic json) {
    final map = <String, TripPrePlanResponseDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TripPrePlanResponseDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TripPrePlanResponseDto-objects as value to a dart map
  static Map<String, List<TripPrePlanResponseDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TripPrePlanResponseDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TripPrePlanResponseDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

