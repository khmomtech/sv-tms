package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.User;
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
public class UserSimpleDto {
  private Long id;
  private String username;
  private String email;
  private Set<String> roles;

  public static UserSimpleDto fromEntity(User user) {
    if (user == null) return null;

    return UserSimpleDto.builder()
        .id(user.getId())
        .username(user.getUsername())
        .email(user.getEmail())
        .roles(
            user.getRoles().stream().map(role -> role.getName().name()).collect(Collectors.toSet()))
        .build();
  }
}
