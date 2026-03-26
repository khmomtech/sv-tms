//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CustomerDto {
  /// Returns a new [CustomerDto] instance.
  CustomerDto({
    this.id,
    this.customerCode,
    this.type,
    this.customerName,
    this.email,
    this.phone,
    this.address,
    this.status,
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
  String? customerCode;

  CustomerDtoTypeEnum? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? customerName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? phone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? address;

  CustomerDtoStatusEnum? status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CustomerDto &&
    other.id == id &&
    other.customerCode == customerCode &&
    other.type == type &&
    other.customerName == customerName &&
    other.email == email &&
    other.phone == phone &&
    other.address == address &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (customerCode == null ? 0 : customerCode!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (customerName == null ? 0 : customerName!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (phone == null ? 0 : phone!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (status == null ? 0 : status!.hashCode);

  @override
  String toString() => 'CustomerDto[id=$id, customerCode=$customerCode, type=$type, customerName=$customerName, email=$email, phone=$phone, address=$address, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.customerCode != null) {
      json[r'customerCode'] = this.customerCode;
    } else {
      json[r'customerCode'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.customerName != null) {
      json[r'customerName'] = this.customerName;
    } else {
      json[r'customerName'] = null;
    }
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.phone != null) {
      json[r'phone'] = this.phone;
    } else {
      json[r'phone'] = null;
    }
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    return json;
  }

  /// Returns a new [CustomerDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CustomerDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return CustomerDto(
        id: mapValueOfType<int>(json, r'id'),
        customerCode: mapValueOfType<String>(json, r'customerCode'),
        type: CustomerDtoTypeEnum.fromJson(json[r'type']),
        customerName: mapValueOfType<String>(json, r'customerName'),
        email: mapValueOfType<String>(json, r'email'),
        phone: mapValueOfType<String>(json, r'phone'),
        address: mapValueOfType<String>(json, r'address'),
        status: CustomerDtoStatusEnum.fromJson(json[r'status']),
      );
    }
    return null;
  }

  static List<CustomerDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CustomerDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CustomerDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CustomerDto> mapFromJson(dynamic json) {
    final map = <String, CustomerDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CustomerDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CustomerDto-objects as value to a dart map
  static Map<String, List<CustomerDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CustomerDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CustomerDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class CustomerDtoTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const CustomerDtoTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const INDIVIDUAL = CustomerDtoTypeEnum._(r'INDIVIDUAL');
  static const COMPANY = CustomerDtoTypeEnum._(r'COMPANY');

  /// List of all possible values in this [enum][CustomerDtoTypeEnum].
  static const values = <CustomerDtoTypeEnum>[
    INDIVIDUAL,
    COMPANY,
  ];

  static CustomerDtoTypeEnum? fromJson(dynamic value) => CustomerDtoTypeEnumTypeTransformer().decode(value);

  static List<CustomerDtoTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CustomerDtoTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CustomerDtoTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CustomerDtoTypeEnum] to String,
/// and [decode] dynamic data back to [CustomerDtoTypeEnum].
class CustomerDtoTypeEnumTypeTransformer {
  factory CustomerDtoTypeEnumTypeTransformer() => _instance ??= const CustomerDtoTypeEnumTypeTransformer._();

  const CustomerDtoTypeEnumTypeTransformer._();

  String encode(CustomerDtoTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CustomerDtoTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CustomerDtoTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'INDIVIDUAL': return CustomerDtoTypeEnum.INDIVIDUAL;
        case r'COMPANY': return CustomerDtoTypeEnum.COMPANY;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CustomerDtoTypeEnumTypeTransformer] instance.
  static CustomerDtoTypeEnumTypeTransformer? _instance;
}



class CustomerDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const CustomerDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ACTIVE = CustomerDtoStatusEnum._(r'ACTIVE');
  static const INACTIVE = CustomerDtoStatusEnum._(r'INACTIVE');

  /// List of all possible values in this [enum][CustomerDtoStatusEnum].
  static const values = <CustomerDtoStatusEnum>[
    ACTIVE,
    INACTIVE,
  ];

  static CustomerDtoStatusEnum? fromJson(dynamic value) => CustomerDtoStatusEnumTypeTransformer().decode(value);

  static List<CustomerDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CustomerDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CustomerDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CustomerDtoStatusEnum] to String,
/// and [decode] dynamic data back to [CustomerDtoStatusEnum].
class CustomerDtoStatusEnumTypeTransformer {
  factory CustomerDtoStatusEnumTypeTransformer() => _instance ??= const CustomerDtoStatusEnumTypeTransformer._();

  const CustomerDtoStatusEnumTypeTransformer._();

  String encode(CustomerDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CustomerDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CustomerDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ACTIVE': return CustomerDtoStatusEnum.ACTIVE;
        case r'INACTIVE': return CustomerDtoStatusEnum.INACTIVE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CustomerDtoStatusEnumTypeTransformer] instance.
  static CustomerDtoStatusEnumTypeTransformer? _instance;
}


