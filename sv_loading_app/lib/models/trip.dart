class Trip {
  final String tripId;
  final int? dispatchId;
  final String? truckPlate;
  final String? driverName;
  final String? warehouse;
  final String? status;

  Trip({
    required this.tripId,
    this.dispatchId,
    this.truckPlate,
    this.driverName,
    this.warehouse,
    this.status,
  });

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v == null) return null;
    return int.tryParse(v.toString());
  }

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        tripId: json['tripId']?.toString() ??
            json['dispatchId']?.toString() ??
            json['id']?.toString() ??
            '',
        dispatchId: _toInt(json['dispatchId'] ?? json['tripId'] ?? json['id']),
        truckPlate: json['truckPlate']?.toString(),
        driverName: json['driverName']?.toString(),
        warehouse: json['warehouse']?.toString(),
        status: json['status']?.toString(),
      );
}
