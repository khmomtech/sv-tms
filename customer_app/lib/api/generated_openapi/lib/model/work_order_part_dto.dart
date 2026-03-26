//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkOrderPartDto {
  /// Returns a new [WorkOrderPartDto] instance.
  WorkOrderPartDto({
    this.id,
    required this.workOrderId,
    this.taskId,
    required this.partId,
    this.partCode,
    this.partName,
    required this.quantity,
    required this.unitPrice,
    this.totalCost,
    this.notes,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  int workOrderId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? taskId;

  int partId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? partCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? partName;

  /// Minimum value: 0.0
  double quantity;

  /// Minimum value: 0.0
  double unitPrice;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? totalCost;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkOrderPartDto &&
    other.id == id &&
    other.workOrderId == workOrderId &&
    other.taskId == taskId &&
    other.partId == partId &&
    other.partCode == partCode &&
    other.partName == partName &&
    other.quantity == quantity &&
    other.unitPrice == unitPrice &&
    other.totalCost == totalCost &&
    other.notes == notes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (workOrderId.hashCode) +
    (taskId == null ? 0 : taskId!.hashCode) +
    (partId.hashCode) +
    (partCode == null ? 0 : partCode!.hashCode) +
    (partName == null ? 0 : partName!.hashCode) +
    (quantity.hashCode) +
    (unitPrice.hashCode) +
    (totalCost == null ? 0 : totalCost!.hashCode) +
    (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() => 'WorkOrderPartDto[id=$id, workOrderId=$workOrderId, taskId=$taskId, partId=$partId, partCode=$partCode, partName=$partName, quantity=$quantity, unitPrice=$unitPrice, totalCost=$totalCost, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'workOrderId'] = this.workOrderId;
    if (this.taskId != null) {
      json[r'taskId'] = this.taskId;
    } else {
      json[r'taskId'] = null;
    }
      json[r'partId'] = this.partId;
    if (this.partCode != null) {
      json[r'partCode'] = this.partCode;
    } else {
      json[r'partCode'] = null;
    }
    if (this.partName != null) {
      json[r'partName'] = this.partName;
    } else {
      json[r'partName'] = null;
    }
      json[r'quantity'] = this.quantity;
      json[r'unitPrice'] = this.unitPrice;
    if (this.totalCost != null) {
      json[r'totalCost'] = this.totalCost;
    } else {
      json[r'totalCost'] = null;
    }
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    return json;
  }

  /// Returns a new [WorkOrderPartDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkOrderPartDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'workOrderId'), 'Required key "WorkOrderPartDto[workOrderId]" is missing from JSON.');
        assert(json[r'workOrderId'] != null, 'Required key "WorkOrderPartDto[workOrderId]" has a null value in JSON.');
        assert(json.containsKey(r'partId'), 'Required key "WorkOrderPartDto[partId]" is missing from JSON.');
        assert(json[r'partId'] != null, 'Required key "WorkOrderPartDto[partId]" has a null value in JSON.');
        assert(json.containsKey(r'quantity'), 'Required key "WorkOrderPartDto[quantity]" is missing from JSON.');
        assert(json[r'quantity'] != null, 'Required key "WorkOrderPartDto[quantity]" has a null value in JSON.');
        assert(json.containsKey(r'unitPrice'), 'Required key "WorkOrderPartDto[unitPrice]" is missing from JSON.');
        assert(json[r'unitPrice'] != null, 'Required key "WorkOrderPartDto[unitPrice]" has a null value in JSON.');
        return true;
      }());

      return WorkOrderPartDto(
        id: mapValueOfType<int>(json, r'id'),
        workOrderId: mapValueOfType<int>(json, r'workOrderId')!,
        taskId: mapValueOfType<int>(json, r'taskId'),
        partId: mapValueOfType<int>(json, r'partId')!,
        partCode: mapValueOfType<String>(json, r'partCode'),
        partName: mapValueOfType<String>(json, r'partName'),
        quantity: mapValueOfType<double>(json, r'quantity')!,
        unitPrice: mapValueOfType<double>(json, r'unitPrice')!,
        totalCost: mapValueOfType<double>(json, r'totalCost'),
        notes: mapValueOfType<String>(json, r'notes'),
      );
    }
    return null;
  }

  static List<WorkOrderPartDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkOrderPartDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkOrderPartDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkOrderPartDto> mapFromJson(dynamic json) {
    final map = <String, WorkOrderPartDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkOrderPartDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkOrderPartDto-objects as value to a dart map
  static Map<String, List<WorkOrderPartDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkOrderPartDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkOrderPartDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'workOrderId',
    'partId',
    'quantity',
    'unitPrice',
  };
}

