# SV-TMS — AI Copilot Instructions

Multi-service Transport Management System monorepo. Read this before touching any code.

---

## Project Map

| Service | Tech | Port | DB |
|---|---|---|---|
| `tms-core-api` | Java 21, Spring Boot 3 | 8080 | MySQL + MongoDB + Redis + Kafka |
| `tms-auth-api` | Java 21, Spring Boot 3 | 8083 | MySQL + Redis |
| `tms-telematics-api` | Java 21, Spring Boot 3 | 8082 | PostgreSQL + MongoDB |
| `tms-driver-app-api` | Java 21, Spring Boot 3 | 8084 | MySQL |
| `tms-safety-api` | Java 21, Spring Boot 3 | 8087 | MySQL |
| `tms-message-api` | Java 21, Spring Boot 3 | 8088 | H2 + Kafka |
| `api-gateway` | Spring Cloud Gateway | 8086 | — |
| `tms-admin-web-ui` | Angular 17+ | 4200 (dev) | — |
| `tms_driver_app` | Flutter 3.5+ | — | — |
| `tms_customer_app` | Flutter 3.x+ | — | — |
| `tms-backend-shared` | Java lib (no service) | — | — |

---

## API Boundary Rule — Never Cross These

| Client | Allowed prefixes |
|---|---|
| Admin UI | `/api/admin/*`, `/api/auth/*` |
| Driver app | `/api/driver/*`, `/api/auth/*` |
| Customer app | `/api/customer/{customerId}/*`, `/api/auth/*` |

**Do not call `/api/admin/*` from mobile. Do not call `/api/driver/*` from admin UI.**

---

## Local Development

```bash
# Start stateful dependencies only (fastest for backend dev)
docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka

# Full stack
docker compose -f docker-compose.local-dev.yml up -d --build

# Individual backend service
cd tms-core-api && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local

# Admin UI (proxy to gateway on 8086)
cd tms-admin-web-ui && npm ci --legacy-peer-deps && npm start

# Flutter
cd tms_driver_app && flutter pub get && flutter run
```

Health checks: `curl http://localhost:{port}/actuator/health`

---

## Backend Conventions

- **Build:** Always use `./mvnw`, never bare `mvn`.
- **After changing Lombok/MapStruct classes:** `./mvnw clean package` — skipping regenerates annotation processors and causes cryptic errors.
- **Multi-module build:** `tms-core-api`, `tms-auth-api`, `tms-driver-app-api`, `tms-message-api`, `api-gateway` use the root `pom.xml` and depend on `tms-backend-shared`. Build from repo root.
- **Standalone services:** `tms-telematics-api`, `tms-safety-api` have their own parent pom. Build from their own directory.
- **Flyway:** Migrations live in `tms-core-api/src/main/resources/db/migration/`. Never edit a migration that has run. Name new ones `V{YYYYMMDD}__{description}.sql`.
- **Tests:** Unit tests use H2. Integration tests need `docker compose -f docker-compose.local-dev.yml up -d mysql redis`.

---

## Frontend Conventions (Angular)

- **Dev server:** Use `npm start` not `ng serve` — proxy in `proxy.conf.cjs` forwards `/api`, `/ws`, `/uploads` to `localhost:8086`.
- **No NgRx.** Use RxJS `BehaviorSubject` in services for shared state.
- **Path aliases:** `@services/`, `@models/`, `@env/` (see `tsconfig.json`).
- **Auth:** `AuthInterceptor` injects Bearer token. On 401 → `authService.refreshToken()` → if fails, logout.
- **WebSocket:** STOMP over SockJS. Token in connect headers. Topics: `/topic/*` (broadcast), `/user/queue/*` (user-specific).
- **CSS:** Angular Material + Tailwind are the standard. Bootstrap is legacy — do not add Bootstrap to new components.

```bash
npm run test        # Karma/Jasmine watch
npm run test:ci     # Headless with coverage
```

---

## Flutter Conventions

- **API base URL:** `--dart-define=API_BASE_URL=<url>` at compile time, or `ApiConstants.setBaseUrlOverride()` at runtime.
- **Android emulator:** Use `10.0.2.2` not `localhost`.
- **State:** Provider pattern with `MultiProvider`.
- **Auth:** JWT stored in `FlutterSecureStorage`. Manual refresh via `AuthService.refreshAccessToken()`.
- **i18n:** `easy_localization` with `en`/`km`. Assets in `assets/lang/`.

---

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| Angular calls `http://localhost:8080` directly | Use relative `/api/...` — proxy handles routing |
| Cryptic errors after DTO change | Run `./mvnw clean package` to regenerate MapStruct/Lombok |
| Flutter can't reach local backend on Android | Use `10.0.2.2` not `localhost` |
| Endpoint contamination | Admin UI → `/api/admin/*` only. Driver app → `/api/driver/*` only |
| Flyway checksum mismatch on VPS | Never rename or edit a migration that has already run |

---

## Key Files

| File | Purpose |
|---|---|
| `pom.xml` (root) | Multi-module Maven reactor |
| `infra/.env` | Production env vars |
| `infra/docker-compose.prod.yml` | Production compose |
| `infra/docker-compose.build-override.yml` | Build-from-source overrides |
| `docker-compose.local-dev.yml` | Local dev stack |
| `tms-admin-web-ui/proxy.conf.cjs` | Dev API proxy config |
| `CLAUDE.md` | Claude Code collaboration rules |
| `LOCAL_DEVELOPMENT.md` | Full local setup guide |
| `docs/guides/SA_DOCUMENT.md` | System architecture |
