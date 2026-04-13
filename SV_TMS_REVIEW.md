# SV-TMS Code Quality & Security Review

**Date:** 2026-03-09
**Scope:** `tms-core-api` (Spring Boot 3 / Java 21), `tms-admin-web-ui` (Angular 19),
`tms_driver_app` (Flutter 3.5+), Docker infrastructure
**Review type:** Code quality + Security

---

## Summary

| Severity | Count |
|---|---|
| CRITICAL | 3 |
| HIGH | 7 |
| MEDIUM | 8 |
| LOW | 4 |

Three critical issues require immediate action before the next production deploy:
secrets exist in committed `.env` files, the integration API guard fails open when
unconfigured, and JWT tokens are stored in `localStorage` making them readable by
any XSS payload. Seven high-severity issues include an unprotected login endpoint
(brute-force), a broken password-reset feature, and the production Docker Compose
running MySQL as root.

---

## Severity Legend

| Tier | Criteria |
|---|---|
| **CRITICAL** | Exploitable without authentication; allows data exfiltration, account takeover, or secrets leak. Fix before next deploy. |
| **HIGH** | Requires partial access or specific conditions; broken features with security impact; production misconfiguration. Fix this sprint. |
| **MEDIUM** | Degrades reliability, observability, or performance under load; technical debt with measurable impact. Schedule within current cycle. |
| **LOW** | Style, maintainability, optional hardening. Backlog. |

---

## CRITICAL

### [C-01] JWT secrets committed in `.env` files

**Files:** `tms-backend/.env`, `tms-safety-api/.env`

Both files contain plaintext `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `APP_API_KEY`, and `APP_REVIEWER_CREATE_SECRET`. Verify with `git log --all --full-history -- "**/.env"` whether they ever entered the object store.

**Fix:**
1. Rotate all secrets immediately — assume compromised.
2. Purge from git history: `git filter-repo --invert-paths --path tms-backend/.env`
3. Inject secrets at runtime only (Docker secrets, secrets manager, or CI/CD encrypted vars).
4. Add `detect-secrets` as a pre-commit hook.

---

### [C-02] `ApiKeyFilter` fails open when `app.api.key` is not configured

**File:** `security/ApiKeyFilter.java:25-27`

When the property is blank or absent, the filter short-circuits with `filterChain.doFilter()`, granting unauthenticated access to every `/api/v1/integrations/*` endpoint.

```java
// Current — FAIL OPEN
@Value("${app.api.key:}")
private String validApiKey;

if (validApiKey == null || validApiKey.isBlank()) {
    filterChain.doFilter(request, response); // passes through unauthenticated
    return;
}
```

**Fix:** Fail closed — assert the key is configured at startup:

```java
@PostConstruct
public void validateConfig() {
    if (validApiKey == null || validApiKey.isBlank()) {
        throw new IllegalStateException(
            "app.api.key must be configured. Integration endpoints are disabled.");
    }
}
```

---

### [C-03] JWT tokens stored in `localStorage` (XSS-accessible)

**Files:** `auth.service.ts:205, 224`, `driver-location.service.ts:704`

Both access and refresh tokens are written to `localStorage`. Any XSS payload can read `window.localStorage` directly. The nginx CSP includes `'unsafe-inline'` in `script-src` (see M-02), so CSP does not block inline XSS.

**Fix:** Migrate to `httpOnly; Secure; SameSite=Strict` cookies issued by the backend. Backend CORS config already has `setAllowCredentials(true)`. Remove all `localStorage.setItem('token', ...)` calls from the frontend.

---

## HIGH

### [H-01] No rate limiting on login endpoints

**File:** `AuthController.java`

`POST /api/auth/login` and `POST /api/auth/driver/login` are `permitAll()` with no rate-limiting. Unlimited credential stuffing is possible.

**Fix:** Add Bucket4j per-IP rate limit, or configure nginx `limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m`. Add account lockout after 10 consecutive failures.

---

### [H-02] `DEV_SECURITY_BYPASS` flag disables driver location auth

**File:** `SecurityConfig.java:60-83`

When `DEV_SECURITY_BYPASS=true` and profile is `local`, `dev`, or `test`, the driver location write route becomes `permitAll()` for `POST /api/driver/location` and its legacy alias `POST /api/driver/location/update`. A staging server with profile `dev` set would expose the endpoint unauthenticated.

**Fix:** Remove the `devBypass` block. Use a `@TestConfiguration` scoped security config for integration tests instead.

---

### [H-03] File upload accepts any MIME type

**File:** `FileStorageService.java:26-42`

Zero content-type or file-extension validation. An authenticated user can upload `.html` or `.js` files. Because `/uploads/**` is `permitAll()`, uploaded files can be served to browsers, enabling stored XSS.

**Fix:** Whitelist MIME types using Apache Tika (content sniffing, not extension trust). Remove `StandardCopyOption.REPLACE_EXISTING`. Serve uploads with `Content-Disposition: attachment` to prevent browser rendering.

---

### [H-04] Password reset email never sent

**File:** `PasswordResetService.java:38-44`

The method generates a token, persists it, hits a `// TODO: integrate with email service` comment, and returns. No email is ever sent.

**Fix:** Add `spring-boot-starter-mail` and send a reset link via `JavaMailSender`.

---

### [H-05] GPS spoofing alerts not persisted or acted upon

**File:** `DriverLocationController.java:448-477`

The spoofing-alert endpoint logs a WARN and returns HTTP 200. Three TODO comments document intended behaviour (persist, notify admin, auto-suspend) that was never implemented.

**Fix:** Create `SpoofingAlertEntity`/repository, persist every alert. Add a scheduled job that counts alerts per driver per hour and triggers admin notification and driver suspension above a threshold.

---

### [H-06] JJWT 0.11.5 is outdated

**File:** `pom.xml:103-118`

The `0.12.x` line introduced mandatory algorithm validation, fixing algorithm confusion edge cases. Upgrade all three JJWT artifacts to `0.12.6` and update `JwtUtil.java` to the 0.12 parser API (`Jwts.parser().verifyWith(key).build()`).

---

### [H-07] MySQL container runs as root with no memory limits

**File:** `docker-compose.yml:8-10, 27-30`

Backend connects as `root` with plaintext password in Compose file. No memory limits on any container.

**Fix:** Create a least-privilege DB user with `GRANT SELECT, INSERT, UPDATE, DELETE` only. Move credentials to a Docker secret or excluded env file. Add `deploy.resources.limits.memory` to all services.

---

## MEDIUM

### [M-01] HSTS header commented out in nginx.conf

Enable once TLS is confirmed on production. Do not include `preload` until all subdomains support HTTPS.

### [M-02] CSP `script-src` contains `'unsafe-inline'` and `'unsafe-eval'`

Negates XSS protection. Remove `'unsafe-eval'` (Angular production builds don't need it). Remove `'unsafe-inline'` and move inline scripts to external files. Consider a nonce-based CSP for Angular Material.

### [M-03] 71 `Optional.isPresent()` + `.get()` occurrences in backend

Pre-Java-8 idiom. Run IntelliJ "Replace with orElseThrow" bulk intention. Prefer `orElseThrow(() -> new EntityNotFoundException(...))` for mandatory lookups.

### [M-04] `catch (Exception ex)` swallows typed exceptions in 10+ service files

**Key files:** `LoadingWorkflowServiceImpl.java:302,444,536`, `BannerService.java:152`, `DriverDocumentService.java:202,214,257`

Prevents `@RestControllerAdvice` from receiving typed exceptions, causing incorrect HTTP status codes. Catch the most specific exception type applicable to each block.

### [M-05] N+1 query risk on `@OneToMany` without `@BatchSize`

`DispatchRepository` correctly uses `@EntityGraph` for detail queries, but list queries don't. Add `@BatchSize(size = 25)` to `@OneToMany` collections on high-traffic entities (Dispatch, Driver, WorkOrder).

### [M-06] Three CSS frameworks coexist — Angular Material + Bootstrap + Tailwind

Angular Material + Tailwind is the declared standard. Bootstrap should be removed once legacy `/components/` are rewritten. Until then, import only the Bootstrap components still in use.

### [M-07] Flutter token refresh race condition — no `Completer` lock

Two simultaneous 401 responses both trigger refresh. The second uses an already-invalidated refresh token. Fix with a `Completer<String>` lock so the first refresh is awaited by all subsequent callers.

### [M-08] 30-second dispatch cache not invalidated on FCM push

When FCM delivers a dispatch status change, the provider cache is not cleared. Driver sees stale state for up to 30 seconds. Call `dispatchProvider.clearCache()` in the FCM message handler before re-fetching.

---

## LOW

### [L-01] Legacy `/components/` contains incomplete migration

Add `@deprecated` JSDoc to each class. Add an ESLint rule that fails the build if any new file is added to `src/app/components/`.

### [L-02] Flutter `pubspec.yaml` exact version pins miss security patches

Switch to `^` (caret) constraints for non-breaking minor and patch updates. Run `flutter pub outdated` quarterly.

### [L-03] `localhost:8080` hardcoded in `environment.ts`

Drive the URL from a build-time variable, or use the existing `proxy.conf.cjs` as the single source of truth and point `environment.ts` to `/api`.

### [L-04] `/actuator/prometheus` and `/actuator/info` are unauthenticated

Restrict the Prometheus scrape endpoint to the monitoring subnet via nginx. Remove `/actuator/info` from the public `permitAll()` list.

---

## Dependency Updates Required

| Package | Current | Target | Reason |
|---|---|---|---|
| `io.jsonwebtoken:jjwt-*` | `0.11.5` | `0.12.6` | Mandatory algorithm validation in 0.12.x |
| `org.apache.pdfbox:pdfbox` | `2.0.30` | `3.0.x` | 2.x branch end-of-maintenance |
| Flutter `dio` | `5.x` pinned | `^5.x` | Enable patch-level security updates |
