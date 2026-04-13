# SV-TMS

Multi-service transport management system monorepo.

## Start Here

- [Local Development](./LOCAL_DEVELOPMENT.md)
- [Project Docs Index](./docs/README.md)
- [Collaboration Rules](./CLAUDE.md)

## Main Services

- `tms-core-api` — core admin/backend API on `8080`
- `tms-telematics-api` — live tracking and telemetry on `8082`
- `tms-auth-api` — authentication on `8083`
- `tms-driver-app-api` — driver app backend on `8084`
- `api-gateway` — unified gateway on `8086`
- `tms-admin-web-ui` — Angular admin UI on `4200`
- `tms_driver_app` — Flutter driver app
- `tms_customer_app` — Flutter customer app

## Quick Start

Start stateful dependencies:

```bash
docker compose -f docker-compose.local-dev.yml up -d mysql redis mongo postgres kafka
```

Run the core backend:

```bash
cd tms-core-api
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

Run the admin UI:

```bash
cd tms-admin-web-ui
npm ci
npm start
```

Open:

- Admin UI: `http://localhost:4200`
- Core API health: `http://localhost:8080/actuator/health`

## Frontend Verification

Run the live-map address regression:

```bash
cd tms-admin-web-ui
npm run test:e2e:live-map
```

## Notes

- Docker frontend container is optional via `--profile frontend`.
- Admin UI should use `/api/admin/*` and `/api/auth/*` only.
- For detailed ports, env vars, and service-specific commands, use [Local Development](./LOCAL_DEVELOPMENT.md).
