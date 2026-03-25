import 'package:tms_customer_app/models/package.dart';

class Booking {
  final String id;
  final bool isDraft;
  final int retryCount;
  final String? remoteId;
  final String title;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime createdAt;
  final String status;
  // syncStatus: pending | synced | failed
  final String syncStatus;
  final String? contactName;
  final String? contactPhone;
  final String? vehicleType;
  final String? serviceType;
  final String? truckType;
  final String? pickupCompany;
  final String? destinationCompany;
  final String? cargoType;
  final double? totalWeightTons;
  final double? totalVolumeCbm;
  final int? palletCount;
  final String? containerNo;
  final String? specialHandlingNotes;
  final String? receiverName;
  final String? receiverPhone;
  final int? capacity;
  final DateTime? pickupDateTime;
  final String? notes;
  final List<PackageItem>? packages;

  Booking({
    required this.id,
    this.isDraft = false,
    this.retryCount = 0,
    this.remoteId,
    required this.title,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.createdAt,
    this.status = 'pending',
    this.syncStatus = 'pending',
    this.contactName,
    this.contactPhone,
    this.vehicleType,
    this.capacity,
    this.pickupDateTime,
    this.notes,
    this.packages,
    this.serviceType,
    this.truckType,
    this.pickupCompany,
    this.destinationCompany,
    this.cargoType,
    this.totalWeightTons,
    this.totalVolumeCbm,
    this.palletCount,
    this.containerNo,
    this.specialHandlingNotes,
    this.receiverName,
    this.receiverPhone,
  });

  Booking copyWith({
    String? id,
    bool? isDraft,
    int? retryCount,
    String? remoteId,
    String? title,
    String? pickupAddress,
    String? dropoffAddress,
    DateTime? createdAt,
    String? status,
    String? syncStatus,
    String? contactName,
    String? contactPhone,
    String? vehicleType,
    String? serviceType,
    String? truckType,
    String? pickupCompany,
    String? destinationCompany,
    String? cargoType,
    double? totalWeightTons,
    double? totalVolumeCbm,
    int? palletCount,
    String? containerNo,
    String? specialHandlingNotes,
    String? receiverName,
    String? receiverPhone,
    int? capacity,
    DateTime? pickupDateTime,
    String? notes,
    List<PackageItem>? packages,
  }) {
    return Booking(
      id: id ?? this.id,
      isDraft: isDraft ?? this.isDraft,
      retryCount: retryCount ?? this.retryCount,
      remoteId: remoteId ?? this.remoteId,
      title: title ?? this.title,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      vehicleType: vehicleType ?? this.vehicleType,
      serviceType: serviceType ?? this.serviceType,
      truckType: truckType ?? this.truckType,
      pickupCompany: pickupCompany ?? this.pickupCompany,
      destinationCompany: destinationCompany ?? this.destinationCompany,
      cargoType: cargoType ?? this.cargoType,
      totalWeightTons: totalWeightTons ?? this.totalWeightTons,
      totalVolumeCbm: totalVolumeCbm ?? this.totalVolumeCbm,
      palletCount: palletCount ?? this.palletCount,
      containerNo: containerNo ?? this.containerNo,
      specialHandlingNotes: specialHandlingNotes ?? this.specialHandlingNotes,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      capacity: capacity ?? this.capacity,
      pickupDateTime: pickupDateTime ?? this.pickupDateTime,
      notes: notes ?? this.notes,
      packages: packages ?? this.packages,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      isDraft: json['isDraft'] as bool? ?? false,
      retryCount: json['retryCount'] is int
          ? json['retryCount'] as int
          : (json['retryCount'] != null
              ? int.tryParse(json['retryCount'].toString()) ?? 0
              : 0),
      remoteId: json['remoteId']?.toString(),
      title: json['title'] as String,
      pickupAddress: json['pickupAddress'] as String,
      dropoffAddress: json['dropoffAddress'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
      syncStatus: (json['syncStatus'] as String?) ?? 'pending',
      contactName: json['contactName'] as String?,
      contactPhone: json['contactPhone'] as String?,
      vehicleType: json['vehicleType'] as String?,
      serviceType: json['serviceType'] as String?,
      truckType: json['truckType'] as String?,
      pickupCompany: json['pickupCompany'] as String?,
      destinationCompany: json['destinationCompany'] as String?,
      cargoType: json['cargoType'] as String?,
      totalWeightTons: json['totalWeightTons'] is num
          ? (json['totalWeightTons'] as num).toDouble()
          : (json['totalWeightTons'] != null
              ? double.tryParse(json['totalWeightTons'].toString())
              : null),
      totalVolumeCbm: json['totalVolumeCbm'] is num
          ? (json['totalVolumeCbm'] as num).toDouble()
          : (json['totalVolumeCbm'] != null
              ? double.tryParse(json['totalVolumeCbm'].toString())
              : null),
      palletCount: json['palletCount'] is int
          ? json['palletCount'] as int
          : (json['palletCount'] != null
              ? int.tryParse(json['palletCount'].toString())
              : null),
      containerNo: json['containerNo'] as String?,
      specialHandlingNotes: json['specialHandlingNotes'] as String?,
      receiverName: json['receiverName'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
      capacity: json['capacity'] is int
          ? json['capacity'] as int
          : (json['capacity'] != null
              ? int.tryParse(json['capacity'].toString())
              : null),
      pickupDateTime: json['pickupDateTime'] != null
          ? DateTime.tryParse(json['pickupDateTime'].toString())
          : null,
      notes: json['notes'] as String?,
      packages: json['packages'] != null
          ? (json['packages'] as List<dynamic>)
              .map((e) => PackageItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isDraft': isDraft,
      'retryCount': retryCount,
      'remoteId': remoteId,
      'title': title,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'syncStatus': syncStatus,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'vehicleType': vehicleType,
      'capacity': capacity,
      'pickupDateTime': pickupDateTime?.toIso8601String(),
      'notes': notes,
      'packages': packages?.map((e) => e.toJson()).toList(),
      'serviceType': serviceType,
      'truckType': truckType,
      'pickupCompany': pickupCompany,
      'destinationCompany': destinationCompany,
      'cargoType': cargoType,
      'totalWeightTons': totalWeightTons,
      'totalVolumeCbm': totalVolumeCbm,
      'palletCount': palletCount,
      'containerNo': containerNo,
      'specialHandlingNotes': specialHandlingNotes,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
    };
  }

  @override
  String toString() => 'Booking($id, $title)';
}
