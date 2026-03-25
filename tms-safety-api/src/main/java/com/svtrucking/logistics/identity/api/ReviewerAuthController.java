package com.svtrucking.logistics.identity.api;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.identity.domain.DriverProfile;
import com.svtrucking.logistics.identity.domain.Role;
import com.svtrucking.logistics.identity.domain.User;
import com.svtrucking.logistics.identity.repository.DriverProfileRepository;
import com.svtrucking.logistics.identity.repository.RoleRepository;
import com.svtrucking.logistics.identity.repository.UserRepository;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Review-only endpoints used for App Store / TestFlight workflows.
 *
 * Enabled only when SPRING_PROFILES_ACTIVE includes "review".
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
@Profile("review")
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
public class ReviewerAuthController {

  @Value("${app.reviewer.bypass:false}")
  private boolean reviewerBypassEnabled;

  @Value("${app.reviewer.username:reviewer@test.sv}")
  private String reviewerUsername;

  @Value("${app.reviewer.create.secret:}")
  private String reviewerCreateSecret;

  private final UserRepository userRepository;
  private final RoleRepository roleRepository;
  private final DriverProfileRepository driverRepository;
  private final PasswordEncoder passwordEncoder;

  /**
   * Create a reviewer user + driver for App Store review.
   * This endpoint only works when app.reviewer.bypass=true and the request
   * includes header X-Reviewer-Create-Secret matching server config.
   */
  @PostMapping("/create-reviewer")
  public ResponseEntity<ApiResponse<String>> createReviewer(
      @RequestHeader(value = "X-Reviewer-Create-Secret", required = false) String secret,
      @RequestBody(required = false) Map<String, String> body) {
    try {
      if (!reviewerBypassEnabled) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(ApiResponse.fail("Reviewer creation disabled on this server"));
      }
      if (reviewerCreateSecret == null || reviewerCreateSecret.isBlank()) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(ApiResponse.fail("Reviewer creation secret not configured"));
      }
      if (secret == null || !secret.equals(reviewerCreateSecret)) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(ApiResponse.fail("Invalid create reviewer secret"));
      }

      String username = body != null ? body.get("username") : null;
      String password = body != null ? body.get("password") : null;
      if (username == null || username.isBlank()) {
        username = reviewerUsername;
      }
      if (password == null || password.isBlank()) {
        return ResponseEntity.badRequest().body(ApiResponse.fail("Password is required"));
      }
      if (password.length() < 10) {
        return ResponseEntity.badRequest().body(ApiResponse.fail("Password must be at least 10 characters"));
      }

      if (userRepository.existsByUsername(username)) {
        return ResponseEntity.ok(ApiResponse.success("Reviewer already exists"));
      }

      User user = new User();
      user.setUsername(username);
      user.setEmail(username);
      user.setPassword(passwordEncoder.encode(password));
      user.setEnabled(true);
      user.setAccountNonLocked(true);
      user.setAccountNonExpired(true);
      user.setCredentialsNonExpired(true);
      userRepository.save(user);

      Optional<Role> driverRoleOpt = roleRepository.findByName(RoleType.DRIVER);
      if (driverRoleOpt.isPresent()) {
        user.getRoles().add(driverRoleOpt.get());
        userRepository.save(user);
      }

      DriverProfile driver = new DriverProfile();
      driver.setUserId(user.getId());
      driver.setName("App Reviewer");
      driver.setPhone("+0000000000");
      driver.setStatus(DriverStatus.ONLINE);
      driver.setActive(true);
      driverRepository.save(driver);

      return ResponseEntity.ok(ApiResponse.success("Reviewer user and driver created"));
    } catch (Exception e) {
      log.error("Failed to create reviewer: {}", e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(ApiResponse.fail("Failed to create reviewer"));
    }
  }

  /**
   * Helper to check reviewer bypass status. Available only in the "review" profile.
   */
  @GetMapping("/reviewer-status")
  public ResponseEntity<ApiResponse<Map<String, Object>>> reviewerStatus() {
    Map<String, Object> info = new HashMap<>();
    info.put("reviewerBypassEnabled", reviewerBypassEnabled);
    info.put("reviewerUsername", reviewerUsername);
    return ResponseEntity.ok(ApiResponse.success("Reviewer status", info));
  }
}
