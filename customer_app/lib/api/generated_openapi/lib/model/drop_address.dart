//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DropAddress {
  /// Returns a new [DropAddress] instance.
  DropAddress({
    this.id,
    this.shipment,
    this.location,
    this.contactPerson,
    this.contactPhone,
    this.scheduledTime,
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
  Shipment? shipment;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? location;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? contactPerson;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? contactPhone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? scheduledTime;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DropAddress &&
    other.id == id &&
    other.shipment == shipment &&
    other.location == location &&
    other.contactPerson == contactPerson &&
    other.contactPhone == contactPhone &&
    other.scheduledTime == scheduledTime;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (shipment == null ? 0 : shipment!.hashCode) +
    (location == null ? 0 : location!.hashCode) +
    (contactPerson == null ? 0 : contactPerson!.hashCode) +
    (contactPhone == null ? 0 : contactPhone!.hashCode) +
    (scheduledTime == null ? 0 : scheduledTime!.hashCode);

  @override
  String toString() => 'DropAddress[id=$id, shipment=$shipment, location=$location, contactPerson=$contactPerson, contactPhone=$contactPhone, scheduledTime=$scheduledTime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.shipment != null) {
      json[r'shipment'] = this.shipment;
    } else {
      json[r'shipment'] = null;
    }
    if (this.location != null) {
      json[r'location'] = this.location;
    } else {
      json[r'location'] = null;
    }
    if (this.contactPerson != null) {
      json[r'contactPerson'] = this.contactPerson;
    } else {
      json[r'contactPerson'] = null;
    }
    if (this.contactPhone != null) {
      json[r'contactPhone'] = this.contactPhone;
    } else {
      json[r'contactPhone'] = null;
    }
    if (this.scheduledTime != null) {
      json[r'scheduledTime'] = this.scheduledTime!.toUtc().toIso8601String();
    } else {
      json[r'scheduledTime'] = null;
    }
    return json;
  }

  /// Returns a new [DropAddress] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DropAddress? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DropAddress(
        id: mapValueOfType<int>(json, r'id'),
        shipment: Shipment.fromJson(json[r'shipment']),
        location: mapValueOfType<String>(json, r'location'),
        contactPerson: mapValueOfType<String>(json, r'contactPerson'),
        contactPhone: mapValueOfType<String>(json, r'contactPhone'),
        scheduledTime: mapDateTime(json, r'scheduledTime', r''),
      );
    }
    return null;
  }

  static List<DropAddress> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DropAddress>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DropAddress.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DropAddress> mapFromJson(dynamic json) {
    final map = <String, DropAddress>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DropAddress.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DropAddress-objects as value to a dart map
  static Map<String, List<DropAddress>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DropAddress>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DropAddress.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

