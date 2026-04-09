// com.svtrucking.logistics.dto.UserDto.java
package com.svtrucking.logistics.dto;

import java.util.List;
import lombok.Data;

@Data
public class DashboardUserDto {
  private Long id;
  private String username;
  private String email;
  private List<String> roles;
}
