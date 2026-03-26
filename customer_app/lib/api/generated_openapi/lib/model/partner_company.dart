//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PartnerCompany {
  /// Returns a new [PartnerCompany] instance.
  PartnerCompany({
    this.id,
    this.companyCode,
    this.companyName,
    this.businessLicense,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.partnershipType,
    this.status,
    this.contractStartDate,
    this.contractEndDate,
    this.commissionRate,
    this.creditLimit,
    this.notes,
    this.logoUrl,
    this.website,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
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
  String? companyCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? companyName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? businessLicense;

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

  PartnerCompanyPartnershipTypeEnum? partnershipType;

  PartnerCompanyStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? contractStartDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? contractEndDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? commissionRate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? creditLimit;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? notes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? logoUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? website;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? createdBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? updatedBy;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PartnerCompany &&
    other.id == id &&
    other.companyCode == companyCode &&
    other.companyName == companyName &&
    other.businessLicense == businessLicense &&
    other.contactPerson == contactPerson &&
    other.email == email &&
    other.phone == phone &&
    other.address == address &&
    other.partnershipType == partnershipType &&
    other.status == status &&
    other.contractStartDate == contractStartDate &&
    other.contractEndDate == contractEndDate &&
    other.commissionRate == commissionRate &&
    other.creditLimit == creditLimit &&
    other.notes == notes &&
    other.logoUrl == logoUrl &&
    other.website == website &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.createdBy == createdBy &&
    other.updatedBy == updatedBy;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (companyCode == null ? 0 : companyCode!.hashCode) +
    (companyName == null ? 0 : companyName!.hashCode) +
    (businessLicense == null ? 0 : businessLicense!.hashCode) +
    (contactPerson == null ? 0 : contactPerson!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (phone == null ? 0 : phone!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (partnershipType == null ? 0 : partnershipType!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (contractStartDate == null ? 0 : contractStartDate!.hashCode) +
    (contractEndDate == null ? 0 : contractEndDate!.hashCode) +
    (commissionRate == null ? 0 : commissionRate!.hashCode) +
    (creditLimit == null ? 0 : creditLimit!.hashCode) +
    (notes == null ? 0 : notes!.hashCode) +
    (logoUrl == null ? 0 : logoUrl!.hashCode) +
    (website == null ? 0 : website!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (createdBy == null ? 0 : createdBy!.hashCode) +
    (updatedBy == null ? 0 : updatedBy!.hashCode);

  @override
  String toString() => 'PartnerCompany[id=$id, companyCode=$companyCode, companyName=$companyName, businessLicense=$businessLicense, contactPerson=$contactPerson, email=$email, phone=$phone, address=$address, partnershipType=$partnershipType, status=$status, contractStartDate=$contractStartDate, contractEndDate=$contractEndDate, commissionRate=$commissionRate, creditLimit=$creditLimit, notes=$notes, logoUrl=$logoUrl, website=$website, createdAt=$createdAt, updatedAt=$updatedAt, createdBy=$createdBy, updatedBy=$updatedBy]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.companyCode != null) {
      json[r'companyCode'] = this.companyCode;
    } else {
      json[r'companyCode'] = null;
    }
    if (this.companyName != null) {
      json[r'companyName'] = this.companyName;
    } else {
      json[r'companyName'] = null;
    }
    if (this.businessLicense != null) {
      json[r'businessLicense'] = this.businessLicense;
    } else {
      json[r'businessLicense'] = null;
    }
    if (this.contactPerson != null) {
      json[r'contactPerson'] = this.contactPerson;
    } else {
      json[r'contactPerson'] = null;
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
    if (this.partnershipType != null) {
      json[r'partnershipType'] = this.partnershipType;
    } else {
      json[r'partnershipType'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.contractStartDate != null) {
      json[r'contractStartDate'] = _dateFormatter.format(this.contractStartDate!.toUtc());
    } else {
      json[r'contractStartDate'] = null;
    }
    if (this.contractEndDate != null) {
      json[r'contractEndDate'] = _dateFormatter.format(this.contractEndDate!.toUtc());
    } else {
      json[r'contractEndDate'] = null;
    }
    if (this.commissionRate != null) {
      json[r'commissionRate'] = this.commissionRate;
    } else {
      json[r'commissionRate'] = null;
    }
    if (this.creditLimit != null) {
      json[r'creditLimit'] = this.creditLimit;
    } else {
      json[r'creditLimit'] = null;
    }
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    if (this.logoUrl != null) {
      json[r'logoUrl'] = this.logoUrl;
    } else {
      json[r'logoUrl'] = null;
    }
    if (this.website != null) {
      json[r'website'] = this.website;
    } else {
      json[r'website'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updatedAt'] = null;
    }
    if (this.createdBy != null) {
      json[r'createdBy'] = this.createdBy;
    } else {
      json[r'createdBy'] = null;
    }
    if (this.updatedBy != null) {
      json[r'updatedBy'] = this.updatedBy;
    } else {
      json[r'updatedBy'] = null;
    }
    return json;
  }

  /// Returns a new [PartnerCompany] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PartnerCompany? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PartnerCompany(
        id: mapValueOfType<int>(json, r'id'),
        companyCode: mapValueOfType<String>(json, r'companyCode'),
        companyName: mapValueOfType<String>(json, r'companyName'),
        businessLicense: mapValueOfType<String>(json, r'businessLicense'),
        contactPerson: mapValueOfType<String>(json, r'contactPerson'),
        email: mapValueOfType<String>(json, r'email'),
        phone: mapValueOfType<String>(json, r'phone'),
        address: mapValueOfType<String>(json, r'address'),
        partnershipType: PartnerCompanyPartnershipTypeEnum.fromJson(json[r'partnershipType']),
        status: PartnerCompanyStatusEnum.fromJson(json[r'status']),
        contractStartDate: mapDateTime(json, r'contractStartDate', r''),
        contractEndDate: mapDateTime(json, r'contractEndDate', r''),
        commissionRate: mapValueOfType<double>(json, r'commissionRate'),
        creditLimit: mapValueOfType<double>(json, r'creditLimit'),
        notes: mapValueOfType<String>(json, r'notes'),
        logoUrl: mapValueOfType<String>(json, r'logoUrl'),
        website: mapValueOfType<String>(json, r'website'),
        createdAt: mapDateTime(json, r'createdAt', r''),
        updatedAt: mapDateTime(json, r'updatedAt', r''),
        createdBy: mapValueOfType<String>(json, r'createdBy'),
        updatedBy: mapValueOfType<String>(json, r'updatedBy'),
      );
    }
    return null;
  }

  static List<PartnerCompany> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PartnerCompany>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PartnerCompany.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PartnerCompany> mapFromJson(dynamic json) {
    final map = <String, PartnerCompany>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PartnerCompany.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PartnerCompany-objects as value to a dart map
  static Map<String, List<PartnerCompany>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PartnerCompany>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PartnerCompany.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class PartnerCompanyPartnershipTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const PartnerCompanyPartnershipTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const DRIVER_FLEET = PartnerCompanyPartnershipTypeEnum._(r'DRIVER_FLEET');
  static const CUSTOMER_CORPORATE = PartnerCompanyPartnershipTypeEnum._(r'CUSTOMER_CORPORATE');
  static const FULL_SERVICE = PartnerCompanyPartnershipTypeEnum._(r'FULL_SERVICE');
  static const LOGISTICS_PROVIDER = PartnerCompanyPartnershipTypeEnum._(r'LOGISTICS_PROVIDER');
  static const TECHNOLOGY_PARTNER = PartnerCompanyPartnershipTypeEnum._(r'TECHNOLOGY_PARTNER');

  /// List of all possible values in this [enum][PartnerCompanyPartnershipTypeEnum].
  static const values = <PartnerCompanyPartnershipTypeEnum>[
    DRIVER_FLEET,
    CUSTOMER_CORPORATE,
    FULL_SERVICE,
    LOGISTICS_PROVIDER,
    TECHNOLOGY_PARTNER,
  ];

  static PartnerCompanyPartnershipTypeEnum? fromJson(dynamic value) => PartnerCompanyPartnershipTypeEnumTypeTransformer().decode(value);

  static List<PartnerCompanyPartnershipTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PartnerCompanyPartnershipTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PartnerCompanyPartnershipTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PartnerCompanyPartnershipTypeEnum] to String,
/// and [decode] dynamic data back to [PartnerCompanyPartnershipTypeEnum].
class PartnerCompanyPartnershipTypeEnumTypeTransformer {
  factory PartnerCompanyPartnershipTypeEnumTypeTransformer() => _instance ??= const PartnerCompanyPartnershipTypeEnumTypeTransformer._();

  const PartnerCompanyPartnershipTypeEnumTypeTransformer._();

  String encode(PartnerCompanyPartnershipTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PartnerCompanyPartnershipTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PartnerCompanyPartnershipTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'DRIVER_FLEET': return PartnerCompanyPartnershipTypeEnum.DRIVER_FLEET;
        case r'CUSTOMER_CORPORATE': return PartnerCompanyPartnershipTypeEnum.CUSTOMER_CORPORATE;
        case r'FULL_SERVICE': return PartnerCompanyPartnershipTypeEnum.FULL_SERVICE;
        case r'LOGISTICS_PROVIDER': return PartnerCompanyPartnershipTypeEnum.LOGISTICS_PROVIDER;
        case r'TECHNOLOGY_PARTNER': return PartnerCompanyPartnershipTypeEnum.TECHNOLOGY_PARTNER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PartnerCompanyPartnershipTypeEnumTypeTransformer] instance.
  static PartnerCompanyPartnershipTypeEnumTypeTransformer? _instance;
}



class PartnerCompanyStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const PartnerCompanyStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ACTIVE = PartnerCompanyStatusEnum._(r'ACTIVE');
  static const INACTIVE = PartnerCompanyStatusEnum._(r'INACTIVE');

  /// List of all possible values in this [enum][PartnerCompanyStatusEnum].
  static const values = <PartnerCompanyStatusEnum>[
    ACTIVE,
    INACTIVE,
  ];

  static PartnerCompanyStatusEnum? fromJson(dynamic value) => PartnerCompanyStatusEnumTypeTransformer().decode(value);

  static List<PartnerCompanyStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PartnerCompanyStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PartnerCompanyStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PartnerCompanyStatusEnum] to String,
/// and [decode] dynamic data back to [PartnerCompanyStatusEnum].
class PartnerCompanyStatusEnumTypeTransformer {
  factory PartnerCompanyStatusEnumTypeTransformer() => _instance ??= const PartnerCompanyStatusEnumTypeTransformer._();

  const PartnerCompanyStatusEnumTypeTransformer._();

  String encode(PartnerCompanyStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PartnerCompanyStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PartnerCompanyStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ACTIVE': return PartnerCompanyStatusEnum.ACTIVE;
        case r'INACTIVE': return PartnerCompanyStatusEnum.INACTIVE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PartnerCompanyStatusEnumTypeTransformer] instance.
  static PartnerCompanyStatusEnumTypeTransformer? _instance;
}


