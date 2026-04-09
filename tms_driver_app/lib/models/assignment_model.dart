class AssignmentModel {
  final int id;
  final int driverId;
  final String driverName;
  final int vehicleId;
  final String truckPlate;
  final DateTime assignedAt;
  final String assignedBy;
  final String? reason;
  final bool active;

  AssignmentModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.truckPlate,
    required this.assignedAt,
    required this.assignedBy,
    this.reason,
    required this.active,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'],
      driverId: json['driverId'],
      driverName: json['driverName'],
      vehicleId: json['vehicleId'],
      truckPlate: json['truckPlate'],
      assignedAt: DateTime.parse(json['assignedAt']),
      assignedBy: json['assignedBy'],
      reason: json['reason'],
      active: json['active'],
    );
  }
}
