# Development Guide

Use this guide for normal day-to-day development in the current SV TMS workspace.

## Active Project Map

- Shared backend library: `tms-backend-shared`
- Core business API: `tms-core-api`
- Auth API: `tms-auth-api`
- Driver API: `tms-driver-app-api`
- Telematics API: `tms-telematics-api`
- Safety API: `tms-safety-api`
- Message API: `tms-message-api`
- API Gateway: `api-gateway`
- Device Gateway: `device-gateway`
- Admin web UI: `tms-admin-web-ui`
- Mobile apps: `tms_driver_app`, `tms_customer_app`, `tms_pre_load_safety_check`, `sv_loading_app`

## Recommended Workflow

1. Start infrastructure with Docker.
2. Run only the service you are editing on the host machine when you want fast feedback.
3. Use full `docker-compose.local-dev.yml` when you need cross-service integration.
4. Run targeted tests before broad integration checks.
5. Update docs when ports, startup commands, or service ownership change.

For Docker-based local testing:

- Start `5` infrastructure services for most tests: `mysql`, `redis`, `mongo`, `postgres`, `kafka`
- Start all `13` services only when you want the complete stack in Docker

## Local Development Entry Points

The canonical local stack is:

- [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md)

Use the integration guide when you want several services running together:

- [INTEGRATION_DEVELOPMENT_DEBUG_GUIDE.md](docs/guides/INTEGRATION_DEVELOPMENT_DEBUG_GUIDE.md)

## Useful Commands

### Compile selected backend modules

```bash
cd sv-tms
mvn -pl tms-core-api,tms-auth-api,tms-driver-app-api,tms-telematics-api,api-gateway -am -DskipTests compile
```

### Run targeted tests

```bash
cd sv-tms
mvn -pl tms-core-api -DfailIfNoTests=false test
mvn -pl tms-auth-api -DfailIfNoTests=false test
mvn -pl tms-driver-app-api -DfailIfNoTests=false test
mvn -pl tms-telematics-api -DfailIfNoTests=false test
```

### Run frontend checks

```bash
cd tms-admin-web-ui
npm ci --legacy-peer-deps
npm run build
npm run lint
```

## Development Rules

- Keep public API paths stable for mobile and web clients.
- Do not silently move endpoints between `tms-core-api`, `tms-auth-api`, `tms-driver-app-api`, `tms-telematics-api`, and `api-gateway`.
- Keep gateway routing aligned with backend ownership.
- Keep JWT and internal API key settings compatible across local services.
- Add or update tests for business logic changes.

## Before Opening PR

1. The edited modules compile.
2. The targeted tests pass.
3. Local startup instructions still work for the changed services.
4. Routing, ports, and environment variables remain documented correctly.
