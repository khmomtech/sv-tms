package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.PermissionType;
import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.repository.PermissionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Enhanced permission service that supports both static core permissions
 * and dynamic runtime permissions managed via admin interface.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DynamicPermissionService {

    private final PermissionRepository permissionRepository;

    /**
     * Get all available permission names (cached for performance)
     */
    @Cacheable(value = "permissions", key = "'all-names'")
    public Set<String> getAllPermissionNames() {
        return permissionRepository.findAll()
            .stream()
            .map(Permission::getName)
            .collect(Collectors.toSet());
    }

    /**
     * Check if a permission exists by name
     */
    @Cacheable(value = "permissions", key = "#name")
    public boolean permissionExists(String name) {
        return permissionRepository.findByName(name).isPresent();
    }

    /**
     * Get permission by name
     */
    @Cacheable(value = "permissions", key = "#name")
    public Optional<Permission> getPermissionByName(String name) {
        return permissionRepository.findByName(name);
    }

    /**
     * Create a new dynamic permission
     */
    @Transactional
    @CacheEvict(value = "permissions", allEntries = true)
    public Permission createPermission(String name, String description, String resourceType, String actionType) {
        // Check if permission already exists
        if (permissionExists(name)) {
            throw new IllegalArgumentException("Permission with name '" + name + "' already exists");
        }

        // Validate naming convention (resource:action)
        if (!isValidPermissionName(name)) {
            throw new IllegalArgumentException("Permission name must follow format 'resource:action' or be 'all_functions'");
        }

        Permission permission = new Permission();
        permission.setName(name);
        permission.setDescription(description);
        permission.setResourceType(resourceType);
        permission.setActionType(actionType);

        Permission saved = permissionRepository.save(permission);
        log.info("Created dynamic permission: {}", name);
        return saved;
    }

    /**
     * Update existing permission
     */
    @Transactional
    @CacheEvict(value = "permissions", allEntries = true)
    public Permission updatePermission(Long id, String description, String resourceType, String actionType) {
        Permission permission = permissionRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Permission not found with id: " + id));

        permission.setDescription(description);
        permission.setResourceType(resourceType);
        permission.setActionType(actionType);

        Permission updated = permissionRepository.save(permission);
        log.info("Updated permission: {}", permission.getName());
        return updated;
    }

    /**
     * Delete permission (only if not core permission)
     */
    @Transactional
    @CacheEvict(value = "permissions", allEntries = true)
    public void deletePermission(Long id) {
        Permission permission = permissionRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Permission not found with id: " + id));

        // Prevent deletion of core permissions
        if (isCorePermission(permission.getName())) {
            throw new IllegalStateException("Cannot delete core system permission: " + permission.getName());
        }

        permissionRepository.deleteById(id);
        log.info("Deleted dynamic permission: {}", permission.getName());
    }

    /**
     * Get permissions by resource type
     */
    @Cacheable(value = "permissions", key = "'resource-' + #resourceType")
    public List<Permission> getPermissionsByResourceType(String resourceType) {
        return permissionRepository.findAll()
            .stream()
            .filter(p -> resourceType.equals(p.getResourceType()))
            .collect(Collectors.toList());
    }

    /**
     * Initialize core permissions if they don't exist
     */
    @Transactional
    public void ensureCorePermissions() {
        for (PermissionType corePermission : PermissionType.values()) {
            Optional<Permission> existing = permissionRepository.findByName(corePermission.getName());
            
            if (existing.isEmpty()) {
                Permission permission = new Permission();
                permission.setName(corePermission.getName());
                permission.setDescription(corePermission.getDescription());
                permission.setResourceType(corePermission.getResourceType());
                permission.setActionType(corePermission.getActionType());
                
                permissionRepository.save(permission);
                log.info("Created core permission: {}", corePermission.getName());
            }
        }
    }

    /**
     * Check if permission name follows valid format
     */
    private boolean isValidPermissionName(String name) {
        if ("all_functions".equals(name)) {
            return true;
        }
        return name.matches("^[a-zA-Z][a-zA-Z0-9_]*:[a-zA-Z][a-zA-Z0-9_]*$");
    }

    /**
     * Check if permission is a core system permission
     */
    private boolean isCorePermission(String name) {
        for (PermissionType corePermission : PermissionType.values()) {
            if (corePermission.getName().equals(name)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Clear permission cache
     */
    @CacheEvict(value = "permissions", allEntries = true)
    public void clearCache() {
        log.info("Cleared permission cache");
    }
}
