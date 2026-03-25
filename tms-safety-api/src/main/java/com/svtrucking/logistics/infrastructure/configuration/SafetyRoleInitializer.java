package com.svtrucking.logistics.infrastructure.configuration;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.identity.domain.Permission;
import com.svtrucking.logistics.identity.domain.Role;
import com.svtrucking.logistics.identity.repository.PermissionRepository;
import com.svtrucking.logistics.identity.repository.RoleRepository;
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
        "Safety team - can manage daily safety checks",
        Arrays.asList("safety:read", "safety:write", "safety:approve"));

    ensureRole(
        RoleType.DISPATCH_MONITOR,
        "Control tower monitoring - read-only safety visibility",
        Arrays.asList("safety:read"));
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
