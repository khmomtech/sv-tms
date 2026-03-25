package com.svtrucking.logistics.infrastructure.security;

/**
 * Central list of logical permission identifiers used in {@code @PreAuthorize} expressions and
 * guards. These strings must match the entries stored in the permissions table.
 *
 * Permission naming convention: resource:action
 * Examples: user:read, driver:create, vehicle:update, audit:read
 */
public final class PermissionNames {

  private PermissionNames() {}

  // Special wildcard permission for superadmin access to all functions
  public static final String ALL_FUNCTIONS = "all_functions";

  // User management permissions
  public static final String USER_READ = "user:read";
  public static final String USER_CREATE = "user:create";
  public static final String USER_UPDATE = "user:update";
  public static final String USER_DELETE = "user:delete";
  public static final String ADMIN_READ = "admin:read";
  public static final String ADMIN_USER_READ = "admin:user:read";

  // Role management permissions
  public static final String ROLE_READ = "role:read";
  public static final String ROLE_CREATE = "role:create";
  public static final String ROLE_UPDATE = "role:update";
  public static final String ROLE_DELETE = "role:delete";

  // Permission management permissions
  public static final String PERMISSION_READ = "permission:read";
  public static final String PERMISSION_CREATE = "permission:create";
  public static final String PERMISSION_UPDATE = "permission:update";
  public static final String PERMISSION_DELETE = "permission:delete";

  // Driver management permissions
  public static final String DRIVER_READ = "driver:read";
  public static final String DRIVER_CREATE = "driver:create";
  public static final String DRIVER_UPDATE = "driver:update";
  public static final String DRIVER_DELETE = "driver:delete";
  public static final String DRIVER_VIEW_ALL = "driver:view_all";
  public static final String DRIVER_MANAGE = "driver:manage";
  public static final String DRIVER_ACCOUNT_MANAGE = "driver:account_manage";

  // Device management permissions
  public static final String DEVICE_READ = "device:read";
  public static final String DEVICE_LIST = "device:list";
  public static final String DEVICE_FILTER = "device:filter";
  public static final String DEVICE_CREATE = "device:create";
  public static final String DEVICE_UPDATE = "device:update";
  public static final String DEVICE_DELETE = "device:delete";
  public static final String DEVICE_APPROVE = "device:approve";
  public static final String DEVICE_BLOCK = "device:block";
  public static final String DEVICE_STATUS_UPDATE = "device:status_update";

  // Vehicle management permissions
  public static final String VEHICLE_READ = "vehicle:read";
  public static final String VEHICLE_CREATE = "vehicle:create";
  public static final String VEHICLE_UPDATE = "vehicle:update";
  public static final String VEHICLE_DELETE = "vehicle:delete";

  // Dispatch / Trips
  public static final String DISPATCH_READ = "dispatch:read";
  public static final String DISPATCH_CREATE = "dispatch:create";
  public static final String DISPATCH_UPDATE = "dispatch:update";
  public static final String DISPATCH_ASSIGN = "dispatch:assign";
  public static final String DISPATCH_TRACK = "dispatch:track";
  public static final String DISPATCH_MONITOR = "dispatch:monitor";
  public static final String DISPATCH_COMPLETE = "dispatch:complete";
  public static final String DISPATCH_EMERGENCY = "dispatch:emergency";

  // Proof of Delivery
  public static final String POD_READ = "pod:read";

  // Job management permissions
  public static final String JOB_READ = "job:read";
  public static final String JOB_CREATE = "job:create";
  public static final String JOB_UPDATE = "job:update";
  public static final String JOB_DELETE = "job:delete";

  // Item management permissions
  public static final String ITEM_READ = "item:read";
  public static final String ITEM_CREATE = "item:create";
  public static final String ITEM_UPDATE = "item:update";
  public static final String ITEM_DELETE = "item:delete";

  // Audit trail permissions
  public static final String AUDIT_READ = "audit:read";
  public static final String AUDIT_CREATE = "audit:create";

  // Report permissions
  public static final String REPORT_READ = "report:read";
  public static final String REPORT_CREATE = "report:create";

  // Notification permissions
  public static final String NOTIFICATION_READ = "notification:read";
  public static final String NOTIFICATION_CREATE = "notification:create";

  // Settings permissions
  public static final String SETTINGS_READ = "settings:read";
  public static final String SETTINGS_UPDATE = "settings:update";

  // Image management permissions
  public static final String IMAGE_READ = "image:read";
  public static final String IMAGE_CREATE = "image:create";
  public static final String IMAGE_UPDATE = "image:update";
  public static final String IMAGE_DELETE = "image:delete";

  // Banner management permissions
  public static final String BANNER_READ = "banner:read";
  public static final String BANNER_CREATE = "banner:create";
  public static final String BANNER_UPDATE = "banner:update";
  public static final String BANNER_DELETE = "banner:delete";

  // Partner management permissions
  public static final String PARTNER_READ = "partner:read";
  public static final String PARTNER_CREATE = "partner:create";
  public static final String PARTNER_UPDATE = "partner:update";
  public static final String PARTNER_DELETE = "partner:delete";

  // Vendor management permissions
  public static final String VENDOR_READ = "vendor:read";
  public static final String VENDOR_CREATE = "vendor:create";
  public static final String VENDOR_UPDATE = "vendor:update";
  public static final String VENDOR_DELETE = "vendor:delete";

  // Maintenance (SV Standard)
  public static final String MAINTENANCE_READ = "maintenance:read";
  public static final String MAINTENANCE_SCHEDULE_READ = "maintenance:schedule:read";
  public static final String MAINTENANCE_WORKORDER_READ = "maintenance:workorder:read";
  public static final String MAINTENANCE_WORKORDER_WRITE = "maintenance:workorder:write";
  public static final String MAINTENANCE_REPAIR_READ = "maintenance:repair:read";
  public static final String MAINTENANCE_PART_READ = "maintenance:part:read";
  public static final String MAINTENANCE_RECORD_READ = "maintenance:record:read";
}
