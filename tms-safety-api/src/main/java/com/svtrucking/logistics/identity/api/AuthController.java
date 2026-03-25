package com.svtrucking.logistics.identity.api;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.requests.ChangePasswordRequest;
import com.svtrucking.logistics.dto.responses.DriverLoginResponseDto;
import com.svtrucking.logistics.dto.LoginRequest;
import com.svtrucking.logistics.dto.RegisterDriverRequest;
import com.svtrucking.logistics.dto.RegisterRequest;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.identity.domain.DriverProfile;
import com.svtrucking.logistics.identity.domain.Role;
import com.svtrucking.logistics.identity.domain.User;
import com.svtrucking.logistics.identity.repository.DriverProfileRepository;
import com.svtrucking.logistics.identity.repository.RoleRepository;
import com.svtrucking.logistics.identity.repository.UserRepository;
import com.svtrucking.logistics.identity.device.DeviceRegistrationService;
import com.svtrucking.logistics.identity.service.RefreshTokenService;
import com.svtrucking.logistics.identity.service.UserPermissionService;
import com.svtrucking.logistics.infrastructure.security.JwtUtil;
import io.jsonwebtoken.JwtException;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.core.env.Environment;
import org.springframework.security.core.userdetails.UserDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for authentication operations.
 * Refactored to use consistent ApiResponse format and better separation of
 * concerns.
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
public class AuthController {

    @org.springframework.beans.factory.annotation.Value("${app.reviewer.bypass:false}")
    private boolean reviewerBypassEnabled;

    @org.springframework.beans.factory.annotation.Value("${app.reviewer.username:reviewer@test.sv}")
    private String reviewerUsername;

    @org.springframework.beans.factory.annotation.Value("${app.reviewer.create.secret:}")
    private String reviewerCreateSecret;

    @org.springframework.beans.factory.annotation.Value("${app.driver.skip-device-check:false}")
    private boolean skipDeviceCheck;

    @org.springframework.beans.factory.annotation.Value("${app.driver.login-bypass:false}")
    private boolean driverLoginBypassEnabled;

    private static final EnumSet<RoleType> ASSIGNABLE_ROLES = EnumSet.allOf(RoleType.class);

    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;
    private final RefreshTokenService refreshTokenService;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final DeviceRegistrationService deviceRegistrationService;
    private final UserPermissionService userPermissionService;
    private final PasswordEncoder passwordEncoder;
    private final DriverProfileRepository driverRepository;
    private final Environment environment;

    /**
     * Standard user login.
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<Map<String, Object>>> login(@RequestBody LoginRequest loginRequest) {
        try {
            String provided = loginRequest.getUsername();
            Optional<User> optionalUser = userRepository.findByUsernameWithRoles(provided);
            if (optionalUser.isEmpty()) {
                // Try email lookup, then re-fetch with roles
                Optional<User> userByEmail = userRepository.findByEmail(provided);
                if (userByEmail.isPresent()) {
                    optionalUser = userRepository.findByIdWithRoles(userByEmail.get().getId());
                }
            }
            if (optionalUser.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(ApiResponse.fail("Invalid username or password"));
            }

            User user = optionalUser.get();
            log.info("User found: {}, roles count: {}",
                    user.getUsername(), user.getRoles().size());

            if (!user.isEnabled()) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(ApiResponse.fail("User account is disabled"));
            }
            if (!user.isAccountNonLocked()) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(ApiResponse.fail("User account is locked"));
            }

            // Authenticate using resolved username
            String usernameToAuth = user.getUsername();
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(usernameToAuth, loginRequest.getPassword()));

            UserDetails userDetails = (UserDetails) authentication.getPrincipal();

            String access = jwtUtil.generateAccessToken(userDetails);
            String refresh = jwtUtil.generateRefreshToken(userDetails);

            // Persist refresh token
            java.util.Date issued = jwtUtil.extractRefreshIssuedAt(refresh);
            java.util.Date expires = jwtUtil.extractRefreshExpiration(refresh);
            Long userId = user.getId();
            String deviceInfo = loginRequest.getDeviceId();
            try {
                refreshTokenService.create(refresh, userId, issued, expires, deviceInfo);
            } catch (Exception ex) {
                log.warn("Failed to persist refresh token: {}", ex.getMessage());
            }

            var effectivePermissions = userPermissionService.getEffectivePermissionNames(user.getId()).stream()
                    .toList();

            Map<String, Object> response = new HashMap<>();
            response.put("code", "LOGIN_SUCCESS");
            response.put("message", "Login successful");
            response.put("token", access);
            response.put("refreshToken", refresh);

            // Build user info map with optional customerId
            Map<String, Object> userInfo = new HashMap<>();
            userInfo.put("username", user.getUsername());
            userInfo.put("email", user.getEmail());
            userInfo.put("roles", user.getRoles().stream().map(r -> r.getName().toString()).toList());
            userInfo.put("permissions", effectivePermissions);
            response.put("user", userInfo);

            return ResponseEntity.ok(ApiResponse.success("Login successful", response));

        } catch (Exception e) {
            log.error("Login failed for user {}: {}", loginRequest.getUsername(), e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail("Invalid username or password"));
        }
    }

    /**
     * Driver login with device validation.
     */
    @PostMapping("/driver/login")
    public ResponseEntity<ApiResponse<Map<String, Object>>> driverLogin(@RequestBody LoginRequest loginRequest) {
        try {
            final boolean isProd = Arrays.stream(environment.getActiveProfiles())
                    .anyMatch(p -> "prod".equalsIgnoreCase(p));
            final boolean effectiveSkipDeviceCheck = skipDeviceCheck && !isProd;
            final boolean effectiveReviewerBypassEnabled = reviewerBypassEnabled && !isProd;
            final boolean effectiveDriverLoginBypassEnabled = driverLoginBypassEnabled && !isProd;

            String provided = loginRequest.getUsername();
            Optional<User> optionalUser = userRepository.findByUsernameWithRoles(provided);
            if (optionalUser.isEmpty()) {
                // Try email lookup, then re-fetch with roles
                Optional<User> userByEmail = userRepository.findByEmail(provided);
                if (userByEmail.isPresent()) {
                    optionalUser = userRepository.findByIdWithRoles(userByEmail.get().getId());
                }
            }
            if (optionalUser.isEmpty() && effectiveDriverLoginBypassEnabled) {
                // Dev-only: auto-provision a user for bypass logins.
                User newUser = new User();
                newUser.setUsername(provided);
                String email = (provided != null && provided.contains("@"))
                        ? provided
                        : (provided + "@local.dev");
                newUser.setEmail(email);
                newUser.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
                newUser.setEnabled(true);
                newUser.setAccountNonLocked(true);
                newUser.setAccountNonExpired(true);
                newUser.setCredentialsNonExpired(true);
                newUser = userRepository.save(newUser);
                optionalUser = userRepository.findByIdWithRoles(newUser.getId());
                log.warn("DEV BYPASS: Auto-created user {} for driver login", newUser.getUsername());
            }
            if (optionalUser.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.fail("Driver not found"));
            }

            User user = optionalUser.get();

            if (!user.isEnabled()) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(ApiResponse.fail("User account is disabled"));
            }
            if (!user.isAccountNonLocked()) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(ApiResponse.fail("User account is locked"));
            }

            // Allow any authenticated user to use driver login, regardless of role.
            // If no driver record exists, create a minimal one for compatibility with
            // downstream driver-specific flows.
            Optional<DriverProfile> driverOpt = driverRepository.findByUserId(user.getId());
            DriverProfile driver;
            if (driverOpt.isEmpty()) {
                driver = new DriverProfile();
                driver.setUserId(user.getId());
                driver.setName(user.getUsername());
                driver.setPhone("+0000000000");
                driver.setActive(true);
                driver.setStatus(DriverStatus.ONLINE);
                driver = driverRepository.save(driver);
                log.info("Created driver record {} for user {}", driver.getId(), user.getUsername());
            } else {
                driver = driverOpt.get();
            }

            String deviceId = loginRequest.getDeviceId();

            // If skipDeviceCheck is enabled, do not require deviceId and bypass device
            // approval checks.
            if (!effectiveSkipDeviceCheck && !effectiveDriverLoginBypassEnabled) {
                if (deviceId == null || deviceId.isBlank()) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(ApiResponse.fail("Device ID is required"));
                }

                // Allow a server-side reviewer bypass when enabled via configuration.
                if (effectiveReviewerBypassEnabled && provided != null && provided.equalsIgnoreCase(reviewerUsername)) {
                    log.info("Reviewer bypass enabled - skipping device approval for {}", provided);
                } else {
                    String deviceStatus = deviceRegistrationService.getDeviceStatus(driver.getId(), deviceId);
                    switch (deviceStatus) {
                        case "NOT_REGISTERED":
                            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                    .body(ApiResponse.failWithCode(
                                            "Device not registered. Please register your device.",
                                            "DEVICE_NOT_REGISTERED"));
                        case "PENDING":
                            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                    .body(ApiResponse.failWithCode("Your device is pending admin approval.",
                                            "DEVICE_PENDING_APPROVAL"));
                        case "REJECTED":
                            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                    .body(ApiResponse.failWithCode("Your device was rejected by admin.",
                                            "DEVICE_REJECTED"));
                        case "APPROVED":
                            break;
                        default:
                            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                    .body(ApiResponse.failWithCode("Device not approved. Contact admin.",
                                            "DEVICE_NOT_APPROVED"));
                    }
                }
            } else {
                log.debug(
                        "Skipping device checks for driver login (skipDeviceCheck={}, driverLoginBypass={}, prod={})",
                        effectiveSkipDeviceCheck,
                        effectiveDriverLoginBypassEnabled,
                        isProd);
            }

            UserDetails userDetails;
            if (effectiveDriverLoginBypassEnabled) {
                // Dev-only: skip password verification and grant DRIVER authority for app
                // access.
                Set<String> authorities = new HashSet<>();
                for (var role : user.getRoles()) {
                    authorities.add("ROLE_" + role.getName().toString());
                }
                authorities.add("ROLE_" + RoleType.DRIVER.name());
                userDetails = org.springframework.security.core.userdetails.User.withUsername(user.getUsername())
                        .password(user.getPassword())
                        .authorities(authorities.toArray(new String[0]))
                        .build();
                log.warn("DEV BYPASS: Skipping password check for driver login {}", user.getUsername());
            } else {
                // Authenticate using resolved username
                String usernameToAuth = user.getUsername();
                Authentication authentication = authenticationManager.authenticate(
                        new UsernamePasswordAuthenticationToken(usernameToAuth, loginRequest.getPassword()));
                userDetails = (UserDetails) authentication.getPrincipal();
            }

            String access = jwtUtil.generateAccessToken(userDetails);
            String refresh = jwtUtil.generateRefreshToken(userDetails);

            // Persist refresh token
            java.util.Date issuedD = jwtUtil.extractRefreshIssuedAt(refresh);
            java.util.Date expiresD = jwtUtil.extractRefreshExpiration(refresh);
            Long uid = user.getId();
            String deviceInfo = loginRequest.getDeviceId();
            try {
                refreshTokenService.create(refresh, uid, issuedD, expiresD, deviceInfo);
            } catch (Exception ex) {
                log.warn("Failed to persist driver refresh token: {}", ex.getMessage());
            }

            var effectivePermissions = userPermissionService.getEffectivePermissionNames(user.getId()).stream()
                    .toList();

            DriverLoginResponseDto.DriverUserInfo userInfo = DriverLoginResponseDto.DriverUserInfo.builder()
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .roles(user.getRoles().stream().map(role -> role.getName().toString()).toList())
                    .permissions(effectivePermissions)
                    .driverId(driver.getId())
                    .zone(null)
                    .vehicleType(null)
                    .status(Optional.ofNullable(driver.getStatus()).orElse(DriverStatus.OFFLINE))
                    .build();

            Map<String, Object> response = new HashMap<>();
            response.put("code", "LOGIN_SUCCESS");
            response.put("message", "Login successful");
            response.put("token", access);
            response.put("refreshToken", refresh);
            response.put("user", userInfo);

            return ResponseEntity.ok(ApiResponse.success("Login successful", response));

        } catch (Exception e) {
            log.error("Driver login failed for user {}: {}", loginRequest.getUsername(), e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail("Invalid username or password"));
        }
    }

    /**
     * Refresh access token using refresh token.
     */
    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<Map<String, Object>>> refresh(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(ApiResponse.fail("Missing refresh token"));
            }
            String refreshToken = authHeader.substring(7);

            if (!jwtUtil.isRefreshToken(refreshToken)) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(ApiResponse.fail("Not a refresh token"));
            }

            String username = jwtUtil.extractUsernameFromRefresh(refreshToken);
            if (username == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(ApiResponse.fail("Invalid refresh token"));
            }

            var userOpt = userRepository.findByUsernameWithRoles(username);
            if (userOpt.isEmpty() || !userOpt.get().isEnabled()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(ApiResponse.fail("User invalid"));
            }

            var user = userOpt.get();

            // Ensure refresh token exists and is valid
            var rtOpt = refreshTokenService.findByToken(refreshToken);
            if (rtOpt.isEmpty() || !refreshTokenService.isValid(rtOpt.get())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(ApiResponse.fail("Refresh token invalid or revoked"));
            }

            var authorities = user.getRoles().stream().map(r -> r.getName().toString()).toArray(String[]::new);
            var userDetails = org.springframework.security.core.userdetails.User.withUsername(user.getUsername())
                    .password(user.getPassword())
                    .authorities(authorities)
                    .build();

            String newAccess = jwtUtil.generateAccessToken(userDetails);

            // Rotate refresh token
            String newRefresh = jwtUtil.generateRefreshToken(userDetails);
            try {
                java.util.Date issuedNew = jwtUtil.extractRefreshIssuedAt(newRefresh);
                java.util.Date expiresNew = jwtUtil.extractRefreshExpiration(newRefresh);
                refreshTokenService.create(newRefresh, user.getId(), issuedNew, expiresNew,
                        rtOpt.map(r -> r.getDeviceInfo()).orElse(null));
                rtOpt.ifPresent(refreshTokenService::revoke);
            } catch (Exception ex) {
                log.warn("Refresh rotation/persist failed: {}", ex.getMessage());
            }

            Map<String, Object> response = new HashMap<>();
            response.put("accessToken", newAccess);
            response.put("refreshToken", newRefresh);

            return ResponseEntity.ok(ApiResponse.success("Token refreshed", response));

        } catch (JwtException e) {
            log.error("JWT error during refresh: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail("Invalid refresh token"));
        } catch (Exception e) {
            log.error("Error during token refresh: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.fail("Server error during token refresh"));
        }
    }

    /**
     * Register a new user (admin only).
     */
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<String>> register(@RequestBody RegisterRequest registerRequest) {
        try {
            if (isBlank(registerRequest.getUsername()) ||
                    isBlank(registerRequest.getPassword()) ||
                    isBlank(registerRequest.getEmail())) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.fail("Username, email, and password are required"));
            }
            if (userRepository.existsByUsername(registerRequest.getUsername())) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.fail("Username already exists"));
            }

            Set<Role> roles = resolveRolesOrDefault(registerRequest.getRoles(), RoleType.USER);
            if (roles.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.fail("Invalid roles"));
            }

            User user = new User();
            user.setUsername(registerRequest.getUsername());
            user.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
            user.setEmail(registerRequest.getEmail());
            user.setRoles(roles);

            userRepository.save(user);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("User registered successfully"));

        } catch (Exception e) {
            log.error("Error registering user {}: {}", registerRequest.getUsername(), e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.fail("Failed to register user: " + e.getMessage()));
        }
    }

    /**
     * Register driver (fallback endpoint).
     */
    @PostMapping("/registerdriver")
    public ResponseEntity<ApiResponse<Map<String, Object>>> registerDriver(
            @RequestBody RegisterDriverRequest request) {
        try {
            if (isBlank(request.getUsername()) ||
                    isBlank(request.getPassword()) ||
                    isBlank(request.getEmail())) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.fail("Missing required fields"));
            }
            if (userRepository.existsByUsername(request.getUsername())) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.fail("Username already exists"));
            }

            Set<String> requestedRoles = new HashSet<>(Optional.ofNullable(request.getRoles()).orElseGet(HashSet::new));
            requestedRoles.add(RoleType.DRIVER.name());

            Set<Role> roles = resolveRoles(requestedRoles);
            if (roles.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.fail("Invalid roles"));
            }

            User user = new User();
            user.setUsername(request.getUsername());
            user.setPassword(passwordEncoder.encode(request.getPassword()));
            user.setEmail(request.getEmail());
            user.setRoles(roles);
            userRepository.save(user);

            // Create a new Driver record and associate the created User account.
            DriverProfile driver = new DriverProfile();
            driver.setUserId(user.getId());
            driver.setName(
                    request.getName() != null && !request.getName().isBlank()
                            ? request.getName().trim()
                            : request.getUsername());
            driver.setPhone(
                    request.getPhone() != null && !request.getPhone().isBlank()
                            ? request.getPhone().trim()
                            : null);
            // New drivers start inactive and offline until admin approves or verifies.
            driver.setActive(false);
            driver.setStatus(DriverStatus.OFFLINE);
            driverRepository.save(driver);

            Map<String, Object> response = new HashMap<>();
            response.put("username", user.getUsername());
            response.put("driverId", driver.getId());

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Driver registered successfully", response));

        } catch (Exception e) {
            log.error("Error registering driver: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.fail("Failed to register driver: " + e.getMessage()));
        }
    }

    /**
     * Change password for authenticated user.
     */
    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<String>> changePassword(@RequestBody ChangePasswordRequest request) {
        try {
            String username = SecurityContextHolder.getContext().getAuthentication().getName();
            Optional<User> userOpt = userRepository.findByUsername(username);
            if (userOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.fail("User not found"));
            }

            User user = userOpt.get();
            if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.fail("Incorrect current password"));
            }

            user.setPassword(passwordEncoder.encode(request.getNewPassword()));
            userRepository.save(user);
            return ResponseEntity.ok(ApiResponse.success("Password updated successfully"));

        } catch (Exception e) {
            log.error("Error changing password for user: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.fail("Failed to change password: " + e.getMessage()));
        }
    }

    // ---------- Utilities ----------
    private Set<Role> resolveRoles(Collection<String> roleNames) {
        if (roleNames == null || roleNames.isEmpty()) {
            return Set.of();
        }

        return roleNames.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(String::toUpperCase)
                .map(name -> {
                    try {
                        RoleType type = RoleType.valueOf(name);
                        if (!ASSIGNABLE_ROLES.contains(type)) {
                            return null;
                        }
                        return roleRepository.findByName(type).orElse(null);
                    } catch (IllegalArgumentException ex) {
                        return null;
                    }
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private Set<Role> resolveRolesOrDefault(Collection<String> roleNames, RoleType defaultRole) {
        Set<Role> resolved = resolveRoles(roleNames);
        if (!resolved.isEmpty()) {
            return resolved;
        }
        return resolveRoles(Set.of(defaultRole.name()));
    }

    private boolean isBlank(String val) {
        return val == null || val.trim().isEmpty();
    }
}
