//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Customer {
  /// Returns a new [Customer] instance.
  Customer({
    this.id,
    this.customerCode,
    this.type,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.status,
    this.user,
    this.partnerCompany,
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

  CustomerTypeEnum? type;

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

  CustomerStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  User? user;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  PartnerCompany? partnerCompany;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Customer &&
    other.id == id &&
    other.customerCode == customerCode &&
    other.type == type &&
    other.name == name &&
    other.email == email &&
    other.phone == phone &&
    other.address == address &&
    other.status == status &&
    other.user == user &&
    other.partnerCompany == partnerCompany;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (customerCode == null ? 0 : customerCode!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (phone == null ? 0 : phone!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (user == null ? 0 : user!.hashCode) +
    (partnerCompany == null ? 0 : partnerCompany!.hashCode);

  @override
  String toString() => 'Customer[id=$id, customerCode=$customerCode, type=$type, name=$name, email=$email, phone=$phone, address=$address, status=$status, user=$user, partnerCompany=$partnerCompany]';

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
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
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
    if (this.user != null) {
      json[r'user'] = this.user;
    } else {
      json[r'user'] = null;
    }
    if (this.partnerCompany != null) {
      json[r'partnerCompany'] = this.partnerCompany;
    } else {
      json[r'partnerCompany'] = null;
    }
    return json;
  }

  /// Returns a new [Customer] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Customer? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return Customer(
        id: mapValueOfType<int>(json, r'id'),
        customerCode: mapValueOfType<String>(json, r'customerCode'),
        type: CustomerTypeEnum.fromJson(json[r'type']),
        name: mapValueOfType<String>(json, r'name'),
        email: mapValueOfType<String>(json, r'email'),
        phone: mapValueOfType<String>(json, r'phone'),
        address: mapValueOfType<String>(json, r'address'),
        status: CustomerStatusEnum.fromJson(json[r'status']),
        user: User.fromJson(json[r'user']),
        partnerCompany: PartnerCompany.fromJson(json[r'partnerCompany']),
      );
    }
    return null;
  }

  static List<Customer> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Customer>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Customer.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Customer> mapFromJson(dynamic json) {
    final map = <String, Customer>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Customer.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Customer-objects as value to a dart map
  static Map<String, List<Customer>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Customer>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Customer.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class CustomerTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const CustomerTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const INDIVIDUAL = CustomerTypeEnum._(r'INDIVIDUAL');
  static const COMPANY = CustomerTypeEnum._(r'COMPANY');

  /// List of all possible values in this [enum][CustomerTypeEnum].
  static const values = <CustomerTypeEnum>[
    INDIVIDUAL,
    COMPANY,
  ];

  static CustomerTypeEnum? fromJson(dynamic value) => CustomerTypeEnumTypeTransformer().decode(value);

  static List<CustomerTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CustomerTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CustomerTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CustomerTypeEnum] to String,
/// and [decode] dynamic data back to [CustomerTypeEnum].
class CustomerTypeEnumTypeTransformer {
  factory CustomerTypeEnumTypeTransformer() => _instance ??= const CustomerTypeEnumTypeTransformer._();

  const CustomerTypeEnumTypeTransformer._();

  String encode(CustomerTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CustomerTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CustomerTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'INDIVIDUAL': return CustomerTypeEnum.INDIVIDUAL;
        case r'COMPANY': return CustomerTypeEnum.COMPANY;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CustomerTypeEnumTypeTransformer] instance.
  static CustomerTypeEnumTypeTransformer? _instance;
}



class CustomerStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const CustomerStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ACTIVE = CustomerStatusEnum._(r'ACTIVE');
  static const INACTIVE = CustomerStatusEnum._(r'INACTIVE');

  /// List of all possible values in this [enum][CustomerStatusEnum].
  static const values = <CustomerStatusEnum>[
    ACTIVE,
    INACTIVE,
  ];

  static CustomerStatusEnum? fromJson(dynamic value) => CustomerStatusEnumTypeTransformer().decode(value);

  static List<CustomerStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CustomerStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CustomerStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CustomerStatusEnum] to String,
/// and [decode] dynamic data back to [CustomerStatusEnum].
class CustomerStatusEnumTypeTransformer {
  factory CustomerStatusEnumTypeTransformer() => _instance ??= const CustomerStatusEnumTypeTransformer._();

  const CustomerStatusEnumTypeTransformer._();

  String encode(CustomerStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CustomerStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CustomerStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ACTIVE': return CustomerStatusEnum.ACTIVE;
        case r'INACTIVE': return CustomerStatusEnum.INACTIVE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CustomerStatusEnumTypeTransformer] instance.
  static CustomerStatusEnumTypeTransformer? _instance;
}


