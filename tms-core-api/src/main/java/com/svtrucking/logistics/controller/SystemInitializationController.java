package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.service.SystemInitializationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller for system initialization and management operations.
 * Only accessible by SUPERADMIN users.
 */
@RestController
@RequestMapping("/api/admin/system")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class SystemInitializationController {

    private final SystemInitializationService systemInitializationService;

    /**
     * Initialize complete system with all permissions, roles, and users
     */
    @PostMapping("/initialize")
    @PreAuthorize("@authorizationService.hasPermission('all_functions')")
    public ResponseEntity<ApiResponse<String>> initializeSystem() {
        try {
            log.info("Manual system initialization triggered by admin");
            systemInitializationService.initializeCompleteSystem();
            
            return ResponseEntity.ok(
                ApiResponse.success("System initialized successfully with all permissions, roles, and users")
            );
        } catch (Exception e) {
            log.error("Error during system initialization", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("System initialization failed: " + e.getMessage()));
        }
    }

    /**
     * Initialize only permissions
     */
    @PostMapping("/initialize/permissions")
    @PreAuthorize("@authorizationService.hasPermission('all_functions')")
    public ResponseEntity<ApiResponse<String>> initializePermissions() {
        try {
            log.info("Manual permission initialization triggered by admin");
            systemInitializationService.initializeAllPermissions();
            
            return ResponseEntity.ok(
                ApiResponse.success("All permissions initialized successfully")
            );
        } catch (Exception e) {
            log.error("Error during permission initialization", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Permission initialization failed: " + e.getMessage()));
        }
    }

    /**
     * Initialize only roles
     */
    @PostMapping("/initialize/roles")
    @PreAuthorize("@authorizationService.hasPermission('all_functions')")
    public ResponseEntity<ApiResponse<String>> initializeRoles() {
        try {
            log.info("Manual role initialization triggered by admin");
            systemInitializationService.initializeAllRoles();
            
            return ResponseEntity.ok(
                ApiResponse.success("All roles initialized successfully")
            );
        } catch (Exception e) {
            log.error("Error during role initialization", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Role initialization failed: " + e.getMessage()));
        }
    }

    /**
     * Initialize only default users
     */
    @PostMapping("/initialize/users")
    @PreAuthorize("@authorizationService.hasPermission('all_functions')")
    public ResponseEntity<ApiResponse<String>> initializeUsers() {
        try {
            log.info("Manual user initialization triggered by admin");
            systemInitializationService.initializeDefaultUsers();
            
            return ResponseEntity.ok(
                ApiResponse.success("Default users initialized successfully")
            );
        } catch (Exception e) {
            log.error("Error during user initialization", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("User initialization failed: " + e.getMessage()));
        }
    }

    /**
     * Get system initialization status
     */
    @GetMapping("/status")
    @PreAuthorize("@authorizationService.hasPermission('system:monitoring')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSystemStatus() {
        try {
            boolean isInitialized = systemInitializationService.isSystemInitialized();
            
            Map<String, Object> status = Map.of(
                "initialized", isInitialized,
                "message", isInitialized 
                    ? "System is fully initialized and operational" 
                    : "System requires initialization",
                "timestamp", System.currentTimeMillis(),
                "endpoints", Map.of(
                    "full_initialization", "/api/admin/system/initialize",
                    "permissions_only", "/api/admin/system/initialize/permissions",
                    "roles_only", "/api/admin/system/initialize/roles",
                    "users_only", "/api/admin/system/initialize/users"
                )
            );
            
            return ResponseEntity.ok(
                ApiResponse.success("System status retrieved", status)
            );
        } catch (Exception e) {
            log.error("Error getting system status", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Failed to get system status"));
        }
    }
}
