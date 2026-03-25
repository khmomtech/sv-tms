package com.svtrucking.logistics.infrastructure.security;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.identity.domain.Permission;
import com.svtrucking.logistics.identity.domain.Role;
import com.svtrucking.logistics.identity.domain.User;
import jakarta.annotation.Nullable;
import java.util.Collection;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * Centralized authorization helper that evaluates the effective permissions for the authenticated
 * user (direct assignments + role derived permissions).
 */
@Component("authorizationService")
@RequiredArgsConstructor
public class AuthorizationService {

  private final AuthenticatedUserUtil authenticatedUserUtil;

  /** Checks whether the current user owns a specific permission. */
  public boolean hasPermission(@Nullable String permissionName) {
    if (!StringUtils.hasText(permissionName)) {
      return false;
    }

    // Fast-path: if the SecurityContext already carries the required authority or a
    // role that implies access (e.g. ROLE_SUPERADMIN) then grant immediately. This
    // helps @WithMockUser-based tests where the principal isn't loaded from the DB.
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth != null && auth.isAuthenticated()) {
      for (GrantedAuthority ga : auth.getAuthorities()) {
        String a = ga.getAuthority();
        if (a == null) continue;
        if (a.equalsIgnoreCase(permissionName.trim())) return true;
        if (a.equalsIgnoreCase("ROLE_SUPERADMIN") || a.equalsIgnoreCase("SUPERADMIN")) return true;
        if (a.equalsIgnoreCase(PermissionNames.ALL_FUNCTIONS)) return true;
      }
    }

    Set<String> effectivePermissions = getEffectivePermissionNames();

    // Grant universal access for SUPERADMIN role
    try {
      User current = authenticatedUserUtil.getCurrentUser();
      if (current != null
          && current.getRoles().stream()
              .map(Role::getName)
              .anyMatch(role -> role == RoleType.SUPERADMIN)) {
        return true;
      }
    } catch (RuntimeException ignored) {
      // If we cannot resolve current user, fall back to permission checks below
    }

    // Check for wildcard all_functions permission first
    if (effectivePermissions.stream()
        .anyMatch(p -> PermissionNames.ALL_FUNCTIONS.equalsIgnoreCase(p))) {
      return true; // User has all_functions, so they have access to everything
    }

    return effectivePermissions.stream()
        .anyMatch(p -> p.equalsIgnoreCase(permissionName.trim()));
  }

  /** Returns true when the user has at least one of the provided permissions. */
  public boolean hasAnyPermission(Collection<String> permissionNames) {
    if (permissionNames == null || permissionNames.isEmpty()) {
      return false;
    }
    Set<String> lowered =
        permissionNames.stream()
            .filter(StringUtils::hasText)
            .map(s -> s.trim().toLowerCase())
            .collect(Collectors.toSet());
    if (lowered.isEmpty()) {
      return false;
    }
    return getEffectivePermissionNames().stream()
        .map(String::toLowerCase)
        .anyMatch(lowered::contains);
  }

  /** Checks whether the current user is assigned the provided role. */
  public boolean hasRole(@Nullable String roleName) {
    if (!StringUtils.hasText(roleName)) {
      return false;
    }
    try {
      User current = authenticatedUserUtil.getCurrentUser();
      if (current == null) {
        return false;
      }
      return current.getRoles().stream()
          .map(Role::getName)
          .map(RoleType::name)
          .anyMatch(r -> r.equalsIgnoreCase(roleName.trim()));
    } catch (RuntimeException ex) {
      return false;
    }
  }

  /** Returns the flattened set of permission identifiers the current user owns. */
  public Set<String> getEffectivePermissionNames() {
    return collectEffectivePermissions().stream()
        .map(Permission::getName)
        .filter(StringUtils::hasText)
        .map(String::trim)
        .collect(Collectors.toCollection(TreeSet::new));
  }

  /**
   * Builds a matrix grouping permissions by resource (if provided) and listing the actions/access
   * levels granted to the user.
   */
  public Map<String, Set<String>> getEffectivePermissionMatrix() {
    Set<Permission> permissions = collectEffectivePermissions();
    Map<String, Set<String>> matrix = new TreeMap<>();
    for (Permission permission : permissions) {
      String resource =
          Optional.ofNullable(permission.getResourceType())
              .filter(StringUtils::hasText)
              .map(String::trim)
              .orElse("GLOBAL");
      String action =
          Optional.ofNullable(permission.getActionType())
              .filter(StringUtils::hasText)
              .map(String::trim)
              .orElseGet(() -> Optional.ofNullable(permission.getName()).orElse("UNKNOWN"));
      matrix.computeIfAbsent(resource, key -> new TreeSet<>()).add(action);
    }
    return matrix;
  }

  private Set<Permission> collectEffectivePermissions() {
    User current;
    try {
      current = authenticatedUserUtil.getCurrentUser();
    } catch (RuntimeException ex) {
      return Set.of();
    }
    // Note: Direct user permissions removed in V29 - all permissions now come from roles
    Set<Permission> combined = new HashSet<>();
    Optional.ofNullable(current.getRoles())
        .orElse(Set.of())
        .forEach(
            role ->
                combined.addAll(Optional.ofNullable(role.getPermissions()).orElse(Set.of())));
    return combined;
  }
}
