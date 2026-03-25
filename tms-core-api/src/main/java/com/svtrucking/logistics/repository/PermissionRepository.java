package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.Permission;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PermissionRepository extends JpaRepository<Permission, Long> {
  Optional<Permission> findByName(String name);
  List<Permission> findByNameIn(List<String> names);
}
