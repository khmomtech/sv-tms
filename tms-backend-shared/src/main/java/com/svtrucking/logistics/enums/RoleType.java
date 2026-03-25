package com.svtrucking.logistics.enums;

public enum RoleType {
  SUPERADMIN,  // Full system access - all permissions
  ADMIN,       // Internal staff with broad permissions
  MANAGER,     // Department/area managers
  TECHNICIAN,  // Workshop mechanics/technicians
  DRIVER,      // Driver mobile app users
  CUSTOMER,    // Customer portal users
  PARTNER_ADMIN, // Partner company administrators
  USER,        // Basic authenticated user
  SAFETY,      // Factory gate and safety verification team
  LOADING,     // Warehouse loading/queue operators
  DISPATCH_MONITOR // Control tower read-only monitoring
}
