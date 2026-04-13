---
name: check-boundaries
description: Audit API boundary violations across all clients
---

Audit the codebase for API boundary violations. $ARGUMENTS

Check the following:

1. **Angular admin UI** (`tms-admin-web-ui/src/`):
   - Search for any HTTP calls to `/api/driver/*` or `/api/customer/*` paths.
   - Flag any hardcoded `localhost:808x` URLs (should use relative `/api/...` paths).

2. **Flutter driver app** (`tms_driver_app/lib/`):
   - Search for any calls to `/api/admin/*` paths.
   - Check `ApiConstants` — base URL must not be hardcoded to `localhost`.

3. **Flutter customer app** (`tms_customer_app/lib/` if it exists):
   - Search for any calls to `/api/admin/*` or `/api/driver/*` paths.

Rules (from `.claude/rules/api-boundaries.md`):
- Admin UI: only `/api/admin/*` and `/api/auth/*`
- Driver app: only `/api/driver/*` and `/api/auth/*`
- Customer app: only `/api/customer/{customerId}/*` and `/api/auth/*`

Output a list of any violations found, with file path and line number. If no violations, confirm each client is clean.
