/// Model representing a Dispatch/Trip assignment
class DispatchModel {
  final int id;
  final String? routeCode;
  final String? status;
  final DateTime? startTime;
  final DateTime? estimatedArrival;
  final String? tripType;
  final int? driverId;
  final String? driverName;
  final int? vehicleId;
  final String? vehicleLicensePlate;
  final int? transportOrderId;
  final String? orderReference;
  final String? customerName;
  final String? pickupAddress;
  final String? deliveryAddress;
  final DateTime? createdAt;
  final DateTime? createdDate;
  final DateTime? updatedDate;

  DispatchModel({
    required this.id,
    this.routeCode,
    this.status,
    this.startTime,
    this.estimatedArrival,
    this.tripType,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleLicensePlate,
    this.transportOrderId,
    this.orderReference,
    this.customerName,
    this.pickupAddress,
    this.deliveryAddress,
    this.createdAt,
    this.createdDate,
    this.updatedDate,
  });

  factory DispatchModel.fromJson(Map<String, dynamic> json) {
    return DispatchModel(
      id: json['id'] as int,
      routeCode: json['routeCode'] as String?,
      status: json['status'] as String?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.parse(json['estimatedArrival'] as String)
          : null,
      tripType: json['tripType'] as String?,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
      vehicleId: json['vehicleId'] as int?,
      vehicleLicensePlate: json['vehicleLicensePlate'] as String?,
      transportOrderId: json['transportOrderId'] as int?,
      orderReference: json['orderReference'] as String?,
      customerName: json['customerName'] as String?,
      pickupAddress: json['pickupAddress'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
      updatedDate: json['updatedDate'] != null
          ? DateTime.parse(json['updatedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeCode': routeCode,
      'status': status,
      'startTime': startTime?.toIso8601String(),
      'estimatedArrival': estimatedArrival?.toIso8601String(),
      'tripType': tripType,
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehicleLicensePlate': vehicleLicensePlate,
      'transportOrderId': transportOrderId,
      'orderReference': orderReference,
      'customerName': customerName,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'createdAt': createdAt?.toIso8601String(),
      'createdDate': createdDate?.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DispatchModel(id: $id, routeCode: $routeCode, status: $status)';
  }
}
