-- Comprehensive Permission System Update
-- This migration adds all permissions used in the frontend application

-- Dashboard
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('dashboard:read', 'View dashboard', 'dashboard', 'read');

-- Customer
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('customer:read', 'View customers', 'customer', 'read'),
('customer:list', 'List all customers', 'customer', 'list'),
('customer:create', 'Create customers', 'customer', 'create'),
('customer:update', 'Update customers', 'customer', 'update'),
('customer:delete', 'Delete customers', 'customer', 'delete');

-- Vendor
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('vendor:read', 'View vendors', 'vendor', 'read'),
('vendor:list', 'List all vendors', 'vendor', 'list'),
('vendor:create', 'Create vendors', 'vendor', 'create'),
('vendor:update', 'Update vendors', 'vendor', 'update'),
('vendor:delete', 'Delete vendors', 'vendor', 'delete');

-- Subcontractor
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('subcontractor:read', 'View subcontractors', 'subcontractor', 'read'),
('subcontractor:admin:read', 'View subcontractor admins', 'subcontractor', 'admin:read');

-- Item
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('item:read', 'View items', 'item', 'read'),
('item:list', 'List all items', 'item', 'list'),
('item:create', 'Create items', 'item', 'create'),
('item:update', 'Update items', 'item', 'update'),
('item:delete', 'Delete items', 'item', 'delete');

-- Shipment
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('shipment:read', 'View shipments', 'shipment', 'read'),
('shipment:list', 'List all shipments', 'shipment', 'list'),
('shipment:create', 'Create shipments', 'shipment', 'create'),
('shipment:update', 'Update shipments', 'shipment', 'update'),
('shipment:delete', 'Delete shipments', 'shipment', 'delete'),
('shipment:upload', 'Bulk upload shipments', 'shipment', 'upload');

-- Trip (Dispatch)
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('trip:read', 'View trips', 'trip', 'read'),
('trip:plan', 'Plan trips', 'trip', 'plan'),
('trip:monitor', 'Monitor trips', 'trip', 'monitor'),
('trip:pod', 'View proof of delivery', 'trip', 'pod');

-- Fleet
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('fleet:read', 'View fleet', 'fleet', 'read'),
('fleet:management:read', 'View fleet management', 'fleet', 'management:read');

-- Driver (Comprehensive)
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('driver:read', 'View drivers', 'driver', 'read'),
('driver:list', 'List all drivers', 'driver', 'list'),
('driver:create', 'Create drivers', 'driver', 'create'),
('driver:update', 'Update drivers', 'driver', 'update'),
('driver:delete', 'Delete drivers', 'driver', 'delete'),
('driver:manage', 'Manage drivers', 'driver', 'manage'),
('driver:view_all', 'View all drivers', 'driver', 'view_all'),
('driver:document:read', 'View driver documents', 'driver', 'document:read'),
('driver:shift:read', 'View driver shifts', 'driver', 'shift:read'),
('driver:account:read', 'View driver accounts', 'driver', 'account:read'),
('driver:performance:read', 'View driver performance', 'driver', 'performance:read'),
('driver:device:read', 'View driver devices', 'driver', 'device:read'),
('driver:attendance:read', 'View driver attendance', 'driver', 'attendance:read'),
('driver:live:read', 'View driver live GPS tracking', 'driver', 'live:read');

-- Vehicle
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('vehicle:read', 'View vehicles', 'vehicle', 'read'),
('vehicle:create', 'Create vehicles', 'vehicle', 'create'),
('vehicle:update', 'Update vehicles', 'vehicle', 'update'),
('vehicle:delete', 'Delete vehicles', 'vehicle', 'delete');

-- Trailer
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('trailer:read', 'View trailers', 'trailer', 'read'),
('trailer:create', 'Create trailers', 'trailer', 'create'),
('trailer:update', 'Update trailers', 'trailer', 'update'),
('trailer:delete', 'Delete trailers', 'trailer', 'delete');

-- Maintenance
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('maintenance:read', 'View maintenance', 'maintenance', 'read'),
('maintenance:schedule:read', 'View maintenance schedules', 'maintenance', 'schedule:read'),
('maintenance:workorder:read', 'View work orders', 'maintenance', 'workorder:read'),
('maintenance:repair:read', 'View repairs', 'maintenance', 'repair:read'),
('maintenance:part:read', 'View parts inventory', 'maintenance', 'part:read'),
('maintenance:record:read', 'View maintenance records', 'maintenance', 'record:read');

-- Order (Legacy - for backward compatibility)
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('order:read', 'View orders', 'order', 'read'),
('order:create', 'Create orders', 'order', 'create'),
('order:update', 'Update orders', 'order', 'update'),
('order:assign', 'Assign orders', 'order', 'assign');

-- Dispatch (Legacy - for backward compatibility)
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('dispatch:read', 'View dispatch', 'dispatch', 'read'),
('dispatch:create', 'Create dispatch', 'dispatch', 'create'),
('dispatch:update', 'Update dispatch', 'dispatch', 'update'),
('dispatch:monitor', 'Monitor dispatch', 'dispatch', 'monitor');

-- Proof of Delivery
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('pod:read', 'View proof of delivery', 'pod', 'read');

-- Reports
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('report:read', 'View reports', 'report', 'read'),
('report:dispatch:day', 'View dispatch day report', 'report', 'dispatch:day'),
('report:driver_performance', 'View driver performance report', 'report', 'driver_performance');

-- Administration
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('admin:read', 'View administration', 'admin', 'read'),
('admin:user:read', 'View user management', 'admin', 'user:read'),
('admin:role:read', 'View role management', 'admin', 'role:read'),
('admin:permission:read', 'View permission management', 'admin', 'permission:read');

-- Notification
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('notification:read', 'View notifications', 'notification', 'read'),
('notification:create', 'Create notifications', 'notification', 'create'),
('notification:update', 'Update notifications', 'notification', 'update'),
('notification:delete', 'Delete notifications', 'notification', 'delete');

-- Banner
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('banner:read', 'View banners', 'banner', 'read'),
('banner:create', 'Create banners', 'banner', 'create'),
('banner:update', 'Update banners', 'banner', 'update'),
('banner:delete', 'Delete banners', 'banner', 'delete');

-- Issue Management
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('issue:read', 'View issues', 'issue', 'read'),
('issue:list', 'List all issues', 'issue', 'list'),
('issue:create', 'Create issues', 'issue', 'create'),
('issue:update', 'Update issues', 'issue', 'update'),
('issue:delete', 'Delete issues', 'issue', 'delete'),
('issue:assign', 'Assign issues', 'issue', 'assign'),
('issue:resolve', 'Resolve issues', 'issue', 'resolve');

-- Settings (Comprehensive)
INSERT IGNORE INTO permissions (name, description, resource_type, action_type) VALUES
('setting:read', 'View settings', 'setting', 'read'),
('setting:create', 'Create settings', 'setting', 'create'),
('setting:update', 'Update settings', 'setting', 'update'),
('setting:delete', 'Delete settings', 'setting', 'delete'),
('setting:system.core:read', 'View system core settings', 'setting', 'system.core:read'),
('setting:security.auth:read', 'View security auth settings', 'setting', 'security.auth:read'),
('setting:feature.flags:read', 'View feature flags', 'setting', 'feature.flags:read'),
('setting:maps.google:read', 'View Google Maps settings', 'setting', 'maps.google:read'),
('setting:uploads.storage:read', 'View upload storage settings', 'setting', 'uploads.storage:read'),
('setting:notifications:read', 'View notification settings', 'setting', 'notifications:read'),
('setting:finance:read', 'View finance settings', 'setting', 'finance:read'),
('setting:branding.theme:read', 'View branding theme settings', 'setting', 'branding.theme:read'),
('setting:i18n.locale:read', 'View internationalization settings', 'setting', 'i18n.locale:read'),
('setting:audit:read', 'View audit settings', 'setting', 'audit:read'),
('setting:import-export:read', 'View import/export settings', 'setting', 'import-export:read');

-- Grant all new permissions to ADMIN and SUPERADMIN roles
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r 
CROSS JOIN permissions p 
WHERE r.name IN ('ADMIN', 'SUPERADMIN')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
);

-- Grant read-only permissions to MANAGER role
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r 
CROSS JOIN permissions p 
WHERE r.name = 'MANAGER'
AND p.action_type IN ('read', 'list', 'view')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
);

-- Grant basic permissions to DISPATCHER role
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r 
CROSS JOIN permissions p 
WHERE r.name = 'DISPATCHER'
AND p.name IN (
    'dashboard:read',
    'shipment:read', 'shipment:list',
    'trip:read', 'trip:plan', 'trip:monitor', 'trip:pod',
    'driver:read', 'driver:list', 'driver:live:read',
    'vehicle:read',
    'dispatch:read', 'dispatch:create', 'dispatch:update', 'dispatch:monitor',
    'order:read',
    'customer:read', 'customer:list'
)
AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
);
