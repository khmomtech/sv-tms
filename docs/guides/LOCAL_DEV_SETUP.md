# SV-TMS Local Development Setup Guide

> Explained simply — think of SV-TMS like a restaurant.

---

## The Big Picture

| Piece | What it's like |
|---|---|
| **Databases** (MySQL, Redis…) | The kitchen storage — where all food (data) is kept |
| **Backend APIs** | The kitchen staff — they cook (process) the data |
| **api-gateway** | The front door — all orders go through it first |
| **Angular admin UI** | The manager's tablet — admin controls everything here |
| **Flutter driver app** | The driver's phone — drivers see their jobs here |

### Traffic Flow

```
Browser / App
     ↓
api-gateway :8086        ← the front door
     ↓
tms-core-api :8080       ← business logic
tms-auth-api :8083       ← login / tokens
tms-driver-app-api :8084 ← driver-specific logic
     ↓
MySQL / Redis / Mongo    ← databases
```

> **Rule:** Angular and Flutter always talk to port **8086** only. Never skip the gateway.

---

## Step 1 — Verify Tools Are Installed

```bash
# Java 21
java -version          # Should say "21.x.x"

# Maven wrapper
./mvnw --version       # Always use ./mvnw, never bare mvn

# Node / npm (for Angular)
node -v                # 18+ recommended
npm -v

# Flutter
flutter doctor         # Fix any red X before continuing

# Docker
docker -v
docker compose version
```

---

## Step 2 — Set Up Your Secret Config

Copy the example env file and fill in all `CHANGE_ME_*` values:

```bash
cp infra/.env.example infra/.env
```

Minimum values to set for local dev in `infra/.env`:

```
MYSQL_ROOT_PASSWORD=anything_strong_local
MYSQL_PASSWORD=anything_strong_local
JWT_ACCESS_SECRET=<run: openssl rand -hex 64>
JWT_REFRESH_SECRET=<run: openssl rand -hex 64>
```

> **Never commit `infra/.env` to git.** It contains secrets.

---

## Step 3 — Start the Databases

Run this once per session. Docker starts MySQL, Postgres, MongoDB, Redis, and Kafka:

```bash
docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka
```

Wait ~30 seconds, then verify all are healthy:

```bash
docker compose -f docker-compose.local-dev.yml ps
```

All services should show `healthy` or `Up`.

---

## Step 4 — Build the Backend

> **Important:** There is no `mvnw` at the repo root. All multi-module commands use `tms-core-api/mvnw` and must be run **from the repo root** (`sv-tms/`).

```bash
# Make sure you are at the repo root first
cd ~/Documents/develop/sv-tms

# Build all modules (skip tests)
tms-core-api/mvnw clean package -DskipTests
```

> Re-run this after any Lombok or MapStruct class change.

---

## Step 5 — Start Backend Services

> All commands below must be run from `sv-tms/` (repo root). Open a separate terminal tab per service.

```bash
# Confirm you are at repo root before each command
cd ~/Documents/develop/sv-tms

# Tab 1 — Main API (port 8080)
tms-core-api/mvnw -pl tms-core-api -am spring-boot:run -Dspring-boot.run.profiles=local

# Tab 2 — Auth (port 8083)
tms-core-api/mvnw -pl tms-auth-api -am spring-boot:run -Dspring-boot.run.profiles=local

# Tab 3 — Gateway (port 8086) — start this last, no profile needed
tms-core-api/mvnw -pl api-gateway -am spring-boot:run
```

Start `api-gateway` last — it needs the other services to be up first.

Optional services (start only if your task requires them):

```bash
# Driver app backend (port 8084) — from repo root
tms-core-api/mvnw -pl tms-driver-app-api -am spring-boot:run -Dspring-boot.run.profiles=local

# Telematics / GPS (port 8082) — standalone, has its own mvnw, uses dev profile
cd tms-telematics-api && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# Safety API (port 8087) — standalone, has its own mvnw
cd tms-safety-api && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

---

## Step 6 — Start the Angular Admin UI

```bash
cd tms-admin-web-ui
npm ci --legacy-peer-deps   # First time only
npm start                   # Opens at http://localhost:4200
```

The dev proxy automatically routes all `/api/*` calls to `localhost:8086`. No URL config needed.

---

## Step 7 — Run the Flutter Driver App

```bash
cd tms_driver_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8086   # Android emulator
# or
flutter run --dart-define=API_BASE_URL=http://localhost:8086   # iOS simulator
```

> `10.0.2.2` is how the Android emulator refers to your laptop's localhost.

---

## Debug Mode

### Mode A — Full Docker (no breakpoints, easiest)

Everything runs in containers. Good for smoke-testing.

```bash
# Start all services + frontend
docker compose -f docker-compose.local-dev.yml up -d

# Watch all logs
docker compose -f docker-compose.local-dev.yml logs -f

# Watch one service
docker compose -f docker-compose.local-dev.yml logs -f core-api
```

Open `http://localhost:4200` → Angular admin UI, proxied through gateway on `:8086`.

---

### Mode B — Hybrid (DBs in Docker, backend runs natively for breakpoints)

Best for debugging Java code with your IDE.

**Step 1 — Start only the databases:**
```bash
docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka
```

**Step 2 — Run backend services natively (each in its own terminal, all from `sv-tms/` repo root):**
```bash
cd ~/Documents/develop/sv-tms   # must be at repo root

# Terminal 1
tms-core-api/mvnw -pl tms-core-api -am spring-boot:run -Dspring-boot.run.profiles=local

# Terminal 2
tms-core-api/mvnw -pl tms-auth-api -am spring-boot:run -Dspring-boot.run.profiles=local

# Terminal 3 (start last, no profile needed)
tms-core-api/mvnw -pl api-gateway -am spring-boot:run
```

**Step 3 — Verify gateway is up:**
```bash
curl http://localhost:8086/actuator/health
```

---

### Java Debugger (IntelliJ / VSCode)

Add the debug JVM flag when starting a service:

```bash
# From repo root
tms-core-api/mvnw -pl tms-core-api -am spring-boot:run \
  -Dspring-boot.run.profiles=local \
  -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
```

Then in IntelliJ: **Run → Attach to Process → port 5005**

| Service | Debug port |
|---|---|
| tms-core-api | 5005 |
| tms-auth-api | 5006 |
| tms-driver-app-api | 5007 |
| api-gateway | 5008 |

---

### Angular Debug

```bash
cd tms-admin-web-ui
npm start   # http://localhost:4200
```

- Chrome DevTools → Sources → `webpack://` → your component files
- All `/api/*` calls proxy to `localhost:8086` via `proxy.conf.cjs`

---

### Flutter Debug

```bash
cd tms_driver_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8086   # Android emulator
flutter run --dart-define=API_BASE_URL=http://localhost:8086   # iOS simulator
```

Use `flutter devtools` for widget inspector + network tab.

---

## Daily Startup Checklist

Every morning, run these in order:

```bash
# 1. Start databases
docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka

# 2. Start backend — each in its own terminal, all from sv-tms/ repo root
cd ~/Documents/develop/sv-tms
tms-core-api/mvnw -pl tms-core-api   -am spring-boot:run -Dspring-boot.run.profiles=local
tms-core-api/mvnw -pl tms-auth-api   -am spring-boot:run -Dspring-boot.run.profiles=local
tms-core-api/mvnw -pl api-gateway    -am spring-boot:run

# 3. Start frontend
cd tms-admin-web-ui  && npm start

# 4. Verify gateway is up
curl http://localhost:8086/actuator/health
```

---

## Before You Commit — Test Checklist

```bash
# Java unit tests
./mvnw test

# Angular tests (headless with coverage)
cd tms-admin-web-ui && npm run test:ci

# Flutter tests
cd tms_driver_app && flutter test
```

No failures = safe to commit.

---

## Common Troubleshooting

| Problem | Fix |
|---|---|
| `mysql: healthy` but app can't connect | Port is `3307` (host) not `3306` — check your `application-local.yml` |
| `401 Unauthorized` on every call | Gateway not started yet — start it last |
| Angular shows `Cannot GET /api/...` | Gateway is down — check `localhost:8086/actuator/health` |
| Flutter can't reach backend on Android | Use `10.0.2.2` not `localhost` |
| `Checksum mismatch` on Flyway startup | Never edit existing migration files — create a new one |
| After Lombok change, compile errors | Run `./mvnw clean package` to regenerate annotation processors |

---

## Quick Reference

| Task | Command |
|---|---|
| Build backend (skip tests) | `tms-core-api/mvnw clean package -DskipTests` |
| Build single module | `tms-core-api/mvnw -pl tms-core-api -am clean package -DskipTests` |
| Start Angular | `cd tms-admin-web-ui && npm start` |
| Start Flutter | `cd tms_driver_app && flutter run` |
| Add DB migration | `/new-migration <description>` |
| Check API boundary violations | `/check-boundaries` |
| Check VPS health | `/deploy-status` |
| Deploy to VPS | `bash DEPLOY_TO_VPS.sh` |

---

## Port Reference

| Service | Port |
|---|---|
| api-gateway | 8086 |
| tms-core-api | 8080 |
| tms-auth-api | 8083 |
| tms-telematics-api | 8082 |
| tms-driver-app-api | 8084 |
| tms-safety-api | 8087 |
| tms-message-api | 8088 |
| Angular admin UI | 4200 |

---

## Common Mistakes to Avoid

| Mistake | Correct Way |
|---|---|
| Running `mvn` directly | Use `tms-core-api/mvnw` from repo root (no root `mvnw` exists) |
| Using `ng serve` | Use `npm start` (loads the proxy config) |
| Calling `localhost:808x` from Angular | Use relative `/api/...` paths |
| Hardcoding `localhost` in Flutter | Use `ApiConstants.baseUrl` |
| Editing an already-applied migration | Create a new migration file |
| Committing `infra/.env` | It's in `.gitignore` — keep it there |
