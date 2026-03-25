# TMS Backend (Spring Boot) - Copilot Instructions

## Project Overview

This is the **single source of truth API server** for SV-TMS. All clients (Angular admin UI, Flutter driver app, Flutter customer app) authenticate and communicate through this backend.

**Stack:** Java 21, Spring Boot 3.5.7, MySQL 8.0, Redis 7, Firebase Admin SDK, MapStruct 1.6.3, Lombok 1.18.42, JWT authentication, STOMP WebSocket.

## Essential Commands

```bash
# Development (requires MySQL and Redis running)
./mvnw spring-boot:run

# Clean build (CRITICAL after MapStruct/Lombok changes)
./mvnw clean package

# Run tests (uses H2 in-memory DB)
./mvnw test

# Integration tests (requires docker-compose.test.yml)
docker compose -f docker-compose.test.yml up -d
./mvnw verify

# Package for production
./mvnw clean package -DskipTests

# Export OpenAPI spec
curl http://localhost:8080/v3/api-docs > api-spec.json
```

## Architecture Essentials

**API Boundary Enforcement** — Controllers are organized by client type:

```
src/main/java/com/svtrucking/logistics/controller/
├── admin/           # /api/admin/* - Admin/dispatcher UI only
├── driver/          # /api/driver/* - Driver mobile app only
├── customer/        # /api/customer/{id}/* - Customer mobile app only
└── auth/            # /api/auth/* - All clients (login, refresh, register)
```

**NEVER mix endpoint prefixes.** Each client type has isolated DTOs, services, and authorization rules.

**Key packages:**
```
src/main/java/com/svtrucking/logistics/
├── controller/              # REST endpoints (client-type organized)
├── service/                 # Business logic
├── repository/              # JPA repositories
├── model/                   # JPA entities (@Entity)
├── dto/                     # Data Transfer Objects
├── mapper/                  # MapStruct interfaces (DTO ↔ Entity)
├── security/                # JWT, AuthorizationService, SecurityConfig
├── websocket/               # STOMP WebSocket configuration
└── exception/               # Custom exceptions and @RestControllerAdvice
```

## Critical Build Patterns

### MapStruct + Lombok Integration

**ALWAYS run `./mvnw clean package` after modifying:**
- Any `@Mapper` interface in `mapper/` package
- Any entity with Lombok annotations (`@Data`, `@Builder`, `@Getter`, `@Setter`)
- Any DTO used in mapper interfaces

**Why:** Lombok generates getters/setters at compile-time → MapStruct needs these generated methods → annotation processors must run in correct order.

**pom.xml configuration:**
```xml
<lombok.version>1.18.42</lombok.version>
<org.mapstruct.version>1.6.3</org.mapstruct.version>

<!-- Annotation processor ordering -->
<annotationProcessorPaths>
  <path>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
  </path>
  <path>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok-mapstruct-binding</artifactId>
  </path>
  <path>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct-processor</artifactId>
  </path>
</annotationProcessorPaths>
```

**Troubleshooting:**
- "Cannot find symbol" on mapper method → Run `./mvnw clean package`
- "No property named X in class Y" → Check Lombok generated methods with `./mvnw clean compile` and inspect `target/generated-sources/annotations/`

## Authentication & Authorization

### JWT Token Flow

**Login endpoint:** `POST /api/auth/login`
```java
// Returns LoginResponse with:
{
  "code": "200",
  "message": "Login successful",
  "token": "eyJhbGci...",      // 15 min expiry
  "refreshToken": "refresh...", // 7 day expiry
  "user": {
    "username": "sotheakh",
    "roles": ["ROLE_DRIVER"],
    "permissions": ["driver:view_profile", "driver:update_location"],
    "driverId": 72,           // For driver clients
    "customerId": 123         // For customer clients
  }
}
```

**Security configuration:**
- `SecurityConfig.java` — Spring Security filter chain
- `JwtTokenProvider.java` — Token generation and validation
- `JwtAuthenticationFilter.java` — Extracts JWT from Authorization header
- `CustomUserDetailsService.java` — Loads user with roles and permissions

### Permission System (RBAC)

**AuthorizationService is the SINGLE source of truth for permission checks:**

```java
@Service
public class AuthorizationService {
    /**
     * CRITICAL: Checks for wildcard 'all_functions' permission FIRST
     * If user has all_functions → returns true immediately
     * Otherwise checks for specific permission
     */
    public boolean hasPermission(String permissionName) {
        Set<String> effectivePermissions = getEffectivePermissionNames();
        
        // Wildcard check
        if (effectivePermissions.stream()
                .anyMatch(p -> PermissionNames.ALL_FUNCTIONS.equalsIgnoreCase(p))) {
            return true;
        }
        
        // Specific permission check
        return effectivePermissions.stream()
                .anyMatch(p -> permissionName.equalsIgnoreCase(p));
    }
}
```

**Permission constants:**
```java
public class PermissionNames {
    public static final String ALL_FUNCTIONS = "all_functions"; // Wildcard
    
    // Driver permissions
    public static final String DRIVER_VIEW_ALL = "driver:view_all";
    public static final String DRIVER_MANAGE = "driver:manage";
    // ... 146 total permissions
}
```

**Usage in services:**
```java
@Service
public class DriverService {
    private final AuthorizationService authorizationService;
    
    public List<Driver> getAllDrivers() {
        if (!authorizationService.hasPermission(PermissionNames.DRIVER_VIEW_ALL)) {
            throw new AccessDeniedException("Insufficient permissions");
        }
        return driverRepository.findAll();
    }
}
```

**Permission initialization:**
- `PermissionInitializationService.java` runs on startup if `permissions.init.enabled=true`
- Seeds all required permissions defined in frontend into database
- Idempotent — safe to run multiple times

## WebSocket/STOMP Real-time Updates

**Configuration:** `WebSocketConfig.java` configures STOMP over SockJS.

**Endpoints:**
```
/ws                          # WebSocket handshake (requires ?token=<jwt>)
/topic/*                     # Broadcast to all subscribers
/user/queue/*                # User-specific messages
```

**Common patterns:**
```java
@Controller
public class NotificationController {
    private final SimpMessagingTemplate messagingTemplate;
    
    // Send to specific user
    public void notifyDriver(Long driverId, String message) {
        messagingTemplate.convertAndSendToUser(
            driverId.toString(),
            "/queue/notifications",
            message
        );
    }
}
```

**Client subscription examples:**
- Driver app: `/topic/assignments/driver/{driverId}`, `/topic/driver-notification/{driverId}`
- Admin UI: `/topic/dispatch/updates`, `/user/queue/notifications`

## Common Workflows

### Add New API Endpoint

1. **Create DTO:**
```java
@Data
@Builder
public class DriverCreateRequest {
    @NotBlank
    private String username;
    @Email
    private String email;
}
```

2. **Update Mapper:**
```java
@Mapper(componentModel = "spring")
public interface DriverMapper {
    Driver toEntity(DriverCreateRequest request);
    // Run: ./mvnw clean package
}
```

3. **Add Service Method:**
```java
@Service
public class DriverService {
    public DriverDTO createDriver(DriverCreateRequest request) {
        if (!authorizationService.hasPermission(PermissionNames.DRIVER_MANAGE)) {
            throw new AccessDeniedException("Cannot create driver");
        }
        
        Driver driver = driverMapper.toEntity(request);
        Driver saved = driverRepository.save(driver);
        return driverMapper.toDTO(saved);
    }
}
```

4. **Add Controller Endpoint:**
```java
@RestController
@RequestMapping("/api/admin/drivers")
public class DriverAdminController {
    @PostMapping
    public ResponseEntity<DriverDTO> createDriver(
            @Valid @RequestBody DriverCreateRequest request) {
        DriverDTO created = driverService.createDriver(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
}
```

5. **Regenerate OpenAPI clients:**
```bash
curl http://localhost:8080/v3/api-docs > api-spec.json
# Then regenerate Angular/Flutter clients
```

### Add Permission

1. **Define constant in `PermissionNames.java`:**
```java
public static final String NEW_FEATURE_ACCESS = "feature:access";
```

2. **Add to `PermissionInitializationService.java`:**
```java
private List<PermissionDefinition> getRequiredPermissions() {
    return Arrays.asList(
        new PermissionDefinition("feature:access", "Access new feature", "New Feature"),
        // ... existing permissions
    );
}
```

3. **Restart backend** (PermissionInitializationService runs on startup)

## Environment Configuration

**application.yml structure:**
```yaml
spring:
  profiles:
    active: dev
  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:mysql://localhost:3306/svlogistics_tms_db}
    username: ${SPRING_DATASOURCE_USERNAME:driver}
    password: ${SPRING_DATASOURCE_PASSWORD:driverpass}
  data:
    redis:
      host: ${SPRING_DATA_REDIS_HOST:localhost}

jwt:
  secret: ${JWT_SECRET:your-256-bit-secret}
  expiration: ${JWT_EXPIRATION:900000}  # 15 minutes

firebase:
  credentials-path: ${FIREBASE_CREDENTIALS_PATH:./firebase-admin-sdk.json}

permissions:
  init:
    enabled: ${PERMISSIONS_INIT_ENABLED:true}
```

## Common Pitfalls

1. **MapStruct not regenerating:** Run `./mvnw clean package`, not just `package`
2. **Permission denied errors:** Check `AuthorizationService.hasPermission()` and ensure user has required permission or `all_functions`
3. **JWT expiry:** Default 15 min; implement refresh token flow in clients
4. **WebSocket auth failing:** Token must be in query param: `/ws?token=<jwt>`
5. **Cross-client contamination:** Driver endpoint using admin DTOs or vice versa
6. **Java version mismatch:** `pom.xml` specifies Java 21; ensure `JAVA_HOME` matches

## Reference Documentation

- [ALL_FUNCTIONS_PERMISSION_AUDIT.md](../ALL_FUNCTIONS_PERMISSION_AUDIT.md) — Permission system deep dive
- [BACKEND_ANGULAR_DEBUG_GUIDE.md](../BACKEND_ANGULAR_DEBUG_GUIDE.md) — VS Code debug setup
- [CI_CD_QUICK_START.md](../CI_CD_QUICK_START.md) — Local testing before push
- [Root copilot-instructions.md](../.github/copilot-instructions.md) — Cross-project integration guide
- When adding new external dependencies, update `pom.xml`, run `./mvnw -DskipTests package`, and ensure the Dockerfile still builds (multi-stage copy uses `target/*.jar`).

If something is missing or ambiguous
- Search the repo for `firebase`, `application.properties`, `application.yml`, `@Controller`, `@RestController`, `@Configuration` to find where runtime wiring happens.
- If you see runtime errors in CI related to Java versions or annotation processing, call that out in the PR and suggest the simplest remediation (align Dockerfile JDK or change `pom.xml` java.version).

Quick checklist for PRs
- Compile locally with `./mvnw clean package` (fix compilation/MapStruct/Lombok issues). Run `./mvnw test`.
- Verify Docker build: `docker build -t driver-app .` and healthcheck responds on `/actuator/health`.
- Add/adjust unit tests (H2) where behavior changed; avoid changing production DB configs in tests.

If you want edits to this guidance or to include more precise file examples (controller names, specific config keys), tell me which areas are unclear and I will update this file.
