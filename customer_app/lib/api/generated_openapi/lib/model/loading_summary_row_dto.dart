//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LoadingSummaryRowDto {
  /// Returns a new [LoadingSummaryRowDto] instance.
  LoadingSummaryRowDto({
    this.customer,
    this.toDestination,
    this.totalTrip,
    this.completed,
    this.pending,
    this.loading,
    this.truckArrived,
    this.truckNotArrived,
    this.achievedPercentage,
    this.completedLoading,
    this.approved,
    this.scheduled,
    this.inProgress,
    this.cancelled,
    this.rejected,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? customer;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? toDestination;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? totalTrip;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? completed;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? pending;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? loading;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? truckArrived;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? truckNotArrived;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? achievedPercentage;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? completedLoading;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? approved;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? scheduled;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? inProgress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? cancelled;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rejected;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LoadingSummaryRowDto &&
    other.customer == customer &&
    other.toDestination == toDestination &&
    other.totalTrip == totalTrip &&
    other.completed == completed &&
    other.pending == pending &&
    other.loading == loading &&
    other.truckArrived == truckArrived &&
    other.truckNotArrived == truckNotArrived &&
    other.achievedPercentage == achievedPercentage &&
    other.completedLoading == completedLoading &&
    other.approved == approved &&
    other.scheduled == scheduled &&
    other.inProgress == inProgress &&
    other.cancelled == cancelled &&
    other.rejected == rejected;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (customer == null ? 0 : customer!.hashCode) +
    (toDestination == null ? 0 : toDestination!.hashCode) +
    (totalTrip == null ? 0 : totalTrip!.hashCode) +
    (completed == null ? 0 : completed!.hashCode) +
    (pending == null ? 0 : pending!.hashCode) +
    (loading == null ? 0 : loading!.hashCode) +
    (truckArrived == null ? 0 : truckArrived!.hashCode) +
    (truckNotArrived == null ? 0 : truckNotArrived!.hashCode) +
    (achievedPercentage == null ? 0 : achievedPercentage!.hashCode) +
    (completedLoading == null ? 0 : completedLoading!.hashCode) +
    (approved == null ? 0 : approved!.hashCode) +
    (scheduled == null ? 0 : scheduled!.hashCode) +
    (inProgress == null ? 0 : inProgress!.hashCode) +
    (cancelled == null ? 0 : cancelled!.hashCode) +
    (rejected == null ? 0 : rejected!.hashCode);

  @override
  String toString() => 'LoadingSummaryRowDto[customer=$customer, toDestination=$toDestination, totalTrip=$totalTrip, completed=$completed, pending=$pending, loading=$loading, truckArrived=$truckArrived, truckNotArrived=$truckNotArrived, achievedPercentage=$achievedPercentage, completedLoading=$completedLoading, approved=$approved, scheduled=$scheduled, inProgress=$inProgress, cancelled=$cancelled, rejected=$rejected]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.customer != null) {
      json[r'customer'] = this.customer;
    } else {
      json[r'customer'] = null;
    }
    if (this.toDestination != null) {
      json[r'toDestination'] = this.toDestination;
    } else {
      json[r'toDestination'] = null;
    }
    if (this.totalTrip != null) {
      json[r'totalTrip'] = this.totalTrip;
    } else {
      json[r'totalTrip'] = null;
    }
    if (this.completed != null) {
      json[r'completed'] = this.completed;
    } else {
      json[r'completed'] = null;
    }
    if (this.pending != null) {
      json[r'pending'] = this.pending;
    } else {
      json[r'pending'] = null;
    }
    if (this.loading != null) {
      json[r'loading'] = this.loading;
    } else {
      json[r'loading'] = null;
    }
    if (this.truckArrived != null) {
      json[r'truckArrived'] = this.truckArrived;
    } else {
      json[r'truckArrived'] = null;
    }
    if (this.truckNotArrived != null) {
      json[r'truckNotArrived'] = this.truckNotArrived;
    } else {
      json[r'truckNotArrived'] = null;
    }
    if (this.achievedPercentage != null) {
      json[r'achievedPercentage'] = this.achievedPercentage;
    } else {
      json[r'achievedPercentage'] = null;
    }
    if (this.completedLoading != null) {
      json[r'completedLoading'] = this.completedLoading;
    } else {
      json[r'completedLoading'] = null;
    }
    if (this.approved != null) {
      json[r'approved'] = this.approved;
    } else {
      json[r'approved'] = null;
    }
    if (this.scheduled != null) {
      json[r'scheduled'] = this.scheduled;
    } else {
      json[r'scheduled'] = null;
    }
    if (this.inProgress != null) {
      json[r'inProgress'] = this.inProgress;
    } else {
      json[r'inProgress'] = null;
    }
    if (this.cancelled != null) {
      json[r'cancelled'] = this.cancelled;
    } else {
      json[r'cancelled'] = null;
    }
    if (this.rejected != null) {
      json[r'rejected'] = this.rejected;
    } else {
      json[r'rejected'] = null;
    }
    return json;
  }

  /// Returns a new [LoadingSummaryRowDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LoadingSummaryRowDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LoadingSummaryRowDto(
        customer: mapValueOfType<String>(json, r'customer'),
        toDestination: mapValueOfType<String>(json, r'toDestination'),
        totalTrip: mapValueOfType<int>(json, r'totalTrip'),
        completed: mapValueOfType<int>(json, r'completed'),
        pending: mapValueOfType<int>(json, r'pending'),
        loading: mapValueOfType<int>(json, r'loading'),
        truckArrived: mapValueOfType<int>(json, r'truckArrived'),
        truckNotArrived: mapValueOfType<int>(json, r'truckNotArrived'),
        achievedPercentage: mapValueOfType<double>(json, r'achievedPercentage'),
        completedLoading: mapValueOfType<int>(json, r'completedLoading'),
        approved: mapValueOfType<int>(json, r'approved'),
        scheduled: mapValueOfType<int>(json, r'scheduled'),
        inProgress: mapValueOfType<int>(json, r'inProgress'),
        cancelled: mapValueOfType<int>(json, r'cancelled'),
        rejected: mapValueOfType<int>(json, r'rejected'),
      );
    }
    return null;
  }

  static List<LoadingSummaryRowDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LoadingSummaryRowDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LoadingSummaryRowDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LoadingSummaryRowDto> mapFromJson(dynamic json) {
    final map = <String, LoadingSummaryRowDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LoadingSummaryRowDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LoadingSummaryRowDto-objects as value to a dart map
  static Map<String, List<LoadingSummaryRowDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LoadingSummaryRowDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LoadingSummaryRowDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

