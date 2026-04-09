// Models for driver-facing maintenance data.
// Maps to the backend MaintenanceTask and MaintenanceRequest entities.

class MaintenanceTaskModel {
  final int id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String status; // PENDING, IN_PROGRESS, COMPLETED, OVERDUE
  final String? taskType;
  final int? vehicleId;
  final String? vehiclePlate;

  const MaintenanceTaskModel({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.dueDate,
    this.completedAt,
    this.taskType,
    this.vehicleId,
    this.vehiclePlate,
  });

  /// True when a task has an overdue date and is not yet completed.
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != 'COMPLETED';

  factory MaintenanceTaskModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceTaskModel(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      description: json['description']?.toString(),
      dueDate: _parseDate(json['dueDate']),
      completedAt: _parseDate(json['completedAt']),
      taskType: json['taskType']?.toString(),
      vehicleId:
          json['vehicleId'] != null ? (json['vehicleId'] as num).toInt() : null,
      vehiclePlate: json['vehiclePlate']?.toString() ??
          json['vehicle']?['licensePlate']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

class MaintenanceRequestModel {
  final int? id;
  final String? mrNumber;
  final String title;
  final String? description;
  final String priority; // LOW, MEDIUM, HIGH, CRITICAL
  final String status; // SUBMITTED, APPROVED, REJECTED, IN_PROGRESS, COMPLETED
  final String requestType; // REPAIR, PREVENTIVE, INSPECTION, EMERGENCY
  final DateTime? requestedAt;
  final int? vehicleId;

  const MaintenanceRequestModel({
    required this.title,
    required this.priority,
    required this.status,
    required this.requestType,
    this.id,
    this.mrNumber,
    this.description,
    this.requestedAt,
    this.vehicleId,
  });

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequestModel(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      mrNumber: json['mrNumber']?.toString() ?? json['code']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      priority: json['priority']?.toString() ?? 'MEDIUM',
      status: json['status']?.toString() ?? 'SUBMITTED',
      requestType: json['requestType']?.toString() ?? 'REPAIR',
      requestedAt: _parseDate(json['requestedAt'] ?? json['createdAt']),
      vehicleId:
          json['vehicleId'] != null ? (json['vehicleId'] as num).toInt() : null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'priority': priority,
        'requestType': requestType,
      };
}
