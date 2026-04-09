package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.service.PermissionService;
import com.svtrucking.logistics.service.RoleService;
import java.util.List;
import java.util.Set;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/roles")
@CrossOrigin(origins = "*")
public class RoleController {

  private final RoleService roleService;
  public RoleController(RoleService roleService, PermissionService permissionService) {
    this.roleService = roleService;
  }

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('role:read')")
  public ResponseEntity<List<Role>> getAllRoles() {
    List<Role> roles = roleService.getAllRoles();
    return ResponseEntity.ok(roles);
  }

  @GetMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('role:read')")
  public ResponseEntity<Role> getRoleById(@PathVariable Long id) {
    Role role = roleService.getRoleById(id);
    return ResponseEntity.ok(role);
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('role:create')")
  public ResponseEntity<Role> createRole(@RequestBody Role role) {
    Role savedRole = roleService.createRole(role);
    return ResponseEntity.ok(savedRole);
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('role:update')")
  public ResponseEntity<Role> updateRole(@PathVariable Long id, @RequestBody Role role) {
    Role updatedRole = roleService.updateRole(id, role);
    return ResponseEntity.ok(updatedRole);
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('role:delete')")
  public ResponseEntity<Void> deleteRole(@PathVariable Long id) {
    roleService.deleteRole(id);
    return ResponseEntity.ok().build();
  }

  @PostMapping("/{roleId}/permissions/{permissionId}")
  @PreAuthorize("@authorizationService.hasPermission('role:update')")
  public ResponseEntity<Role> addPermissionToRole(
      @PathVariable Long roleId, @PathVariable Long permissionId) {
    Role role = roleService.addPermissionToRole(roleId, permissionId);
    return ResponseEntity.ok(role);
  }

  @DeleteMapping("/{roleId}/permissions/{permissionId}")
  @PreAuthorize("@authorizationService.hasPermission('role:update')")
  public ResponseEntity<Role> removePermissionFromRole(
      @PathVariable Long roleId, @PathVariable Long permissionId) {
    Role role = roleService.removePermissionFromRole(roleId, permissionId);
    return ResponseEntity.ok(role);
  }

  @GetMapping("/{roleId}/permissions")
  @PreAuthorize("@authorizationService.hasPermission('role:read')")
  public ResponseEntity<Set<Permission>> getRolePermissions(@PathVariable Long roleId) {
    Set<Permission> permissions = roleService.getPermissions(roleId);
    return ResponseEntity.ok(permissions);
  }
}
