package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.repository.PermissionRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;

@Service
public class RoleServiceImpl implements RoleService {

  private final RoleRepository roleRepository;
  private final PermissionRepository permissionRepository;

  public RoleServiceImpl(
      RoleRepository roleRepository, PermissionRepository permissionRepository) {
    this.roleRepository = roleRepository;
    this.permissionRepository = permissionRepository;
  }

  @Override
  public List<Role> getAllRoles() {
    return roleRepository.findAll();
  }

  @Override
  public Role getRoleById(Long id) {
    return roleRepository.findById(id).orElseThrow(() -> new EntityNotFoundException("Role not found"));
  }

  @Override
  public Role createRole(Role role) {
    return roleRepository.save(role);
  }

  @Override
  public Role updateRole(Long id, Role role) {
    if (!roleRepository.existsById(id)) {
      throw new EntityNotFoundException("Role not found");
    }
    role.setId(id);
    return roleRepository.save(role);
  }

  @Override
  public void deleteRole(Long id) {
    if (!roleRepository.existsById(id)) {
      throw new EntityNotFoundException("Role not found");
    }
    roleRepository.deleteById(id);
  }

  @Override
  public Role addPermissionToRole(Long roleId, Long permissionId) {
    Role role = getRoleById(roleId);
    Permission permission =
        permissionRepository
            .findById(permissionId)
            .orElseThrow(() -> new EntityNotFoundException("Permission not found"));
    role.getPermissions().add(permission);
    return roleRepository.save(role);
  }

  @Override
  public Role removePermissionFromRole(Long roleId, Long permissionId) {
    Role role = getRoleById(roleId);
    Permission permission =
        permissionRepository
            .findById(permissionId)
            .orElseThrow(() -> new EntityNotFoundException("Permission not found"));
    role.getPermissions().remove(permission);
    return roleRepository.save(role);
  }

  @Override
  public Set<Permission> getPermissions(Long roleId) {
    Role role = getRoleById(roleId);
    return role.getPermissions();
  }
}
