export const PERMISSIONS = {
  // Home Layout Management
  HOME_LAYOUT_MANAGE: 'home-layout:manage',
  // Dashboard
  DASHBOARD_READ: 'dashboard:read',

  // Customer
  CUSTOMER_READ: 'customer:read',
  CUSTOMER_LIST: 'customer:list',
  CUSTOMER_CREATE: 'customer:create',
  CUSTOMER_UPDATE: 'customer:update',
  CUSTOMER_DELETE: 'customer:delete',

  // Vendor
  VENDOR_READ: 'vendor:read',
  VENDOR_LIST: 'vendor:list',
  VENDOR_CREATE: 'vendor:create',
  VENDOR_UPDATE: 'vendor:update',
  VENDOR_DELETE: 'vendor:delete',

  // Subcontractor
  SUBCONTRACTOR_READ: 'subcontractor:read',
  SUBCONTRACTOR_ADMIN_READ: 'subcontractor:admin:read',

  // Item
  ITEM_READ: 'item:read',
  ITEM_LIST: 'item:list',
  ITEM_CREATE: 'item:create',
  ITEM_UPDATE: 'item:update',
  ITEM_DELETE: 'item:delete',

  // Shipment
  SHIPMENT_READ: 'shipment:read',
  SHIPMENT_LIST: 'shipment:list',
  SHIPMENT_CREATE: 'shipment:create',
  SHIPMENT_UPDATE: 'shipment:update',
  SHIPMENT_DELETE: 'shipment:delete',
  SHIPMENT_UPLOAD: 'shipment:upload',

  // Fleet
  FLEET_READ: 'fleet:read',
  FLEET_MANAGEMENT_READ: 'fleet:management:read',

  // Driver
  DRIVER_READ: 'driver:read',
  DRIVER_MESSAGES_READ: 'driver:messages:read',
  DRIVER_LIST: 'driver:list',
  DRIVER_CREATE: 'driver:create',
  DRIVER_UPDATE: 'driver:update',
  DRIVER_DELETE: 'driver:delete',
  DRIVER_MANAGE: 'driver:manage',
  DRIVER_VIEW_ALL: 'driver:view_all',
  DRIVER_DOCUMENT_READ: 'driver:document:read',
  DRIVER_SHIFT_READ: 'driver:shift:read',
  DRIVER_ACCOUNT_READ: 'driver:account:read',
  DRIVER_PERFORMANCE_READ: 'driver:performance:read',
  DRIVER_DEVICE_READ: 'driver:device:read',
  DRIVER_ATTENDANCE_READ: 'driver:attendance:read',
  DRIVER_LIVE_READ: 'driver:live:read',

  // Telematics (tms-telematics-api)
  TELEMATICS_LIVE_READ: 'telematics:live:read',
  TELEMATICS_GEOFENCE_READ: 'telematics:geofence:read',
  TELEMATICS_GEOFENCE_WRITE: 'telematics:geofence:write',
  TELEMATICS_CONSOLE_READ: 'telematics:console:read',

  // Geofence (legacy aliases — prefer TELEMATICS_GEOFENCE_*)
  GEOFENCE_READ: 'geofence:read',
  GEOFENCE_LIST: 'geofence:list',
  GEOFENCE_CREATE: 'geofence:create',
  GEOFENCE_UPDATE: 'geofence:update',
  GEOFENCE_DELETE: 'geofence:delete',

  // Legacy/Backward Compatibility (deprecated - use specific permissions above)
  DRIVER_DOCUMENTS_READ: 'driver:document:read',
  DRIVER_DOCUMENTS_UPLOAD: 'driver:document:upload',
  DRIVER_SCHEDULE_READ: 'driver:shift:read',
  DRIVER_SCHEDULE_UPDATE: 'driver:shift:update',
  DRIVER_ACCOUNT_MANAGE: 'driver:account:manage',

  // Vehicle
  VEHICLE_READ: 'vehicle:read',
  VEHICLE_CREATE: 'vehicle:create',
  VEHICLE_UPDATE: 'vehicle:update',
  VEHICLE_DELETE: 'vehicle:delete',

  // Trailer
  TRAILER_READ: 'trailer:read',
  TRAILER_CREATE: 'trailer:create',
  TRAILER_UPDATE: 'trailer:update',
  TRAILER_DELETE: 'trailer:delete',

  // Maintenance
  MAINTENANCE_READ: 'maintenance:read',
  MAINTENANCE_SCHEDULE_READ: 'maintenance:schedule:read',
  MAINTENANCE_WORKORDER_READ: 'maintenance:workorder:read',
  MAINTENANCE_WORKORDER_WRITE: 'maintenance:workorder:write',
  MAINTENANCE_REPAIR_READ: 'maintenance:repair:read',
  MAINTENANCE_PART_READ: 'maintenance:part:read',
  MAINTENANCE_RECORD_READ: 'maintenance:record:read',
  MAINTENANCE_PM_READ: 'maintenance:pm:read',
  MAINTENANCE_PM_WRITE: 'maintenance:pm:write',
  MAINTENANCE_FAILURE_CODE_READ: 'maintenance:failure-code:read',
  MAINTENANCE_FAILURE_CODE_WRITE: 'maintenance:failure-code:write',
  MAINTENANCE_ATTACHMENT_READ: 'maintenance:attachment:read',
  MAINTENANCE_ATTACHMENT_WRITE: 'maintenance:attachment:write',
  MAINTENANCE_VENDOR_APPROVE_HIGH: 'maintenance:vendor:approve:high',

  // Booking
  BOOKING_READ: 'booking:read',
  BOOKING_LIST: 'booking:list',
  BOOKING_CREATE: 'booking:create',
  BOOKING_UPDATE: 'booking:update',
  BOOKING_DELETE: 'booking:delete',
  BOOKING_CONFIRM: 'booking:confirm',
  BOOKING_CANCEL: 'booking:cancel',
  BOOKING_CONVERT: 'booking:convert',

  // Order (Legacy)
  ORDER_READ: 'order:read',
  ORDER_CREATE: 'order:create',
  ORDER_UPDATE: 'order:update',
  ORDER_ASSIGN: 'order:assign',

  // Dispatch
  DISPATCH_READ: 'dispatch:read',
  DISPATCH_LIST: 'dispatch:list',
  DISPATCH_CREATE: 'dispatch:create',
  DISPATCH_UPDATE: 'dispatch:update',
  DISPATCH_DELETE: 'dispatch:delete',
  DISPATCH_MONITOR: 'dispatch:monitor',
  DISPATCH_ASSIGN: 'dispatch:assign',
  DISPATCH_FLOW_MANAGE: 'dispatch:flow:manage',
  DISPATCH_STATUS_OVERRIDE: 'dispatch:status:override',
  DISPATCH_STATUS_MANUAL_UPDATE: 'dispatch:status:manual:update',

  // Proof of Delivery
  POD_READ: 'pod:read',

  // Reports
  REPORT_READ: 'report:read',
  REPORT_DISPATCH_DAY: 'report:dispatch:day',
  REPORT_DRIVER_PERFORMANCE: 'report:driver_performance',

  // Administration
  ADMIN_READ: 'admin:read',
  ADMIN_USER_READ: 'admin:user:read',
  ADMIN_ROLE_READ: 'admin:role:read',
  ADMIN_PERMISSION_READ: 'admin:permission:read',

  // User
  USER_READ: 'user:read',
  USER_CREATE: 'user:create',
  USER_UPDATE: 'user:update',
  USER_DELETE: 'user:delete',

  // Role
  ROLE_READ: 'role:read',
  ROLE_CREATE: 'role:create',
  ROLE_UPDATE: 'role:update',
  ROLE_DELETE: 'role:delete',

  // Notification
  NOTIFICATION_READ: 'notification:read',
  NOTIFICATION_CREATE: 'notification:create',
  NOTIFICATION_UPDATE: 'notification:update',
  NOTIFICATION_DELETE: 'notification:delete',

  // Banner
  BANNER_READ: 'banner:read',
  BANNER_CREATE: 'banner:create',
  BANNER_UPDATE: 'banner:update',
  BANNER_DELETE: 'banner:delete',

  // Issue Management
  ISSUE_READ: 'issue:read',
  ISSUE_LIST: 'issue:list',
  ISSUE_CREATE: 'issue:create',
  ISSUE_UPDATE: 'issue:update',
  ISSUE_DELETE: 'issue:delete',
  ISSUE_ASSIGN: 'issue:assign',
  ISSUE_RESOLVE: 'issue:resolve',

  // Incident Management
  INCIDENT_READ: 'incident:list',
  INCIDENT_LIST: 'incident:list',
  INCIDENT_CREATE: 'incident:create',
  INCIDENT_UPDATE: 'incident:update',
  INCIDENT_DELETE: 'incident:delete',
  INCIDENT_VALIDATE: 'incident:validate',
  INCIDENT_CLOSE: 'incident:close',
  INCIDENT_ESCALATE: 'incident:escalate',

  // Case Management
  CASE_READ: 'case:list',
  CASE_LIST: 'case:list',
  CASE_CREATE: 'case:create',
  CASE_UPDATE: 'case:update',
  CASE_DELETE: 'case:delete',
  CASE_ASSIGN: 'case:assign',
  CASE_CLOSE: 'case:close',
  CASE_TASK_CREATE: 'case:task:create',
  CASE_TASK_UPDATE: 'case:task:update',
  CASE_TASK_DELETE: 'case:task:delete',

  // Unified Task Management
  TASK_READ: 'task:read',
  TASK_CREATE: 'task:create',
  TASK_UPDATE: 'task:update',
  TASK_DELETE: 'task:delete',

  // Settings
  SETTING_READ: 'setting:read',
  SETTING_CREATE: 'setting:create',
  SETTING_UPDATE: 'setting:update',
  SETTING_DELETE: 'setting:delete',
  SETTING_SYSTEM_CORE_READ: 'setting:system.core:read',
  SETTING_SECURITY_AUTH_READ: 'setting:security.auth:read',
  SETTING_FEATURE_FLAGS_READ: 'setting:feature.flags:read',
  SETTING_MAPS_GOOGLE_READ: 'setting:maps.google:read',
  SETTING_UPLOADS_STORAGE_READ: 'setting:uploads.storage:read',
  SETTING_NOTIFICATIONS_READ: 'setting:notifications:read',
  SETTING_FINANCE_READ: 'setting:finance:read',
  SETTING_BRANDING_THEME_READ: 'setting:branding.theme:read',
  SETTING_I18N_LOCALE_READ: 'setting:i18n.locale:read',
  SETTING_AUDIT_READ: 'setting:audit:read',
  SETTING_IMPORT_EXPORT_READ: 'setting:import-export:read',
};
