//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttendanceDto {
  /// Returns a new [AttendanceDto] instance.
  AttendanceDto({
    this.id,
    this.driverId,
    this.driverName,
    this.truckPlateNo,
    this.date,
    this.status,
    this.checkInTime,
    this.checkOutTime,
    this.hoursWorked,
    this.notes,
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
  String? driverName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? truckPlateNo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? date;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? checkInTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? checkOutTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? hoursWorked;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttendanceDto &&
    other.id == id &&
    other.driverId == driverId &&
    other.driverName == driverName &&
    other.truckPlateNo == truckPlateNo &&
    other.date == date &&
    other.status == status &&
    other.checkInTime == checkInTime &&
    other.checkOutTime == checkOutTime &&
    other.hoursWorked == hoursWorked &&
    other.notes == notes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (driverId == null ? 0 : driverId!.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (truckPlateNo == null ? 0 : truckPlateNo!.hashCode) +
    (date == null ? 0 : date!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (checkInTime == null ? 0 : checkInTime!.hashCode) +
    (checkOutTime == null ? 0 : checkOutTime!.hashCode) +
    (hoursWorked == null ? 0 : hoursWorked!.hashCode) +
    (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() => 'AttendanceDto[id=$id, driverId=$driverId, driverName=$driverName, truckPlateNo=$truckPlateNo, date=$date, status=$status, checkInTime=$checkInTime, checkOutTime=$checkOutTime, hoursWorked=$hoursWorked, notes=$notes]';

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
    if (this.driverName != null) {
      json[r'driverName'] = this.driverName;
    } else {
      json[r'driverName'] = null;
    }
    if (this.truckPlateNo != null) {
      json[r'truckPlateNo'] = this.truckPlateNo;
    } else {
      json[r'truckPlateNo'] = null;
    }
    if (this.date != null) {
      json[r'date'] = this.date;
    } else {
      json[r'date'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.checkInTime != null) {
      json[r'checkInTime'] = this.checkInTime;
    } else {
      json[r'checkInTime'] = null;
    }
    if (this.checkOutTime != null) {
      json[r'checkOutTime'] = this.checkOutTime;
    } else {
      json[r'checkOutTime'] = null;
    }
    if (this.hoursWorked != null) {
      json[r'hoursWorked'] = this.hoursWorked;
    } else {
      json[r'hoursWorked'] = null;
    }
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    return json;
  }

  /// Returns a new [AttendanceDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttendanceDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AttendanceDto(
        id: mapValueOfType<int>(json, r'id'),
        driverId: mapValueOfType<int>(json, r'driverId'),
        driverName: mapValueOfType<String>(json, r'driverName'),
        truckPlateNo: mapValueOfType<String>(json, r'truckPlateNo'),
        date: mapValueOfType<String>(json, r'date'),
        status: mapValueOfType<String>(json, r'status'),
        checkInTime: mapValueOfType<String>(json, r'checkInTime'),
        checkOutTime: mapValueOfType<String>(json, r'checkOutTime'),
        hoursWorked: mapValueOfType<double>(json, r'hoursWorked'),
        notes: mapValueOfType<String>(json, r'notes'),
      );
    }
    return null;
  }

  static List<AttendanceDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttendanceDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttendanceDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttendanceDto> mapFromJson(dynamic json) {
    final map = <String, AttendanceDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttendanceDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttendanceDto-objects as value to a dart map
  static Map<String, List<AttendanceDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttendanceDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttendanceDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

