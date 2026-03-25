package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import jakarta.persistence.NamedEntityGraph;
import jakarta.persistence.NamedAttributeNode;
import java.util.HashSet;
import java.util.Set;
import java.util.Objects;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.OneToOne;

/**
 * User entity representing system users.
 * Uses role-based access control (RBAC) where permissions are granted through roles.
 * Direct user permissions have been removed to simplify the authorization model.
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "password"})
@NamedEntityGraph(
    name = "User.withRoles",
    attributeNodes = @NamedAttributeNode("roles")
)
public class User {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(unique = true, nullable = false, length = 50)
  private String username;

  @Column(nullable = false)
  private String password;

  @Column(nullable = false, length = 100)
  private String email;

  /**
   * User roles - fetched LAZILY by default, use EntityGraph when needed.
   * All permissions should be granted through roles, not directly to users.
   */
  // EAGER to avoid LazyInitialization when mapping users to DTOs in admin lists
  @ManyToMany(fetch = FetchType.EAGER)
  @JoinTable(
      name = "user_roles",
      joinColumns = @JoinColumn(name = "user_id"),
      inverseJoinColumns = @JoinColumn(name = "role_id"))
  private Set<Role> roles = new HashSet<>();

  /** Optional customer association for CUSTOMER role users */
  @OneToOne(mappedBy = "user", fetch = FetchType.LAZY)
  private Customer customer;

  /** Security fields required by Spring Security */
  @Column(nullable = false)
  private boolean enabled = true;

  @Column(nullable = false)
  private boolean accountNonLocked = true;

  @Column(nullable = false)
  private boolean accountNonExpired = true;

  @Column(nullable = false)
  private boolean credentialsNonExpired = true;

  /** Utility method to add a role */
  public void addRole(Role role) {
    if (role != null) {
      this.roles.add(role);
    }
  }

  /** Utility method to remove a role */
  public void removeRole(Role role) {
    if (role != null) {
      this.roles.remove(role);
    }
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof User)) return false;
    User user = (User) o;
    return id != null && id.equals(user.id);
  }

  @Override
  public int hashCode() {
    return Objects.hash(id);
  }
}
