package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Index;
import java.util.Objects;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Permission entity representing granular access control permissions.
 * Permissions follow the format: resource:action (e.g., "user:read", "driver:update")
 * 
 * The resource_type and action_type fields provide additional structure for
 * permission management and can be used for advanced authorization logic.
 */
@Entity
@Table(
    name = "permissions",
    indexes = {
        @Index(name = "idx_permission_resource", columnList = "resource_type"),
        @Index(name = "idx_permission_action", columnList = "action_type")
    }
)
@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Permission {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  /**
   * Unique permission name in format resource:action (e.g., "user:read", "driver:create")
   */
  @Column(unique = true, nullable = false, length = 100)
  private String name;

  @Column(length = 500)
  private String description;

  /**
   * Resource type this permission applies to (e.g., "user", "driver", "order")
   */
  @Column(name = "resource_type", length = 50)
  private String resourceType;

  /**
   * Action type for this permission (e.g., "read", "create", "update", "delete")
   */
  @Column(name = "action_type", length = 50)
  private String actionType;

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Permission)) return false;
    Permission that = (Permission) o;
    return id != null && id.equals(that.id);
  }

  @Override
  public int hashCode() {
    return Objects.hash(id);
  }
}
