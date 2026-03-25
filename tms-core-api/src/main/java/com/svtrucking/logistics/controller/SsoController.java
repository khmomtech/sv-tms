package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.security.JwtUtil;
import com.svtrucking.logistics.service.SsoService;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/sso")
@CrossOrigin(origins = "*")
public class SsoController {

  private final SsoService ssoService;
  private final JwtUtil jwtUtil;

  public SsoController(SsoService ssoService, JwtUtil jwtUtil) {
    this.ssoService = ssoService;
    this.jwtUtil = jwtUtil;
  }

  /** Authenticate user with SSO token */
  @PostMapping("/authenticate")
  public ResponseEntity<?> authenticateWithSsoToken(@RequestBody Map<String, String> request) {
    String ssoToken = request.get("ssoToken");

    if (ssoToken == null || ssoToken.isEmpty()) {
      return ResponseEntity.badRequest().body(Map.of("error", "SSO token is required"));
    }

    Optional<User> userOpt = ssoService.validateSsoToken(ssoToken);

    if (userOpt.isEmpty()) {
      return ResponseEntity.badRequest().body(Map.of("error", "Invalid or expired SSO token"));
    }

    User user = userOpt.get();

    if (!user.isEnabled()) {
      return ResponseEntity.badRequest().body(Map.of("error", "User account is disabled"));
    }

    // Generate a new JWT token for the user
    String jwtToken =
        jwtUtil.generateToken(
            org.springframework.security.core.userdetails.User.withUsername(user.getUsername())
                .password(user.getPassword())
                .authorities(
                    new org.springframework.security.core.authority.SimpleGrantedAuthority[0])
                .build());

    Map<String, Object> response = new HashMap<>();
    response.put("token", jwtToken);
    response.put(
        "user",
        Map.of(
            "username", user.getUsername(),
            "email", user.getEmail(),
            "roles", user.getRoles().stream().map(r -> r.getName().toString()).toList()));

    return ResponseEntity.ok(response);
  }

  /** Validate SSO token */
  @PostMapping("/validate")
  @PreAuthorize("@authorizationService.hasPermission('user:read')")
  public ResponseEntity<?> validateSsoToken(@RequestBody Map<String, String> request) {
    String ssoToken = request.get("ssoToken");

    if (ssoToken == null || ssoToken.isEmpty()) {
      return ResponseEntity.badRequest().body(Map.of("error", "SSO token is required"));
    }

    Optional<User> userOpt = ssoService.validateSsoToken(ssoToken);

    if (userOpt.isEmpty()) {
      return ResponseEntity.badRequest().body(Map.of("error", "Invalid or expired SSO token"));
    }

    User user = userOpt.get();

    return ResponseEntity.ok(
        Map.of(
            "valid",
            true,
            "user",
            Map.of(
                "username", user.getUsername(),
                "email", user.getEmail(),
                "roles", user.getRoles().stream().map(r -> r.getName().toString()).toList())));
  }

  /** Create SSO token for user */
  @PostMapping("/create-token")
  @PreAuthorize("@authorizationService.hasPermission('user:create')")
  public ResponseEntity<?> createSsoToken(@RequestBody Map<String, String> request) {
    String username = request.get("username");

    if (username == null || username.isEmpty()) {
      return ResponseEntity.badRequest().body(Map.of("error", "Username is required"));
    }

    // In a real implementation, you would authenticate the user first
    // For this example, we'll just create a token for any existing user

    return ResponseEntity.ok(Map.of("ssoToken", "sample_sso_token_for_" + username));
  }
}
