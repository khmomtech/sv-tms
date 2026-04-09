package com.svtrucking.logistics.config;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.repository.PermissionRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Ensures new operational roles required for the factory gate flow exist with sensible
 * permissions. Safe to run repeatedly; it only creates missing roles/permissions.
 */
@Component
@Profile("!test")
@RequiredArgsConstructor
@Slf4j
public class SafetyRoleInitializer implements CommandLineRunner {

  private final RoleRepository roleRepository;
  private final PermissionRepository permissionRepository;

  @Override
  @Transactional
  public void run(String... args) {
    ensureRole(
        RoleType.SAFETY,
        "Factory gate safety team - can submit pre-loading safety checks",
        Arrays.asList(
            "dispatch:read",
            "dispatch:list",
            "dispatch:monitor",
            "dispatch:track",
            "preloading_safety:submit",
            "preloading_safety:view"));

    ensureRole(
        RoleType.LOADING,
        "Warehouse loading operator - queue and loading actions (no safety submission)",
        Arrays.asList(
            "dispatch:read",
            "dispatch:list",
            "dispatch:monitor",
            "loading:queue",
            "loading:start",
            "loading:complete",
            "preloading_safety:view"));

    ensureRole(
        RoleType.DISPATCH_MONITOR,
        "Control tower monitoring - read-only dispatch and safety visibility",
        Arrays.asList("dispatch:read", "dispatch:list", "dispatch:monitor", "preloading_safety:view"));
  }

  private void ensureRole(RoleType type, String description, List<String> permissionNames) {
    Role role =
        roleRepository
            .findByNameWithPermissions(type)
            .orElseGet(
                () -> {
                  Role r = new Role();
                  r.setName(type);
                  r.setDescription(description);
                  return roleRepository.save(r);
                });

    if (role.getDescription() == null || role.getDescription().isBlank()) {
      role.setDescription(description);
    }

    boolean updated = false;
    for (String permName : permissionNames) {
      Permission permission = ensurePermission(permName);
      if (!role.getPermissions().contains(permission)) {
        role.getPermissions().add(permission);
        updated = true;
      }
    }

    if (updated) {
      roleRepository.save(role);
      log.info("Updated role {} with {} permissions", type, permissionNames.size());
    }
  }

  private Permission ensurePermission(String name) {
    Optional<Permission> existing = permissionRepository.findByName(name);
    if (existing.isPresent()) {
      return existing.get();
    }
    Permission permission = new Permission();
    permission.setName(name);
    String[] parts = name.split(":");
    permission.setResourceType(parts[0]);
    permission.setActionType(parts.length > 1 ? parts[1] : "read");
    permission.setDescription("Auto-created permission for " + name);
    return permissionRepository.save(permission);
  }
}
