# Cleanup 3-Phase Execution Guide

Last updated: 2026-03-11
Scope: `tms_driver_app`, `tms-admin-web-ui`, `tms-auth-api`, `tms-driver-app-api`

## Simple Goal
Make navigation and APIs clean without breaking production URLs.

## Phase 1 (Baseline) Checklist
1. Create inventory matrix: done in `docs/frontend/CLEANUP_FLOW_INVENTORY_MATRIX.md`.
2. Apply freeze rule and priority list: done in `docs/frontend/CLEANUP_FREEZE_DEAD_OVERLAP_PRIORITIES.md`.
3. Start dead/overlap cleanup from P0:
   - fixed dead quick-action mappings in Flutter.
   - fixed missing documents route handling.
   - removed direct mobile dependency on `/api/admin/**` in assignment flow.

## Phase 2 (Contract/API) Checklist
1. Use canonical map: `docs/frontend/DRIVER_API_FACADE_MAP.md`.
2. Apply dynamic admin key contract: `docs/frontend/DYNAMIC_DRIVER_APP_ADMIN_KEYS.md`.
3. Remove mobile `/api/admin/**` fallback usage (continuing sweep).
4. Keep ownership contract strict:
   - auth: `/api/auth/**`, `/api/driver/device/**`
   - driver-app: `/api/driver/**`, `/api/driver-app/**`, `/api/public/app-version/**`, `/ws`, `/ws-sockjs/**`
5. Generate OpenAPI diff artifacts (before/after) per service before release.

## Phase 3 (Menu/Flow) Checklist
1. Flutter:
   - keep one route registry (`AppRoutes` + `RouteGenerator`).
   - ensure every quick action has a route mapping.
2. Angular:
   - enforce menu route integrity by tests.
   - keep legacy items explicitly advanced.
3. Remove deprecated aliases only after smoke validation.

## Release Gate (No-Go by default)
Release is allowed only when all are true:
- `MICROSERVICE_ROUTING_SMOKE_OK`
- `OPENAPI_SPLIT_SMOKE_OK`
- `DYNAMIC_DRIVER_POLICY_SMOKE_OK`
- mobile smoke pass (login/refresh/bootstrap/assignment/tracking/location/notifications/incidents/safety)

## Commands (copy/paste)
```bash
# Split services compile
mvn -pl tms-auth-api,tms-driver-app-api -am -DskipTests clean compile

# Backend integration tests
mvn -pl tms-backend -am -Dtest='*IntegrationTest,*IT' -Dsurefire.failIfNoSpecifiedTests=false test

# VPS routing smoke
infra/scripts/post_deploy_smoke.sh

# VPS OpenAPI ownership smoke
infra/scripts/post_deploy_smoke.sh

# VPS dynamic driver-policy smoke
infra/scripts/post_deploy_smoke.sh
```
