# Integration Development Debug Guide

Use this guide when you need the admin UI, backend services, and local infrastructure working together.

## Target Local Topology

- Admin UI: `http://localhost:4200`
- API Gateway: `http://localhost:8086`
- Core API: `http://localhost:8080`
- Auth API: `http://localhost:8083`
- Driver App API: `http://localhost:8084`
- Telematics API: `http://localhost:8082`
- Safety API: `http://localhost:8087`
- Message API: `http://localhost:8088`

## Prerequisites

- Docker Desktop with Compose
- Java `21`
- Maven `3.9+`
- Node.js `20.19+`
- Flutter SDK if you are testing mobile apps

Quick checks:

```bash
docker --version
mvn -v
node -v
npm -v
flutter --version
```

## Fastest Integration Start

Docker service counts:

- Minimum for most local tests: `5` services
  - `mysql`, `redis`, `mongo`, `postgres`, `kafka`
- Full Docker stack: `13` services
  - `mysql`, `redis`, `mongo`, `postgres`, `kafka`
  - `core-api`, `auth-api`, `driver-app-api`, `telematics-api`
  - `safety-api`, `message-api`, `api-gateway`, `angular`

From the repository root:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.local-dev.yml up -d --build
```

Check services:

```bash
docker compose -f docker-compose.local-dev.yml ps
```

Tail logs:

```bash
docker compose -f docker-compose.local-dev.yml logs -f core-api
docker compose -f docker-compose.local-dev.yml logs -f api-gateway
docker compose -f docker-compose.local-dev.yml logs -f angular
```

## Hybrid Integration Flow

Use this when you want Docker for infrastructure but host-run services for faster code iteration.

### 1. Start infrastructure only

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka
```

### 2. Start backend services on the host

Core API:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms-core-api
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

Telematics API:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
export JWT_ACCESS_SECRET='changeme-dev-secret-32-chars-min!!!'
export TELEMATICS_INTERNAL_API_KEY='dev-internal-key'
mvn -pl tms-telematics-api spring-boot:run
```

Auth API:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
export MYSQL_PORT=3307
mvn -pl tms-auth-api -am spring-boot:run
```

Driver App API:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
export MYSQL_PORT=3307
export TELEMATICS_PROXY_BASE_URL='http://localhost:8082'
export TELEMATICS_PROXY_ENABLED='true'
mvn -pl tms-driver-app-api -am spring-boot:run
```

API Gateway:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
export CORE_API_BASE_URL='http://localhost:8080'
export AUTH_API_BASE_URL='http://localhost:8083'
export DRIVER_APP_API_BASE_URL='http://localhost:8084'
export TELEMATICS_API_BASE_URL='http://localhost:8082'
export SAFETY_API_BASE_URL='http://localhost:8087'
mvn -pl api-gateway -am spring-boot:run
```

Notes:

- `tms-safety-api` is easiest through Compose in the current setup.
- `tms-message-api` is also easiest through Compose because it relies on Kafka and its local H2 file setup.

### 3. Start the admin UI

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms-admin-web-ui
npm ci --legacy-peer-deps
npm start
```

The proxy defaults to `http://127.0.0.1:8086`.

## Mobile App Debug

Example for Android emulator:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms_driver_app
flutter pub get
flutter run
```

If the emulator cannot reach your host service, use `10.0.2.2` or your host machine IP instead of `localhost`.

## Health Checks

```bash
curl -s http://localhost:8080/actuator/health
curl -s http://localhost:8082/actuator/health
curl -s http://localhost:8083/actuator/health
curl -s http://localhost:8084/actuator/health
curl -s http://localhost:8086/actuator/health
curl -s http://localhost:8087/actuator/health
curl -s http://localhost:8088/actuator/health
curl -I http://localhost:4200
```

## Common Problems

### Admin UI does not load on `4200`

- Check that Node.js is `20.19+`.
- Check whether another process already owns port `4200`.
- Check whether `api-gateway` is reachable on `8086`.

Commands:

```bash
node -v
lsof -nP -iTCP:4200 -sTCP:LISTEN
curl -s http://localhost:8086/actuator/health
```

### Auth or driver API cannot connect to MySQL

- When running outside Docker, set `MYSQL_PORT=3307`.
- Confirm MySQL is up from `docker-compose.local-dev.yml`.

Commands:

```bash
docker compose -f docker-compose.local-dev.yml ps mysql
curl -s http://localhost:8083/actuator/health
curl -s http://localhost:8084/actuator/health
```

### Telematics API cannot start

- Confirm Postgres is running on `5432`.
- Confirm `JWT_ACCESS_SECRET` and `TELEMATICS_INTERNAL_API_KEY` are set when needed.

Commands:

```bash
docker compose -f docker-compose.local-dev.yml ps postgres
curl -s http://localhost:8082/actuator/health
```

### Gateway routes fail but direct services work

- Recheck the exported `*_BASE_URL` values before starting `api-gateway`.
- Confirm each target service health endpoint responds locally.

## Stop Everything

Stop host-run services with `Ctrl + C`.

Stop Compose services:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.local-dev.yml down
```

## Reference

- [LOCAL_DEVELOPMENT.md](/Users/sotheakh/Documents/develop/sv-tms/LOCAL_DEVELOPMENT.md)
