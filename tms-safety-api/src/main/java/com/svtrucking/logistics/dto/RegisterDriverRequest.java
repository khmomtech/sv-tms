package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.HashSet;
import java.util.Set;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class RegisterDriverRequest {
  private String email;
  private String username;
  private String password;
  private String name;
  private String phone;
  private Long driverId;
  private Set<String> roles = new HashSet<>();
}
