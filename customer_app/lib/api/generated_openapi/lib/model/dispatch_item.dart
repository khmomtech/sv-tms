//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DispatchItem {
  /// Returns a new [DispatchItem] instance.
  DispatchItem({
    this.id,
    this.itemName,
    this.quantity,
    this.unitOfMeasurement,
    this.palletType,
    this.dimensions,
    this.weight,
    this.palletQty,
    this.loadingPlace,
    this.dispatch,
    this.orderItem,
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
  String? itemName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? quantity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitOfMeasurement;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? palletType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? dimensions;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? weight;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? palletQty;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? loadingPlace;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Dispatch? dispatch;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  OrderItem? orderItem;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DispatchItem &&
    other.id == id &&
    other.itemName == itemName &&
    other.quantity == quantity &&
    other.unitOfMeasurement == unitOfMeasurement &&
    other.palletType == palletType &&
    other.dimensions == dimensions &&
    other.weight == weight &&
    other.palletQty == palletQty &&
    other.loadingPlace == loadingPlace &&
    other.dispatch == dispatch &&
    other.orderItem == orderItem;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (itemName == null ? 0 : itemName!.hashCode) +
    (quantity == null ? 0 : quantity!.hashCode) +
    (unitOfMeasurement == null ? 0 : unitOfMeasurement!.hashCode) +
    (palletType == null ? 0 : palletType!.hashCode) +
    (dimensions == null ? 0 : dimensions!.hashCode) +
    (weight == null ? 0 : weight!.hashCode) +
    (palletQty == null ? 0 : palletQty!.hashCode) +
    (loadingPlace == null ? 0 : loadingPlace!.hashCode) +
    (dispatch == null ? 0 : dispatch!.hashCode) +
    (orderItem == null ? 0 : orderItem!.hashCode);

  @override
  String toString() => 'DispatchItem[id=$id, itemName=$itemName, quantity=$quantity, unitOfMeasurement=$unitOfMeasurement, palletType=$palletType, dimensions=$dimensions, weight=$weight, palletQty=$palletQty, loadingPlace=$loadingPlace, dispatch=$dispatch, orderItem=$orderItem]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.itemName != null) {
      json[r'itemName'] = this.itemName;
    } else {
      json[r'itemName'] = null;
    }
    if (this.quantity != null) {
      json[r'quantity'] = this.quantity;
    } else {
      json[r'quantity'] = null;
    }
    if (this.unitOfMeasurement != null) {
      json[r'unitOfMeasurement'] = this.unitOfMeasurement;
    } else {
      json[r'unitOfMeasurement'] = null;
    }
    if (this.palletType != null) {
      json[r'palletType'] = this.palletType;
    } else {
      json[r'palletType'] = null;
    }
    if (this.dimensions != null) {
      json[r'dimensions'] = this.dimensions;
    } else {
      json[r'dimensions'] = null;
    }
    if (this.weight != null) {
      json[r'weight'] = this.weight;
    } else {
      json[r'weight'] = null;
    }
    if (this.palletQty != null) {
      json[r'palletQty'] = this.palletQty;
    } else {
      json[r'palletQty'] = null;
    }
    if (this.loadingPlace != null) {
      json[r'loadingPlace'] = this.loadingPlace;
    } else {
      json[r'loadingPlace'] = null;
    }
    if (this.dispatch != null) {
      json[r'dispatch'] = this.dispatch;
    } else {
      json[r'dispatch'] = null;
    }
    if (this.orderItem != null) {
      json[r'orderItem'] = this.orderItem;
    } else {
      json[r'orderItem'] = null;
    }
    return json;
  }

  /// Returns a new [DispatchItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DispatchItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DispatchItem(
        id: mapValueOfType<int>(json, r'id'),
        itemName: mapValueOfType<String>(json, r'itemName'),
        quantity: mapValueOfType<double>(json, r'quantity'),
        unitOfMeasurement: mapValueOfType<String>(json, r'unitOfMeasurement'),
        palletType: mapValueOfType<String>(json, r'palletType'),
        dimensions: mapValueOfType<String>(json, r'dimensions'),
        weight: mapValueOfType<double>(json, r'weight'),
        palletQty: mapValueOfType<int>(json, r'palletQty'),
        loadingPlace: mapValueOfType<String>(json, r'loadingPlace'),
        dispatch: Dispatch.fromJson(json[r'dispatch']),
        orderItem: OrderItem.fromJson(json[r'orderItem']),
      );
    }
    return null;
  }

  static List<DispatchItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DispatchItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DispatchItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DispatchItem> mapFromJson(dynamic json) {
    final map = <String, DispatchItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DispatchItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DispatchItem-objects as value to a dart map
  static Map<String, List<DispatchItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DispatchItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DispatchItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

