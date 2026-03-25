enum VehicleType {
  TRUCK,
  BIG_TRUCK,
  SMALL_VAN,
  OTHER,
}

enum DriverStatus {
  online,
  offline,
  busy,
  idle,
}

class DriverUser {
  final String username;
  final String email;
  final List<String> roles;
  final int driverId;
  final String? zone;
  final VehicleType? vehicleType;
  final DriverStatus? status;

  DriverUser({
    required this.username,
    required this.email,
    required this.roles,
    required this.driverId,
    this.zone,
    this.vehicleType,
    this.status,
  });

  factory DriverUser.fromJson(Map<String, dynamic> json) {
    return DriverUser(
      username: json['username'],
      email: json['email'],
      roles: List<String>.from(json['roles'] ?? []),
      driverId: json['driverId'],
      zone: json['zone'],
      vehicleType: _parseVehicleType(json['vehicleType']),
      status: _parseDriverStatus(json['status']),
    );
  }

  static VehicleType? _parseVehicleType(String? value) {
    if (value == null) return null;
    return VehicleType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => VehicleType.OTHER,
    );
  }

  static DriverStatus? _parseDriverStatus(String? value) {
    if (value == null) return null;
    return DriverStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => DriverStatus.offline,
    );
  }
}

class DriverLoginResponse {
  final String token;
  final DriverUser user;

  DriverLoginResponse({
    required this.token,
    required this.user,
  });

  factory DriverLoginResponse.fromJson(Map<String, dynamic> json) {
    return DriverLoginResponse(
      token: json['token'],
      user: DriverUser.fromJson(json['user']),
    );
  }
}
