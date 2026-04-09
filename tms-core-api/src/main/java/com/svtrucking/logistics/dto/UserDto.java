package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import java.util.Objects;
import org.hibernate.Hibernate;
import org.hibernate.LazyInitializationException;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDto {

  private Long id;
  private String username;
  private String email;
  private boolean enabled;
  private Set<String> roles;

  private Long driverId; // Optional: Can be set manually in service/controller

  public UserDto(String username) {
    this.username = username;
  }

  public UserDto(Long id, String username) {
    this.id = id;
    this.username = username;
  }

  public UserDto(Long id) {
    this.id = id;
  }

  public static UserDto fromEntity(User user) {
    if (user == null) return null;

    Set<Role> roles = Set.of();
    try {
      // Avoid triggering initialization on a proxied/detached User instance.
      if (Hibernate.isInitialized(user)) {
        Set<Role> userRoles = user.getRoles();
        if (!Hibernate.isInitialized(userRoles)) {
          Hibernate.initialize(userRoles);
        }
        roles = userRoles != null ? userRoles : Set.of();
      } else {
        // User is a proxy and not initialized; do not attempt to access relationships.
        roles = Set.of();
      }
    } catch (LazyInitializationException ex) {
      roles = Set.of(); // gracefully degrade when session is closed
    }

    return UserDto.builder()
        .id(user.getId())
        .username(user.getUsername())
        .email(user.getEmail())
        .enabled(user.isEnabled())
        .roles(
            roles.stream()
                .filter(Objects::nonNull)
                .map(role -> role.getName().name())
                .collect(Collectors.toSet()))
        // .driverId removed from here since User no longer has Driver reference
        .build();
  }

  public static User toEntity(UserDto dto, Set<Role> availableRoles) {
    User user = new User();
    user.setId(dto.getId());
    user.setUsername(dto.getUsername());
    user.setEmail(dto.getEmail());
    user.setEnabled(dto.isEnabled());

    Set<Role> userRoles =
        dto.getRoles().stream()
            .map(RoleType::valueOf)
            .flatMap(roleType -> availableRoles.stream().filter(role -> role.getName() == roleType))
            .collect(Collectors.toSet());

    user.setRoles(userRoles);

    return user;
  }
}
