package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.UserPermissionSummaryDto;
import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.UserPermissionService;
import java.util.List;
import java.util.Set;
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

  @PostMapping("/assign")
  @PreAuthorize("@authorizationService.hasPermission('user:update')")
  public ResponseEntity<String> assignPermissionToUser(
      @RequestParam Long userId, @RequestParam Long permissionId) {
    boolean success = userPermissionService.assignPermissionToUser(userId, permissionId);
    if (success) {
      return ResponseEntity.ok("Permission assigned successfully");
    } else {
      return ResponseEntity.badRequest().body("Failed to assign permission");
    }
  }

  @PostMapping("/assign-by-name")
  @PreAuthorize("@authorizationService.hasPermission('user:update')")
  public ResponseEntity<String> assignPermissionToUserByName(
      @RequestParam Long userId, @RequestParam String permissionName) {
    boolean success = userPermissionService.assignPermissionToUser(userId, permissionName);
    if (success) {
      return ResponseEntity.ok("Permission assigned successfully");
    } else {
      return ResponseEntity.badRequest().body("Failed to assign permission");
    }
  }

  @DeleteMapping("/remove")
  @PreAuthorize("@authorizationService.hasPermission('user:update')")
  public ResponseEntity<String> removePermissionFromUser(
      @RequestParam Long userId, @RequestParam Long permissionId) {
    boolean success = userPermissionService.removePermissionFromUser(userId, permissionId);
    if (success) {
      return ResponseEntity.ok("Permission removed successfully");
    } else {
      return ResponseEntity.badRequest().body("Failed to remove permission");
    }
  }

  @GetMapping("/user/{userId}")
  @PreAuthorize("@authorizationService.hasPermission('user:read')")
  public ResponseEntity<Set<Permission>> getUserPermissions(@PathVariable Long userId) {
    Set<Permission> permissions = userPermissionService.getUserPermissions(userId);
    return ResponseEntity.ok(permissions);
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
  public ResponseEntity<List<User>> getUsersWithPermission(@RequestParam String permissionName) {
    List<User> users = userPermissionService.getUsersWithPermission(permissionName);
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
