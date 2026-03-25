package com.svtrucking.logistics.config;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.repository.PermissionRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import java.util.HashMap;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Safe, idempotent starter that ensures critical permissions exist and are assigned to ADMIN and
 * SUPERADMIN roles. This runs on every application startup.
 */
@Component
@Profile("!test")
public class PermissionEnsurer implements CommandLineRunner {

  private final PermissionRepository permissionRepository;
  private final RoleRepository roleRepository;
  private final HashMap<String, Permission> cache = new HashMap<>();

  public PermissionEnsurer(
      PermissionRepository permissionRepository, RoleRepository roleRepository) {
    this.permissionRepository = permissionRepository;
    this.roleRepository = roleRepository;
  }

  @Override
  @Transactional
  public void run(String... args) throws Exception {
    // Skip if system already seeded (avoids redundant startup queries)
    if (permissionRepository.count() > 0
        && roleRepository.count() > 0
        && permissionRepository.findByName("all_functions").isPresent()) {
      return;
    }

    // Ensure 'all_functions' permission exists
    Permission allFunctionsPerm =
        ensurePermissionExists(
            "all_functions",
            "Wildcard permission granting access to all system functions",
            "global",
            "all");

    // Ensure Banner-related permissions exist
    List<Permission> bannerPermissions =
        Arrays.asList(
            ensurePermissionExists(
                "banner:read", "Read access to banners", "banner", "read"),
            ensurePermissionExists(
                "banner:create", "Create access for banners", "banner", "create"),
            ensurePermissionExists(
                "banner:update", "Update access for banners", "banner", "update"),
            ensurePermissionExists(
                "banner:delete", "Delete access for banners", "banner", "delete"));

    // Assign 'all_functions' to ADMIN and SUPERADMIN
    assignPermissionsToRoles(
        Arrays.asList(RoleType.ADMIN, RoleType.SUPERADMIN), Arrays.asList(allFunctionsPerm));

    // For explicitness, also assign specific banner permissions to ADMIN and SUPERADMIN
    // Although all_functions covers this, it makes the role's capabilities clearer.
    assignPermissionsToRoles(
        Arrays.asList(RoleType.ADMIN, RoleType.SUPERADMIN), bannerPermissions);
  }

  private Permission ensurePermissionExists(
      String name, String description, String resourceType, String actionType) {
    if (cache.containsKey(name)) {
      return cache.get(name);
    }
    Permission resolved =
        permissionRepository
            .findByName(name)
            .orElseGet(
                () -> {
                  Permission p = new Permission();
                  p.setName(name);
                  p.setDescription(description);
                  p.setResourceType(resourceType);
                  p.setActionType(actionType);
                  System.out.println("[permission-ensurer] Creating permission: " + name);
                  return permissionRepository.save(p);
                });
    cache.put(name, resolved);
    return resolved;
  }

  @Transactional
  private void assignPermissionsToRoles(List<RoleType> roleTypes, List<Permission> permissions) {
    String permissionNames =
        permissions.stream().map(Permission::getName).collect(Collectors.joining(", "));

    roleTypes.forEach(
        roleType -> {
          Optional<Role> rOpt = roleRepository.findByNameWithPermissions(roleType);
          if (rOpt.isPresent()) {
            Role role = rOpt.get();
            boolean updated = false;
            
            for (Permission perm : permissions) {
              if (!role.getPermissions().contains(perm)) {
                role.getPermissions().add(perm);
                updated = true;
              }
            }
            if (updated) {
              roleRepository.save(role);
              System.out.println(
                  "[permission-ensurer] Added permissions ("
                      + permissionNames
                      + ") to role: "
                      + roleType.name());
            } else {
              System.out.println(
                  "[permission-ensurer] Role "
                      + roleType.name()
                      + " already has permissions: "
                      + permissionNames);
            }
          } else {
            System.out.println(
                "[permission-ensurer] Role not found (skipping assignment): " + roleType.name());
          }
        });
  }
}
