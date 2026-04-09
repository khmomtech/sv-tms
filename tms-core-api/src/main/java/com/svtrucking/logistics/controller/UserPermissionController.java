package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.UserDto;
import com.svtrucking.logistics.dto.UserPermissionSummaryDto;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.UserPermissionService;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/user-permissions")
@CrossOrigin(origins = "*")
public class UserPermissionController {

  private final UserPermissionService userPermissionService;
  private final AuthenticatedUserUtil authenticatedUserUtil;

  public UserPermissionController(
      UserPermissionService userPermissionService, AuthenticatedUserUtil authenticatedUserUtil) {
    this.userPermissionService = userPermissionService;
    this.authenticatedUserUtil = authenticatedUserUtil;
  }

  /**
   * @deprecated Direct user-permission assignment removed in V29. Assign permissions via roles:
   *             POST /api/admin/roles/{roleId}/permissions/{permissionId}
   */
  @PostMapping("/assign")
  @Deprecated
  public ResponseEntity<Map<String, String>> assignPermissionToUser(
      @RequestParam Long userId, @RequestParam Long permissionId) {
    return ResponseEntity.status(HttpStatus.GONE).body(Map.of(
        "error", "Direct user-permission assignment was removed in V29.",
        "action", "Use POST /api/admin/roles/{roleId}/permissions/{permissionId} instead."));
  }

  /**
   * @deprecated Direct user-permission assignment removed in V29. Assign permissions via roles.
   */
  @PostMapping("/assign-by-name")
  @Deprecated
  public ResponseEntity<Map<String, String>> assignPermissionToUserByName(
      @RequestParam Long userId, @RequestParam String permissionName) {
    return ResponseEntity.status(HttpStatus.GONE).body(Map.of(
        "error", "Direct user-permission assignment was removed in V29.",
        "action", "Use POST /api/admin/roles/{roleId}/permissions/{permissionId} instead."));
  }

  /**
   * @deprecated Direct user-permission removal removed in V29. Manage permissions via roles.
   */
  @DeleteMapping("/remove")
  @Deprecated
  public ResponseEntity<Map<String, String>> removePermissionFromUser(
      @RequestParam Long userId, @RequestParam Long permissionId) {
    return ResponseEntity.status(HttpStatus.GONE).body(Map.of(
        "error", "Direct user-permission removal was removed in V29.",
        "action", "Use DELETE /api/admin/roles/{roleId}/permissions/{permissionId} instead."));
  }

  /**
   * @deprecated Direct user permissions no longer exist. Use /user/{userId}/effective instead.
   */
  @GetMapping("/user/{userId}")
  @Deprecated
  @PreAuthorize("@authorizationService.hasPermission('user:read')")
  public ResponseEntity<Map<String, String>> getUserPermissions(@PathVariable Long userId) {
    return ResponseEntity.status(HttpStatus.GONE).body(Map.of(
        "error", "Direct user permissions were removed in V29.",
        "action", "Use GET /api/admin/user-permissions/user/" + userId + "/effective instead."));
  }

  @GetMapping("/user/{userId}/has-permission")
  @PreAuthorize("@authorizationService.hasPermission('user:read')")
  public ResponseEntity<Boolean> userHasPermission(
      @PathVariable Long userId, @RequestParam String permissionName) {
    boolean hasPermission = userPermissionService.userHasPermission(userId, permissionName);
    return ResponseEntity.ok(hasPermission);
  }

  @GetMapping("/users-with-permission")
  @PreAuthorize("@authorizationService.hasPermission('user:read')")
  public ResponseEntity<List<UserDto>> getUsersWithPermission(@RequestParam String permissionName) {
    List<UserDto> users = userPermissionService.getUsersWithPermission(permissionName).stream()
        .map(UserDto::fromEntity)
        .toList();
    return ResponseEntity.ok(users);
  }

  @GetMapping("/user/{userId}/effective")
  @PreAuthorize("@authorizationService.hasPermission('user:read')")
  public ResponseEntity<UserPermissionSummaryDto> getEffectivePermissions(
      @PathVariable Long userId) {
    UserPermissionSummaryDto summary =
        UserPermissionSummaryDto.builder()
            .userId(userId)
            .permissions(userPermissionService.getEffectivePermissionNames(userId))
            .permissionMatrix(userPermissionService.getEffectivePermissionMatrix(userId))
            .build();
    return ResponseEntity.ok(summary);
  }

  @GetMapping("/me/effective")
  @PreAuthorize("isAuthenticated()")
  public ResponseEntity<UserPermissionSummaryDto> getCurrentUserPermissions() {
    Long userId = authenticatedUserUtil.getCurrentUser().getId();
    UserPermissionSummaryDto summary =
        UserPermissionSummaryDto.builder()
            .userId(userId)
            .permissions(userPermissionService.getEffectivePermissionNames(userId))
            .permissionMatrix(userPermissionService.getEffectivePermissionMatrix(userId))
            .build();
    return ResponseEntity.ok(summary);
  }
}
