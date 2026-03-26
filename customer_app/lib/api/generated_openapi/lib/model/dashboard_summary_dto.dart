//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DashboardSummaryDto {
  /// Returns a new [DashboardSummaryDto] instance.
  DashboardSummaryDto({
    this.totalOrders,
    this.pendingOrders,
    this.inTransitOrders,
    this.completedOrders,
    this.cancelledOrders,
    this.todayOrders,
    this.scheduledDeliveriesToday,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? totalOrders;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? pendingOrders;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? inTransitOrders;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? completedOrders;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? cancelledOrders;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? todayOrders;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? scheduledDeliveriesToday;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DashboardSummaryDto &&
    other.totalOrders == totalOrders &&
    other.pendingOrders == pendingOrders &&
    other.inTransitOrders == inTransitOrders &&
    other.completedOrders == completedOrders &&
    other.cancelledOrders == cancelledOrders &&
    other.todayOrders == todayOrders &&
    other.scheduledDeliveriesToday == scheduledDeliveriesToday;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (totalOrders == null ? 0 : totalOrders!.hashCode) +
    (pendingOrders == null ? 0 : pendingOrders!.hashCode) +
    (inTransitOrders == null ? 0 : inTransitOrders!.hashCode) +
    (completedOrders == null ? 0 : completedOrders!.hashCode) +
    (cancelledOrders == null ? 0 : cancelledOrders!.hashCode) +
    (todayOrders == null ? 0 : todayOrders!.hashCode) +
    (scheduledDeliveriesToday == null ? 0 : scheduledDeliveriesToday!.hashCode);

  @override
  String toString() => 'DashboardSummaryDto[totalOrders=$totalOrders, pendingOrders=$pendingOrders, inTransitOrders=$inTransitOrders, completedOrders=$completedOrders, cancelledOrders=$cancelledOrders, todayOrders=$todayOrders, scheduledDeliveriesToday=$scheduledDeliveriesToday]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.totalOrders != null) {
      json[r'totalOrders'] = this.totalOrders;
    } else {
      json[r'totalOrders'] = null;
    }
    if (this.pendingOrders != null) {
      json[r'pendingOrders'] = this.pendingOrders;
    } else {
      json[r'pendingOrders'] = null;
    }
    if (this.inTransitOrders != null) {
      json[r'inTransitOrders'] = this.inTransitOrders;
    } else {
      json[r'inTransitOrders'] = null;
    }
    if (this.completedOrders != null) {
      json[r'completedOrders'] = this.completedOrders;
    } else {
      json[r'completedOrders'] = null;
    }
    if (this.cancelledOrders != null) {
      json[r'cancelledOrders'] = this.cancelledOrders;
    } else {
      json[r'cancelledOrders'] = null;
    }
    if (this.todayOrders != null) {
      json[r'todayOrders'] = this.todayOrders;
    } else {
      json[r'todayOrders'] = null;
    }
    if (this.scheduledDeliveriesToday != null) {
      json[r'scheduledDeliveriesToday'] = this.scheduledDeliveriesToday;
    } else {
      json[r'scheduledDeliveriesToday'] = null;
    }
    return json;
  }

  /// Returns a new [DashboardSummaryDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DashboardSummaryDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DashboardSummaryDto(
        totalOrders: mapValueOfType<int>(json, r'totalOrders'),
        pendingOrders: mapValueOfType<int>(json, r'pendingOrders'),
        inTransitOrders: mapValueOfType<int>(json, r'inTransitOrders'),
        completedOrders: mapValueOfType<int>(json, r'completedOrders'),
        cancelledOrders: mapValueOfType<int>(json, r'cancelledOrders'),
        todayOrders: mapValueOfType<int>(json, r'todayOrders'),
        scheduledDeliveriesToday: mapValueOfType<int>(json, r'scheduledDeliveriesToday'),
      );
    }
    return null;
  }

  static List<DashboardSummaryDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DashboardSummaryDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DashboardSummaryDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DashboardSummaryDto> mapFromJson(dynamic json) {
    final map = <String, DashboardSummaryDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DashboardSummaryDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DashboardSummaryDto-objects as value to a dart map
  static Map<String, List<DashboardSummaryDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DashboardSummaryDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DashboardSummaryDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

