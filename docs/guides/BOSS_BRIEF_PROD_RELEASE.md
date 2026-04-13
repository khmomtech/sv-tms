# Boss Brief: Production Release (One Page)

Date: 2026-03-11  
Project: `sv-tms`  
Target: morning production release

## 1) What We Changed

- Moved to split microservice operations model:
  - `tms-auth-api` (auth/login/token)
  - `tms-driver-app-api` (driver mobile APIs)
- Standardized route ownership and deploy checks.
- Created a clean docs system with one starting point.
- Marked old docs as legacy to reduce team confusion.

## 2) Current Technical Status

- Split services compile successfully.
- Auth and driver-app module test runs are green (no module-local tests defined yet).
- Backend integration suite executed and passed:
  - 100 tests run
  - 0 failures
  - 0 errors

## 3) Release Safety Gates (Must Pass)

1. Service health checks pass on VPS.
2. Routing smoke script passes and prints:
   - `MICROSERVICE_ROUTING_SMOKE_OK`
3. OpenAPI split ownership smoke passes and prints:
   - `OPENAPI_SPLIT_SMOKE_OK`
4. Dynamic driver policy smoke passes and prints:
   - `DYNAMIC_DRIVER_POLICY_SMOKE_OK`
5. Mobile smoke checks pass:
   - login + refresh
   - bootstrap/home
   - assignment
   - tracking/location
   - notifications/safety flows used by app

If any gate fails: stop release and rollback.

## 4) Main Risks (Honest View)

- Phase-1 split still has compile-time dependency on `tms-backend` code.
- Shared database is still used by both split services.
- Split modules have limited service-local tests (integration safety currently comes mostly from backend integration suite + smoke checks).

Risk level for today release: **medium but controlled** if smoke gates pass.

## 5) Rollback Plan

- Use release rollback script on VPS:
  - `DEPLOY_TO_VPS.sh`
- Restart services and reload nginx:
  - `tms-auth-api`
  - `tms-driver-app-api`
  - `nginx`

## 6) Decision Recommendation

Recommended: **Go Live** only after all post-deploy smoke markers pass and mobile smoke confirms core driver flows.

## 7) Source Docs

- Main docs hub:
  - `docs/README.md`
- System architecture:
  - `docs/guides/SA_DOCUMENT.md`
- Production checklist:
  - `docs/guides/PRODUCTION_READINESS_CHECKLIST.md`
- VPS runbook:
  - `docs/deployment/VPS_MAINTENANCE_AND_MONITORING_RUNBOOK.md`
