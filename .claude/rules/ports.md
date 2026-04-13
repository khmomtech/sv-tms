# Service Ports — Authoritative Reference

**When routing is ambiguous, this file wins. Always verify against it before suggesting a port.**

## Port Map

| Port | Service | Module | Notes |
|------|---------|--------|-------|
| 4200 | Admin Web UI (dev) | `tms-admin-web-ui` | `npm start` only |
| 8080 | Core API | `tms-core-api` | Main business logic |
| 8082 | Telematics API | `tms-telematics-api` | GPS / live tracking |
| 8083 | Auth API | `tms-auth-api` | JWT, login, refresh |
| 8084 | Driver App API | `tms-driver-app-api` | Mobile backend |
| 8086 | API Gateway | `api-gateway` | Single entry point for all clients |
| 8087 | Safety API | `tms-safety-api` | Base `application.properties` mistakenly shows `8080` — actual port is **8087** (set via `SERVER_PORT` env var or docker-compose) |
| 8088 | Message API | `tms-message-api` | Notifications / Kafka |

## Proxy Rules (local dev — `proxy.conf.cjs`)

Angular dev server (`localhost:4200`) proxies as follows:

| Path prefix | Proxies to | Port |
|-------------|-----------|------|
| `/api/auth` | Auth API | **8083** |
| `/api/admin/geofences` | Telematics API | 8082 |
| `/api/admin/telematics` | Telematics API | 8082 |
| `/api/driver/device` | Auth API | **8083** |
| `/api/driver/chat` | Core API | 8080 |
| `/api/driver-app` | Driver App API | 8084 |
| `/api/driver` | Driver App API | 8084 |
| `/api` (catch-all) | Core API | 8080 |
| `/ws`, `/ws-sockjs` | Core API | 8080 |
| `/uploads` | Core API | 8080 |

> **Key rule:** `/api/auth` → **8083** (auth-api), NOT 8080 (core-api) and NOT 8086 (gateway).
> Using 8086 (gateway) also works since the gateway routes auth to 8083 internally.

## Gateway Routing (port 8086)

The gateway (`application.properties`) routes:

```
/api/auth/**        → http://localhost:8083  (AUTH_API_BASE_URL)
/api/admin/**       → http://localhost:8080  (CORE_API_BASE_URL)
/api/driver/**      → http://localhost:8084  (DRIVER_APP_API_BASE_URL)
/api/telematics/**  → http://localhost:8082  (TELEMATICS_API_BASE_URL)
/api/safety/**      → http://localhost:8087  (SAFETY_API_BASE_URL)
```

## Local Docker Network

Existing infra containers run on **`svtms-network`**. When starting app services manually with `docker run`, always add `--network svtms-network` and use container names (e.g. `svtms-mysql:3306`, `svtms-redis`) not `localhost`.

The prod compose creates its own isolated network — do NOT mix prod compose and manually-run containers.

## Common Mistakes to Avoid

- **Do NOT** route `/api/auth` to `8080` — that is core-api and has no auth endpoints.
- **Do NOT** assume safety-api is on `8080` — its base properties say `8080` but the real port is `8087` via `SERVER_PORT`.
- **Do NOT** hardcode `localhost:808x` in Angular code — always use relative `/api/...` paths.
- **Do NOT** hardcode `localhost` in Flutter — use `ApiConstants.baseUrl`; Android emulator needs `10.0.2.2`.

## Health Check Commands

```bash
curl http://localhost:8080/actuator/health   # core-api
curl http://localhost:8082/actuator/health   # telematics-api
curl http://localhost:8083/actuator/health   # auth-api
curl http://localhost:8084/actuator/health   # driver-app-api
curl http://localhost:8086/actuator/health   # api-gateway
curl http://localhost:8087/actuator/health   # safety-api
curl http://localhost:8088/actuator/health   # message-api
```
