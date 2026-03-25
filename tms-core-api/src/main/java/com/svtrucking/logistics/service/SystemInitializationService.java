package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.PermissionRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.PermissionNames;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.context.event.EventListener;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * Comprehensive service for initializing all permissions, roles, and users
 * for a complete user permission system.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SystemInitializationService {

    private final PermissionRepository permissionRepository;
    private final RoleRepository roleRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final DynamicPermissionService dynamicPermissionService;
    private final Environment environment;

    @Value("${app.system.init.enabled:true}")
    private boolean systemInitEnabled;

    /**
     * Check if the system is initialized
     */
    public boolean isSystemInitialized() {
        try {
            // Check if all required roles exist (not just any roles)
            RoleType[] requiredRoles = {
                    RoleType.SUPERADMIN, RoleType.ADMIN, RoleType.MANAGER,
                    RoleType.DRIVER, RoleType.CUSTOMER, RoleType.USER
            };

            for (RoleType roleType : requiredRoles) {
                if (!roleRepository.findByName(roleType).isPresent()) {
                    log.debug("🔍 Missing required role: {}", roleType);
                    return false;
                }
            }

            // Check if permissions exist (we need a substantial number)
            long permissionCount = permissionRepository.count();
            if (permissionCount < 60) { // We expect 60+ permissions
                log.debug("🔍 Insufficient permissions: {} (expected 60+)", permissionCount);
                return false;
            }

            // Check if admin users exist
            boolean hasUsers = userRepository.count() > 0;
            if (!hasUsers) {
                log.debug("🔍 No users found");
                return false;
            }

            log.debug("System appears to be fully initialized");
            return true;
        } catch (Exception e) {
            log.error("Error checking system initialization status", e);
            return false;
        }
    }

    /**
     * Auto-initialize system on application startup if no data exists
     */
    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        if (!systemInitEnabled) {
            log.info("⏭️  System initialization is disabled (app.system.init.enabled=false)");
            return;
        }

        try {
            log.info("🔍 Checking if system initialization is needed...");

            if (!isSystemInitialized()) {
                log.warn("⚠️  System is not initialized. Starting automatic initialization...");
                initializeCompleteSystem();
                log.info("🎉 Automatic system initialization completed successfully!");
            } else {
                log.info("System is already initialized. Skipping automatic initialization.");
            }
        } catch (Exception e) {
            log.error("❌ Error during automatic system initialization", e);
            // Don't throw exception to prevent application startup failure
        }
    }

    /**
     * Initialize the complete permission system with all necessary data
     */
    @Transactional
    public void initializeCompleteSystem() {
        log.info("🚀 Starting complete system initialization...");

        // Step 1: Initialize all permissions
        initializeAllPermissions();

        // Step 2: Initialize all roles with proper permissions
        initializeAllRoles();

        // Step 3: Initialize default users
        initializeDefaultUsers();

        log.info("Complete system initialization finished successfully!");
    }

    /**
     * Initialize permissions only
     */
    @Transactional
    public void initializePermissions() {
        log.info("📋 Initializing permissions...");
        initializeAllPermissions();
        log.info("Permissions initialization completed");
    }

    /**
     * Initialize roles only
     */
    @Transactional
    public void initializeRoles() {
        log.info("👥 Initializing roles...");
        initializeAllRoles();
        log.info("Roles initialization completed");
    }

    /**
     * Initialize all permissions including core and extended permissions
     */
    @Transactional
    public void initializeAllPermissions() {
        log.info("📋 Initializing all permissions...");

        // Initialize core permissions first
        dynamicPermissionService.ensureCorePermissions();

        // Create the special all_functions permission for superadmin
        createAllFunctionsPermission();

        // Extended permissions for complete system functionality
        String[] extendedPermissions = {
                // Customer management
                "customer:read", "customer:create", "customer:update", "customer:delete",
                "customer:view_all", "customer:manage",

                // Item management
                "item:read", "item:create", "item:update", "item:delete",
                "item:manage", "item:import",

                // Shipment management
                "shipment:read", "shipment:create", "shipment:update", "shipment:delete",
                "shipment:assign", "shipment:track", "shipment:complete",

                // Order management
                "order:read", "order:create", "order:update", "order:delete",
                "order:assign", "order:track", "order:complete", "order:cancel",

                // Fleet management
                "fleet:read", "fleet:create", "fleet:update", "fleet:delete",
                "fleet:assign", "fleet:track", "fleet:maintenance",

                // Driver-specific permissions
                "driver:location:read", "driver:location:update",
                "driver:schedule:read", "driver:schedule:update",
                "driver:documents:read", "driver:documents:upload",
                "driver:profile:read", "driver:profile:update",
                "driver:view_all",

                // Vehicle-specific permissions
                "vehicle:maintenance:read", "vehicle:maintenance:create", "vehicle:maintenance:update",
                "vehicle:inspection:read", "vehicle:inspection:create", "vehicle:inspection:update",
                "vehicle:assignment:read", "vehicle:assignment:create", "vehicle:assignment:update",

                // Financial management
                "invoice:read", "invoice:create", "invoice:update", "invoice:delete",
                "invoice:approve", "invoice:send", "invoice:payment",
                "payment:read", "payment:create", "payment:update", "payment:process",

                // Reporting and analytics
                "report:driver_performance", "report:vehicle_utilization", "report:revenue",
                "report:customer_analysis", "report:route_optimization", "report:cost_analysis",
                "analytics:read", "analytics:create", "analytics:dashboard",

                // System administration
                "system:backup", "system:restore", "system:configuration",
                "system:logs:read", "system:logs:export", "system:monitoring",

                // Communication
                "notification:send", "notification:broadcast", "notification:schedule",
                "message:read", "message:send", "message:broadcast",

                // Document management
                "document:read", "document:upload", "document:download", "document:delete",
                "document:approve", "document:reject", "document:archive",

                // Location and tracking
                "location:read", "location:track", "location:geofence",
                "route:read", "route:create", "route:update", "route:optimize",

                // Dispatch management
                "dispatch:read", "dispatch:list", "dispatch:create", "dispatch:update", "dispatch:assign",
                "dispatch:delete", "dispatch:track", "dispatch:monitor", "dispatch:complete", "dispatch:emergency",

                // Device management
                "device:read", "device:list", "device:filter", "device:create", "device:update",
                "device:delete", "device:approve", "device:block", "device:status_update",

                // Partner management
                "partner:read", "partner:create", "partner:update", "partner:delete",

                // Vendor management
                "vendor:read", "vendor:create", "vendor:update", "vendor:delete",

                // Proof of delivery
                "pod:read"
        };

        for (String permissionName : extendedPermissions) {
            createPermissionIfNotExists(permissionName);
        }

        log.info("All permissions initialized successfully");
    }

    /**
     * Initialize all roles with appropriate permissions
     */
    @Transactional
    public void initializeAllRoles() {
        log.info("👥 Initializing all roles with permissions...");

        // SUPERADMIN - All permissions
        initializeSuperAdminRole();

        // ADMIN - Most administrative permissions
        initializeAdminRole();

        // MANAGER - Management and oversight permissions
        initializeManagerRole();

        // DRIVER - Driver-specific permissions
        initializeDriverRole();

        // CUSTOMER - Customer-specific permissions
        initializeCustomerRole();

        // USER - Basic user permissions
        initializeUserRole();

        log.info("All roles initialized successfully");
    }

    /**
     * Initialize default system users
     */
    @Transactional
    public void initializeDefaultUsers() {
        log.info("👤 Initializing default users...");

        // Create SUPERADMIN user
        createUserIfNotExists(
                "superadmin",
                "super123",
                "superadmin@svtms.com",
                "Super Administrator",
                RoleType.SUPERADMIN);

        // Create ADMIN user
        createUserIfNotExists(
                "admin",
                "admin123",
                "admin@svtms.com",
                "System Administrator",
                RoleType.ADMIN);

        // Create MANAGER user
        createUserIfNotExists(
                "manager",
                "manager123",
                "manager@svtms.com",
                "Operations Manager",
                RoleType.MANAGER);

        // Create sample DRIVER user
        createUserIfNotExists(
                "driver1",
                "driver123",
                "driver1@svtms.com",
                "Sample Driver",
                RoleType.DRIVER);

        // Create driver app smoke-test user
        createUserIfNotExists(
                "drivertest",
                "123456",
                "drivertest@svtms.com",
                "Driver Test",
                RoleType.DRIVER);

        // Create sample CUSTOMER user
        createUserIfNotExists(
                "customer1",
                "customer123",
                "customer1@example.com",
                "Sample Customer",
                RoleType.CUSTOMER);

        log.info("All default users initialized successfully");
    }

    // Helper methods for role initialization

    private void initializeSuperAdminRole() {
        Role role = createOrGetRole(RoleType.SUPERADMIN,
                "Super Administrator with unrestricted access to all system functions");

        // SUPERADMIN gets ALL permissions
        List<Permission> allPermissions = permissionRepository.findAll();
        role.getPermissions().clear();
        role.getPermissions().addAll(allPermissions);

        // Ensure all_functions permission is included (critical for authorization
        // bypass)
        Optional<Permission> allFunctions = permissionRepository.findByName(PermissionNames.ALL_FUNCTIONS);
        if (allFunctions.isPresent() && !role.getPermissions().contains(allFunctions.get())) {
            role.getPermissions().add(allFunctions.get());
            log.info("Added all_functions permission to SUPERADMIN role");
        }

        roleRepository.save(role);

        log.info("🔥 SUPERADMIN role configured with {} permissions (including all_functions wildcard)",
                allPermissions.size());
    }

    private void initializeAdminRole() {
        Role role = createOrGetRole(RoleType.ADMIN, "System Administrator with comprehensive management access");

        String[] adminPermissions = {
                // Core admin permissions
                "user:read", "user:create", "user:update", "user:delete",
                "role:read", "role:create", "role:update",
                "permission:read", "permission:create", "permission:update",

                // Management permissions
                "driver:read", "driver:messages:read", "driver:create", "driver:update", "driver:manage",
                "driver:documents:read", "driver:documents:upload",
                "driver:schedule:read", "driver:schedule:update",
                "driver:account_manage", "driver:view_all",
                "vehicle:read", "vehicle:create", "vehicle:update", "vehicle:delete",
                "customer:read", "customer:create", "customer:update", "customer:delete",
                "item:read", "item:create", "item:update", "item:delete",

                // Operational permissions
                "order:read", "order:create", "order:update", "order:assign",
                "shipment:read", "shipment:create", "shipment:update", "shipment:assign",
                "fleet:read", "fleet:create", "fleet:update", "fleet:assign",
                "dispatch:read", "dispatch:list", "dispatch:create", "dispatch:update", "dispatch:delete",
                "dispatch:monitor",
                "pod:read",

                // Financial permissions
                "invoice:read", "invoice:create", "invoice:update", "invoice:approve",
                "payment:read", "payment:create", "payment:update",

                // System permissions
                "system:configuration", "system:logs:read", "system:monitoring",
                "report:read", "report:create", "analytics:read", "analytics:create",
                "notification:read", "notification:create", "notification:send",
                "document:read", "document:upload", "document:approve",
                "audit:read", "audit:create", "settings:read", "settings:update"
        };

        assignPermissionsToRole(role, adminPermissions);
        log.info("👨‍💼 ADMIN role configured with {} permissions", adminPermissions.length);
    }

    private void initializeManagerRole() {
        Role role = createOrGetRole(RoleType.MANAGER, "Operations Manager with oversight and coordination access");

        String[] managerPermissions = {
                // Viewing permissions
                "user:read", "driver:read", "vehicle:read", "customer:read",
                "item:read", "item:create", "item:update",

                // Management permissions
                "order:read", "order:create", "order:update", "order:assign",
                "shipment:read", "shipment:create", "shipment:update", "shipment:assign", "shipment:track",
                "fleet:read", "fleet:assign", "fleet:track",
                "driver:manage", "driver:schedule:update",
                "driver:view_all",

                // Operational permissions
                "dispatch:read", "dispatch:list", "dispatch:create", "dispatch:update", "dispatch:delete",
                "dispatch:assign", "dispatch:monitor",
                "pod:read",
                "route:read", "route:create", "route:update", "route:optimize",
                "location:read", "location:track",

                // Communication
                "notification:read", "notification:send", "message:read", "message:send", "driver:messages:read",

                // Reporting
                "report:read", "report:driver_performance", "report:vehicle_utilization",
                "analytics:read", "analytics:dashboard",

                // Documents
                "document:read", "document:upload", "document:approve"
        };

        assignPermissionsToRole(role, managerPermissions);
        log.info("📊 MANAGER role configured with {} permissions", managerPermissions.length);
    }

    private void initializeDriverRole() {
        Role role = createOrGetRole(RoleType.DRIVER, "Driver with mobile app and job-specific access");

        // Assign all_functions permission for full access
        Optional<Permission> allFunctions = permissionRepository.findByName(PermissionNames.ALL_FUNCTIONS);
        if (allFunctions.isPresent() && !role.getPermissions().contains(allFunctions.get())) {
            role.getPermissions().clear();
            role.getPermissions().add(allFunctions.get());
            roleRepository.save(role);
            log.info("🚚 DRIVER role configured with ALL_FUNCTIONS permission (full access)");
        } else {
            String[] driverPermissions = {
                    // Profile management
                    "driver:profile:read", "driver:profile:update",
                    "driver:documents:read", "driver:documents:upload",
                    // Location and tracking
                    "driver:location:read", "driver:location:update",
                    "location:read", "route:read",
                    // Job management
                    "order:read", "shipment:read", "shipment:track", "shipment:complete",
                    "job:read", "job:update",
                    // Schedule and assignments
                    "driver:schedule:read", "driver:schedule:update", "vehicle:assignment:read",
                    // Communication
                    "notification:read", "message:read", "message:send",
                    // Vehicle inspection
                    "vehicle:inspection:read", "vehicle:inspection:create",
                    // Documents and proof of delivery
                    "document:read", "document:upload"
            };
            assignPermissionsToRole(role, driverPermissions);
            log.info("🚚 DRIVER role configured with {} permissions", driverPermissions.length);
        }
    }

    private void initializeCustomerRole() {
        Role role = createOrGetRole(RoleType.CUSTOMER, "Customer with order tracking and account management access");

        String[] customerPermissions = {
                // Order management
                "order:read", "order:create",

                // Shipment tracking
                "shipment:read", "shipment:track",

                // Profile management
                "customer:read", "customer:update",

                // Communication
                "notification:read", "message:read", "message:send",

                // Documents
                "document:read", "document:download",

                // Invoicing and payments
                "invoice:read", "payment:read"
        };

        assignPermissionsToRole(role, customerPermissions);
        log.info("🏢 CUSTOMER role configured with {} permissions", customerPermissions.length);
    }

    private void initializeUserRole() {
        Role role = createOrGetRole(RoleType.USER, "Basic user with minimal system access");

        String[] userPermissions = {
                // Basic read permissions
                "user:read", "notification:read", "item:read"
        };

        assignPermissionsToRole(role, userPermissions);
        log.info("👤 USER role configured with {} permissions", userPermissions.length);
    }

    // Utility methods

    private void createPermissionIfNotExists(String permissionName) {
        Optional<Permission> existing = permissionRepository.findByName(permissionName);
        if (existing.isEmpty()) {
            Permission permission = new Permission();
            permission.setName(permissionName);

            // Parse resource:action format
            String[] parts = permissionName.split(":");
            if (parts.length >= 2) {
                permission.setResourceType(capitalizeFirst(parts[0]));
                permission.setActionType(parts[1]);
                permission.setDescription("Auto-generated permission for " + permissionName);
            } else {
                permission.setResourceType("System");
                permission.setActionType("execute");
                permission.setDescription("System permission: " + permissionName);
            }

            permissionRepository.save(permission);
            log.debug("Created permission: {}", permissionName);
        }
    }

    private Role createOrGetRole(RoleType roleType, String description) {
        Optional<Role> existing = roleRepository.findByName(roleType);
        if (existing.isPresent()) {
            return existing.get();
        }

        Role role = new Role();
        role.setName(roleType);
        role.setDescription(description);
        return roleRepository.save(role);
    }

    private void assignPermissionsToRole(Role role, String[] permissionNames) {
        role.getPermissions().clear();

        // Batch fetch all permissions in one query to avoid N+1 problem
        List<Permission> permissions = permissionRepository.findByNameIn(Arrays.asList(permissionNames));
        role.getPermissions().addAll(permissions);

        roleRepository.save(role);
    }

    private void createUserIfNotExists(String username, String password, String email, String fullName,
            RoleType roleType) {
        Optional<Role> role = roleRepository.findByName(roleType);
        if (role.isEmpty()) {
            log.error("Role not found: {}", roleType);
            return;
        }

        Optional<User> existing = userRepository.findByUsernameWithRoles(username);
        if (existing.isEmpty()) {
            User user = new User();
            user.setUsername(username);
            user.setPassword(passwordEncoder.encode(password));
            user.setEmail(email);
            user.getRoles().add(role.get());

            userRepository.save(user);
            log.info("Created user: {} with role: {}", username, roleType);
            return;
        }

        User user = existing.get();
        boolean changed = false;

        // Repair imported/bad plaintext password for known default users in dev/local init.
        if (!looksLikeBcrypt(user.getPassword())) {
            user.setPassword(passwordEncoder.encode(password));
            changed = true;
            log.warn("Repaired non-bcrypt password for default user: {}", username);
        }

        if (shouldRepairDefaultPassword(user.getPassword(), password)) {
            user.setPassword(passwordEncoder.encode(password));
            changed = true;
            log.warn("Reset default password for local/dev user: {}", username);
        }

        if (!user.getRoles().contains(role.get())) {
            user.getRoles().add(role.get());
            changed = true;
            log.info("Added missing role {} to user {}", roleType, username);
        }

        if (changed) {
            userRepository.save(user);
        } else {
            log.debug("User already exists and is valid: {}", username);
        }
    }

    private boolean looksLikeBcrypt(String encodedPassword) {
        if (encodedPassword == null) {
            return false;
        }
        return encodedPassword.startsWith("$2a$")
                || encodedPassword.startsWith("$2b$")
                || encodedPassword.startsWith("$2y$");
    }

    private boolean shouldRepairDefaultPassword(String encodedPassword, String expectedRawPassword) {
        if (!environment.acceptsProfiles(Profiles.of("dev", "local"))) {
            return false;
        }
        if (!looksLikeBcrypt(encodedPassword)) {
            return false;
        }
        return !passwordEncoder.matches(expectedRawPassword, encodedPassword);
    }

    private String capitalizeFirst(String str) {
        if (str == null || str.isEmpty()) {
            return str;
        }
        return str.substring(0, 1).toUpperCase() + str.substring(1);
    }

    /**
     * Creates the special all_functions permission that grants access to
     * everything.
     * This is used by SUPERADMIN role for unrestricted access.
     */
    private void createAllFunctionsPermission() {
        Optional<Permission> existing = permissionRepository.findByName(PermissionNames.ALL_FUNCTIONS);
        if (existing.isEmpty()) {
            Permission allFunctions = new Permission();
            allFunctions.setName(PermissionNames.ALL_FUNCTIONS);
            allFunctions.setResourceType("System");
            allFunctions.setActionType("all");
            allFunctions.setDescription("Wildcard permission granting unrestricted access to all system functions");
            permissionRepository.save(allFunctions);
            log.info("Created all_functions wildcard permission");
        } else {
            log.debug("all_functions permission already exists");
        }
    }
}
