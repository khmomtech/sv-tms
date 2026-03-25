# Cleanup Freeze + Dead/Overlap + Priorities

Last updated: 2026-03-11

## 1) Freeze Rule (effective immediately)
- No new menu item, route, endpoint, or navigation alias during cleanup unless linked to an approved cleanup ticket.
- No contract-breaking path changes for mobile.
- No merging frontend menu changes without route-resolution validation.

## 2) Dead/Overlap List
## Flutter (`tms_driver_app`)
- Dead route constant: `AppRoutes.documents` existed but had no route case in `RouteGenerator`.
- Dead quick-action IDs: `daily_summary` and `more` had no mapping in `HomeRoutes.quickActionRoute`.
- Legacy API dependency: `AssignmentService` used `/api/admin/assignments/permanent/{driverId}`.
- Legacy fallback: `AboutAppProvider` fallback to `/api/admin/about-app`.

## Angular (`tms-frontend`)
- Sidebar config contains legacy/advanced aliases mixed with primary navigation.
- Several routes depend on redirects (for compatibility) and need explicit ownership in docs/tests.

## Split APIs
- Driver flows must only use:
  - `/api/driver/**`
  - `/api/driver-app/**`
  - `/api/public/app-version/**`
- Auth flows must only use:
  - `/api/auth/**`
  - `/api/driver/device/**`

## 3) Priority Buckets
- P0
  - Broken route/action behavior (tap but no destination).
  - Any driver-mobile `/api/admin/**` usage.
  - Auth/session regressions (login/refresh/logout mismatch).
- P1
  - Confusing menu labels/order.
  - Legacy aliases kept without explicit deprecation note.
  - Route-permission mismatches in sidebar.
- P2
  - Cosmetic naming consistency.
  - Non-critical copy/visual harmonization.

## 4) Merge Gate (minimum)
- Core flow smoke passes:
  - login/refresh
  - bootstrap/home
  - assignment/dispatch actions
  - tracking/location/ws
  - notifications/incidents/safety
- Routing smoke marker present: `MICROSERVICE_ROUTING_SMOKE_OK`
- OpenAPI marker present: `OPENAPI_SPLIT_SMOKE_OK`
- Dynamic policy marker present: `DYNAMIC_DRIVER_POLICY_SMOKE_OK`
