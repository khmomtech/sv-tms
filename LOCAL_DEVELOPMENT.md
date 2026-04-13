# Local Development

This repository is a multi-service TMS workspace. The current local development entry points are:

- Backend services: `tms-core-api`, `tms-auth-api`, `tms-driver-app-api`, `tms-telematics-api`, `tms-safety-api`, `tms-message-api`, `api-gateway`, `device-gateway`
- Web frontend: `tms-admin-web-ui`
- Flutter apps: `tms_driver_app`, `tms_customer_app`, `tms_pre_load_safety_check`, `sv_loading_app`

The fastest path depends on what you are changing:

- Use `docker-compose.local-dev.yml` for full-stack integration.
- Use a hybrid setup for day-to-day backend or frontend work.

## Prerequisites

- Java `21`
- Maven `3.9+`
- Node.js `20.19+` and npm `10+`
- Docker Desktop with Compose
- Flutter SDK for mobile work

## Port Map

- MySQL: `3307`
- Redis: `6379`
- MongoDB: `27017`
- Postgres: `5432`
- Kafka: `9092`
- Core API: `8080`
- Telematics API: `8082`
- Auth API: `8083`
- Driver App API: `8084`
- API Gateway: `8086`
- Safety API: `8087`
- Message API: `8088`
- Admin UI: `4200`

## Recommended Workflows

### Docker services needed for testing

For most local testing, you do not need the full stack in Docker.

- Minimum for most backend and web integration testing: `5` services
  - `mysql`
  - `redis`
  - `mongo`
  - `postgres`
  - `kafka`
- Full Docker stack: `13` services
  - `mysql`
  - `redis`
  - `mongo`
  - `postgres`
  - `kafka`
  - `core-api`
  - `auth-api`
  - `driver-app-api`
  - `telematics-api`
  - `safety-api`
  - `message-api`
  - `api-gateway`
  - `angular`

The `angular` container is now opt-in behind the Compose `frontend` profile so backend restarts stay stable by default.

Start the minimum Docker set:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka
```

Start the full Docker set:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.local-dev.yml up -d --build
```

Start the full Docker set including the frontend container:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.local-dev.yml --profile frontend up -d --build
```

### 1. Full local stack with Docker

Use this when you need cross-service integration, gateway routing, or a clean reproducible environment.

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.local-dev.yml up -d --build
```

Check status:

```bash
docker compose -f docker-compose.local-dev.yml ps
```

Main URLs:

- Admin UI: `http://localhost:4200`
- API Gateway: `http://localhost:8086`
- Core API health: `http://localhost:8080/actuator/health`
- Auth API health: `http://localhost:8083/actuator/health`
- Driver App API health: `http://localhost:8084/actuator/health`
- Telematics API health: `http://localhost:8082/actuator/health`
- Safety API health: `http://localhost:8087/actuator/health`
- Message API health: `http://localhost:8088/actuator/health`

Stop everything:

```bash
docker compose -f docker-compose.local-dev.yml down
```

### 2. Hybrid local development

Use this when you want faster edit-run-debug loops.

Start only the stateful dependencies:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka
```

Then run only the services you are actively editing on your host machine.

## Backend Development

### Core API

`tms-core-api` already has a working local profile for MySQL on `3307` and Redis on `6379`.

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms-core-api
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

Health check:

```bash
curl http://localhost:8080/actuator/health
```

### Telematics API

`tms-telematics-api` runs against local Postgres by default. Set the shared secrets so calls from other services stay compatible.

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
export JWT_ACCESS_SECRET='changeme-dev-secret-32-chars-min!!!'
export TELEMATICS_INTERNAL_API_KEY='dev-internal-key'
mvn -pl tms-telematics-api spring-boot:run
```

Health check:

```bash
curl http://localhost:8082/actuator/health
```

### Auth API

`tms-auth-api` imports common datasource settings from `tms-backend-shared`. Point MySQL to `3307` when running outside Docker.

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
export MYSQL_PORT=3307
mvn -pl tms-auth-api -am spring-boot:run
```

### Driver App API

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
export MYSQL_PORT=3307
export TELEMATICS_PROXY_BASE_URL='http://localhost:8082'
export TELEMATICS_PROXY_ENABLED='true'
mvn -pl tms-driver-app-api -am spring-boot:run
```

### API Gateway

Run this when the admin UI should talk to all backend services through one entry point.

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
export CORE_API_BASE_URL='http://localhost:8080'
export AUTH_API_BASE_URL='http://localhost:8083'
export DRIVER_APP_API_BASE_URL='http://localhost:8084'
export TELEMATICS_API_BASE_URL='http://localhost:8082'
export SAFETY_API_BASE_URL='http://localhost:8087'
mvn -pl api-gateway -am spring-boot:run
```

### Other services

- `tms-safety-api` is currently easiest to run through Compose because `docker-compose.local-dev.yml` starts it with the `dev` profile.
- `tms-message-api` is usually simplest through Compose because it expects Kafka and persists to a local H2 file volume there.
- `device-gateway` can be run directly with:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/device-gateway
./mvnw spring-boot:run
```

## Frontend Development

`tms-admin-web-ui` requires Node.js `20.19+`. The dev proxy defaults to the gateway on `8086`, with per-service overrides available through environment variables.

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms-admin-web-ui
npm ci --legacy-peer-deps
npm start
```

Open:

- `http://localhost:4200`

Useful verification:

```bash
npm run test:e2e:live-map
```

This validates the selected-driver latest-address flow on `/live/map`.

Useful proxy overrides:

```bash
API_GATEWAY_PROXY_TARGET=http://127.0.0.1:8086 npm start
CORE_API_PROXY_TARGET=http://127.0.0.1:8080 npm start
AUTH_API_PROXY_TARGET=http://127.0.0.1:8083 npm start
DRIVER_API_PROXY_TARGET=http://127.0.0.1:8084 npm start
TELEMATICS_PROXY_TARGET=http://127.0.0.1:8082 npm start
```

## Mobile Development

Example for the driver app:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms_driver_app
flutter pub get
flutter run
```

If the emulator cannot reach `localhost`, use the host machine IP or Android emulator alias `10.0.2.2` where appropriate.

## Verification Commands

```bash
curl http://localhost:8080/actuator/health
curl http://localhost:8082/actuator/health
curl http://localhost:8083/actuator/health
curl http://localhost:8084/actuator/health
curl http://localhost:8086/actuator/health
curl http://localhost:8087/actuator/health
curl http://localhost:8088/actuator/health
```

Tail logs from Compose:

```bash
docker compose -f docker-compose.local-dev.yml logs -f core-api
docker compose -f docker-compose.local-dev.yml logs -f api-gateway
docker compose -f docker-compose.local-dev.yml logs -f angular
```

## Notes

- The old `tms-backend` and `tms-frontend` names are no longer the active local development entry points in this workspace.
- `docker-compose.local-dev.yml` is the current canonical local integration stack.
- For backend iteration, the most practical host-run services today are `tms-core-api`, `tms-telematics-api`, `tms-auth-api`, `tms-driver-app-api`, and `api-gateway`.
