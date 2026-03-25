package com.svtrucking.logistics.security;

/**
 * Central list of logical permission identifiers used in {@code @PreAuthorize}
 * expressions and guards. These strings must match the entries stored in the
 * permissions table.
 */
public final class PermissionNames {

  private PermissionNames() {}

  public static final String ALL_FUNCTIONS = "all_functions";

  public static final String USER_READ = "user:read";
  public static final String USER_CREATE = "user:create";
  public static final String USER_UPDATE = "user:update";
  public static final String USER_DELETE = "user:delete";
  public static final String ADMIN_READ = "admin:read";
  public static final String ADMIN_USER_READ = "admin:user:read";

  public static final String ROLE_READ = "role:read";
  public static final String ROLE_CREATE = "role:create";
  public static final String ROLE_UPDATE = "role:update";
  public static final String ROLE_DELETE = "role:delete";

  public static final String PERMISSION_READ = "permission:read";
  public static final String PERMISSION_CREATE = "permission:create";
  public static final String PERMISSION_UPDATE = "permission:update";
  public static final String PERMISSION_DELETE = "permission:delete";

  public static final String DRIVER_READ = "driver:read";
  public static final String DRIVER_CREATE = "driver:create";
  public static final String DRIVER_UPDATE = "driver:update";
  public static final String DRIVER_DELETE = "driver:delete";
  public static final String DRIVER_VIEW_ALL = "driver:view_all";
  public static final String DRIVER_MANAGE = "driver:manage";
  public static final String DRIVER_ACCOUNT_MANAGE = "driver:account_manage";

  public static final String DEVICE_READ = "device:read";
  public static final String DEVICE_LIST = "device:list";
  public static final String DEVICE_FILTER = "device:filter";
  public static final String DEVICE_CREATE = "device:create";
  public static final String DEVICE_UPDATE = "device:update";
  public static final String DEVICE_DELETE = "device:delete";
  public static final String DEVICE_APPROVE = "device:approve";
  public static final String DEVICE_BLOCK = "device:block";
  public static final String DEVICE_STATUS_UPDATE = "device:status_update";

  public static final String VEHICLE_READ = "vehicle:read";
  public static final String VEHICLE_CREATE = "vehicle:create";
  public static final String VEHICLE_UPDATE = "vehicle:update";
  public static final String VEHICLE_DELETE = "vehicle:delete";

  public static final String DISPATCH_READ = "dispatch:read";
  public static final String DISPATCH_CREATE = "dispatch:create";
  public static final String DISPATCH_UPDATE = "dispatch:update";
  public static final String DISPATCH_ASSIGN = "dispatch:assign";
  public static final String DISPATCH_TRACK = "dispatch:track";
  public static final String DISPATCH_MONITOR = "dispatch:monitor";
  public static final String DISPATCH_COMPLETE = "dispatch:complete";
  public static final String DISPATCH_EMERGENCY = "dispatch:emergency";
  public static final String DISPATCH_FLOW_MANAGE = "dispatch:flow:manage";
  public static final String DISPATCH_STATUS_OVERRIDE = "dispatch:status:override";
  public static final String DISPATCH_STATUS_MANUAL_UPDATE = "dispatch:status:manual:update";
  public static final String DISPATCH_REOPEN = "dispatch:reopen";

  public static final String POD_READ = "pod:read";

  public static final String JOB_READ = "job:read";
  public static final String JOB_CREATE = "job:create";
  public static final String JOB_UPDATE = "job:update";
  public static final String JOB_DELETE = "job:delete";

  public static final String ITEM_READ = "item:read";
  public static final String ITEM_CREATE = "item:create";
  public static final String ITEM_UPDATE = "item:update";
  public static final String ITEM_DELETE = "item:delete";

  public static final String AUDIT_READ = "audit:read";
  public static final String AUDIT_CREATE = "audit:create";

  public static final String REPORT_READ = "report:read";
  public static final String REPORT_CREATE = "report:create";

  public static final String NOTIFICATION_READ = "notification:read";
  public static final String NOTIFICATION_CREATE = "notification:create";

  public static final String SETTINGS_READ = "settings:read";
  public static final String SETTINGS_UPDATE = "settings:update";

  public static final String IMAGE_READ = "image:read";
  public static final String IMAGE_CREATE = "image:create";
  public static final String IMAGE_UPDATE = "image:update";
  public static final String IMAGE_DELETE = "image:delete";

  public static final String BANNER_READ = "banner:read";
  public static final String BANNER_CREATE = "banner:create";
  public static final String BANNER_UPDATE = "banner:update";
  public static final String BANNER_DELETE = "banner:delete";

  public static final String PARTNER_READ = "partner:read";
  public static final String PARTNER_CREATE = "partner:create";
  public static final String PARTNER_UPDATE = "partner:update";
  public static final String PARTNER_DELETE = "partner:delete";

  public static final String VENDOR_READ = "vendor:read";
  public static final String VENDOR_CREATE = "vendor:create";
  public static final String VENDOR_UPDATE = "vendor:update";
  public static final String VENDOR_DELETE = "vendor:delete";

  public static final String MAINTENANCE_READ = "maintenance:read";
  public static final String MAINTENANCE_SCHEDULE_READ = "maintenance:schedule:read";
  public static final String MAINTENANCE_WORKORDER_READ = "maintenance:workorder:read";
  public static final String MAINTENANCE_WORKORDER_WRITE = "maintenance:workorder:write";
  public static final String MAINTENANCE_REPAIR_READ = "maintenance:repair:read";
  public static final String MAINTENANCE_PART_READ = "maintenance:part:read";
  public static final String MAINTENANCE_RECORD_READ = "maintenance:record:read";
}
