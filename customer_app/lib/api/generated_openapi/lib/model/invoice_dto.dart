//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InvoiceDto {
  /// Returns a new [InvoiceDto] instance.
  InvoiceDto({
    this.id,
    this.transportOrderId,
    this.invoiceDate,
    this.totalAmount,
    this.paymentStatus,
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
  int? transportOrderId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? invoiceDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? totalAmount;

  InvoiceDtoPaymentStatusEnum? paymentStatus;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InvoiceDto &&
    other.id == id &&
    other.transportOrderId == transportOrderId &&
    other.invoiceDate == invoiceDate &&
    other.totalAmount == totalAmount &&
    other.paymentStatus == paymentStatus;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (transportOrderId == null ? 0 : transportOrderId!.hashCode) +
    (invoiceDate == null ? 0 : invoiceDate!.hashCode) +
    (totalAmount == null ? 0 : totalAmount!.hashCode) +
    (paymentStatus == null ? 0 : paymentStatus!.hashCode);

  @override
  String toString() => 'InvoiceDto[id=$id, transportOrderId=$transportOrderId, invoiceDate=$invoiceDate, totalAmount=$totalAmount, paymentStatus=$paymentStatus]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.transportOrderId != null) {
      json[r'transportOrderId'] = this.transportOrderId;
    } else {
      json[r'transportOrderId'] = null;
    }
    if (this.invoiceDate != null) {
      json[r'invoiceDate'] = _dateFormatter.format(this.invoiceDate!.toUtc());
    } else {
      json[r'invoiceDate'] = null;
    }
    if (this.totalAmount != null) {
      json[r'totalAmount'] = this.totalAmount;
    } else {
      json[r'totalAmount'] = null;
    }
    if (this.paymentStatus != null) {
      json[r'paymentStatus'] = this.paymentStatus;
    } else {
      json[r'paymentStatus'] = null;
    }
    return json;
  }

  /// Returns a new [InvoiceDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InvoiceDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return InvoiceDto(
        id: mapValueOfType<int>(json, r'id'),
        transportOrderId: mapValueOfType<int>(json, r'transportOrderId'),
        invoiceDate: mapDateTime(json, r'invoiceDate', r''),
        totalAmount: num.parse('${json[r'totalAmount']}'),
        paymentStatus: InvoiceDtoPaymentStatusEnum.fromJson(json[r'paymentStatus']),
      );
    }
    return null;
  }

  static List<InvoiceDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvoiceDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvoiceDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InvoiceDto> mapFromJson(dynamic json) {
    final map = <String, InvoiceDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InvoiceDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InvoiceDto-objects as value to a dart map
  static Map<String, List<InvoiceDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InvoiceDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InvoiceDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class InvoiceDtoPaymentStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const InvoiceDtoPaymentStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PAID = InvoiceDtoPaymentStatusEnum._(r'PAID');
  static const UNPAID = InvoiceDtoPaymentStatusEnum._(r'UNPAID');
  static const PARTIAL = InvoiceDtoPaymentStatusEnum._(r'PARTIAL');

  /// List of all possible values in this [enum][InvoiceDtoPaymentStatusEnum].
  static const values = <InvoiceDtoPaymentStatusEnum>[
    PAID,
    UNPAID,
    PARTIAL,
  ];

  static InvoiceDtoPaymentStatusEnum? fromJson(dynamic value) => InvoiceDtoPaymentStatusEnumTypeTransformer().decode(value);

  static List<InvoiceDtoPaymentStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvoiceDtoPaymentStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvoiceDtoPaymentStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [InvoiceDtoPaymentStatusEnum] to String,
/// and [decode] dynamic data back to [InvoiceDtoPaymentStatusEnum].
class InvoiceDtoPaymentStatusEnumTypeTransformer {
  factory InvoiceDtoPaymentStatusEnumTypeTransformer() => _instance ??= const InvoiceDtoPaymentStatusEnumTypeTransformer._();

  const InvoiceDtoPaymentStatusEnumTypeTransformer._();

  String encode(InvoiceDtoPaymentStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a InvoiceDtoPaymentStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  InvoiceDtoPaymentStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PAID': return InvoiceDtoPaymentStatusEnum.PAID;
        case r'UNPAID': return InvoiceDtoPaymentStatusEnum.UNPAID;
        case r'PARTIAL': return InvoiceDtoPaymentStatusEnum.PARTIAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [InvoiceDtoPaymentStatusEnumTypeTransformer] instance.
  static InvoiceDtoPaymentStatusEnumTypeTransformer? _instance;
}


