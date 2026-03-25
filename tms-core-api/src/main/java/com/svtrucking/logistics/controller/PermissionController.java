package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.service.PermissionService;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/permissions")
@CrossOrigin(origins = "*")
public class PermissionController {

  private final PermissionService permissionService;

  public PermissionController(PermissionService permissionService) {
    this.permissionService = permissionService;
  }

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('permission:read')")
  public ResponseEntity<List<Permission>> getAllPermissions() {
    List<Permission> permissions = permissionService.getAllPermissions();
    return ResponseEntity.ok(permissions);
  }

  @GetMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('permission:read')")
  public ResponseEntity<Permission> getPermissionById(@PathVariable Long id) {
    Permission permission = permissionService.getPermissionById(id);
    return ResponseEntity.ok(permission);
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('permission:create')")
  public ResponseEntity<Permission> createPermission(@RequestBody Permission permission) {
    Permission createdPermission = permissionService.createPermission(permission);
    return ResponseEntity.ok(createdPermission);
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('permission:update')")
  public ResponseEntity<Permission> updatePermission(
      @PathVariable Long id, @RequestBody Permission permission) {
    Permission updatedPermission = permissionService.updatePermission(id, permission);
    return ResponseEntity.ok(updatedPermission);
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('permission:delete')")
  public ResponseEntity<Void> deletePermission(@PathVariable Long id) {
    permissionService.deletePermission(id);
    return ResponseEntity.ok().build();
  }
}
