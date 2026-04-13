# SOP Index (Standard Operating Procedures)

Use this page to run day-to-day production work consistently.

## Core SOPs

1. [SOP 01 - Daily Operations](docs/guides/SOP_01_DAILY_OPERATIONS.md)
2. [SOP 02 - Release Deployment](docs/guides/SOP_02_RELEASE_DEPLOYMENT.md)
3. [SOP 03 - Incident Response](docs/guides/SOP_03_INCIDENT_RESPONSE.md)
4. [SOP 04 - Rollback and Recovery](docs/guides/SOP_04_ROLLBACK_AND_RECOVERY.md)
5. [SOP 05 - Handover and Reporting](docs/guides/SOP_05_HANDOVER_AND_REPORTING.md)
6. [SOP 06 - Dynamic Driver App Control](docs/guides/SOP_DYNAMIC_DRIVER_APP_CONTROL.md)

## Khmer SOP

- [SOP Khmer (Split Ops)](docs/guides/SOP_KHMER_SPLIT.md)

## Scope

These SOPs are for split microservice production:
- `tms-auth-api`
- `tms-driver-app-api`
- `nginx`

## Success Markers

Every release must pass:
- `MICROSERVICE_ROUTING_SMOKE_OK`
- `OPENAPI_SPLIT_SMOKE_OK`
- `DYNAMIC_DRIVER_POLICY_SMOKE_OK`
