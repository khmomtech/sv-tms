class TransportOrderDto {
  int? id;
  String? orderRef;
  String? orderDate;
  String? deliveryDate;
  String? shipmentType;
  Map<String, dynamic>? pickupAddress;
  Map<String, dynamic>? dropAddress;
  String? status;

  TransportOrderDto({
    this.id,
    this.orderRef,
    this.orderDate,
    this.deliveryDate,
    this.shipmentType,
    this.pickupAddress,
    this.dropAddress,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderRef': orderRef,
        'orderDate': orderDate,
        'deliveryDate': deliveryDate,
        'shipmentType': shipmentType,
        'pickupAddress': pickupAddress,
        'dropAddress': dropAddress,
        'status': status,
      };

  factory TransportOrderDto.fromJson(Map<String, dynamic> json) => TransportOrderDto(
        id: json['id'] is int
            ? json['id'] as int
            : (json['id'] is String ? int.tryParse(json['id'] as String) : null),
        orderRef: json['orderRef'] as String?,
        orderDate: json['orderDate'] as String?,
        deliveryDate: json['deliveryDate'] as String?,
        shipmentType: json['shipmentType'] as String?,
        pickupAddress: json['pickupAddress'] as Map<String, dynamic>?,
        dropAddress: json['dropAddress'] as Map<String, dynamic>?,
        status: json['status'] as String?,
      );
}
