//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DispatchDayReportRow {
  /// Returns a new [DispatchDayReportRow] instance.
  DispatchDayReportRow({
    this.dispatchId,
    this.planDate,
    this.truckNo,
    this.truckTrip,
    this.depot,
    this.numberOfPallets,
    this.truckType,
    this.factoryDeparture,
    this.depotArrival,
    this.plannedDepotArrival,
    this.unloadingComplete,
    this.finalDestinationText,
  });

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
  DateTime? planDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? truckNo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? truckTrip;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? depot;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? numberOfPallets;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? truckType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? factoryDeparture;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? depotArrival;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? plannedDepotArrival;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? unloadingComplete;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? finalDestinationText;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DispatchDayReportRow &&
    other.dispatchId == dispatchId &&
    other.planDate == planDate &&
    other.truckNo == truckNo &&
    other.truckTrip == truckTrip &&
    other.depot == depot &&
    other.numberOfPallets == numberOfPallets &&
    other.truckType == truckType &&
    other.factoryDeparture == factoryDeparture &&
    other.depotArrival == depotArrival &&
    other.plannedDepotArrival == plannedDepotArrival &&
    other.unloadingComplete == unloadingComplete &&
    other.finalDestinationText == finalDestinationText;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (dispatchId == null ? 0 : dispatchId!.hashCode) +
    (planDate == null ? 0 : planDate!.hashCode) +
    (truckNo == null ? 0 : truckNo!.hashCode) +
    (truckTrip == null ? 0 : truckTrip!.hashCode) +
    (depot == null ? 0 : depot!.hashCode) +
    (numberOfPallets == null ? 0 : numberOfPallets!.hashCode) +
    (truckType == null ? 0 : truckType!.hashCode) +
    (factoryDeparture == null ? 0 : factoryDeparture!.hashCode) +
    (depotArrival == null ? 0 : depotArrival!.hashCode) +
    (plannedDepotArrival == null ? 0 : plannedDepotArrival!.hashCode) +
    (unloadingComplete == null ? 0 : unloadingComplete!.hashCode) +
    (finalDestinationText == null ? 0 : finalDestinationText!.hashCode);

  @override
  String toString() => 'DispatchDayReportRow[dispatchId=$dispatchId, planDate=$planDate, truckNo=$truckNo, truckTrip=$truckTrip, depot=$depot, numberOfPallets=$numberOfPallets, truckType=$truckType, factoryDeparture=$factoryDeparture, depotArrival=$depotArrival, plannedDepotArrival=$plannedDepotArrival, unloadingComplete=$unloadingComplete, finalDestinationText=$finalDestinationText]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.dispatchId != null) {
      json[r'dispatchId'] = this.dispatchId;
    } else {
      json[r'dispatchId'] = null;
    }
    if (this.planDate != null) {
      json[r'planDate'] = _dateFormatter.format(this.planDate!.toUtc());
    } else {
      json[r'planDate'] = null;
    }
    if (this.truckNo != null) {
      json[r'truckNo'] = this.truckNo;
    } else {
      json[r'truckNo'] = null;
    }
    if (this.truckTrip != null) {
      json[r'truckTrip'] = this.truckTrip;
    } else {
      json[r'truckTrip'] = null;
    }
    if (this.depot != null) {
      json[r'depot'] = this.depot;
    } else {
      json[r'depot'] = null;
    }
    if (this.numberOfPallets != null) {
      json[r'numberOfPallets'] = this.numberOfPallets;
    } else {
      json[r'numberOfPallets'] = null;
    }
    if (this.truckType != null) {
      json[r'truckType'] = this.truckType;
    } else {
      json[r'truckType'] = null;
    }
    if (this.factoryDeparture != null) {
      json[r'factoryDeparture'] = this.factoryDeparture!.toUtc().toIso8601String();
    } else {
      json[r'factoryDeparture'] = null;
    }
    if (this.depotArrival != null) {
      json[r'depotArrival'] = this.depotArrival!.toUtc().toIso8601String();
    } else {
      json[r'depotArrival'] = null;
    }
    if (this.plannedDepotArrival != null) {
      json[r'plannedDepotArrival'] = this.plannedDepotArrival!.toUtc().toIso8601String();
    } else {
      json[r'plannedDepotArrival'] = null;
    }
    if (this.unloadingComplete != null) {
      json[r'unloadingComplete'] = this.unloadingComplete!.toUtc().toIso8601String();
    } else {
      json[r'unloadingComplete'] = null;
    }
    if (this.finalDestinationText != null) {
      json[r'finalDestinationText'] = this.finalDestinationText;
    } else {
      json[r'finalDestinationText'] = null;
    }
    return json;
  }

  /// Returns a new [DispatchDayReportRow] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DispatchDayReportRow? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DispatchDayReportRow(
        dispatchId: mapValueOfType<int>(json, r'dispatchId'),
        planDate: mapDateTime(json, r'planDate', r''),
        truckNo: mapValueOfType<String>(json, r'truckNo'),
        truckTrip: mapValueOfType<String>(json, r'truckTrip'),
        depot: mapValueOfType<String>(json, r'depot'),
        numberOfPallets: num.parse('${json[r'numberOfPallets']}'),
        truckType: mapValueOfType<String>(json, r'truckType'),
        factoryDeparture: mapDateTime(json, r'factoryDeparture', r''),
        depotArrival: mapDateTime(json, r'depotArrival', r''),
        plannedDepotArrival: mapDateTime(json, r'plannedDepotArrival', r''),
        unloadingComplete: mapDateTime(json, r'unloadingComplete', r''),
        finalDestinationText: mapValueOfType<String>(json, r'finalDestinationText'),
      );
    }
    return null;
  }

  static List<DispatchDayReportRow> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DispatchDayReportRow>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DispatchDayReportRow.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DispatchDayReportRow> mapFromJson(dynamic json) {
    final map = <String, DispatchDayReportRow>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DispatchDayReportRow.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DispatchDayReportRow-objects as value to a dart map
  static Map<String, List<DispatchDayReportRow>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DispatchDayReportRow>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DispatchDayReportRow.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

