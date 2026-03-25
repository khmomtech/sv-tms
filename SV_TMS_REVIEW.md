# SV-TMS Code Quality & Performance Review

**Date:** 2026-03-09
**Scope:** `tms-backend` (Spring Boot 3.5.7 / Java 21), `tms-frontend` (Angular 19),
`tms_driver_app` (Flutter 3.5+), Docker infrastructure
**Review type:** Code quality + Performance

---

## Executive Summary

| Severity | Count |
| -------- | ----- |
| CRITICAL | 3     |
| HIGH     | 7     |
| MEDIUM   | 8     |
| LOW      | 4     |

Three critical issues require immediate action before the next production deploy:
secrets exist in committed `.env` files, the integration API guard fails open when
unconfigured, and JWT tokens are stored in `localStorage` making them readable by
any XSS payload. Seven high severity issues include an unprotected login endpoint
(brute-force), a broken password-reset feature, and the production Docker Compose
running MySQL as `root`. Remaining medium and low issues cover maintainability and
performance: 71 `Optional.isPresent()/.get()` anti-patterns, broad exception swallowing,
bundle bloat from three CSS frameworks, and missing HSTS.

---

## Severity Legend

| Tier         | Criteria                                                                                                                                       |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **CRITICAL** | Exploitable without authentication, allows data exfiltration, account takeover, or secrets leak. Fix before next deploy.                       |
| **HIGH**     | Requires partial access or specific conditions to exploit; broken features with security impact; production misconfiguration. Fix this sprint. |
| **MEDIUM**   | Degrades reliability, observability, or performance under load; technical debt with measurable impact. Schedule within current cycle.          |
| **LOW**      | Style, maintainability, optional hardening. Backlog.                                                                                           |

---

## CRITICAL Issues

---

### [C-01] JWT secrets and API keys committed in `.env` files

**Component:** Backend / Infrastructure
**Files:**

- `tms-backend/.env`
- `tms-safety-api/.env`

**Finding:**
Both `.env` files exist on disk and contain plaintext credentials including
`JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `APP_API_KEY`, and
`APP_REVIEWER_CREATE_SECRET`. While the root `.gitignore` lists `.env`, the
files exist on disk — verify with `git log --all --full-history -- "**/.env"`
whether they ever entered the repository's object store.

**Evidence (redacted):**

```
# tms-backend/.env
JWT_ACCESS_SECRET=<secret>
JWT_REFRESH_SECRET=<secret>
APP_API_KEY=<key>
APP_REVIEWER_CREATE_SECRET=<secret>
```

**Risk:**
Any developer with repository access, or anyone who obtains a git history dump,
can forge arbitrary JWTs for any user and call protected integration endpoints
with a valid API key.

**Recommended Fix:**

1. Rotate all secrets immediately — assume they are compromised.
2. Remove the files from disk and purge from git history:
   ```bash
   git filter-repo --invert-paths --path tms-backend/.env --path tms-safety-api/.env
   ```
3. Inject secrets exclusively via runtime environment variables (Docker secrets,
   a secrets manager, or CI/CD encrypted variables). Never store them in files
   that could be committed.
4. Add `detect-secrets` as a pre-commit hook to block future secret commits:
   ```yaml
   # .pre-commit-config.yaml
   - repo: https://github.com/Yelp/detect-secrets
     rev: v1.4.0
     hooks:
       - id: detect-secrets
   ```

---

### [C-02] `ApiKeyFilter` fails open when `app.api.key` is not configured

**Component:** Backend
**File:** `tms-backend/src/main/java/com/svtrucking/logistics/security/ApiKeyFilter.java:25-27`

**Finding:**
The filter reads `app.api.key` with a blank default (`@Value("${app.api.key:}")`).
When the property is blank or absent, the guard short-circuits with
`filterChain.doFilter()` and returns, granting unauthenticated access to
every `/api/v1/integrations/*` endpoint.

**Evidence:**

```java
// ApiKeyFilter.java
@Value("${app.api.key:}")
private String validApiKey;          // line 15-16: default is blank

if (validApiKey == null || validApiKey.isBlank()) {
    filterChain.doFilter(request, response);  // line 25-27: fail-OPEN
    return;
}
```

**Risk:**
On any environment where `app.api.key` is not explicitly set (missed in staging,
misconfigured container), the integration API surface is fully public. An attacker
can POST to push external order data, trigger callbacks, or exfiltrate integration
payloads with no credentials.

**Recommended Fix:**
Fail closed. Assert the key is configured at startup:

```java
@PostConstruct
public void validateConfig() {
    if (validApiKey == null || validApiKey.isBlank()) {
        throw new IllegalStateException(
            "app.api.key must be configured. Integration endpoints are disabled.");
    }
}
```

For test environments, set a deterministic test key (`app.api.key=test-key`)
rather than leaving the property blank.

---

### [C-03] JWT access and refresh tokens stored in `localStorage` (XSS-accessible)

**Component:** Frontend
**Files:**

- `tms-frontend/src/app/services/auth.service.ts:205, 224, 229, 233, 422-423`
- `tms-frontend/src/app/pages/bulk-dispatch-upload/bulk-dispatch-upload.component.ts:200`
- `tms-frontend/src/app/services/driver-location.service.ts:704`

**Finding:**
`AuthService` writes both the access token (`'token'`) and refresh token
(`'refresh_token'`) directly to `localStorage`. Any JavaScript running in the
page — including from XSS, injected ads, or malicious npm packages — can read
`localStorage` via `window.localStorage` without any restrictions.
The nginx CSP includes `'unsafe-inline'` in `script-src` (see M-02), which means
CSP does not block inline XSS payloads from accessing these tokens.

**Evidence:**

```typescript
// auth.service.ts
localStorage.setItem('token', token);            // line 205
localStorage.setItem('refresh_token', refreshToken); // line 224

getToken(): string | null {
  return localStorage.getItem('token');          // line 229
}
getRefreshToken(): string | null {
  return localStorage.getItem('refresh_token');  // line 233
}
```

**Risk:**
A successful XSS attack (one malicious script tag, one unsafe eval) directly
exfiltrates both the access and refresh tokens to attacker infrastructure,
enabling full account takeover with extended persistence (the refresh token lives
for 14 days per `SecurityConfig`).

**Recommended Fix:**
Migrate tokens to `httpOnly; Secure; SameSite=Strict` cookies managed by the
backend. This requires:

1. Backend: issue `Set-Cookie` headers on login/refresh responses instead of
   returning tokens in the JSON body.
2. Frontend: remove all `localStorage.setItem('token', ...)` calls; the browser
   will send the cookies automatically.
3. Backend CORS config already has `setAllowCredentials(true)` — this is the
   required flag for cross-origin cookie forwarding.

If cookie migration is deferred, switching to `sessionStorage` (cleared on tab
close) reduces the attack window while the full fix is implemented.

---

## HIGH Issues

---

### [H-01] No rate limiting on login endpoints — brute-force attack surface

**Component:** Backend
**File:** `tms-backend/src/main/java/com/svtrucking/logistics/controller/AuthController.java`

**Finding:**
`POST /api/auth/login` and `POST /api/auth/driver/login` are explicitly
`permitAll()` in `SecurityConfig.java:112-118` with no rate-limiting filter,
no Bucket4j annotation, no Resilience4j `@RateLimiter`, and no nginx
`limit_req_zone` directive. An attacker can send unlimited login attempts
at full network speed.

**Evidence:**

```java
// SecurityConfig.java:112-118
authz.requestMatchers(
    "/error",
    "/api/auth/login",
    "/api/auth/refresh",
    "/api/auth/driver/login",
    "/api/auth/driver/**")
  .permitAll();
// No rate-limiting filter added before or after this config
```

**Risk:**
Credential stuffing and brute-force attacks against all admin and driver
accounts with no throttle, lockout, or detection.

**Recommended Fix:**
Add Bucket4j with a per-IP rate limit on login methods:

```java
// Add to pom.xml
<dependency>
  <groupId>com.bucket4j</groupId>
  <artifactId>bucket4j-core</artifactId>
  <version>8.10.1</version>
</dependency>

// @PostMapping("/login")
@RateLimiter(name = "login")   // configure in application.yml
public ResponseEntity<?> login(...) { ... }
```

Alternatively, configure nginx `limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m` upstream of the backend. Add an account lockout after 10 consecutive failures.

---

### [H-02] `DEV_SECURITY_BYPASS` flag can disable driver location auth via environment variable

**Component:** Backend
**File:** `tms-backend/src/main/java/com/svtrucking/logistics/security/SecurityConfig.java:60-83, 107-109`

**Finding:**
When `DEV_SECURITY_BYPASS=true` and the active Spring profile is `local`, `dev`,
or `test`, `POST /api/driver/location/update` becomes `permitAll()`. Profile names
are developer-controlled strings — a staging or CI server running with profile `dev`
and this environment variable set would expose the endpoint unauthenticated.

**Evidence:**

```java
// SecurityConfig.java:60-83
final boolean isLocalLike =
    Arrays.stream(environment.getActiveProfiles())
        .anyMatch(p ->
            "local".equalsIgnoreCase(p)
            || "dev".equalsIgnoreCase(p)
            || "test".equalsIgnoreCase(p));        // line 61-67
// ...
_tmp = requestedBypass && !isProd;                 // line 78: only "prod" is protected

// SecurityConfig.java:107-109
if (devBypass) {
    authz.requestMatchers("/api/driver/location/update").permitAll();
}
```

**Risk:**
Unauthenticated GPS coordinate injection for any driver, enabling location spoofing
or phantom location writes that corrupt dispatch tracking in non-prod environments
that are monitored or reviewed by stakeholders.

**Recommended Fix:**
Remove the `devBypass` block entirely. Use a test-scoped Spring Security config
for integration tests instead:

```java
@TestConfiguration
@Profile("test")
public class TestSecurityConfig {
    @Bean
    @Order(1)
    SecurityFilterChain testFilterChain(HttpSecurity http) throws Exception {
        return http.csrf(AbstractHttpConfigurer::disable)
            .authorizeHttpRequests(a -> a.anyRequest().permitAll())
            .build();
    }
}
```

---

### [H-03] File upload accepts any MIME type with no validation

**Component:** Backend
**File:** `tms-backend/src/main/java/com/svtrucking/logistics/service/FileStorageService.java:26-42`

**Finding:**
`storeFileInSubfolder()` accepts any `MultipartFile`, prepends a UUID prefix
(good), checks for `..` in the filename (good), but performs zero content-type
or file-extension validation. `StandardCopyOption.REPLACE_EXISTING` on line 42
additionally allows any upload to silently overwrite a previously stored file
with a matching generated name (UUID collision is unlikely but the flag removes
any safeguard). The `/uploads/**` path is `permitAll()` in `SecurityConfig.java:131`.

**Evidence:**

```java
// FileStorageService.java:25-42
public String storeFileInSubfolder(MultipartFile file, String subFolder) {
    String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());
    String fileName = UUID.randomUUID() + "_" + originalFileName;
    // No MIME-type or extension check
    // ...
    Files.copy(file.getInputStream(), targetLocation,
        StandardCopyOption.REPLACE_EXISTING);   // line 42
    return fileStorageProperties.publicUrl(subFolder, fileName);
}
```

**Risk:**
An authenticated user (any role) can upload an `.html`, `.svg`, or `.js` file.
Because `/uploads/**` is publicly accessible and served directly by the container,
the uploaded file can be rendered in a visitor's browser, enabling stored XSS.
If the uploads directory is inside the nginx web root, a `.html` file served with
`text/html` content-type is a persistent XSS vector for every visitor.

**Recommended Fix:**

1. Whitelist accepted MIME types using Apache Tika (content sniffing, not
   extension trust):

   ```java
   private static final Set<String> ALLOWED_TYPES = Set.of(
       "image/jpeg", "image/png", "image/gif", "image/webp",
       "application/pdf");

   String detectedType = new Tika().detect(file.getInputStream());
   if (!ALLOWED_TYPES.contains(detectedType)) {
       throw new IllegalArgumentException("File type not allowed: " + detectedType);
   }
   ```

2. Remove `StandardCopyOption.REPLACE_EXISTING` — throw or rename on collision.
3. Serve uploaded files from a path that is NOT the web root, or add a
   `Content-Disposition: attachment` header to the serving endpoint so browsers
   download rather than render uploaded files.

---

### [H-04] Password reset email never sent — feature silently broken in production

**Component:** Backend
**File:** `tms-backend/src/main/java/com/svtrucking/logistics/service/PasswordResetService.java:38-44`

**Finding:**
`createAndSendToken()` generates a valid UUID token, persists it to the database
with a 1-hour expiry, then hits a TODO comment and returns. No email is ever sent.
The method name and API contract (`POST /api/auth/password-reset/request`) imply
the user receives a reset link, but the link never arrives.

**Evidence:**

```java
// PasswordResetService.java:38-44
token.setToken(UUID.randomUUID().toString());
token.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));
tokenRepo.save(token);                           // token persisted to DB

// TODO: integrate with email service. For now, assume email sent.
log.info("Password reset requested for user: {}", user.getUsername());
// method returns — no email sent
```

**Risk:**
Any user who loses their password cannot recover their account without direct
database or admin intervention. This is a complete functional outage of the
password recovery flow in production.

**Recommended Fix:**
Add `spring-boot-starter-mail` and wire a Thymeleaf email template:

```java
// application.yml
spring.mail.host: smtp.example.com
spring.mail.port: 587
spring.mail.username: ${MAIL_USERNAME}
spring.mail.password: ${MAIL_PASSWORD}

// PasswordResetService.java
private final JavaMailSender mailSender;

// Replace the TODO comment with:
SimpleMailMessage msg = new SimpleMailMessage();
msg.setTo(user.getEmail());
msg.setSubject("Password Reset Request");
msg.setText("Reset your password: " + baseUrl + "/reset-password?token=" + token.getToken());
mailSender.send(msg);
```

---

### [H-05] GPS spoofing alerts detected but never persisted or acted upon

**Component:** Backend
**File:** `tms-backend/src/main/java/com/svtrucking/logistics/controller/drivers/DriverLocationController.java:448-477`

**Finding:**
The `POST /api/locations/spoofing-alert` endpoint receives spoofing reports from
the mobile app, logs a WARN-level message, and returns HTTP 200. Three TODO comments
document the intended behaviour that was never implemented: persist the alert,
notify an admin, and auto-suspend the driver after repeated attempts.

**Evidence:**

```java
// DriverLocationController.java:466-468
// TODO: Store in database for investigation
// TODO: Send notification to admin
// TODO: Auto-suspend driver account if repeated attempts (>5 in 1 hour)
```

**Risk:**
GPS spoofing by drivers goes completely unrecorded. There is no audit trail,
no admin visibility, and no enforcement mechanism. Spoofing detection in the
mobile app provides a false sense of security.

**Recommended Fix:**

1. Create a `SpoofingAlertEntity` / `SpoofingAlertRepository` and persist every
   alert with driver ID, timestamp, coordinates claimed vs. detected, and device
   fingerprint.
2. Add a `@Scheduled` job (or an inline threshold check) that counts alerts per
   driver in the last hour and triggers the existing admin notification system
   when the threshold is exceeded.
3. Wire a `DRIVER_SUSPENDED` event to the dispatch workflow if the threshold is
   breached, consistent with the existing `DispatchStateMachine` patterns.

---

### [H-06] JJWT 0.11.5 is outdated (0.12.6 available with key algorithm enforcement)

**Component:** Backend
**File:** `tms-backend/pom.xml:103-118`

**Finding:**
All three JJWT artifacts are pinned to `0.11.5`. The `0.12.x` line introduced
mandatory algorithm validation (the parser must now specify the expected algorithm),
fixed API deprecations on `Jwts.parserBuilder()`, and made the builder API fully
type-safe. The `0.11.x` API allows building JWTs without explicitly naming the
algorithm, which can permit algorithm confusion in edge cases.

**Evidence:**

```xml
<!-- pom.xml:103-118 -->
<dependency>
  <groupId>io.jsonwebtoken</groupId>
  <artifactId>jjwt-api</artifactId>
  <version>0.11.5</version>       <!-- outdated -->
</dependency>
<!-- same version for jjwt-impl and jjwt-jackson -->
```

**Recommended Fix:**
Upgrade all three artifacts to `0.12.6`:

```xml
<version>0.12.6</version>
```

Update `JwtUtil.java` to the 0.12 parser API (the `parserBuilder()` is replaced
by `Jwts.parser().verifyWith(key).build()`). The migration is straightforward;
the 0.11 API still compiles but generates deprecation warnings.

---

### [H-07] MySQL container runs as root DB user with no memory limits

**Component:** Infrastructure
**File:** `docker-compose.yml:8-10, 27-30`

**Finding:**
The MySQL service is initialised with `MYSQL_ROOT_PASSWORD: rootpass` and the
backend connects as `SPRING_DATASOURCE_USERNAME: root`. Additionally, neither the
MySQL nor the backend service defines memory limits, allowing an OOM event in one
container to cascade across the entire stack.

**Evidence:**

```yaml
# docker-compose.yml:8-10
environment:
  MYSQL_ROOT_PASSWORD: rootpass    # plain-text in Compose file

# docker-compose.yml:27-30
environment:
  SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/svlogistics_tms_db...
  SPRING_DATASOURCE_USERNAME: root   # application uses root credentials
  SPRING_DATASOURCE_PASSWORD: root   # plain-text password
```

**Risk:**
If a SQL injection vulnerability is found anywhere in the backend, the attacker
operates with full MySQL root privileges: `GRANT`, `DROP`, `FILE`, `SUPER`.
Without memory limits, a slow query flood or memory leak in one service can
exhaust host memory and kill the entire container stack.

**Recommended Fix:**

1. Create a least-privilege application user during DB initialisation:
   ```sql
   CREATE USER 'svapp'@'%' IDENTIFIED BY '<strong-password>';
   GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX
     ON svlogistics_tms_db.* TO 'svapp'@'%';
   ```
2. Update Compose to use the application user credentials:
   `SPRING_DATASOURCE_USERNAME: svapp`
3. Move the password to a Docker secret or environment variable file excluded
   from version control.
4. Add resource limits:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 2G
   ```

---

## MEDIUM Issues

---

### [M-01] HSTS header commented out in nginx.conf

**Component:** Frontend / Infrastructure
**File:** `tms-frontend/nginx.conf:24-25`

**Finding:**
The HSTS header is present but disabled with a comment ("enable after SSL setup"):

```nginx
# add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

**Risk:**
Browsers will accept plain HTTP connections to the application, enabling protocol
downgrade attacks (SSL-strip) on networks the user does not control.

**Recommended Fix:**
Enable the header once TLS is confirmed on the production load balancer.
Do not include `preload` until all subdomains are confirmed to support HTTPS,
as HSTS preloading is very difficult to reverse.

---

### [M-02] CSP `script-src` contains `'unsafe-inline'` and `'unsafe-eval'` — header is ineffective

**Component:** Frontend / Infrastructure
**File:** `tms-frontend/nginx.conf:22`

**Finding:**
The Content-Security-Policy header is set but its `script-src` directive includes
`'unsafe-inline'` and `'unsafe-eval'`. This negates the primary purpose of a CSP:
preventing arbitrary script execution. Combined with the localStorage token storage
(C-03), a successful XSS leads directly to credential theft.

**Evidence:**

```nginx
# nginx.conf:22
add_header Content-Security-Policy "default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval'
  https://maps.googleapis.com ...;" always;
```

**Recommended Fix:**

1. Remove `'unsafe-eval'` — Angular production builds do not require it.
2. Remove `'unsafe-inline'` — move all inline scripts to external `.js` files.
3. If the Angular build requires a nonce for dynamic styles (Angular Material),
   use a nonce-based CSP:
   `script-src 'self' 'nonce-{SERVER_GENERATED_NONCE}'`
4. Verify with Chrome DevTools → Security panel that no violations remain.

---

### [M-03] 71 `Optional.isPresent()` + `.get()` occurrences throughout the backend

**Component:** Backend

**Finding:**
`grep -rn "\.isPresent()" tms-backend/src --include="*.java"` returns 71 matches.
The predominant pattern is:

```java
Optional<Foo> opt = repository.findById(id);
if (opt.isPresent()) {
    Foo foo = opt.get();   // can NullPointerException if refactored carelessly
    ...
}
```

This is a pre-Java-8 idiom. The idiomatic Java 8+ replacement is
`orElseThrow()`, `orElse()`, `ifPresent()`, or `map()` chaining. The current
pattern is error-prone when code is inserted between the `.isPresent()` check
and the `.get()` call.

**Recommended Fix:**
Run the IntelliJ "Replace with orElseThrow" bulk intention across the codebase.
For mandatory lookups, prefer:

```java
Foo foo = repository.findById(id)
    .orElseThrow(() -> new EntityNotFoundException("Foo not found: " + id));
```

For optional operations:

```java
repository.findById(id).ifPresent(foo -> process(foo));
```

---

### [M-04] `catch (Exception ex)` swallows typed exceptions in 10+ service files

**Component:** Backend
**Files:**

- `service/impl/LoadingWorkflowServiceImpl.java:302, 444, 536`
- `service/BannerService.java:152`
- `service/DriverLicenseService.java:123, 229`
- `service/VehicleRedisCacheService.java:35, 50, 56, 63`
- `service/CustomerAddressService.java:140`
- `service/DriverLocationMongoService.java:34, 85`
- `service/DriverDocumentService.java:202, 214, 257`

**Finding:**
Broad `catch (Exception ex)` blocks prevent Spring's
`@RestControllerAdvice` from receiving typed exceptions such as
`DataIntegrityViolationException`, `OptimisticLockException`, or
`TransactionSystemException`. These are either silently swallowed or
re-wrapped as a generic `RuntimeException`, causing incorrect HTTP status codes
and undiagnosable production failures.

**Recommended Fix:**
Catch the most specific exception type applicable to each block:

```java
} catch (DataAccessException ex) {
    log.error("DB error in loadingStep: {}", ex.getMessage(), ex);
    throw new ServiceException("Loading step failed", ex);
} catch (IllegalStateException ex) {
    throw new WorkflowViolationException("Invalid loading state", ex);
}
// Let other exceptions propagate to GlobalExceptionHandler
```

---

### [M-05] N+1 query risk on `@OneToMany` relationships without `@BatchSize`

**Component:** Backend

**Finding:**
`spring.jpa.open-in-view=false` is correctly set in `application.yml:17`, which
is good. However, several `@OneToMany` collections use `FetchType.LAZY` without
`@BatchSize`, meaning that loading a list of N parent entities followed by
accessing their child collections triggers N additional `SELECT` statements.
The risk is highest on endpoints that return lists of dispatches, work orders,
or drivers with nested stops/documents.

**Note:** `DispatchRepository` correctly uses `@EntityGraph` for its detail
queries — the risk is on list queries that do not specify an entity graph.

**Recommended Fix:**

1. Add `@BatchSize(size = 25)` to `@OneToMany` collection fields on high-traffic
   entities (Dispatch, Driver, WorkOrder) to replace N individual queries with
   `ceil(N/25)` batch queries.
2. Verify list endpoints with `spring.jpa.show-sql=true` in the dev profile —
   any list endpoint that generates more SQL statements than returned rows has
   an N+1 problem.
3. For complex projections, prefer Spring Data `@Query` with `JOIN FETCH` or
   dedicated `@EntityGraph` definitions.

---

### [M-06] Three CSS frameworks coexist — Angular Material + Bootstrap + Tailwind CSS

**Component:** Frontend
**File:** `tms-frontend/package.json`

**Finding:**
Angular Material 19.2.19, Bootstrap 5.3.6, and Tailwind CSS 3.4.3 are all
included. Each framework ships its own reset, grid system, and component library.
The legacy `/components/` directory intermingles all three, making consistent
styling impossible and tripling the base CSS bundle before any application code.
Tailwind's `content` config in `tailwind.config.js` handles tree-shaking for
utility classes but the full Bootstrap and Material stylesheets are still bundled.

**Recommended Fix:**

1. Establish a migration decision: Angular Material + Tailwind is the declared
   standard (per the copilot instructions); Bootstrap should be removed once the
   legacy components are rewritten.
2. Until then, limit Bootstrap imports to only the components still in use:
   ```scss
   // Import only what is needed, not the full bootstrap
   @import "bootstrap/scss/grid";
   @import "bootstrap/scss/utilities";
   ```
3. Set Angular `angular.json` budget warnings to catch bundle size regressions:
   ```json
   "budgets": [
     { "type": "initial", "maximumWarning": "500kb", "maximumError": "1mb" }
   ]
   ```

---

### [M-07] Flutter token refresh race condition — no Completer lock

**Component:** Mobile (Driver App)
**File:** `tms_driver_app/lib/providers/dispatch_provider.dart`

**Finding:**
When two simultaneous API calls both receive an HTTP 401 response, both
callers independently trigger a token refresh. The second refresh attempt
uses an already-invalidated refresh token, causing the server to reject it
and log the driver out mid-dispatch. This is a classic Dart async concurrency
issue in token refresh flows.

**Recommended Fix:**
Use a `Completer<String>` lock so that the first refresh attempt is awaited
by all subsequent callers:

```dart
Completer<String>? _refreshCompleter;

Future<String> refreshAccessToken() async {
  if (_refreshCompleter != null) {
    return _refreshCompleter!.future;
  }
  _refreshCompleter = Completer<String>();
  try {
    final newToken = await _authService.doRefresh();
    _refreshCompleter!.complete(newToken);
    return newToken;
  } catch (e) {
    _refreshCompleter!.completeError(e);
    rethrow;
  } finally {
    _refreshCompleter = null;
  }
}
```

---

### [M-08] 30-second dispatch cache not invalidated on FCM push notification arrival

**Component:** Mobile (Driver App)
**File:** `tms_driver_app/lib/providers/dispatch_provider.dart`

**Finding:**
The dispatch cache has a 30-second TTL. When a Firebase Cloud Messaging (FCM)
push notification arrives indicating a dispatch status change (e.g., a new
dispatch assigned), the provider cache is not invalidated. The driver app
continues to show stale state for up to 30 seconds after a real-time update
was already delivered.

**Risk:**
Driver sees the wrong dispatch status after admin actions, causing confusion,
double-confirmations, or missed updates during time-sensitive operations.

**Recommended Fix:**
In the FCM message handler (typically in `FirebaseMessagingService` or the
`main.dart` background message handler), call `dispatchProvider.clearCache()`
before re-fetching:

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['type'] == 'DISPATCH_UPDATE') {
    dispatchProvider.clearCache();       // invalidate stale data
    dispatchProvider.fetchActiveDispatch();
  }
});
```

---

## LOW Issues

---

### [L-01] Legacy `/components/` contains technical debt from incomplete migration

**Component:** Frontend
**File:** `tms-frontend/src/app/components/` (all files)

**Finding:**
The `components/` directory is documented as "Legacy components (refactoring
ongoing)". Files in this directory bypass the feature module structure, use
direct `localStorage` calls instead of `StorageService`, and mix Angular Material,
Bootstrap, and Tailwind haphazardly. Progress on migration to `features/` is
not tracked anywhere in the codebase.

**Recommended Fix:**
Create a tracking issue for each remaining legacy component. Add
`@deprecated` JSDoc to each class. Set a target milestone for full removal,
and add an ESLint rule that fails the build if any new file is added to
`src/app/components/`:

```json
// eslint.config.js
{ "rule": "no-restricted-imports", "patterns": ["**/app/components/**"] }
```

---

### [L-02] Flutter `pubspec.yaml` exact version pins may miss security patches

**Component:** Mobile (all Flutter apps)
**File:** `tms_driver_app/pubspec.yaml` (and equivalent in other Flutter apps)

**Finding:**
All Flutter dependencies are pinned to exact versions. While this improves
reproducibility, it means security patches in transitive dependencies require
manual version bump PRs and easy to miss.

**Recommended Fix:**
Adopt `^` (caret) constraints for non-breaking minor and patch updates:

```yaml
dependencies:
  dio: ^5.4.0 # was: dio: 5.4.0
  provider: ^6.0.5 # unchanged behaviour, gets patches
```

Run `flutter pub outdated` as part of the quarterly dependency review.

---

### [L-03] `localhost:8080` hardcoded in development environment file

**Component:** Frontend
**File:** `tms-frontend/src/app/environments/environment.ts`

**Finding:**
The development environment file hardcodes `http://localhost:8080` as the API
base URL. If a developer's backend runs on a different port or host (Docker,
remote dev environment), they must edit a tracked file, risking accidental
commits of local overrides.

**Recommended Fix:**
Drive the URL from a build-time environment variable:

```typescript
// environment.ts
export const environment = {
  apiUrl: (window as any).__env?.API_URL || "http://localhost:8080",
};
```

Or use `proxy.conf.cjs` (already present in the project) as the single
source of truth for the dev API target and keep `environment.ts` pointing
to `/api` (the proxy path).

---

### [L-04] `/actuator/prometheus` and `/actuator/info` are unauthenticated

**Component:** Backend
**File:** `tms-backend/src/main/java/com/svtrucking/logistics/security/SecurityConfig.java:128-129`

**Finding:**
Both `/actuator/prometheus` and `/actuator/info` are included in the `permitAll()`
block. This exposes JVM metrics, request rate counts, error rates, memory usage,
and build metadata (version, git commit) to any unauthenticated request.

**Evidence:**

```java
// SecurityConfig.java:126-129
"/actuator/health",
"/actuator/health/**",
"/actuator/info",
"/actuator/prometheus",
```

**Risk:**
Prometheus metrics leak application internals (endpoint names, error codes,
processing times) useful for reconnaissance. `/actuator/info` may expose the
application version and git commit hash, helping an attacker target known CVEs.

**Recommended Fix:**
Restrict the Prometheus scrape endpoint to the internal monitoring network via
nginx:

```nginx
location /actuator/prometheus {
  allow 10.0.0.0/8;   # monitoring subnet
  deny all;
}
```

Remove `/actuator/info` from the public `permitAll()` list entirely, or move
it behind the `ADMIN`/`SUPERADMIN` role check.

---

## Dependency Versions Requiring Update

| Package                    | Current        | Target   | Reason                                                    |
| -------------------------- | -------------- | -------- | --------------------------------------------------------- |
| `io.jsonwebtoken:jjwt-*`   | `0.11.5`       | `0.12.6` | API deprecation; mandatory algorithm validation in 0.12.x |
| `org.apache.pdfbox:pdfbox` | `2.0.30`       | `3.0.x`  | 2.x branch is end-of-maintenance                          |
| Flutter `dio`              | `5.x` (pinned) | `^5.x`   | Enable patch-level security updates via `^`               |

---

## Appendix: Files Reviewed

| File                                                                                                  | Notes                                                                |
| ----------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `tms-backend/src/main/java/com/svtrucking/logistics/security/ApiKeyFilter.java`                       | Fail-open bug confirmed at lines 25-27                               |
| `tms-backend/src/main/java/com/svtrucking/logistics/security/SecurityConfig.java`                     | DEV_SECURITY_BYPASS block lines 60-83; actuator permit lines 128-129 |
| `tms-backend/src/main/java/com/svtrucking/logistics/security/JwtAuthFilter.java`                      | Reviewed; correct typed exception handling for JWT errors            |
| `tms-backend/src/main/java/com/svtrucking/logistics/controller/AuthController.java`                   | No rate-limiting on `POST /login`; reviewer bypass flags present     |
| `tms-backend/src/main/java/com/svtrucking/logistics/service/FileStorageService.java`                  | REPLACE_EXISTING on line 42; no MIME validation                      |
| `tms-backend/src/main/java/com/svtrucking/logistics/service/PasswordResetService.java`                | TODO on line 42; email never sent                                    |
| `tms-backend/src/main/java/com/svtrucking/logistics/controller/drivers/DriverLocationController.java` | 3 TODO stubs in spoofing alert handler (lines 466-468)               |
| `tms-backend/src/main/java/com/svtrucking/logistics/service/impl/LoadingWorkflowServiceImpl.java`     | `catch (Exception ex)` at lines 302, 444, 536                        |
| `tms-backend/src/main/java/com/svtrucking/logistics/service/BannerService.java`                       | `catch (Exception e)` at line 152                                    |
| `tms-backend/src/main/java/com/svtrucking/logistics/service/DriverLicenseService.java`                | `catch (Exception e)` at lines 123, 229                              |
| `tms-backend/src/main/resources/application.yml`                                                      | `open-in-view: false` confirmed correctly set                        |
| `tms-backend/pom.xml`                                                                                 | JJWT 0.11.5 at lines 103-118                                         |
| `tms-frontend/src/app/shared/services/storage.service.ts`                                             | Pure `localStorage` wrapper — no httpOnly cookie support             |
| `tms-frontend/src/app/services/auth.service.ts`                                                       | `localStorage.setItem('token', ...)` at lines 205, 224               |
| `tms-frontend/nginx.conf`                                                                             | HSTS commented out line 25; weak CSP line 22                         |
| `docker-compose.yml`                                                                                  | Root DB credentials lines 9, 29-30; no resource limits               |
| `tms-backend/.env` + `tms-safety-api/.env`                                                        | Both files confirmed on disk with plaintext credentials              |
