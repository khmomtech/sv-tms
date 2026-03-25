package com.svtrucking.logistics.dto;

import java.util.Set;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RegisterRequest {
  private String username;
  private String password;
  private String email;
  private Set<String> roles; //  Supports multiple roles
  private Boolean enabled; // Optional: defaults to true if not provided
}
