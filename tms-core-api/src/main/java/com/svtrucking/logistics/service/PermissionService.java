package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.repository.PermissionRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;

@Service
public class PermissionService {

  private final PermissionRepository permissionRepository;

  public PermissionService(PermissionRepository permissionRepository) {
    this.permissionRepository = permissionRepository;
  }

  public List<Permission> getAllPermissions() {
    return permissionRepository.findAll();
  }

  public Permission getPermissionById(Long id) {
    return permissionRepository
        .findById(id)
        .orElseThrow(() -> new EntityNotFoundException("Permission not found"));
  }

  public Optional<Permission> getPermissionByName(String name) {
    return permissionRepository.findByName(name);
  }

  public Permission createPermission(Permission permission) {
    return permissionRepository.save(permission);
  }

  public Permission updatePermission(Long id, Permission permission) {
    if (!permissionRepository.existsById(id)) {
      throw new EntityNotFoundException("Permission not found");
    }
    permission.setId(id);
    return permissionRepository.save(permission);
  }

  public void deletePermission(Long id) {
    if (!permissionRepository.existsById(id)) {
      throw new EntityNotFoundException("Permission not found");
    }
    permissionRepository.deleteById(id);
  }
}
