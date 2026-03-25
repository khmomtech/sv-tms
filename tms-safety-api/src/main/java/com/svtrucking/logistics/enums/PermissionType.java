package com.svtrucking.logistics.enums;

/**
 * Enum for core permission types that are essential for system operation.
 * These are the minimum permissions required and should always exist.
 * Additional permissions can be dynamically created via the admin interface.
 */
public enum PermissionType {
  // Core system permissions that must always exist
  ALL_FUNCTIONS("all_functions", "Global", "Superadmin wildcard access to all functions"),
  
  // User management - essential for admin operations
  USER_READ("user:read", "User", "View users"),
  USER_CREATE("user:create", "User", "Create new users"),
  USER_UPDATE("user:update", "User", "Update existing users"),
  USER_DELETE("user:delete", "User", "Delete users"),
  
  // Role management - essential for permission system
  ROLE_READ("role:read", "Role", "View roles"),
  ROLE_CREATE("role:create", "Role", "Create new roles"),
  ROLE_UPDATE("role:update", "Role", "Update existing roles"),
  ROLE_DELETE("role:delete", "Role", "Delete roles"),
  
  // Permission management - essential for security
  PERMISSION_READ("permission:read", "Permission", "View permissions"),
  PERMISSION_CREATE("permission:create", "Permission", "Create new permissions"),
  PERMISSION_UPDATE("permission:update", "Permission", "Update existing permissions"),
  PERMISSION_DELETE("permission:delete", "Permission", "Delete permissions"),
  
  // Extended core permissions for complete system
  DRIVER_READ("driver:read", "Driver", "View driver information"),
  DRIVER_CREATE("driver:create", "Driver", "Create new drivers"),
  DRIVER_UPDATE("driver:update", "Driver", "Update driver information"),
  DRIVER_DELETE("driver:delete", "Driver", "Delete drivers"),
  
  VEHICLE_READ("vehicle:read", "Vehicle", "View vehicle information"),
  VEHICLE_CREATE("vehicle:create", "Vehicle", "Create new vehicles"),
  VEHICLE_UPDATE("vehicle:update", "Vehicle", "Update vehicle information"),
  VEHICLE_DELETE("vehicle:delete", "Vehicle", "Delete vehicles"),
  
  CUSTOMER_READ("customer:read", "Customer", "View customer information"),
  CUSTOMER_CREATE("customer:create", "Customer", "Create new customers"),
  CUSTOMER_UPDATE("customer:update", "Customer", "Update customer information"),
  CUSTOMER_DELETE("customer:delete", "Customer", "Delete customers"),
  
  // Dispatch / Trips
  DISPATCH_READ("dispatch:read", "Dispatch", "View dispatches and trips"),
  DISPATCH_CREATE("dispatch:create", "Dispatch", "Create new dispatches/trips"),
  DISPATCH_UPDATE("dispatch:update", "Dispatch", "Update dispatches/trips"),
  DISPATCH_MONITOR("dispatch:monitor", "Dispatch", "Monitor live trips/dispatches"),

  // Proof of Delivery
  POD_READ("pod:read", "POD", "View proof of delivery records"),

  ORDER_READ("order:read", "Order", "View orders"),
  ORDER_CREATE("order:create", "Order", "Create new orders"),
  ORDER_UPDATE("order:update", "Order", "Update orders"),
  ORDER_DELETE("order:delete", "Order", "Delete orders"),
  
  AUDIT_READ("audit:read", "Audit", "View audit logs"),
  AUDIT_CREATE("audit:create", "Audit", "Create audit entries"),
  
  SETTINGS_READ("settings:read", "Settings", "View system settings"),
  SETTINGS_UPDATE("settings:update", "Settings", "Update system settings");

  private final String name;
  private final String resourceType;
  private final String description;

  PermissionType(String name, String resourceType, String description) {
    this.name = name;
    this.resourceType = resourceType;
    this.description = description;
  }

  public String getName() {
    return name;
  }

  public String getResourceType() {
    return resourceType;
  }

  public String getDescription() {
    return description;
  }

  /**
   * Extract action from permission name (e.g., "user:read" -> "read")
   */
  public String getActionType() {
    String[] parts = name.split(":");
    return parts.length > 1 ? parts[1] : "execute";
  }
}
