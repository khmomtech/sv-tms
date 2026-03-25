# Production Readiness Checklist (Kid-Friendly)

Use this checklist before every production release.

## A) Build Ready

- [ ] `mvn -pl tms-auth-api,tms-driver-app-api -am -DskipTests clean compile` is green
- [ ] no unresolved IDE compile errors in split modules

## B) Test Ready

- [ ] auth-api tests run (or no tests expected) and build is green
- [ ] driver-app-api tests run (or no tests expected) and build is green
- [ ] backend integration tests pass
- [ ] important mobile flows manually smoke-tested

## C) Route Ownership Ready

- [ ] nginx routes match split contract
- [ ] auth owns `/api/auth/**` and `/api/driver/device/**`
- [ ] driver-app owns `/api/driver/**`, `/api/driver-app/**`, `/api/public/app-version/**`, `/ws-sockjs/**`
- [ ] no driver-mobile dependency on `/api/admin/**`

## D) Deploy Ready

- [ ] environment files exist for both services
- [ ] systemd unit files are correct (`tms-auth-api`, `tms-driver-app-api`)
- [ ] rollback script is available and tested
- [ ] DB backup completed before release

## E) Post-Deploy Must Pass

Run in this order:
1. service health
2. routing smoke
3. OpenAPI split smoke
4. dynamic driver-policy smoke

Must contain:
- [ ] `MICROSERVICE_ROUTING_SMOKE_OK`
- [ ] `OPENAPI_SPLIT_SMOKE_OK`
- [ ] `DYNAMIC_DRIVER_POLICY_SMOKE_OK`

If any item fails, stop release and rollback.

## F) Early Monitoring (First 60 Minutes)

- [ ] monitor `journalctl -u tms-auth-api -f`
- [ ] monitor `journalctl -u tms-driver-app-api -f`
- [ ] monitor nginx errors
- [ ] verify login, bootstrap, assignment, tracking, notifications from mobile
