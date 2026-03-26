//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OrderAddress {
  /// Returns a new [OrderAddress] instance.
  OrderAddress({
    this.id,
    this.name,
    this.address,
    this.city,
    this.country,
    this.postcode,
    this.scheduledTime,
    this.longitude,
    this.latitude,
    this.type,
    this.customer,
    this.fullAddress,
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
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? address;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? city;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? country;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? postcode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? scheduledTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? longitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? latitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Customer? customer;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fullAddress;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OrderAddress &&
    other.id == id &&
    other.name == name &&
    other.address == address &&
    other.city == city &&
    other.country == country &&
    other.postcode == postcode &&
    other.scheduledTime == scheduledTime &&
    other.longitude == longitude &&
    other.latitude == latitude &&
    other.type == type &&
    other.customer == customer &&
    other.fullAddress == fullAddress;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (city == null ? 0 : city!.hashCode) +
    (country == null ? 0 : country!.hashCode) +
    (postcode == null ? 0 : postcode!.hashCode) +
    (scheduledTime == null ? 0 : scheduledTime!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (customer == null ? 0 : customer!.hashCode) +
    (fullAddress == null ? 0 : fullAddress!.hashCode);

  @override
  String toString() => 'OrderAddress[id=$id, name=$name, address=$address, city=$city, country=$country, postcode=$postcode, scheduledTime=$scheduledTime, longitude=$longitude, latitude=$latitude, type=$type, customer=$customer, fullAddress=$fullAddress]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.city != null) {
      json[r'city'] = this.city;
    } else {
      json[r'city'] = null;
    }
    if (this.country != null) {
      json[r'country'] = this.country;
    } else {
      json[r'country'] = null;
    }
    if (this.postcode != null) {
      json[r'postcode'] = this.postcode;
    } else {
      json[r'postcode'] = null;
    }
    if (this.scheduledTime != null) {
      json[r'scheduledTime'] = this.scheduledTime;
    } else {
      json[r'scheduledTime'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.customer != null) {
      json[r'customer'] = this.customer;
    } else {
      json[r'customer'] = null;
    }
    if (this.fullAddress != null) {
      json[r'fullAddress'] = this.fullAddress;
    } else {
      json[r'fullAddress'] = null;
    }
    return json;
  }

  /// Returns a new [OrderAddress] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OrderAddress? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return OrderAddress(
        id: mapValueOfType<int>(json, r'id'),
        name: mapValueOfType<String>(json, r'name'),
        address: mapValueOfType<String>(json, r'address'),
        city: mapValueOfType<String>(json, r'city'),
        country: mapValueOfType<String>(json, r'country'),
        postcode: mapValueOfType<String>(json, r'postcode'),
        scheduledTime: mapValueOfType<String>(json, r'scheduledTime'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        type: mapValueOfType<String>(json, r'type'),
        customer: Customer.fromJson(json[r'customer']),
        fullAddress: mapValueOfType<String>(json, r'fullAddress'),
      );
    }
    return null;
  }

  static List<OrderAddress> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderAddress>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderAddress.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OrderAddress> mapFromJson(dynamic json) {
    final map = <String, OrderAddress>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OrderAddress.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OrderAddress-objects as value to a dart map
  static Map<String, List<OrderAddress>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OrderAddress>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OrderAddress.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

