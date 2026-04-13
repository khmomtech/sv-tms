---
description: Flyway migration rules and database conventions for SV-TMS
---

# Database Rules

## Flyway Migrations

- Migrations live in `tms-core-api/src/main/resources/db/migration/`
- **Never edit a migration that has already run on production.** Create a new one instead.
- Naming: `V{YYYYMMDD}__{snake_case_description}.sql` (e.g. `V20260327__add_customer_field.sql`)
- For destructive changes, write a paired rollback: `U{version}__{description}_rollback.sql`
- If a checksum mismatch error appears on VPS, do not rename or edit the file — investigate first.

## Databases

| Service | DB Type | Database Name |
|---|---|---|
| tms-core-api | MySQL 8 | `svlogistics_tms_db` |
| tms-telematics-api | PostgreSQL 16 | `svlogistics_telematics` |
| tms-auth-api | MySQL 8 | shared MySQL instance |
| tms-driver-app-api | MySQL 8 | shared MySQL instance |
| tms-safety-api | MySQL 8 | shared MySQL instance |

## Before Touching Schema

1. Read all existing migrations to understand the current state.
2. Check if a migration is already applied on VPS before creating a new one.
3. Test locally with `docker compose -f docker-compose.local-dev.yml up -d mysql`.
