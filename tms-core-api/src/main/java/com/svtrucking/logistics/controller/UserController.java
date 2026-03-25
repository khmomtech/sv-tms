package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.domain.driver.DriverAccessGuard;
import com.svtrucking.logistics.dto.RegisterRequest;
import com.svtrucking.logistics.dto.UserDto;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.service.UserService;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/users")
@CrossOrigin(origins = "*")
public class UserController {

  private final UserService userService;
  private final RoleRepository roleRepository;
  private final UserRepository userRepository;
  private final DriverRepository driverRepository;
  private final PasswordEncoder passwordEncoder;
  private final DriverAccessGuard driverAccessGuard;

  private static final String ERROR_MESSAGE = "error";

  public UserController(
      UserService userService,
      RoleRepository roleRepository,
      UserRepository userRepository,
      DriverRepository driverRepository,
      PasswordEncoder passwordEncoder,
      DriverAccessGuard driverAccessGuard) {
    this.userService = userService;
    this.roleRepository = roleRepository;
    this.userRepository = userRepository;
    this.driverRepository = driverRepository;
    this.passwordEncoder = passwordEncoder;
    this.driverAccessGuard = driverAccessGuard;
  }

  // ------------------------------------------------------------------------
  //  GENERAL USER CRUD
  // ------------------------------------------------------------------------

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('user:read')")
  public ResponseEntity<List<UserDto>> getAllUsers() {
    return ResponseEntity.ok(userService.getAllUserDtos());
  }

  private void populateUserFromRequest(User user, RegisterRequest request) {
    user.setUsername(request.getUsername());
    user.setEmail(request.getEmail());

    if (request.getPassword() != null && !request.getPassword().isBlank()) {
      user.setPassword(passwordEncoder.encode(request.getPassword()));
    }

    // Handle enabled field (defaults to true if not provided)
    if (request.getEnabled() != null) {
      user.setEnabled(request.getEnabled());
    }

    Set<Role> userRoles = getValidRoles(request.getRoles());
    if (userRoles.isEmpty()) {
      throw new IllegalArgumentException("No valid roles found in database");
    }
    user.setRoles(userRoles);
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('user:create')")
  public ResponseEntity<?> createUser(@RequestBody RegisterRequest userRequest) {
    try {
      if (userRepository.existsByUsername(userRequest.getUsername())) {
        return ResponseEntity.badRequest().body(Map.of(ERROR_MESSAGE, "Username already exists!"));
      }

      User newUser = new User();
      populateUserFromRequest(newUser, userRequest);

      userRepository.save(newUser);
      return ResponseEntity.ok(
          Map.of("message", "User created successfully!", "user", UserDto.fromEntity(newUser)));
    } catch (IllegalArgumentException e) {
      return ResponseEntity.badRequest().body(Map.of(ERROR_MESSAGE, e.getMessage()));
    }
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('user:update')")
  public ResponseEntity<?> updateUser(
      @PathVariable Long id, @RequestBody RegisterRequest userRequest) {
    try {
      Optional<User> existingUser = userRepository.findById(id);
      if (existingUser.isEmpty()) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(Map.of(ERROR_MESSAGE, "User not found"));
      }

      User user = existingUser.get();
      populateUserFromRequest(user, userRequest);
      userRepository.save(user);

      return ResponseEntity.ok(
          Map.of("message", "User updated successfully!", "user", UserDto.fromEntity(user)));
    } catch (IllegalArgumentException e) {
      return ResponseEntity.badRequest().body(Map.of(ERROR_MESSAGE, e.getMessage()));
    }
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('user:delete')")
  public ResponseEntity<?> deleteUser(@PathVariable Long id) {
    if (userRepository.existsById(id)) {
      userRepository.deleteById(id);
      return ResponseEntity.ok(Map.of("message", "User deleted successfully"));
    } else {
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(Map.of(ERROR_MESSAGE, "User not found"));
    }
  }

  // ------------------------------------------------------------------------
  //  DRIVER LOGIN ACCOUNT CRUD (Admin)
  // ------------------------------------------------------------------------

  @PostMapping("/registerdriver")
  @PreAuthorize(
      "@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_ACCOUNT_MANAGE)"
          + " or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ResponseEntity<?> registerDriverAccount(
      @RequestParam Long driverId, @RequestBody RegisterRequest request) {
    try {
      Driver driver =
          driverRepository
              .findById(driverId)
              .orElseThrow(() -> new IllegalArgumentException("Driver not found"));

      driverAccessGuard.assertCanManageAccount(driverId);

      User user =
          (driver.getUser() != null)
              ? updateUserForDriver(driver.getUser(), request)
              : createUserForDriver(request);

      driver.setUser(user);
      driverRepository.save(driver);

      String message =
          (driver.getUser() != null) ? "Driver account updated" : "Driver account created";
      return ResponseEntity.ok(
          Map.of("message", message, "user", UserDto.fromEntity(user)));
    } catch (IllegalArgumentException e) {
      return ResponseEntity.badRequest().body(Map.of(ERROR_MESSAGE, e.getMessage()));
    }
  }

  private User createUserForDriver(RegisterRequest request) {
    User user = new User();
    populateUserFromRequest(user, request);
    return userRepository.save(user);
  }

  private User updateUserForDriver(User user, RegisterRequest request) {
    populateUserFromRequest(user, request);
    return userRepository.save(user);
  }

  @GetMapping("/driver-account/{driverId}")
  @PreAuthorize("@authorizationService.hasPermission('user:read')")
  public ResponseEntity<?> getDriverAccount(@PathVariable Long driverId) {
    Optional<Driver> driverOpt = driverRepository.findByIdWithUserAndRoles(driverId);
    if (driverOpt.isEmpty()) {
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(Map.of(ERROR_MESSAGE, "Driver not found"));
    }

    Driver driver = driverOpt.get();
    if (driver.getUser() != null) {
      return ResponseEntity.ok(UserDto.fromEntity(driver.getUser()));
    } else {
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(Map.of(ERROR_MESSAGE, "No user account linked to this driver"));
    }
  }

  @DeleteMapping("/driver-account/{driverId}")
  @PreAuthorize("@authorizationService.hasPermission('user:delete')")
  public ResponseEntity<?> deleteDriverAccount(@PathVariable Long driverId) {
    Optional<Driver> driverOpt = driverRepository.findById(driverId);
    if (driverOpt.isEmpty()) {
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(Map.of(ERROR_MESSAGE, "Driver not found"));
    }

    Driver driver = driverOpt.get();
    User user = driver.getUser();
    if (user != null) {
      driver.setUser(null);
      driverRepository.save(driver);
      userRepository.delete(user);
      return ResponseEntity.ok(Map.of("message", "Driver login account deleted"));
    } else {
      return ResponseEntity.status(HttpStatus.NOT_FOUND)
          .body(Map.of(ERROR_MESSAGE, "No user account linked to this driver"));
    }
  }

  // ------------------------------------------------------------------------
  // 🔁 UTIL
  // ------------------------------------------------------------------------

  private Set<Role> getValidRoles(Collection<String> roleStrings) {
    return roleStrings.stream()
        .map(role -> roleRepository.findByName(RoleType.valueOf(role.toUpperCase())).orElse(null))
        .filter(Objects::nonNull)
        .collect(Collectors.toSet());
  }
}
