package com.svtrucking.logistics.identity.service;

import com.svtrucking.logistics.identity.domain.Permission;
import com.svtrucking.logistics.identity.domain.Role;
import com.svtrucking.logistics.identity.domain.User;
import com.svtrucking.logistics.identity.repository.UserRepository;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

@Service
public class UserPermissionService {

  private final UserRepository userRepository;

  public UserPermissionService(UserRepository userRepository) {
    this.userRepository = userRepository;
  }

  /**
   * Direct user permission assignment is no longer supported.
   * All permissions must be assigned through roles.
   * Use RoleService to manage role permissions instead.
   * 
   * @deprecated Use role-based permission assignment instead
   */
  @Deprecated(since = "V29", forRemoval = true)
  public boolean assignPermissionToUser(Long userId, Long permissionId) {
    throw new UnsupportedOperationException(
        "Direct user permission assignment is not supported. Assign permissions through roles.");
  }

  /**
   * Direct user permission assignment is no longer supported.
   * All permissions must be assigned through roles.
   * 
   * @deprecated Use role-based permission assignment instead
   */
  @Deprecated(since = "V29", forRemoval = true)
  public boolean assignPermissionToUser(Long userId, String permissionName) {
    throw new UnsupportedOperationException(
        "Direct user permission assignment is not supported. Assign permissions through roles.");
  }

  /**
   * Direct user permission removal is no longer supported.
   * All permissions are managed through roles.
   * 
   * @deprecated Use role-based permission management instead
   */
  @Deprecated(since = "V29", forRemoval = true)
  public boolean removePermissionFromUser(Long userId, Long permissionId) {
    throw new UnsupportedOperationException(
        "Direct user permission removal is not supported. Manage permissions through roles.");
  }

  /**
   * Direct user permissions are no longer supported.
   * Use getEffectivePermissions() instead to get all permissions through roles.
   * 
   * @deprecated Use getEffectivePermissions() instead
   */
  @Deprecated(since = "V29", forRemoval = true)
  public Set<Permission> getUserPermissions(Long userId) {
    // Return empty set for compatibility - all permissions come from roles now
    return Set.of();
  }

  public Set<Permission> getEffectivePermissions(Long userId) {
    return collectEffectivePermissions(userId);
  }

  public Set<String> getEffectivePermissionNames(Long userId) {
    return collectEffectivePermissions(userId).stream()
        .map(Permission::getName)
        .filter(name -> name != null && !name.isBlank())
        .map(String::trim)
        .collect(Collectors.toCollection(TreeSet::new));
  }

  public Map<String, Set<String>> getEffectivePermissionMatrix(Long userId) {
    Set<Permission> effectivePermissions = collectEffectivePermissions(userId);
    Map<String, Set<String>> matrix = new TreeMap<>();
    for (Permission permission : effectivePermissions) {
      String resource = optionalTrim(permission.getResourceType(), "GLOBAL");
      String action =
          optionalTrim(permission.getActionType(), optionalTrim(permission.getName(), "UNKNOWN"));
      matrix.computeIfAbsent(resource, key -> new TreeSet<>()).add(action);
    }
    return matrix;
  }

  /** Check if a user has a specific permission */
  public boolean userHasPermission(Long userId, String permissionName) {
    if (permissionName == null || permissionName.isBlank()) {
      return false;
    }
    String target = permissionName.trim().toLowerCase();
    return collectEffectivePermissions(userId).stream()
        .map(Permission::getName)
        .filter(name -> name != null && !name.isBlank())
        .map(String::trim)
        .map(String::toLowerCase)
        .anyMatch(target::equals);
  }

  /** Get all users with a specific permission */
  public List<User> getUsersWithPermission(String permissionName) {
    return userRepository.findAll().stream()
        .filter(
            user ->
                collectEffectivePermissions(user).stream()
                    .anyMatch(permission -> permission.getName().equals(permissionName)))
        .toList();
  }

  private Set<Permission> collectEffectivePermissions(Long userId) {
    Optional<User> userOpt = userRepository.findByIdWithRoles(userId);
    return userOpt.map(this::collectEffectivePermissions).orElse(Set.of());
  }

  /**
   * Collect all effective permissions for a user from their assigned roles.
   * Note: Direct user permissions are no longer supported - all permissions come from roles.
   */
  private Set<Permission> collectEffectivePermissions(User user) {
    if (user == null) {
      return Set.of();
    }
    Set<Permission> combined = new HashSet<>();
    // Only collect permissions from roles (direct user permissions no longer supported)
    if (user.getRoles() != null) {
      for (Role role : user.getRoles()) {
        if (role != null && role.getPermissions() != null) {
          combined.addAll(role.getPermissions());
        }
      }
    }
    return combined;
  }

  private String optionalTrim(String value, String fallback) {
    if (value == null) {
      return fallback;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? fallback : trimmed;
  }
}
