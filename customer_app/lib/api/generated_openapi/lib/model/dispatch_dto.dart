//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DispatchDto {
  /// Returns a new [DispatchDto] instance.
  DispatchDto({
    this.id,
    this.routeCode,
    this.startTime,
    this.estimatedArrival,
    this.status,
    this.tripType,
    this.transportOrderId,
    this.orderReference,
    this.transportOrder,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.pickupName,
    this.pickupLocation,
    this.pickupLat,
    this.pickupLng,
    this.dropoffName,
    this.dropoffLocation,
    this.dropoffLat,
    this.dropoffLng,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleId,
    this.licensePlate,
    this.createdBy,
    this.createdByUsername,
    this.createdDate,
    this.updatedDate,
    this.stops = const [],
    this.items = const [],
    this.loadProof,
    this.unloadProof,
    this.loadingProofImages = const [],
    this.loadingSignature,
    this.unloadingProofImages = const [],
    this.unloadingSignature,
    this.expectedDelivery,
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
  String? routeCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? startTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? estimatedArrival;

  DispatchDtoStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tripType;

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
  String? orderReference;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  TransportOrderDto? transportOrder;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? customerId;

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
  String? customerPhone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? pickupName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? pickupLocation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? pickupLat;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? pickupLng;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? dropoffName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? dropoffLocation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? dropoffLat;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? dropoffLng;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? driverId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? driverName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? driverPhone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vehicleId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? licensePlate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? createdBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? createdByUsername;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedDate;

  List<DispatchStopDto> stops;

  List<DispatchItemDto> items;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  LoadProofDto? loadProof;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UnloadProofDto? unloadProof;

  List<String> loadingProofImages;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? loadingSignature;

  List<String> unloadingProofImages;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unloadingSignature;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? expectedDelivery;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DispatchDto &&
    other.id == id &&
    other.routeCode == routeCode &&
    other.startTime == startTime &&
    other.estimatedArrival == estimatedArrival &&
    other.status == status &&
    other.tripType == tripType &&
    other.transportOrderId == transportOrderId &&
    other.orderReference == orderReference &&
    other.transportOrder == transportOrder &&
    other.customerId == customerId &&
    other.customerName == customerName &&
    other.customerPhone == customerPhone &&
    other.pickupName == pickupName &&
    other.pickupLocation == pickupLocation &&
    other.pickupLat == pickupLat &&
    other.pickupLng == pickupLng &&
    other.dropoffName == dropoffName &&
    other.dropoffLocation == dropoffLocation &&
    other.dropoffLat == dropoffLat &&
    other.dropoffLng == dropoffLng &&
    other.driverId == driverId &&
    other.driverName == driverName &&
    other.driverPhone == driverPhone &&
    other.vehicleId == vehicleId &&
    other.licensePlate == licensePlate &&
    other.createdBy == createdBy &&
    other.createdByUsername == createdByUsername &&
    other.createdDate == createdDate &&
    other.updatedDate == updatedDate &&
    _deepEquality.equals(other.stops, stops) &&
    _deepEquality.equals(other.items, items) &&
    other.loadProof == loadProof &&
    other.unloadProof == unloadProof &&
    _deepEquality.equals(other.loadingProofImages, loadingProofImages) &&
    other.loadingSignature == loadingSignature &&
    _deepEquality.equals(other.unloadingProofImages, unloadingProofImages) &&
    other.unloadingSignature == unloadingSignature &&
    other.expectedDelivery == expectedDelivery;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (routeCode == null ? 0 : routeCode!.hashCode) +
    (startTime == null ? 0 : startTime!.hashCode) +
    (estimatedArrival == null ? 0 : estimatedArrival!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (tripType == null ? 0 : tripType!.hashCode) +
    (transportOrderId == null ? 0 : transportOrderId!.hashCode) +
    (orderReference == null ? 0 : orderReference!.hashCode) +
    (transportOrder == null ? 0 : transportOrder!.hashCode) +
    (customerId == null ? 0 : customerId!.hashCode) +
    (customerName == null ? 0 : customerName!.hashCode) +
    (customerPhone == null ? 0 : customerPhone!.hashCode) +
    (pickupName == null ? 0 : pickupName!.hashCode) +
    (pickupLocation == null ? 0 : pickupLocation!.hashCode) +
    (pickupLat == null ? 0 : pickupLat!.hashCode) +
    (pickupLng == null ? 0 : pickupLng!.hashCode) +
    (dropoffName == null ? 0 : dropoffName!.hashCode) +
    (dropoffLocation == null ? 0 : dropoffLocation!.hashCode) +
    (dropoffLat == null ? 0 : dropoffLat!.hashCode) +
    (dropoffLng == null ? 0 : dropoffLng!.hashCode) +
    (driverId == null ? 0 : driverId!.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (driverPhone == null ? 0 : driverPhone!.hashCode) +
    (vehicleId == null ? 0 : vehicleId!.hashCode) +
    (licensePlate == null ? 0 : licensePlate!.hashCode) +
    (createdBy == null ? 0 : createdBy!.hashCode) +
    (createdByUsername == null ? 0 : createdByUsername!.hashCode) +
    (createdDate == null ? 0 : createdDate!.hashCode) +
    (updatedDate == null ? 0 : updatedDate!.hashCode) +
    (stops.hashCode) +
    (items.hashCode) +
    (loadProof == null ? 0 : loadProof!.hashCode) +
    (unloadProof == null ? 0 : unloadProof!.hashCode) +
    (loadingProofImages.hashCode) +
    (loadingSignature == null ? 0 : loadingSignature!.hashCode) +
    (unloadingProofImages.hashCode) +
    (unloadingSignature == null ? 0 : unloadingSignature!.hashCode) +
    (expectedDelivery == null ? 0 : expectedDelivery!.hashCode);

  @override
  String toString() => 'DispatchDto[id=$id, routeCode=$routeCode, startTime=$startTime, estimatedArrival=$estimatedArrival, status=$status, tripType=$tripType, transportOrderId=$transportOrderId, orderReference=$orderReference, transportOrder=$transportOrder, customerId=$customerId, customerName=$customerName, customerPhone=$customerPhone, pickupName=$pickupName, pickupLocation=$pickupLocation, pickupLat=$pickupLat, pickupLng=$pickupLng, dropoffName=$dropoffName, dropoffLocation=$dropoffLocation, dropoffLat=$dropoffLat, dropoffLng=$dropoffLng, driverId=$driverId, driverName=$driverName, driverPhone=$driverPhone, vehicleId=$vehicleId, licensePlate=$licensePlate, createdBy=$createdBy, createdByUsername=$createdByUsername, createdDate=$createdDate, updatedDate=$updatedDate, stops=$stops, items=$items, loadProof=$loadProof, unloadProof=$unloadProof, loadingProofImages=$loadingProofImages, loadingSignature=$loadingSignature, unloadingProofImages=$unloadingProofImages, unloadingSignature=$unloadingSignature, expectedDelivery=$expectedDelivery]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.routeCode != null) {
      json[r'routeCode'] = this.routeCode;
    } else {
      json[r'routeCode'] = null;
    }
    if (this.startTime != null) {
      json[r'startTime'] = this.startTime!.toUtc().toIso8601String();
    } else {
      json[r'startTime'] = null;
    }
    if (this.estimatedArrival != null) {
      json[r'estimatedArrival'] = this.estimatedArrival!.toUtc().toIso8601String();
    } else {
      json[r'estimatedArrival'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.tripType != null) {
      json[r'tripType'] = this.tripType;
    } else {
      json[r'tripType'] = null;
    }
    if (this.transportOrderId != null) {
      json[r'transportOrderId'] = this.transportOrderId;
    } else {
      json[r'transportOrderId'] = null;
    }
    if (this.orderReference != null) {
      json[r'orderReference'] = this.orderReference;
    } else {
      json[r'orderReference'] = null;
    }
    if (this.transportOrder != null) {
      json[r'transportOrder'] = this.transportOrder;
    } else {
      json[r'transportOrder'] = null;
    }
    if (this.customerId != null) {
      json[r'customerId'] = this.customerId;
    } else {
      json[r'customerId'] = null;
    }
    if (this.customerName != null) {
      json[r'customerName'] = this.customerName;
    } else {
      json[r'customerName'] = null;
    }
    if (this.customerPhone != null) {
      json[r'customerPhone'] = this.customerPhone;
    } else {
      json[r'customerPhone'] = null;
    }
    if (this.pickupName != null) {
      json[r'pickupName'] = this.pickupName;
    } else {
      json[r'pickupName'] = null;
    }
    if (this.pickupLocation != null) {
      json[r'pickupLocation'] = this.pickupLocation;
    } else {
      json[r'pickupLocation'] = null;
    }
    if (this.pickupLat != null) {
      json[r'pickupLat'] = this.pickupLat;
    } else {
      json[r'pickupLat'] = null;
    }
    if (this.pickupLng != null) {
      json[r'pickupLng'] = this.pickupLng;
    } else {
      json[r'pickupLng'] = null;
    }
    if (this.dropoffName != null) {
      json[r'dropoffName'] = this.dropoffName;
    } else {
      json[r'dropoffName'] = null;
    }
    if (this.dropoffLocation != null) {
      json[r'dropoffLocation'] = this.dropoffLocation;
    } else {
      json[r'dropoffLocation'] = null;
    }
    if (this.dropoffLat != null) {
      json[r'dropoffLat'] = this.dropoffLat;
    } else {
      json[r'dropoffLat'] = null;
    }
    if (this.dropoffLng != null) {
      json[r'dropoffLng'] = this.dropoffLng;
    } else {
      json[r'dropoffLng'] = null;
    }
    if (this.driverId != null) {
      json[r'driverId'] = this.driverId;
    } else {
      json[r'driverId'] = null;
    }
    if (this.driverName != null) {
      json[r'driverName'] = this.driverName;
    } else {
      json[r'driverName'] = null;
    }
    if (this.driverPhone != null) {
      json[r'driverPhone'] = this.driverPhone;
    } else {
      json[r'driverPhone'] = null;
    }
    if (this.vehicleId != null) {
      json[r'vehicleId'] = this.vehicleId;
    } else {
      json[r'vehicleId'] = null;
    }
    if (this.licensePlate != null) {
      json[r'licensePlate'] = this.licensePlate;
    } else {
      json[r'licensePlate'] = null;
    }
    if (this.createdBy != null) {
      json[r'createdBy'] = this.createdBy;
    } else {
      json[r'createdBy'] = null;
    }
    if (this.createdByUsername != null) {
      json[r'createdByUsername'] = this.createdByUsername;
    } else {
      json[r'createdByUsername'] = null;
    }
    if (this.createdDate != null) {
      json[r'createdDate'] = this.createdDate!.toUtc().toIso8601String();
    } else {
      json[r'createdDate'] = null;
    }
    if (this.updatedDate != null) {
      json[r'updatedDate'] = this.updatedDate!.toUtc().toIso8601String();
    } else {
      json[r'updatedDate'] = null;
    }
      json[r'stops'] = this.stops;
      json[r'items'] = this.items;
    if (this.loadProof != null) {
      json[r'loadProof'] = this.loadProof;
    } else {
      json[r'loadProof'] = null;
    }
    if (this.unloadProof != null) {
      json[r'unloadProof'] = this.unloadProof;
    } else {
      json[r'unloadProof'] = null;
    }
      json[r'loadingProofImages'] = this.loadingProofImages;
    if (this.loadingSignature != null) {
      json[r'loadingSignature'] = this.loadingSignature;
    } else {
      json[r'loadingSignature'] = null;
    }
      json[r'unloadingProofImages'] = this.unloadingProofImages;
    if (this.unloadingSignature != null) {
      json[r'unloadingSignature'] = this.unloadingSignature;
    } else {
      json[r'unloadingSignature'] = null;
    }
    if (this.expectedDelivery != null) {
      json[r'expectedDelivery'] = this.expectedDelivery!.toUtc().toIso8601String();
    } else {
      json[r'expectedDelivery'] = null;
    }
    return json;
  }

  /// Returns a new [DispatchDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DispatchDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DispatchDto(
        id: mapValueOfType<int>(json, r'id'),
        routeCode: mapValueOfType<String>(json, r'routeCode'),
        startTime: mapDateTime(json, r'startTime', r''),
        estimatedArrival: mapDateTime(json, r'estimatedArrival', r''),
        status: DispatchDtoStatusEnum.fromJson(json[r'status']),
        tripType: mapValueOfType<String>(json, r'tripType'),
        transportOrderId: mapValueOfType<int>(json, r'transportOrderId'),
        orderReference: mapValueOfType<String>(json, r'orderReference'),
        transportOrder: TransportOrderDto.fromJson(json[r'transportOrder']),
        customerId: mapValueOfType<int>(json, r'customerId'),
        customerName: mapValueOfType<String>(json, r'customerName'),
        customerPhone: mapValueOfType<String>(json, r'customerPhone'),
        pickupName: mapValueOfType<String>(json, r'pickupName'),
        pickupLocation: mapValueOfType<String>(json, r'pickupLocation'),
        pickupLat: mapValueOfType<double>(json, r'pickupLat'),
        pickupLng: mapValueOfType<double>(json, r'pickupLng'),
        dropoffName: mapValueOfType<String>(json, r'dropoffName'),
        dropoffLocation: mapValueOfType<String>(json, r'dropoffLocation'),
        dropoffLat: mapValueOfType<double>(json, r'dropoffLat'),
        dropoffLng: mapValueOfType<double>(json, r'dropoffLng'),
        driverId: mapValueOfType<int>(json, r'driverId'),
        driverName: mapValueOfType<String>(json, r'driverName'),
        driverPhone: mapValueOfType<String>(json, r'driverPhone'),
        vehicleId: mapValueOfType<int>(json, r'vehicleId'),
        licensePlate: mapValueOfType<String>(json, r'licensePlate'),
        createdBy: mapValueOfType<int>(json, r'createdBy'),
        createdByUsername: mapValueOfType<String>(json, r'createdByUsername'),
        createdDate: mapDateTime(json, r'createdDate', r''),
        updatedDate: mapDateTime(json, r'updatedDate', r''),
        stops: DispatchStopDto.listFromJson(json[r'stops']),
        items: DispatchItemDto.listFromJson(json[r'items']),
        loadProof: LoadProofDto.fromJson(json[r'loadProof']),
        unloadProof: UnloadProofDto.fromJson(json[r'unloadProof']),
        loadingProofImages: json[r'loadingProofImages'] is Iterable
            ? (json[r'loadingProofImages'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        loadingSignature: mapValueOfType<String>(json, r'loadingSignature'),
        unloadingProofImages: json[r'unloadingProofImages'] is Iterable
            ? (json[r'unloadingProofImages'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        unloadingSignature: mapValueOfType<String>(json, r'unloadingSignature'),
        expectedDelivery: mapDateTime(json, r'expectedDelivery', r''),
      );
    }
    return null;
  }

  static List<DispatchDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DispatchDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DispatchDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DispatchDto> mapFromJson(dynamic json) {
    final map = <String, DispatchDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DispatchDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DispatchDto-objects as value to a dart map
  static Map<String, List<DispatchDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DispatchDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DispatchDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class DispatchDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DispatchDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = DispatchDtoStatusEnum._(r'PENDING');
  static const ASSIGNED = DispatchDtoStatusEnum._(r'ASSIGNED');
  static const DRIVER_CONFIRMED = DispatchDtoStatusEnum._(r'DRIVER_CONFIRMED');
  static const APPROVED = DispatchDtoStatusEnum._(r'APPROVED');
  static const REJECTED = DispatchDtoStatusEnum._(r'REJECTED');
  static const SCHEDULED = DispatchDtoStatusEnum._(r'SCHEDULED');
  static const ARRIVED_LOADING = DispatchDtoStatusEnum._(r'ARRIVED_LOADING');
  static const LOADING = DispatchDtoStatusEnum._(r'LOADING');
  static const LOADED = DispatchDtoStatusEnum._(r'LOADED');
  static const IN_TRANSIT = DispatchDtoStatusEnum._(r'IN_TRANSIT');
  static const ARRIVED_UNLOADING = DispatchDtoStatusEnum._(r'ARRIVED_UNLOADING');
  static const UNLOADING = DispatchDtoStatusEnum._(r'UNLOADING');
  static const UNLOADED = DispatchDtoStatusEnum._(r'UNLOADED');
  static const DELIVERED = DispatchDtoStatusEnum._(r'DELIVERED');
  static const COMPLETED = DispatchDtoStatusEnum._(r'COMPLETED');
  static const CANCELLED = DispatchDtoStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][DispatchDtoStatusEnum].
  static const values = <DispatchDtoStatusEnum>[
    PENDING,
    ASSIGNED,
    DRIVER_CONFIRMED,
    APPROVED,
    REJECTED,
    SCHEDULED,
    ARRIVED_LOADING,
    LOADING,
    LOADED,
    IN_TRANSIT,
    ARRIVED_UNLOADING,
    UNLOADING,
    UNLOADED,
    DELIVERED,
    COMPLETED,
    CANCELLED,
  ];

  static DispatchDtoStatusEnum? fromJson(dynamic value) => DispatchDtoStatusEnumTypeTransformer().decode(value);

  static List<DispatchDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DispatchDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DispatchDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DispatchDtoStatusEnum] to String,
/// and [decode] dynamic data back to [DispatchDtoStatusEnum].
class DispatchDtoStatusEnumTypeTransformer {
  factory DispatchDtoStatusEnumTypeTransformer() => _instance ??= const DispatchDtoStatusEnumTypeTransformer._();

  const DispatchDtoStatusEnumTypeTransformer._();

  String encode(DispatchDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DispatchDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DispatchDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return DispatchDtoStatusEnum.PENDING;
        case r'ASSIGNED': return DispatchDtoStatusEnum.ASSIGNED;
        case r'DRIVER_CONFIRMED': return DispatchDtoStatusEnum.DRIVER_CONFIRMED;
        case r'APPROVED': return DispatchDtoStatusEnum.APPROVED;
        case r'REJECTED': return DispatchDtoStatusEnum.REJECTED;
        case r'SCHEDULED': return DispatchDtoStatusEnum.SCHEDULED;
        case r'ARRIVED_LOADING': return DispatchDtoStatusEnum.ARRIVED_LOADING;
        case r'LOADING': return DispatchDtoStatusEnum.LOADING;
        case r'LOADED': return DispatchDtoStatusEnum.LOADED;
        case r'IN_TRANSIT': return DispatchDtoStatusEnum.IN_TRANSIT;
        case r'ARRIVED_UNLOADING': return DispatchDtoStatusEnum.ARRIVED_UNLOADING;
        case r'UNLOADING': return DispatchDtoStatusEnum.UNLOADING;
        case r'UNLOADED': return DispatchDtoStatusEnum.UNLOADED;
        case r'DELIVERED': return DispatchDtoStatusEnum.DELIVERED;
        case r'COMPLETED': return DispatchDtoStatusEnum.COMPLETED;
        case r'CANCELLED': return DispatchDtoStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DispatchDtoStatusEnumTypeTransformer] instance.
  static DispatchDtoStatusEnumTypeTransformer? _instance;
}


