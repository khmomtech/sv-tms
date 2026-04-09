package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.User;
import java.util.Optional;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

/**
 * Repository for User entity operations.
 * Uses explicit JOIN FETCH to eagerly load roles when needed.
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

  /**
   * Find user by username (roles loaded lazily by default).
   * For login and authentication, use findByUsernameWithRoles() instead.
   */
  Optional<User> findByUsername(String username);

  /**
   * Find user by username with roles eagerly loaded.
   * Use this for authentication/authorization operations.
   * Also fetches customer relationship for CUSTOMER role users.
   */
  @Query(
      "SELECT DISTINCT u FROM User u "
          + "LEFT JOIN FETCH u.roles r "
          + "LEFT JOIN FETCH r.permissions "
          + "LEFT JOIN FETCH u.customer "
          + "WHERE u.username = :username")
  Optional<User> findByUsernameWithRoles(@Param("username") String username);

  /**
   * Find user by ID with roles eagerly loaded.
   * Also fetches customer relationship for CUSTOMER role users.
   */
  @Query("SELECT DISTINCT u FROM User u " +
         "LEFT JOIN FETCH u.roles r " +
         "LEFT JOIN FETCH r.permissions " +
         "LEFT JOIN FETCH u.customer " +
         "WHERE u.id = :id")
  Optional<User> findByIdWithRoles(@Param("id") Long id);

  /** Check if username exists */
  boolean existsByUsername(String username);

  /**
   * Find user by email (roles loaded lazily by default).
   * For login and authentication, fetch separately with findByIdWithRoles().
   */
  Optional<User> findByEmail(String email);

  /**
   * Fetch all users with roles (and role permissions) eagerly loaded to avoid lazy init issues
   * when mapping to DTOs outside of a transactional context.
   */
  @Query(
      "SELECT DISTINCT u FROM User u "
          + "LEFT JOIN FETCH u.roles r "
          + "LEFT JOIN FETCH r.permissions "
          + "LEFT JOIN FETCH u.customer")
  List<User> findAllWithRoles();
}
