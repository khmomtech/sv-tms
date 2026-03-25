package com.svtrucking.logistics.identity.repository;

import com.svtrucking.logistics.identity.domain.User;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
  Optional<User> findByUsername(String username);

  Optional<User> findByEmail(String email);

  boolean existsByUsername(String username);

  @Query(
      "SELECT DISTINCT u FROM User u "
          + "LEFT JOIN FETCH u.roles r "
          + "LEFT JOIN FETCH r.permissions "
          + "WHERE u.username = :username")
  Optional<User> findByUsernameWithRoles(@Param("username") String username);

  @Query(
      "SELECT DISTINCT u FROM User u "
          + "LEFT JOIN FETCH u.roles r "
          + "LEFT JOIN FETCH r.permissions "
          + "WHERE u.id = :id")
  Optional<User> findByIdWithRoles(@Param("id") Long id);
}

