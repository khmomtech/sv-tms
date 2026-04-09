package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.Permission;
import java.util.List;
import java.util.Set;

public interface RoleService {
  List<Role> getAllRoles();

  Role getRoleById(Long id);

  Role createRole(Role role);

  Role updateRole(Long id, Role role);

  void deleteRole(Long id);

  Role addPermissionToRole(Long roleId, Long permissionId);

  Role removePermissionFromRole(Long roleId, Long permissionId);

  Set<Permission> getPermissions(Long roleId);
}
