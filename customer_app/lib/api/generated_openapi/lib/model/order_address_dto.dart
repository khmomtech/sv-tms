//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OrderAddressDto {
  /// Returns a new [OrderAddressDto] instance.
  OrderAddressDto({
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
    this.customerId,
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
  int? customerId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OrderAddressDto &&
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
    other.customerId == customerId;

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
    (customerId == null ? 0 : customerId!.hashCode);

  @override
  String toString() => 'OrderAddressDto[id=$id, name=$name, address=$address, city=$city, country=$country, postcode=$postcode, scheduledTime=$scheduledTime, longitude=$longitude, latitude=$latitude, type=$type, customerId=$customerId]';

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
    if (this.customerId != null) {
      json[r'customerId'] = this.customerId;
    } else {
      json[r'customerId'] = null;
    }
    return json;
  }

  /// Returns a new [OrderAddressDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OrderAddressDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return OrderAddressDto(
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
        customerId: mapValueOfType<int>(json, r'customerId'),
      );
    }
    return null;
  }

  static List<OrderAddressDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderAddressDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderAddressDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OrderAddressDto> mapFromJson(dynamic json) {
    final map = <String, OrderAddressDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OrderAddressDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OrderAddressDto-objects as value to a dart map
  static Map<String, List<OrderAddressDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OrderAddressDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OrderAddressDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

