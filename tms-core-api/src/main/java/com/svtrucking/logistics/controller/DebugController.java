package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import com.svtrucking.logistics.service.UserPermissionService;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.model.User;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Small debug controller to inspect the current authentication context.
 * Useful for local debugging to confirm the server sees the token, username and roles.
 */
@RestController
@RequestMapping("/api/debug")
public class DebugController {

  private final UserPermissionService userPermissionService;
  private final UserRepository userRepository;

  public DebugController(UserPermissionService userPermissionService, UserRepository userRepository) {
    this.userPermissionService = userPermissionService;
    this.userRepository = userRepository;
  }

  @GetMapping("/whoami")
  public ResponseEntity<ApiResponse<Map<String, Object>>> whoami() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !auth.isAuthenticated() || auth.getPrincipal() == null) {
      return ResponseEntity.ok(new ApiResponse<>(false, "Not authenticated", null));
    }

    String username = auth.getName();
    List<String> roles = auth.getAuthorities().stream()
        .map(GrantedAuthority::getAuthority)
        .collect(Collectors.toList());

    Map<String, Object> data = new HashMap<>();
    data.put("username", username);
    data.put("authorities", roles);

    return ResponseEntity.ok(new ApiResponse<>(true, "Authenticated", data));
  }

  @GetMapping("/permissions")
  public ResponseEntity<ApiResponse<Map<String, Object>>> myPermissions() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !auth.isAuthenticated() || auth.getPrincipal() == null) {
      return ResponseEntity.ok(new ApiResponse<>(false, "Not authenticated", null));
    }

    String username = auth.getName();
    Map<String, Object> data = new HashMap<>();
    User user = userRepository.findByUsername(username).orElse(null);
    if (user == null) {
      return ResponseEntity.ok(new ApiResponse<>(false, "User not found", null));
    }

    var perms = userPermissionService.getEffectivePermissionNames(user.getId());
    data.put("username", username);
    data.put("permissions", perms);
    return ResponseEntity.ok(new ApiResponse<>(true, "Permissions fetched", data));
  }

  @GetMapping("/finduser/{username}")
  public ResponseEntity<Map<String, Object>> findUserDebug(@org.springframework.web.bind.annotation.PathVariable String username) {
    Map<String, Object> result = new HashMap<>();
    result.put("searchedUsername", username);
    
    java.util.Optional<User> userOpt = userRepository.findByUsername(username);
    result.put("foundByUsername", userOpt.isPresent());
    if (userOpt.isPresent()) {
      User user = userOpt.get();
      result.put("userId", user.getId());
      result.put("username", user.getUsername());
      result.put("email", user.getEmail());
      result.put("enabled", user.isEnabled());
      result.put("roles", user.getRoles().stream().map(r -> r.getName()).toList());
    }
    
    long count = userRepository.count();
    result.put("totalUsersInDb", count);
    
    return ResponseEntity.ok(result);
  }
}
