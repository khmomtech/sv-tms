package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.RoleType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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

/**
 * Role entity representing user roles in the system.
 * Each role can have multiple permissions assigned through the role_permissions join table.
 */
@Entity
@Table(name = "roles")
@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@NamedEntityGraph(
    name = "Role.withPermissions",
    attributeNodes = @NamedAttributeNode("permissions")
)
public class Role {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Enumerated(EnumType.STRING)
  @Column(unique = true, nullable = false, length = 50)
  private RoleType name;

  @Column(length = 500)
  private String description;

  /**
   * Permissions associated with this role.
   * Changed from 'rolePermissions' to 'permissions' for better naming consistency.
   * Fetched LAZILY - use EntityGraph when permissions are needed.
   * JsonIgnore prevents infinite recursion during serialization.
   */
  @JsonIgnore
  @ManyToMany(fetch = FetchType.LAZY)
  @JoinTable(
      name = "role_permissions",
      joinColumns = @JoinColumn(name = "role_id"),
      inverseJoinColumns = @JoinColumn(name = "permission_id"))
  private Set<Permission> permissions = new HashSet<>();

  /** Utility method to add a permission */
  public void addPermission(Permission permission) {
    if (permission != null) {
      this.permissions.add(permission);
    }
  }

  /** Utility method to remove a permission */
  public void removePermission(Permission permission) {
    if (permission != null) {
      this.permissions.remove(permission);
    }
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Role)) return false;
    Role role = (Role) o;
    return id != null && id.equals(role.id);
  }

  @Override
  public int hashCode() {
    return Objects.hash(id);
  }
}
