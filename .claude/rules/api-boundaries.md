---
description: API boundary rules — which client can call which prefix
---

# API Boundary Rules

These rules are enforced by the API gateway. Violating them is a security issue, not just a style issue.

| Client | Allowed prefixes |
|---|---|
| Admin UI (`tms-admin-web-ui`) | `/api/admin/*`, `/api/auth/*` |
| Driver app (`tms_driver_app`) | `/api/driver/*`, `/api/auth/*` |
| Customer app (`tms_customer_app`) | `/api/customer/{customerId}/*`, `/api/auth/*` |

## Rules

- **Never call `/api/admin/*` from mobile apps.**
- **Never call `/api/driver/*` from the admin UI.**
- **Never call `/api/customer/*` from admin or driver clients.**
- Angular components must use relative paths (`/api/...`) — the dev proxy in `proxy.conf.cjs` handles routing to `localhost:8086`.
- Flutter must use `ApiConstants.baseUrl` — never hardcode `localhost` (use `10.0.2.2` for Android emulator).

## Verification

Before adding a new API call in any client, check the path prefix matches the allowed list above.
