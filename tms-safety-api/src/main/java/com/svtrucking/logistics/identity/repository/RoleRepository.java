package com.svtrucking.logistics.identity.repository;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.identity.domain.Role;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface RoleRepository extends JpaRepository<Role, Long> {
  Optional<Role> findByName(RoleType name);

  @Query("SELECT r FROM Role r LEFT JOIN FETCH r.permissions WHERE r.name = :name")
  Optional<Role> findByNameWithPermissions(@Param("name") RoleType name);
}

