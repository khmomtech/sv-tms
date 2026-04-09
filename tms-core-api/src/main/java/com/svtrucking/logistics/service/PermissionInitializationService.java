package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.repository.PermissionRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.beans.factory.annotation.Value;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * Service to ensure all permissions defined in the frontend are present in the database.
 * This runs on application startup and creates any missing permissions.
 */
@Component
public class PermissionInitializationService implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(PermissionInitializationService.class);

    private final PermissionRepository permissionRepository;
    @Value("${permissions.init.enabled:true}")
    private boolean permissionsInitEnabled;

    public PermissionInitializationService(
            PermissionRepository permissionRepository,
            RoleRepository roleRepository) {
        this.permissionRepository = permissionRepository;
    }

    @Override
    @Transactional
    public void run(String... args) {
        if (!permissionsInitEnabled) {
            logger.info("🔐 Permission initialization skipped via permissions.init.enabled=false");
            return;
        }

        logger.info("🔐 Initializing permissions...");
        
        List<PermissionDefinition> requiredPermissions = getRequiredPermissions();
        int created = 0;
        int existing = 0;

        for (PermissionDefinition def : requiredPermissions) {
            Optional<Permission> existingPermission = permissionRepository.findByName(def.name);
            
            if (existingPermission.isEmpty()) {
                try {
                    Permission permission = new Permission();
                    permission.setName(def.name);
                    permission.setDescription(def.description);
                    permission.setResourceType(def.resourceType);
                    permission.setActionType(def.actionType);
                    permissionRepository.save(permission);
                    created++;
                    logger.debug("Created permission: {}", def.name);
                } catch (org.springframework.dao.DataIntegrityViolationException dive) {
                    // Another process might have inserted the same permission concurrently.
                    // Log and continue; the end state is the same (permission exists).
                    logger.warn("Permission '{}' creation race: {}", def.name, dive.getMessage());
                    existing++;
                } catch (Exception ex) {
                    logger.error("Failed to create permission {}: {}", def.name, ex.getMessage(), ex);
                }
            } else {
                existing++;
            }
        }

        logger.info("Permission initialization complete: {} created, {} existing", created, existing);
    }

    private List<PermissionDefinition> getRequiredPermissions() {
        return Arrays.asList(
            // Dashboard
            new PermissionDefinition("dashboard:read", "View dashboard", "dashboard", "read"),

            // Customer
            new PermissionDefinition("customer:read", "View customers", "customer", "read"),
            new PermissionDefinition("customer:list", "List all customers", "customer", "list"),
            new PermissionDefinition("customer:create", "Create customers", "customer", "create"),
            new PermissionDefinition("customer:update", "Update customers", "customer", "update"),
            new PermissionDefinition("customer:delete", "Delete customers", "customer", "delete"),

            // Vendor
            new PermissionDefinition("vendor:read", "View vendors", "vendor", "read"),
            new PermissionDefinition("vendor:list", "List all vendors", "vendor", "list"),
            new PermissionDefinition("vendor:create", "Create vendors", "vendor", "create"),
            new PermissionDefinition("vendor:update", "Update vendors", "vendor", "update"),
            new PermissionDefinition("vendor:delete", "Delete vendors", "vendor", "delete"),

            // Subcontractor
            new PermissionDefinition("subcontractor:read", "View subcontractors", "subcontractor", "read"),
            new PermissionDefinition("subcontractor:admin:read", "View subcontractor admins", "subcontractor", "admin:read"),

            // Item
            new PermissionDefinition("item:read", "View items", "item", "read"),
            new PermissionDefinition("item:list", "List all items", "item", "list"),
            new PermissionDefinition("item:create", "Create items", "item", "create"),
            new PermissionDefinition("item:update", "Update items", "item", "update"),
            new PermissionDefinition("item:delete", "Delete items", "item", "delete"),

            // Shipment
            new PermissionDefinition("shipment:read", "View shipments", "shipment", "read"),
            new PermissionDefinition("shipment:list", "List all shipments", "shipment", "list"),
            new PermissionDefinition("shipment:create", "Create shipments", "shipment", "create"),
            new PermissionDefinition("shipment:update", "Update shipments", "shipment", "update"),
            new PermissionDefinition("shipment:delete", "Delete shipments", "shipment", "delete"),
            new PermissionDefinition("shipment:upload", "Bulk upload shipments", "shipment", "upload"),

            // Trip
            new PermissionDefinition("trip:read", "View trips", "trip", "read"),
            new PermissionDefinition("trip:plan", "Plan trips", "trip", "plan"),
            new PermissionDefinition("trip:monitor", "Monitor trips", "trip", "monitor"),
            new PermissionDefinition("trip:pod", "View proof of delivery", "trip", "pod"),

            // Fleet
            new PermissionDefinition("fleet:read", "View fleet", "fleet", "read"),
            new PermissionDefinition("fleet:management:read", "View fleet management", "fleet", "management:read"),

            // Driver
            new PermissionDefinition("driver:read", "View drivers", "driver", "read"),
            new PermissionDefinition("driver:messages:read", "View driver messages", "driver", "messages:read"),
            new PermissionDefinition("driver:list", "List all drivers", "driver", "list"),
            new PermissionDefinition("driver:create", "Create drivers", "driver", "create"),
            new PermissionDefinition("driver:update", "Update drivers", "driver", "update"),
            new PermissionDefinition("driver:delete", "Delete drivers", "driver", "delete"),
            new PermissionDefinition("driver:manage", "Manage drivers", "driver", "manage"),
            new PermissionDefinition("driver:view_all", "View all drivers", "driver", "view_all"),
            new PermissionDefinition("driver:document:read", "View driver documents", "driver", "document:read"),
            new PermissionDefinition("driver:shift:read", "View driver shifts", "driver", "shift:read"),
            new PermissionDefinition("driver:account:read", "View driver accounts", "driver", "account:read"),
            new PermissionDefinition("driver:performance:read", "View driver performance", "driver", "performance:read"),
            new PermissionDefinition("driver:device:read", "View driver devices", "driver", "device:read"),
            new PermissionDefinition("driver:attendance:read", "View driver attendance", "driver", "attendance:read"),
            new PermissionDefinition("driver:live:read", "View driver live GPS tracking", "driver", "live:read"),

            // Vehicle
            new PermissionDefinition("vehicle:read", "View vehicles", "vehicle", "read"),
            new PermissionDefinition("vehicle:create", "Create vehicles", "vehicle", "create"),
            new PermissionDefinition("vehicle:update", "Update vehicles", "vehicle", "update"),
            new PermissionDefinition("vehicle:delete", "Delete vehicles", "vehicle", "delete"),

            // Trailer
            new PermissionDefinition("trailer:read", "View trailers", "trailer", "read"),
            new PermissionDefinition("trailer:create", "Create trailers", "trailer", "create"),
            new PermissionDefinition("trailer:update", "Update trailers", "trailer", "update"),
            new PermissionDefinition("trailer:delete", "Delete trailers", "trailer", "delete"),

            // Maintenance
            new PermissionDefinition("maintenance:read", "View maintenance", "maintenance", "read"),
            new PermissionDefinition("maintenance:schedule:read", "View maintenance schedules", "maintenance", "schedule:read"),
            new PermissionDefinition("maintenance:workorder:read", "View work orders", "maintenance", "workorder:read"),
            new PermissionDefinition("maintenance:repair:read", "View repairs", "maintenance", "repair:read"),
            new PermissionDefinition("maintenance:part:read", "View parts inventory", "maintenance", "part:read"),
            new PermissionDefinition("maintenance:record:read", "View maintenance records", "maintenance", "record:read"),

            // Order (Legacy)
            new PermissionDefinition("order:read", "View orders", "order", "read"),
            new PermissionDefinition("order:create", "Create orders", "order", "create"),
            new PermissionDefinition("order:update", "Update orders", "order", "update"),
            new PermissionDefinition("order:assign", "Assign orders", "order", "assign"),

            // Dispatch (Legacy)
            new PermissionDefinition("dispatch:read", "View dispatch", "dispatch", "read"),
            new PermissionDefinition("dispatch:create", "Create dispatch", "dispatch", "create"),
            new PermissionDefinition("dispatch:update", "Update dispatch", "dispatch", "update"),
            new PermissionDefinition("dispatch:monitor", "Monitor dispatch", "dispatch", "monitor"),
            new PermissionDefinition("dispatch:flow:manage", "Manage dispatch flow templates and transition policy", "dispatch", "flow:manage"),
            new PermissionDefinition("dispatch:status:override", "Override dispatch status outside normal policy", "dispatch", "status:override"),
            new PermissionDefinition("dispatch:status:manual:update", "Manual dispatch status update through admin channel", "dispatch", "status:manual:update"),

            // POD
            new PermissionDefinition("pod:read", "View proof of delivery", "pod", "read"),

            // Reports
            new PermissionDefinition("report:read", "View reports", "report", "read"),
            new PermissionDefinition("report:dispatch:day", "View dispatch day report", "report", "dispatch:day"),
            new PermissionDefinition("report:driver_performance", "View driver performance report", "report", "driver_performance"),

            // Administration
            new PermissionDefinition("admin:read", "View administration", "admin", "read"),
            new PermissionDefinition("admin:user:read", "View user management", "admin", "user:read"),
            new PermissionDefinition("admin:role:read", "View role management", "admin", "role:read"),
            new PermissionDefinition("admin:permission:read", "View permission management", "admin", "permission:read"),

            // User
            new PermissionDefinition("user:read", "View users", "user", "read"),
            new PermissionDefinition("user:create", "Create users", "user", "create"),
            new PermissionDefinition("user:update", "Update users", "user", "update"),
            new PermissionDefinition("user:delete", "Delete users", "user", "delete"),

            // Role
            new PermissionDefinition("role:read", "View roles", "role", "read"),
            new PermissionDefinition("role:create", "Create roles", "role", "create"),
            new PermissionDefinition("role:update", "Update roles", "role", "update"),
            new PermissionDefinition("role:delete", "Delete roles", "role", "delete"),

            // Permission
            new PermissionDefinition("permission:read", "View permissions", "permission", "read"),
            new PermissionDefinition("permission:create", "Create permissions", "permission", "create"),
            new PermissionDefinition("permission:update", "Update permissions", "permission", "update"),
            new PermissionDefinition("permission:delete", "Delete permissions", "permission", "delete"),

            // Notification
            new PermissionDefinition("notification:read", "View notifications", "notification", "read"),
            new PermissionDefinition("notification:create", "Create notifications", "notification", "create"),
            new PermissionDefinition("notification:update", "Update notifications", "notification", "update"),
            new PermissionDefinition("notification:delete", "Delete notifications", "notification", "delete"),

            // Banner
            new PermissionDefinition("banner:read", "View banners", "banner", "read"),
            new PermissionDefinition("banner:create", "Create banners", "banner", "create"),
            new PermissionDefinition("banner:update", "Update banners", "banner", "update"),
            new PermissionDefinition("banner:delete", "Delete banners", "banner", "delete"),

            // Issue Management
            new PermissionDefinition("issue:read", "View issues", "issue", "read"),
            new PermissionDefinition("issue:list", "List all issues", "issue", "list"),
            new PermissionDefinition("issue:create", "Create issues", "issue", "create"),
            new PermissionDefinition("issue:update", "Update issues", "issue", "update"),
            new PermissionDefinition("issue:delete", "Delete issues", "issue", "delete"),
            new PermissionDefinition("issue:assign", "Assign issues", "issue", "assign"),
            new PermissionDefinition("issue:resolve", "Resolve issues", "issue", "resolve"),

            // Settings
            new PermissionDefinition("setting:read", "View settings", "setting", "read"),
            new PermissionDefinition("setting:create", "Create settings", "setting", "create"),
            new PermissionDefinition("setting:update", "Update settings", "setting", "update"),
            new PermissionDefinition("setting:delete", "Delete settings", "setting", "delete"),
            new PermissionDefinition("setting:system.core:read", "View system core settings", "setting", "system.core:read"),
            new PermissionDefinition("setting:security.auth:read", "View security auth settings", "setting", "security.auth:read"),
            new PermissionDefinition("setting:feature.flags:read", "View feature flags", "setting", "feature.flags:read"),
            new PermissionDefinition("setting:maps.google:read", "View Google Maps settings", "setting", "maps.google:read"),
            new PermissionDefinition("setting:uploads.storage:read", "View upload storage settings", "setting", "uploads.storage:read"),
            new PermissionDefinition("setting:notifications:read", "View notification settings", "setting", "notifications:read"),
            new PermissionDefinition("setting:finance:read", "View finance settings", "setting", "finance:read"),
            new PermissionDefinition("setting:branding.theme:read", "View branding theme settings", "setting", "branding.theme:read"),
            new PermissionDefinition("setting:i18n.locale:read", "View internationalization settings", "setting", "i18n.locale:read"),
            new PermissionDefinition("setting:audit:read", "View audit settings", "setting", "audit:read"),
            new PermissionDefinition("setting:import-export:read", "View import/export settings", "setting", "import-export:read")
        );
    }

    /**
     * Internal class to define permission metadata
     */
    private static class PermissionDefinition {
        final String name;
        final String description;
        final String resourceType;
        final String actionType;

        PermissionDefinition(String name, String description, String resourceType, String actionType) {
            this.name = name;
            this.description = description;
            this.resourceType = resourceType;
            this.actionType = actionType;
        }
    }
}
