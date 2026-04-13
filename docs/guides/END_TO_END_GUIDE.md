# SV-TMS — End-to-End Guide

From cloning the repo to a live production deploy. Every step, every command, every decision point.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Prerequisites](#2-prerequisites)
3. [Repository Structure](#3-repository-structure)
4. [Local Development Setup](#4-local-development-setup)
5. [Running Services](#5-running-services)
6. [Development Workflow](#6-development-workflow)
7. [Testing](#7-testing)
8. [Database Migrations](#8-database-migrations)
9. [Building for Production](#9-building-for-production)
10. [Production Deployment (VPS)](#10-production-deployment-vps)
11. [Post-Deploy Validation](#11-post-deploy-validation)
12. [Monitoring & Observability](#12-monitoring--observability)
13. [Rollback](#13-rollback)
14. [Common Operations Runbook](#14-common-operations-runbook)
15. [Troubleshooting Index](#15-troubleshooting-index)

---

## 1. System Overview

SV-TMS is a **Transport Management System** for SV Trucking. It is a monorepo containing multiple
Java Spring Boot microservices, an Angular admin dashboard, Flutter mobile apps, and all
infrastructure configuration.

### Service map

| Service | Tech | Port | Databases | Purpose |
|---------|------|------|-----------|---------|
| `tms-core-api` | Java 21 / Spring Boot 3 | 8080 | MySQL + MongoDB + Redis + Kafka | Main business logic (orders, dispatch, drivers, customers) |
| `tms-auth-api` | Java 21 / Spring Boot 3 | 8083 | MySQL + Redis | Login, JWT issue/refresh, user sessions |
| `tms-telematics-api` | Java 21 / Spring Boot 3 | 8082 | PostgreSQL + MongoDB | GPS live tracking, geofences |
| `tms-driver-app-api` | Java 21 / Spring Boot 3 | 8084 | MySQL | Driver mobile backend |
| `tms-safety-api` | Java 21 / Spring Boot 3 | 8087 | MySQL | Pre-load safety checks |
| `tms-message-api` | Java 21 / Spring Boot 3 | 8088 | H2 + Kafka | Push notifications, in-app messages |
| `api-gateway` | Spring Cloud Gateway | 8086 | Redis | Single entry point, JWT header validation |
| `tms-admin-web-ui` | Angular 17+ | 4200 (dev) | — | Admin dashboard |
| `tms_driver_app` | Flutter 3.5+ | — | — | Driver mobile app |
| `tms_customer_app` | Flutter 3.x+ | — | — | Customer mobile app |
| `tms-backend-shared` | Java library | — | — | Shared DTOs, models, security |

### Traffic flow

```
Browser (Admin UI :4200 dev / :443 prod)
           │
           ▼
      nginx (prod only)
      TLS termination, rate limiting
           │
           ▼
    api-gateway :8086
    JWT header validation
    route by path prefix
           │
    ┌──────┴──────────────────────┐
    ▼           ▼          ▼      ▼
core-api  auth-api  driver-api  telematics-api ...
  :8080     :8083     :8084       :8082
    │
  MySQL   Redis   MongoDB   Kafka   PostgreSQL
```

### API boundary rules

| Client | Allowed path prefixes |
|--------|----------------------|
| Admin UI | `/api/admin/*`, `/api/auth/*` |
| Driver app | `/api/driver/*`, `/api/auth/*` |
| Customer app | `/api/customer/{customerId}/*`, `/api/auth/*` |

**Never call `/api/admin/*` from mobile apps. Never call `/api/driver/*` from the admin UI.**

---

## 2. Prerequisites

### Required tools

```bash
# Java 21 (exact major version required)
java -version          # must print 21.x.x

# Maven wrapper — always use ./mvnw, never bare mvn
./tms-core-api/mvnw --version

# Node / npm (Angular)
node -v                # 20.x recommended
npm -v                 # 10.x+

# Flutter (mobile apps)
flutter doctor         # fix all red ✗ before building

# Docker + Compose
docker -v              # 24+
docker compose version # v2.x (not legacy v1)

# git
git --version
```

### Recommended IDE

VS Code with extensions:
- Extension Pack for Java
- Spring Boot Extension Pack
- Angular Language Service
- Flutter / Dart

---

## 3. Repository Structure

```
sv-tms/
├── pom.xml                        ← multi-module Maven reactor (root)
├── tms-backend-shared/            ← shared models, DTOs, security (no server)
├── tms-core-api/                  ← main business logic
├── tms-auth-api/                  ← authentication + JWT
├── tms-telematics-api/            ← GPS / live tracking (standalone Maven)
├── tms-driver-app-api/            ← driver mobile backend
├── tms-safety-api/                ← pre-load safety (standalone Maven)
├── tms-message-api/               ← notifications + Kafka consumer
├── api-gateway/                   ← Spring Cloud Gateway
├── tms-admin-web-ui/              ← Angular admin dashboard
│   ├── proxy.conf.cjs             ← dev server proxy (routes /api/* → backends)
│   └── src/app/
│       ├── features/              ← feature modules (use these for new components)
│       ├── admin/                 ← admin-specific pages (user/role/permission mgmt)
│       ├── services/              ← Angular services
│       ├── guards/                ← route guards
│       └── shared/permissions.ts ← permission name constants
├── tms_driver_app/                ← Flutter driver app
├── tms_customer_app/              ← Flutter customer app
├── infra/
│   ├── docker-compose.prod.yml    ← production compose (build on VPS)
│   ├── docker-compose.build-override.yml ← overrides image refs for VPS builds
│   ├── .env                       ← secrets (never commit real secrets)
│   ├── nginx/site.conf            ← nginx reverse proxy config
│   ├── monitoring/                ← Prometheus + Grafana config
│   └── scripts/                   ← backup, restore, smoke tests
├── docker-compose.local-dev.yml   ← full local stack (infra + all services)
├── DEPLOY_TO_VPS.sh               ← one-command VPS deploy
└── docs/guides/                   ← all operational guides
```

### Maven module layout

Multi-module services build from **repo root** using `./tms-core-api/mvnw`:
- `tms-backend-shared` (shared library)
- `tms-core-api`
- `tms-auth-api`
- `tms-driver-app-api`
- `tms-message-api`
- `api-gateway`

Standalone services build from **their own directory**:
- `tms-telematics-api` (own `mvnw`)
- `tms-safety-api` (own `mvnw`)

---

## 4. Local Development Setup

### Step 1 — Clone

```bash
git clone <repo-url> sv-tms
cd sv-tms
```

### Step 2 — Configure secrets

```bash
cp infra/.env.example infra/.env   # if template exists, otherwise edit infra/.env
```

Edit `infra/.env` — fill in all `CHANGE_ME_*` values:

| Variable | What to set |
|----------|-------------|
| `MYSQL_ROOT_PASSWORD` | Any local password, e.g. `rootpass` |
| `MYSQL_PASSWORD` | App DB password, e.g. `driverpass` |
| `JWT_ACCESS_SECRET` | Min 32-char random string |
| `JWT_REFRESH_SECRET` | Min 32-char random string |
| `MAPS_API_KEY` | Google Maps key (required for production; mock for local) |
| `FIREBASE_*` | Firebase project credentials |

> **Never commit `infra/.env` with real secrets.** It is gitignored.

### Step 3 — Verify Docker network

The local compose creates a network named `svtms-network`. Make sure no other compose stack
conflicts on ports 3307, 5432, 27017, 6379, 9092.

```bash
docker network ls | grep svtms
```

---

## 5. Running Services

### Option A — Full Docker stack (recommended for integration testing)

Starts every service including all backends and Angular in containers:

```bash
docker compose -f docker-compose.local-dev.yml up -d --build
```

First build takes ~20-30 minutes (Maven downloads dependencies). Subsequent starts are seconds.

Check status:
```bash
docker compose -f docker-compose.local-dev.yml ps
```

Tail logs for a specific service:
```bash
docker compose -f docker-compose.local-dev.yml logs -f core-api
docker compose -f docker-compose.local-dev.yml logs -f auth-api
```

Open admin UI: **http://localhost:4200**

### Option B — Infra only + host services (fastest for backend development)

Start only databases and message bus, then run the service you are editing on the host for
instant code reload:

```bash
# Start infra
docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka

# Run core-api on host (Spring DevTools reloads on file save)
cd tms-core-api
./mvnw spring-boot:run -Dspring-boot.run.profiles=local

# In another terminal — run auth-api
cd tms-auth-api
./mvnw spring-boot:run -Dspring-boot.run.profiles=local -Dserver.port=8083

# Run Angular (proxies /api/* to gateway or directly to services)
cd tms-admin-web-ui
npm ci --legacy-peer-deps
npm start              # http://localhost:4200
```

### Option C — Infra only + restart single Docker service after code change

```bash
# Rebuild one service image after editing its code
docker compose -f docker-compose.local-dev.yml build core-api

# Restart it
docker compose -f docker-compose.local-dev.yml up -d core-api
```

### Health checks

```bash
curl http://localhost:8080/actuator/health   # core-api
curl http://localhost:8082/actuator/health   # telematics-api
curl http://localhost:8083/actuator/health   # auth-api
curl http://localhost:8084/actuator/health   # driver-app-api
curl http://localhost:8086/actuator/health   # api-gateway
curl http://localhost:8087/actuator/health   # safety-api
curl http://localhost:8088/actuator/health   # message-api
```

All should return `{"status":"UP"}`.

### Stop everything

```bash
docker compose -f docker-compose.local-dev.yml down
# To also remove volumes (resets databases):
docker compose -f docker-compose.local-dev.yml down -v
```

---

## 6. Development Workflow

### Branch naming

```
feature/TMS-{ticket}-short-description    # new feature
fix/TMS-{ticket}-short-description        # bug fix
chore/TMS-{ticket}-description            # non-functional change
```

### Adding a backend endpoint (standard flow)

1. **Check the port map** — which service owns the resource? (see Section 1)
2. **Create or update the entity/DTO** in `tms-backend-shared` if it crosses service boundaries.
3. **Write the repository method** (use `@Query` with HQL field names, never column names).
4. **Write the service method** — add `@Transactional` and `@CacheEvict` as needed.
5. **Write the controller endpoint**:
   - Path must match the API boundary rules (Section 1).
   - Add `@PreAuthorize("@authorizationService.hasPermission('resource:action')")`.
6. **Write a failing test**, fix the code, confirm it passes (see Section 7).
7. **Test the endpoint**:
   ```bash
   curl http://localhost:8086/actuator/health  # confirm service is up
   curl -X GET -H "Authorization: Bearer $TOKEN" \
     http://localhost:8086/api/admin/your-endpoint
   ```

### Adding an Angular feature

1. New components go in `src/app/features/{feature-name}/` — never in `src/app/components/`.
2. Use Angular Material + Tailwind. No Bootstrap in new components.
3. Use relative API paths (`/api/...`) — never `http://localhost:808x`.
4. Use `ReactiveFormsModule` — not template-driven forms.
5. All user-visible strings use `TranslatePipe` — `{{ 'key' | translate }}`.
6. Add the route to the appropriate routes file with a `PermissionGuard`:
   ```typescript
   {
     path: 'my-feature',
     loadComponent: () => import('./my-feature/my-feature.component'),
     canActivate: [PermissionGuard],
     data: { permissions: ['resource:read'] }
   }
   ```

### Adding a Flutter screen

1. API base URL: always `ApiConstants.baseUrl` — never hardcode `localhost`.
   Android emulator needs `10.0.2.2` instead of `127.0.0.1`.
2. Only call `/api/driver/*` or `/api/auth/*` paths from the driver app.
3. Mock HTTP with the `dio` mock adapter in tests — never hit real endpoints in unit tests.
4. Widget tests: always `await tester.pumpAndSettle()`.

### Environment variables you can toggle locally

| Variable | Default (local) | Effect |
|----------|----------------|--------|
| `DEV_SECURITY_BYPASS` | `false` | `true` skips JWT validation entirely |
| `APP_DRIVER_SKIP_DEVICE_CHECK` | `true` | Skip device fingerprint for login |
| `APP_DRIVER_LOGIN_BYPASS` | `true` | Allow driver login without real device |
| `APP_SEEDALLFUNCTIONS` | `true` | Seed `all_functions` permission on startup |

---

## 7. Testing

### Backend unit + integration tests

```bash
# Run all tests for all modules (from repo root)
./tms-core-api/mvnw test

# Run tests for a single module
./tms-core-api/mvnw -pl tms-core-api test
./tms-core-api/mvnw -pl tms-auth-api test
./tms-core-api/mvnw -pl tms-driver-app-api test

# Integration tests require MySQL + Redis running:
docker compose -f docker-compose.local-dev.yml up -d mysql redis
./tms-core-api/mvnw -pl tms-core-api test -Dspring.profiles.active=test
```

> **Do not mock the database in integration tests.** Real DB divergence has caused prod failures.
> H2 is used automatically in unit tests via `application-test.properties`.

After any Lombok / MapStruct change:
```bash
./tms-core-api/mvnw clean package  # regenerates annotation processors
```

### Angular tests

```bash
cd tms-admin-web-ui
npm run test          # Karma/Jasmine watch mode
npm run test:ci       # headless with coverage report
```

### Flutter tests

```bash
cd tms_driver_app
flutter test                   # all unit tests
flutter test test/widget/      # widget tests only
flutter analyze                # static analysis
```

### Pre-PR checklist

- [ ] `./tms-core-api/mvnw test` — all backend tests pass
- [ ] `npm run test:ci` — Angular tests pass with coverage
- [ ] `flutter test` — Flutter tests pass
- [ ] Manually verify the changed flow in browser or emulator
- [ ] `/check-boundaries` — no new API boundary violations

---

## 8. Database Migrations

All schema changes for MySQL services go through **Flyway** — never alter production tables manually.

### Naming convention

```
V{YYYYMMDD}__{snake_case_description}.sql
```
Example: `V20260404__add_status_to_drivers.sql`

### Where migrations live

```
tms-core-api/src/main/resources/db/migration/
```

### Create a new migration

```bash
# Use the slash command (creates file with correct name and boilerplate)
/new-migration add_status_to_drivers
```

Or create manually:
```sql
-- V20260404__add_status_to_drivers.sql
-- Always use IF NOT EXISTS / IF EXISTS guards
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'ACTIVE';
CREATE INDEX IF NOT EXISTS idx_driver_status ON drivers(status);
```

### Rules

- **Never edit a migration that has already run on production.** Create a new one instead.
- Test locally before pushing:
  ```bash
  docker compose -f docker-compose.local-dev.yml up -d mysql
  ./tms-core-api/mvnw -pl tms-core-api spring-boot:run -Dspring-boot.run.profiles=local
  # watch logs for Flyway output
  ```
- For destructive changes (DROP COLUMN, RENAME), write a paired rollback:
  `U{YYYYMMDD}__{description}_rollback.sql`
- If a Flyway **checksum mismatch** error appears on VPS — stop. Do not rename the file.
  Investigate whether it was edited after running on production.

---

## 9. Building for Production

Production images are built **on the VPS** — not locally. `DEPLOY_TO_VPS.sh` handles this.
You do not need to build Docker images locally for a production deploy.

If you need to manually build a JAR for inspection:

```bash
# Multi-module services (from repo root)
./tms-core-api/mvnw clean package -DskipTests
# JAR at: tms-core-api/target/tms-core-api-0.0.1-SNAPSHOT.jar

# Standalone services
cd tms-safety-api
./mvnw clean package -DskipTests

# Angular production build
cd tms-admin-web-ui
npm run build
# Output at: dist/tms-admin-web-ui/
```

### VPS build constraints

- Maven heap capped at **1 GB** (`MAVEN_OPTS=-Xmx1g`) — prevents OOM on 4 GB VPS.
- Services build **sequentially** — do not add `-T` parallel flag.
- VPS has **4 GB swap** at `/swapfile` — required during builds.

---

## 10. Production Deployment (VPS)

### VPS details

| Item | Value |
|------|-------|
| Host | `207.180.245.156` |
| User | `root` |
| SSH key | `infra/deploy_key` |
| App root | `/opt/sv-tms/repo/` |
| Data volumes | `/srv/svtms/{mysql,postgres,redis,mongo,kafka-*}` |
| Compose files | `infra/docker-compose.prod.yml` + `infra/docker-compose.build-override.yml` |
| Domain | `https://svtms.svtrucking.biz` |

### Pre-deploy checklist

- [ ] All tests pass locally.
- [ ] `infra/.env` has correct production values (especially `JWT_*_SECRET`, `MAPS_API_KEY`).
- [ ] `infra/secrets/firebase-service-account.json` is uploaded to `/opt/sv-tms/secrets/` on VPS.
- [ ] DB backup completed (see Section 14 — Backup).
- [ ] You are on the correct branch (`main` or release branch).
- [ ] Rollback plan reviewed.

### Full deploy

```bash
# From repo root on your Mac
bash DEPLOY_TO_VPS.sh
```

The script runs 6 phases automatically:

```
[1/6] rsync source → VPS (excludes node_modules, .git, .angular)
[2/6] copy infra/.env + build-override.yml
[3/6] pull base images (mysql, redis, kafka, nginx, prometheus…)
[4/6] build app images sequentially (~20-30 min first time, ~5-10 min incremental)
      core-api → auth-api → driver-app-api → message-api →
      telematics-api → safety-api → api-gateway
[5/6] start infra containers first (wait for DB health)
[6/6] start application containers + admin-web-ui
```

### Deploy only one service (after a hotfix)

```bash
ssh -i infra/deploy_key root@207.180.245.156 "
  cd /opt/sv-tms/repo/infra
  docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml \
    build core-api && \
  docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml \
    up -d core-api
"
```

### Push only config changes (no rebuild)

```bash
scp -i infra/deploy_key infra/.env \
  root@207.180.245.156:/opt/sv-tms/repo/infra/.env
```

Then restart affected services:
```bash
ssh -i infra/deploy_key root@207.180.245.156 "
  cd /opt/sv-tms/repo/infra
  docker compose -f docker-compose.prod.yml up -d core-api auth-api
"
```

### SSL / TLS

- Certbot auto-provisions SSL on first deploy if the domain DNS points to the VPS.
- Certbot auto-renews via cron on the VPS.
- If nginx fails to start, check that `/etc/letsencrypt/live/svtms.svtrucking.biz/` exists.
- nginx config: `infra/nginx/site.conf`

### Nginx routing (production)

| Path | Backend |
|------|---------|
| `/api/auth/login`, `/api/auth/driver/login` | api-gateway (rate-limited: 5 req/min/IP) |
| `/api/*` | api-gateway `:8086` |
| `/uploads/*` | core-api `:8080` (static file serving) |
| `/ws` | core-api `:8080` (WebSocket) |
| `/ws-sockjs` | core-api `:8080` (SockJS) |
| `/telematics/ws` | telematics-api `:8082` (WebSocket) |
| `/actuator/health` | api-gateway `:8086` (public health) |
| `/grafana` | Grafana `:3000` |

---

## 11. Post-Deploy Validation

**Run these in order. Do not declare a deploy successful until all pass.**

### 1. Service health

```bash
# Via public domain
curl -sf https://svtms.svtrucking.biz/actuator/health | jq .

# Via SSH on VPS (direct, no nginx)
ssh -i infra/deploy_key root@207.180.245.156 "
  for port in 8080 8082 8083 8084 8086 8087 8088; do
    status=\$(curl -sf http://127.0.0.1:\$port/actuator/health | python3 -c 'import sys,json; print(json.load(sys.stdin)[\"status\"])' 2>/dev/null || echo NOT_READY)
    echo \"Port \$port: \$status\"
  done
"
```

All must print `UP`.

### 2. Login smoke test

```bash
curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"YOUR_ADMIN_PASSWORD"}' \
  https://svtms.svtrucking.biz/api/auth/login | jq '.token // .data.token'
```

Must return a JWT string. If it returns `null` or an error — stop and check auth-api logs.

### 3. Admin UI smoke

Open `https://svtms.svtrucking.biz` in a browser. Log in as admin. Navigate to:
- Dashboard — should load without errors
- Dispatch — should load orders
- Drivers — should load driver list

### 4. WebSocket smoke

```bash
curl -i "https://svtms.svtrucking.biz/ws-sockjs/info?token=TEST"
# Must return HTTP 200 with JSON body
```

### 5. Routing smoke scripts

```bash
ssh -i infra/deploy_key root@207.180.245.156 "bash /opt/sv-tms/repo/infra/scripts/post_deploy_smoke.sh"
```

Required markers in output:
- `MICROSERVICE_ROUTING_SMOKE_OK`
- `OPENAPI_SPLIT_SMOKE_OK`
- `DYNAMIC_DRIVER_POLICY_SMOKE_OK`

If any marker is missing — execute [Section 13 — Rollback](#13-rollback) immediately.

---

## 12. Monitoring & Observability

### Grafana dashboard

URL: `https://svtms.svtrucking.biz/grafana`
Default user: `admin` / see `GRAFANA_ADMIN_PASSWORD` in `infra/.env`

Panels to watch after a deploy:
- **JVM heap** — should stabilize below 800 MB per service
- **HTTP error rate** — 5xx rate should be < 0.1%
- **DB connection pool** — should not be at saturation
- **Kafka consumer lag** — `tms-message-api` consumer should have lag < 100 messages

### Prometheus

Internal only at `:9090`. Access via SSH port-forward if needed:
```bash
ssh -i infra/deploy_key -L 9090:localhost:9090 root@207.180.245.156
# Open http://localhost:9090 in browser
```

### Live log tailing (production)

```bash
# All services
ssh -i infra/deploy_key root@207.180.245.156 "
  docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \
    -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml logs -f
"

# Single service
ssh -i infra/deploy_key root@207.180.245.156 "
  docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml logs -f core-api
"
```

### Spring Boot Actuator endpoints

Available at `/actuator/*` via nginx (health only exposed publicly):

| Endpoint | URL | Access |
|----------|-----|--------|
| Health | `/actuator/health` | Public (nginx exposes) |
| Metrics | `http://127.0.0.1:{port}/actuator/metrics` | VPS only (not public) |
| Info | `http://127.0.0.1:{port}/actuator/info` | VPS only |
| Loggers | `http://127.0.0.1:{port}/actuator/loggers` | VPS only |

Change log level at runtime (no restart needed):
```bash
ssh -i infra/deploy_key root@207.180.245.156 \
  "curl -s -X POST http://127.0.0.1:8080/actuator/loggers/com.svtrucking \
    -H 'Content-Type: application/json' \
    -d '{\"configuredLevel\":\"DEBUG\"}'"
```

---

## 13. Rollback

Use the Claude slash command from the repo root:
```bash
/rollback core-api
```

Or manually:

```bash
ssh -i infra/deploy_key root@207.180.245.156 "
  cd /opt/sv-tms/repo/infra

  # 1. Stop the broken service
  docker compose -f docker-compose.prod.yml stop core-api

  # 2. Re-tag the previous image as latest
  docker tag tms-core-api:previous tms-core-api:latest

  # 3. Start it back up
  docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml up -d core-api
"
```

After rollback — re-run all post-deploy checks from Section 11.

### Database rollback

If a Flyway migration caused issues:
1. **Do not run Flyway repair blindly.** Understand what the migration did first.
2. If the migration was destructive (DROP / TRUNCATE), restore from backup:
   ```bash
   ssh -i infra/deploy_key root@207.180.245.156 \
     "bash /opt/sv-tms/repo/infra/scripts/restore_db.sh svlogistics_tms_db /path/to/backup.sql"
   ```
3. Remove the bad migration file from `db/migration/` and create a corrective one.

---

## 14. Common Operations Runbook

### Backup databases

```bash
ssh -i infra/deploy_key root@207.180.245.156 \
  "bash /opt/sv-tms/repo/infra/scripts/backup_db.sh"
```

Backups are stored at `/srv/svtms/backups/` and optionally synced offsite:
```bash
ssh -i infra/deploy_key root@207.180.245.156 \
  "bash /opt/sv-tms/repo/infra/scripts/sync_backups_offsite.sh"
```

### Restart a single service

```bash
ssh -i infra/deploy_key root@207.180.245.156 "
  cd /opt/sv-tms/repo/infra
  docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml \
    restart core-api
"
```

### Check disk usage (VPS)

```bash
ssh -i infra/deploy_key root@207.180.245.156 "df -h && du -sh /srv/svtms/*"
```

Docker image cleanup (if disk is full):
```bash
ssh -i infra/deploy_key root@207.180.245.156 "docker image prune -f"
```

### View Kafka consumer lag

```bash
ssh -i infra/deploy_key root@207.180.245.156 "
  docker exec svtms-kafka-1 \
    kafka-consumer-groups.sh --bootstrap-server kafka-1:9092 \
    --describe --all-groups
"
```

### Reset a user's password (admin)

```bash
TOKEN=$(curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"YOUR_PASS"}' \
  https://svtms.svtrucking.biz/api/auth/login | jq -r '.token')

curl -s -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"username":"johndoe","email":"john@example.com","password":"newpass123","roles":["ADMIN"]}' \
  https://svtms.svtrucking.biz/api/admin/users/42
```

### Enable / disable a user account

```bash
# Disable
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  "https://svtms.svtrucking.biz/api/admin/users/42/status?enabled=false"

# Enable
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  "https://svtms.svtrucking.biz/api/admin/users/42/status?enabled=true"
```

### Grant a permission to a role

```bash
# List roles to find role ID
curl -s -H "Authorization: Bearer $TOKEN" \
  https://svtms.svtrucking.biz/api/admin/roles | jq '.[] | {id, name}'

# List permissions to find permission ID
curl -s -H "Authorization: Bearer $TOKEN" \
  https://svtms.svtrucking.biz/api/admin/permissions | jq '.[] | select(.name=="report:export")'

# Assign
curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  "https://svtms.svtrucking.biz/api/admin/roles/{roleId}/permissions/{permId}"
```

### Add a new DB migration (quick)

```bash
# Slash command scaffolds the file with correct naming and boilerplate
/new-migration add_customer_phone_index
```

### Check VPS health (all services at once)

```bash
/deploy-status
```

---

## 15. Troubleshooting Index

### Service won't start

1. Check logs: `docker compose -f docker-compose.local-dev.yml logs -f {service}`
2. Most common causes:
   - **DB not healthy yet** — wait 30s and retry; `depends_on: condition: service_healthy` sometimes races.
   - **Port already in use** — `lsof -i :{port}` to find the occupier.
   - **Flyway checksum mismatch** — see Section 8.
   - **`@PreUpdate` on multiple methods** — Hibernate 6.6 rejects combining lifecycle annotations on one method; split into separate methods.
   - **HQL uses column names instead of field names** — use Java entity field names in `@Query`, not DB column names.

### 401 Unauthorized on every request

1. Check token expiry: `echo $TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | python3 -m json.tool`
2. Check that `JWT_ACCESS_SECRET` in `infra/.env` matches between auth-api and api-gateway.
3. Check api-gateway logs for `AuthHeaderValidationFilter` errors.

### 403 Forbidden on a specific endpoint

1. Check the user's effective permissions:
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" \
     https://svtms.svtrucking.biz/api/admin/user-permissions/me/effective | jq .
   ```
2. Compare with the `@PreAuthorize` on the controller method.
3. Check if the permission is explicit-only (`dispatch:flow:manage` etc.) — those must be directly assigned to a role.

### Angular: route shows "Unauthorized" despite having the role

The server-loaded permission cache (`PermissionGuardService`) may be empty.
Check browser Network tab — did `GET /api/admin/user-permissions/me/effective` fire after login?
If not, log out and back in.

### Flyway migration failed on VPS

```bash
# SSH in and inspect
ssh -i infra/deploy_key root@207.180.245.156 \
  "docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml logs core-api | grep -i flyway"
```

**Do not run `flyway repair` until you understand why it failed.** If the migration is simply bad SQL, fix the file and deploy again — Flyway will retry. If checksums drifted, investigate before any fix.

### message-api unhealthy (Redis connection refused)

The compose stack is missing `SPRING_DATA_REDIS_HOST: redis` for message-api. Ensure `docker-compose.local-dev.yml` (and prod equivalent) includes this env var and restart message-api.

### core-api crash-loops on startup

Most likely causes:
1. `@PostLoad @PrePersist @PreUpdate` all on one method — Hibernate 6.6 rejects this. Split into two methods.
2. HQL query references non-existent field name (column name used instead of Java field name).
3. DB migration failed and JPA can't initialize `EntityManagerFactory`.

Run: `docker logs svtms-core-api 2>&1 | grep "Caused by"` to find the root cause.

### Kafka: message-api consumer lag growing

1. Check if message-api is running: `docker ps | grep message-api`
2. Check logs for connection errors: `docker logs svtms-message-api --tail 50`
3. If Kafka brokers are all down, start them: `docker compose -f docker-compose.local-dev.yml up -d kafka`
4. Consumer will auto-resume and catch up on backlog.

### VPS disk full

```bash
# 1. Check what's large
du -sh /srv/svtms/*
docker system df

# 2. Clean old Docker images (safe — only removes untagged/dangling)
docker image prune -f

# 3. Clean old logs
journalctl --vacuum-time=7d

# 4. Prune old DB backups
bash /opt/sv-tms/repo/infra/scripts/prune_backups.sh
```

### SSL certificate expired / not found

```bash
ssh -i infra/deploy_key root@207.180.245.156 "certbot renew --dry-run"
# If dry run passes:
ssh -i infra/deploy_key root@207.180.245.156 "certbot renew && systemctl reload nginx"
```

---

## Quick Reference Card

```
LOCAL DEV
  Start infra only:    docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka
  Start full stack:    docker compose -f docker-compose.local-dev.yml up -d --build
  Health check all:    for p in 8080 8082 8083 8084 8086 8087 8088; do curl -sf http://localhost:$p/actuator/health; echo " :$p"; done
  Stop everything:     docker compose -f docker-compose.local-dev.yml down

BUILD
  Backend (all):       ./tms-core-api/mvnw clean package -DskipTests
  Single module:       ./tms-core-api/mvnw -pl tms-core-api -am clean package -DskipTests
  Safety API:          cd tms-safety-api && ./mvnw clean package -DskipTests
  Angular:             cd tms-admin-web-ui && npm run build

TEST
  Backend:             ./tms-core-api/mvnw test
  Angular:             cd tms-admin-web-ui && npm run test:ci
  Flutter:             cd tms_driver_app && flutter test

DEPLOY
  Full VPS deploy:     bash DEPLOY_TO_VPS.sh
  One service:         ssh -i infra/deploy_key root@207.180.245.156 "cd /opt/sv-tms/repo/infra && docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml build {svc} && docker compose ... up -d {svc}"
  Health check (VPS):  /deploy-status
  Rollback service:    /rollback {service}

LOGS
  Local service:       docker compose -f docker-compose.local-dev.yml logs -f {service}
  VPS all:             ssh -i infra/deploy_key root@207.180.245.156 "docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml logs -f"

PORTS
  4200  Angular dev
  8080  core-api
  8082  telematics-api
  8083  auth-api
  8084  driver-app-api
  8086  api-gateway  ← only port clients use
  8087  safety-api
  8088  message-api
```
