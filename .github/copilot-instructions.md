# SV-TMS — AI Agent Copilot Instructions

This multi-project workspace contains a complete Transport Management System (TMS) with strict API boundary enforcement between client types.

## System Architecture

**Four independent projects, one backend authority:**

- `tms-backend/` — Java 21 + Spring Boot 3.5.7 API & auth server (MySQL 8, Redis 7, Firebase Admin)
- `tms-frontend/` — Angular 19 admin/dispatcher web UI (Material, Tailwind, Google Maps, STOMP)
- `tms_driver_app/` — Flutter 3.5+ driver mobile app (Provider, FCM, GPS tracking, i18n en/km)
- `tms_customer_app/` — Flutter 3.x+ customer mobile app (Provider, STOMP WebSocket, easy_localization)

**Critical API boundary rule:** Each client uses ONLY its designated endpoint prefix:
- Admin UI → `/api/admin/*` and `/api/auth/*`
- Driver app → `/api/driver/*` and `/api/auth/*`
- Customer app → `/api/customer/{customerId}/*` and `/api/auth/*`

**Do not cross-contaminate endpoints.** Each has separate controllers, DTOs, and authorization scopes.

## Quick Start Commands

**Full dev stack** (MySQL + Redis + backend + Angular dev server):
```bash
docker compose -f docker-compose.dev.yml up --build
# Backend: http://localhost:8080 | Frontend: http://localhost:4200
# OpenAPI: http://localhost:8080/v3/api-docs
```

**Individual services:**
```bash
# Backend (Spring Boot)
cd tms-backend && ./mvnw spring-boot:run

# Frontend (Angular with proxy)
cd tms-frontend && npm ci --legacy-peer-deps && npm start

# Driver app (Flutter - Android emulator)
cd tms_driver_app && flutter pub get && flutter run --flavor dev

# Customer app (Flutter - Android emulator)
cd tms_customer_app && flutter pub get && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

**Key flags:**
- `npm start` in Angular → proxies `/api`, `/ws-sockjs`, `/uploads` to localhost:8080 (see `proxy.conf.json`)
- Flutter `--dart-define=API_BASE_URL=<url>` overrides `ApiConstants` at compile time
- Android emulator: use `10.0.2.2` for host machine's localhost
- iOS simulator: use `localhost` or actual IP for physical devices

## Backend Conventions (Java/Spring Boot)

**Build system:** Always use `./mvnw` (Maven wrapper). Never call `mvn` directly.

**Critical build step:** After modifying Lombok (`@Data`, `@Builder`) or MapStruct (`@Mapper`) annotated classes:
```bash
./mvnw clean package
```
This regenerates annotation processor outputs. Skipping causes cryptic compilation errors.

**Testing:** Unit tests use H2 in-memory DB (test scope). For integration tests requiring MySQL:
```bash
docker compose -f docker-compose.test.yml up -d
./mvnw verify
```

**OpenAPI client generation workflow:**
```bash
# Export OpenAPI spec
curl http://localhost:8080/v3/api-docs > api-spec.json

# Generate TypeScript client (Angular)
cd tms-frontend && npx openapi-generator-cli generate -i ../api-spec.json -g typescript-angular

# Generate Dart client (Flutter)
cd tms_customer_app && openapi-generator-cli generate -i ../api-spec.json -g dart
```

**Permission system:** `all_functions` is a wildcard permission granting unrestricted access. Check `AuthorizationService.hasPermission()` for enforcement logic. Roles have many-to-many permissions; `PermissionInitializationService` seeds permissions on startup if `permissions.init.enabled=true`.

**Key directories:**
- `src/main/java/com/svtrucking/logistics/controller/` — REST endpoints organized by client type (admin, driver, customer)
- `src/main/java/com/svtrucking/logistics/security/` — JWT auth, `AuthorizationService`, permission constants
- `src/main/java/com/svtrucking/logistics/mapper/` — MapStruct interfaces (run `./mvnw clean package` after changes)

## Frontend Conventions (Angular)

**Proxy requirement in dev:** Use `npm start` (not `ng serve`) to enable proxy in `proxy.conf.json`. This forwards `/api`, `/ws-sockjs`, `/uploads` to `localhost:8080`. Direct `http://localhost:8080` calls bypass proxy and fail CORS.

**Path aliases** (tsconfig.json):
```typescript
import { AuthService } from '@services/auth.service';  // src/app/services/
import { Driver } from '@models/driver.model';        // src/app/models/
import { environment } from '@env/environment';       // src/environments/
```

**State management:** No NgRx. Use RxJS `BehaviorSubject` in services for shared state.

**Auth flow:**
1. `AuthInterceptor` injects `Authorization: Bearer <token>` on every HTTP request
2. On 401, interceptor calls `authService.refreshToken()` → `POST /api/auth/refresh`
3. If refresh fails, logout and redirect to `/login`

**WebSocket:** `WebSocketService` uses STOMP over SockJS. Topics: `/topic/*` (broadcast), `/user/queue/*` (user-specific). Token passed in STOMP connect headers.

**Testing:**
```bash
npm run test        # Karma/Jasmine (watch mode)
npm run test:ci     # Headless with coverage
npm run test:e2e    # Playwright E2E
```

## Flutter Conventions (driver_app & tms_customer_app)

**API base URL management:**
- Compile-time: `--dart-define=API_BASE_URL=<url>`
- Runtime: `await ApiConstants.setBaseUrlOverride('<url>')` (persisted to SharedPreferences)
- Android emulator: `10.0.2.2` for localhost; iOS simulator: `localhost`

**State management:** Provider pattern with `MultiProvider` in `app.dart` (customer) or `main.dart` (driver).

**Auth flow:**
1. `AuthService.login()` → `POST /api/auth/login` → stores JWT in `FlutterSecureStorage`
2. `GeneratedApiService.setAuthToken(token)` injects token into all API calls
3. Manual refresh via `AuthService.refreshAccessToken()` (no auto-refresh interceptor)
4. `NotificationProvider` listens to auth state and auto-connects WebSocket on login

**WebSocket:** `stomp_dart_client` connects to derived endpoint (http→ws, https→wss) + `/ws?token={token}`. Subscribes to `/user/queue/notifications`.

**i18n:** `easy_localization` with `en`/`km` (Khmer). Assets in `assets/lang/{en,km}.json`. NotoSansKhmer font for Khmer rendering.

**Flavors:** `dev`, `uat`, `prod` (configured in `android/app/build.gradle` and `ios/Runner/Info.plist`).

## Common Pitfalls (Flag These in PRs)

1. **Proxy bypass in Angular:** Hardcoded `http://localhost:8080` calls skip proxy → CORS errors. Use relative `/api/...` paths.
2. **MapStruct/Lombok skipped build:** Compile errors after DTO changes? Run `./mvnw clean package` to regenerate.
3. **Java version mismatch:** `pom.xml` targets Java 21, but `Dockerfile` uses Temurin 17 images. Align runtime versions.
4. **Flutter emulator localhost:** Android requires `10.0.2.2`, not `localhost`.
5. **Endpoint contamination:** Admin UI calling `/api/driver/*` or driver app calling `/api/admin/*`. Respect client boundaries.
6. **Permission checks:** Ensure `all_functions` wildcard bypasses specific permission checks in `AuthorizationService.hasPermission()`.

## Developer Workflows

**Implement API endpoint:**
1. Update `tms-backend` controller (admin/driver/customer package)
2. Run `./mvnw clean package` if DTOs/mappers changed
3. Test with `curl` or integration test script (e.g., `test-driver-api.sh`)
4. Export OpenAPI spec: `curl http://localhost:8080/v3/api-docs > api-spec.json`
5. Regenerate client (Angular: `openapi-generator-cli generate -g typescript-angular`, Flutter: `-g dart`)
6. Update service layer in frontend/mobile app

**Add Angular feature:**
1. Create lazy-loaded route in `app.routes.ts` (e.g., `loadComponent: () => import('@features/xyz')`)
2. Build standalone component with explicit imports
3. Use `BehaviorSubject` for state if needed
4. Add E2E smoke test in `e2e/` using Playwright

**Add Flutter feature:**
1. Create provider/service (ChangeNotifier pattern)
2. Wire into `MultiProvider` in `app.dart` or `main.dart`
3. Add unit tests using mock API client
4. Test on both Android emulator and iOS simulator

## Key Reference Files

- `tms-backend/pom.xml` — Java 21, Spring Boot 3.5.7, Lombok 1.18.42, MapStruct 1.6.3
- `tms-backend/.env.example` — Required env vars (DB creds, JWT secret, Firebase path)
- `docker-compose.dev.yml` — Full stack config (MySQL 3307→3306, Redis 6379, backend 8080, Angular 4200)
- `tms-frontend/proxy.conf.json` — Dev proxy config (critical for CORS)
- `tms-frontend/src/app/core/core.providers.ts` — HTTP, auth, error handling setup
- `tms_driver_app/lib/constants/api_constants.dart` — API base URLs and endpoint paths
- `tms_customer_app/lib/app.dart` — MultiProvider setup
- `ALL_FUNCTIONS_PERMISSION_AUDIT.md` — Wildcard permission implementation details
- `BACKEND_ANGULAR_DEBUG_GUIDE.md` — VS Code debug configurations for full stack
- `CI_CD_QUICK_START.md` — Local CI checks before pushing

## Per-Project Instructions

Each subproject has detailed `.github/copilot-instructions.md`:
- `tms-backend/.github/copilot-instructions.md` — Spring Boot internals, security, MapStruct patterns
- `tms-frontend/.github/copilot-instructions.md` — Angular 19 standalone components, Material, RxJS patterns (748 lines)
- `tms_driver_app/.github/copilot-instructions.md` — Flutter driver app, GPS, FCM, i18n (579 lines)
- `tms_customer_app/.github/copilot-instructions.md` — Flutter customer app, WebSocket, OpenAPI client (293 lines)

**Consult project-specific instructions for deep work. This umbrella guide prioritizes cross-project integration and boundary enforcement.**
