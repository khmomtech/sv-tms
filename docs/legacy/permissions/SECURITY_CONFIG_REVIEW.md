> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Spring Security Configuration Review & Improvements

## Executive Summary

Fixed critical test failures caused by missing `AuthenticationManager` bean and improved the overall security architecture for the SV-TMS Driver App. The application now has proper separation between production and test security configurations.

## Issues Identified

### 1. Test Failures ❌
- **Error**: `No qualifying bean of type 'org.springframework.security.authentication.AuthenticationManager'`
- **Impact**: All Spring Boot tests failing, blocking CI/CD pipeline
- **Root Cause**: `SecurityConfig.java` was disabled (renamed to `.disabled`)

### 2. Security Configuration Issues ⚠️
- No active security configuration in production
- Missing authentication requirements
- No role-based access control
- **CRITICAL**: All endpoints currently permit anonymous access

### 3. Test Environment Issues
- No test-specific configuration
- Redis/WebSocket trying to initialize in tests
- MySQL dependency in test environment

## Solutions Implemented ✅

### 1. Re-enabled and Fixed SecurityConfig.java
**Location**: `driver-app/src/main/java/com/svtrucking/logistics/security/SecurityConfig.java`

**Changes**:
- Renamed from `.disabled` back to `.java`
- Fixed missing imports (`Arrays`, `@Value`, `AbstractHttpConfigurer`)
- Added `@Profile("!test")` to exclude from test runs
- Provides all required beans:
  - `AuthenticationManager` (via `AuthenticationConfiguration`)
  - `DaoAuthenticationProvider` (configured with `CustomUserDetailsService`)
  - `BCryptPasswordEncoder`
  - `SecurityFilterChain`
  - `CorsConfigurationSource`
  - `WebSecurityCustomizer` (WebSocket bypass)

**Current Status**:
```java
// ⚠️ TEMPORARY - ALL REQUESTS PERMITTED
.authorizeHttpRequests(authz -> authz
    .anyRequest().permitAll()
)
```

### 2. Created Test Security Configuration
**Location**: `driver-app/src/main/java/com/svtrucking/logistics/security/TestAuthConfig.java`

**Provides**:
- Mock `AuthenticationManager` (auto-approves all authentications)
- Same `BCryptPasswordEncoder` as production
- Permissive `SecurityFilterChain` for tests

**Active**: Only when `@Profile("test")` is set

### 3. Created Test Application Properties
**Location**: `driver-app/src/test/resources/application-test.properties`

**Key Features**:
- H2 in-memory database (MySQL compatibility mode)
- Disabled Redis auto-configuration
- Disabled WebSocket auto-configuration
- Test JWT secrets
- Minimal logging for faster tests

### 4. Updated Test Classes
**Location**: `driver-app/src/test/java/com/svtrucking/logistics/DriverAppApplicationTests.java`

**Change**:
```java
@SpringBootTest
@ActiveProfiles("test")  // ← Added to activate test profile
class DriverAppApplicationTests {
    @Test
    void contextLoads() {}
}
```

## Architecture

### Production Profile (`!test`)

```
Application Startup
     ↓
SecurityConfig.java (@Profile("!test"))
     ├─→ AuthenticationManager
     │    └─→ DaoAuthenticationProvider
     │         └─→ CustomUserDetailsService (DB)
     ├─→ BCryptPasswordEncoder
     ├─→ SecurityFilterChain
     │    ├─→ JwtAuthFilter
     │    ├─→ ApiKeyFilter
     │    └─→ CORS Configuration
     └─→ WebSecurityCustomizer (WebSocket bypass)
```

### Test Profile (`test`)

```
Test Execution
     ↓
TestAuthConfig.java (@Profile("test"))
     ├─→ Mock AuthenticationManager (auto-approve)
     ├─→ BCryptPasswordEncoder (same as prod)
     └─→ SecurityFilterChain (permitAll)
     
application-test.properties
     ├─→ H2 Database (in-memory)
     ├─→ Redis: DISABLED
     ├─→ WebSocket: DISABLED
     └─→ Test secrets
```

## Security Recommendations

### 🔴 CRITICAL - Must Fix Before Production

#### 1. Enable Proper Authorization Rules

Replace in `SecurityConfig.java`:

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http, 
    @Value("${app.cors.allowed-origins:http://localhost:4200}") String allowedOrigins) 
    throws Exception {
    http
        .csrf(AbstractHttpConfigurer::disable)
        .cors(cors -> cors.configurationSource(corsConfigurationSource(allowedOrigins)))
        .authorizeHttpRequests(authz -> authz
            // Public authentication endpoints
            .requestMatchers("/api/auth/login").permitAll()
            .requestMatchers("/api/auth/driver/login").permitAll()
            .requestMatchers("/api/auth/refresh").permitAll()
            .requestMatchers("/api/public/**").permitAll()
            
            // Admin-only endpoints
            .requestMatchers("/api/auth/register").hasRole("ADMIN")
            .requestMatchers("/api/auth/registerdriver").hasRole("ADMIN")
            .requestMatchers("/api/admin/**").hasRole("ADMIN")
            .requestMatchers(HttpMethod.DELETE, "/api/**").hasRole("ADMIN")
            
            // Driver-specific endpoints
            .requestMatchers("/api/driver/**").hasRole("DRIVER")
            .requestMatchers("/api/auth/change-password").authenticated()
            
            // Dispatcher endpoints
            .requestMatchers("/api/dispatch/**").hasAnyRole("DISPATCHER", "ADMIN")
            .requestMatchers("/api/orders/**").hasAnyRole("DISPATCHER", "ADMIN", "DRIVER")
            
            // Require authentication for everything else
            .anyRequest().authenticated()
        )
        .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        // Add JWT and API key filters
        .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
        .addFilterBefore(apiKeyFilter, JwtAuthFilter.class);

    return http.build();
}
```

#### 2. Enable CSRF for State-Changing Operations

If you have any session-based operations (not just JWT), consider enabling CSRF:

```java
.csrf(csrf -> csrf
    .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
    .ignoringRequestMatchers("/api/auth/**")  // JWT endpoints don't need CSRF
)
```

#### 3. Add Security Headers

```java
.headers(headers -> headers
    .frameOptions(HeadersConfigurer.FrameOptionsConfig::deny)
    .xssProtection(xss -> xss.disable())  // Use Content-Security-Policy instead
    .contentSecurityPolicy(csp -> csp
        .policyDirectives("default-src 'self'; script-src 'self' 'unsafe-inline'")
    )
)
```

### 🟡 MEDIUM Priority

#### 1. Implement Rate Limiting
Add rate limiting to prevent brute force attacks on login endpoints:

```java
@Configuration
public class RateLimitConfig {
    @Bean
    public RateLimiter loginRateLimiter() {
        return RateLimiter.create(5.0);  // 5 requests per second
    }
}
```

#### 2. Add Logging for Security Events

```java
@Bean
public AuthenticationEventPublisher authenticationEventPublisher(
        ApplicationEventPublisher applicationEventPublisher) {
    return new DefaultAuthenticationEventPublisher(applicationEventPublisher);
}

@Component
class AuthenticationEvents {
    private static final Logger log = LoggerFactory.getLogger(AuthenticationEvents.class);
    
    @EventListener
    public void onSuccess(AuthenticationSuccessEvent event) {
        log.info("Login successful: {}", event.getAuthentication().getName());
    }
    
    @EventListener
    public void onFailure(AbstractAuthenticationFailureEvent event) {
        log.warn("Login failed: {}", event.getException().getMessage());
    }
}
```

#### 3. Password Policy Validation

```java
@Component
public class PasswordValidator {
    public boolean isValid(String password) {
        // At least 8 characters
        if (password.length() < 8) return false;
        
        // Contains uppercase, lowercase, digit, special char
        return password.matches("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$");
    }
}
```

### 🟢 GOOD Practices Already Implemented

Stateless JWT authentication  
BCrypt password encoding  
Profile-based configuration separation  
CORS configuration with environment-specific origins  
WebSocket security bypass (for performance)  
Refresh token rotation  
Device-based authentication for drivers

## Testing Guidelines

### Unit Tests

```java
@SpringBootTest
@ActiveProfiles("test")
@AutoConfigureMockMvc
class SecurityTests {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    void anonymousUser_cannotAccessProtectedEndpoint() throws Exception {
        mockMvc.perform(get("/api/admin/users"))
               .andExpect(status().isUnauthorized());
    }
    
    @Test
    @WithMockUser(roles = "ADMIN")
    void adminUser_canAccessAdminEndpoint() throws Exception {
        mockMvc.perform(get("/api/admin/users"))
               .andExpect(status().isOk());
    }
    
    @Test
    @WithMockUser(roles = "DRIVER")
    void driverUser_cannotAccessAdminEndpoint() throws Exception {
        mockMvc.perform(get("/api/admin/users"))
               .andExpect(status().isForbidden());
    }
}
```

### Integration Tests

```java
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class AuthenticationIntegrationTest {
    
    @Autowired
    private TestRestTemplate restTemplate;
    
    @Test
    void loginFlow_withValidCredentials_returnsToken() {
        LoginRequest request = new LoginRequest("testuser", "password");
        
        ResponseEntity<Map> response = restTemplate.postForEntity(
            "/api/auth/login",
            request,
            Map.class
        );
        
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).containsKey("token");
    }
}
```

## Code Quality Improvements

### 1. Extract Magic Strings to Constants

```java
public class SecurityConstants {
    public static final String[] PUBLIC_ENDPOINTS = {
        "/api/auth/login",
        "/api/auth/driver/login",
        "/api/auth/refresh",
        "/api/public/**"
    };
    
    public static final String[] ADMIN_ENDPOINTS = {
        "/api/admin/**",
        "/api/auth/register"
    };
}
```

### 2. Use Method Security

Enable method-level security (already present via `@EnableMethodSecurity`):

```java
@Service
public class UserService {
    
    @PreAuthorize("hasRole('ADMIN')")
    public void deleteUser(Long userId) {
        // Only admins can delete users
    }
    
    @PreAuthorize("#userId == authentication.principal.id or hasRole('ADMIN')")
    public User updateUser(Long userId, UpdateUserRequest request) {
        // Users can update themselves, admins can update anyone
    }
}
```

### 3. Custom Security Expressions

```java
@Component("securityService")
public class SecurityService {
    
    public boolean isOwnerOrAdmin(Long resourceOwnerId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return false;
        
        UserDetails user = (UserDetails) auth.getPrincipal();
        return user.getUsername().equals(String.valueOf(resourceOwnerId))
            || auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }
}

// Usage
@PreAuthorize("@securityService.isOwnerOrAdmin(#userId)")
public void updateProfile(Long userId, ProfileUpdate update) {
    // ...
}
```

## Deployment Checklist

Before deploying to production:

- [ ] Tests passing (`./mvnw clean test`)
- [ ] ❌ **Replace `permitAll()` with proper authorization rules**
- [ ] ❌ Configure production JWT secrets (NOT the test values!)
- [ ] ❌ Enable HTTPS/TLS
- [ ] ❌ Configure production CORS origins
- [ ] ❌ Set up security monitoring/alerting
- [ ] ❌ Document API authentication requirements
- [ ] ❌ Perform penetration testing
- [ ] ❌ Review and rotate secrets
- [ ] ❌ Set up rate limiting
- [ ] ❌ Enable security headers
- [ ] ❌ Implement account lockout after failed attempts

## Monitoring & Alerts

### Key Metrics to Track

1. **Authentication Failures**  
   - Alert if > 10 failures per minute from same IP
   - Alert if > 100 failures per minute globally

2. **Unauthorized Access Attempts**  
   - Log all 401/403 responses
   - Alert on unusual patterns

3. **Token Refresh Rate**  
   - Monitor for potential token theft

4. **Session Duration**  
   - Alert on suspiciously long sessions

### Example Metrics Configuration (Prometheus)

```java
@Component
public class SecurityMetrics {
    private final Counter authFailures;
    private final Counter authSuccesses;
    private final Counter unauthorizedAttempts;
    
    public SecurityMetrics(MeterRegistry registry) {
        this.authFailures = Counter.builder("auth.failures")
            .description("Authentication failures")
            .register(registry);
        // ... etc
    }
}
```

## Additional Resources

- [Spring Security Reference](https://docs.spring.io/spring-security/reference/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Spring Security Architecture](https://spring.io/guides/topicals/spring-security-architecture)

## Summary

**Fixed**: Test failures resolved  
**Improved**: Proper separation of prod/test security  
**Created**: Comprehensive test configuration  
❌ **TODO**: Enable proper authorization rules in production  
❌ **TODO**: Implement additional security hardening

**Status**: Tests passing, but **SECURITY CONFIGURATION INCOMPLETE FOR PRODUCTION**

---

**Last Updated**: 2025-11-16  
**Next Review**: Before production deployment  
**Reviewer**: Security team sign-off required
