package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.requests.CreatePermissionRequest;
import com.svtrucking.logistics.dto.requests.UpdatePermissionRequest;
import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.service.DynamicPermissionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Enhanced permission controller that supports dynamic permission management.
 * Allows admins to create, update, and manage permissions at runtime.
 */
@RestController
@RequestMapping("/api/admin/dynamic-permissions")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class DynamicPermissionController {

    private final DynamicPermissionService dynamicPermissionService;

    /**
     * Get all available permission names
     */
    @GetMapping("/names")
    @PreAuthorize("@authorizationService.hasPermission('permission:read')")
    public ResponseEntity<ApiResponse<Set<String>>> getAllPermissionNames() {
        try {
            Set<String> permissionNames = dynamicPermissionService.getAllPermissionNames();
            return ResponseEntity.ok(ApiResponse.success("Permission names retrieved successfully", permissionNames));
        } catch (Exception e) {
            log.error("Error retrieving permission names", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Failed to retrieve permission names"));
        }
    }

    /**
     * Get permissions by resource type
     */
    @GetMapping("/by-resource/{resourceType}")
    @PreAuthorize("@authorizationService.hasPermission('permission:read')")
    public ResponseEntity<ApiResponse<List<Permission>>> getPermissionsByResource(@PathVariable String resourceType) {
        try {
            List<Permission> permissions = dynamicPermissionService.getPermissionsByResourceType(resourceType);
            return ResponseEntity.ok(ApiResponse.success("Permissions retrieved successfully", permissions));
        } catch (Exception e) {
            log.error("Error retrieving permissions for resource: {}", resourceType, e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Failed to retrieve permissions for resource"));
        }
    }

    /**
     * Create a new dynamic permission
     */
    @PostMapping
    @PreAuthorize("@authorizationService.hasPermission('permission:create')")
    public ResponseEntity<ApiResponse<Permission>> createPermission(@Valid @RequestBody CreatePermissionRequest request) {
        try {
            Permission permission = dynamicPermissionService.createPermission(
                request.getName(),
                request.getDescription(),
                request.getResourceType(),
                request.getActionType()
            );
            
            log.info("Created dynamic permission: {} by admin", request.getName());
            return ResponseEntity.ok(ApiResponse.success("Permission created successfully", permission));
            
        } catch (IllegalArgumentException e) {
            log.warn("Invalid permission creation request: {}", e.getMessage());
            return ResponseEntity.badRequest()
                .body(ApiResponse.fail(e.getMessage()));
        } catch (Exception e) {
            log.error("Error creating permission", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Failed to create permission"));
        }
    }

    /**
     * Update existing permission
     */
    @PutMapping("/{id}")
    @PreAuthorize("@authorizationService.hasPermission('permission:update')")
    public ResponseEntity<ApiResponse<Permission>> updatePermission(
            @PathVariable Long id,
            @Valid @RequestBody UpdatePermissionRequest request) {
        try {
            Permission permission = dynamicPermissionService.updatePermission(
                id,
                request.getDescription(),
                request.getResourceType(),
                request.getActionType()
            );
            
            log.info("Updated permission ID: {} by admin", id);
            return ResponseEntity.ok(ApiResponse.success("Permission updated successfully", permission));
            
        } catch (IllegalArgumentException e) {
            log.warn("Invalid permission update request: {}", e.getMessage());
            return ResponseEntity.badRequest()
                .body(ApiResponse.fail(e.getMessage()));
        } catch (Exception e) {
            log.error("Error updating permission", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Failed to update permission"));
        }
    }

    /**
     * Delete permission (only dynamic permissions)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("@authorizationService.hasPermission('permission:delete')")
    public ResponseEntity<ApiResponse<String>> deletePermission(@PathVariable Long id) {
        try {
            dynamicPermissionService.deletePermission(id);
            
            log.info("Deleted dynamic permission ID: {} by admin", id);
            return ResponseEntity.ok(ApiResponse.success("Permission deleted successfully"));
            
        } catch (IllegalStateException e) {
            log.warn("Cannot delete core permission: {}", e.getMessage());
            return ResponseEntity.badRequest()
                .body(ApiResponse.fail(e.getMessage()));
        } catch (IllegalArgumentException e) {
            log.warn("Permission not found: {}", e.getMessage());
            return ResponseEntity.badRequest()
                .body(ApiResponse.fail(e.getMessage()));
        } catch (Exception e) {
            log.error("Error deleting permission", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Failed to delete permission"));
        }
    }

    /**
     * Check if permission exists
     */
    @GetMapping("/exists/{name}")
    @PreAuthorize("@authorizationService.hasPermission('permission:read')")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> checkPermissionExists(@PathVariable String name) {
        try {
            boolean exists = dynamicPermissionService.permissionExists(name);
            Map<String, Boolean> response = Map.of("exists", exists);
            return ResponseEntity.ok(ApiResponse.success("Permission existence checked", response));
        } catch (Exception e) {
            log.error("Error checking permission existence", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Failed to check permission existence"));
        }
    }

    /**
     * Clear permission cache (for admin use)
     */
    @PostMapping("/clear-cache")
    @PreAuthorize("@authorizationService.hasPermission('permission:update')")
    public ResponseEntity<ApiResponse<String>> clearCache() {
        try {
            dynamicPermissionService.clearCache();
            log.info("Permission cache cleared by admin");
            return ResponseEntity.ok(ApiResponse.success("Permission cache cleared successfully"));
        } catch (Exception e) {
            log.error("Error clearing permission cache", e);
            return ResponseEntity.internalServerError()
                .body(ApiResponse.fail("Failed to clear permission cache"));
        }
    }
}
