# Telematics API Migration Note

## Purpose
This note defines the canonical telematics URL contract and the migration policy for legacy aliases.

Use this document when updating:
- `tms_driver_app`
- `tms-admin-web-ui`
- smoke tests and post-deploy validation scripts
- telematics API docs and onboarding guides

## Canonical URL Rules

Use these rules consistently:
- driver self-service writes stay under `/api/driver/...`
- admin reads and admin actions stay under `/api/admin/drivers/...`
- use resource names, not verb-heavy paths
- keep backward-compatible aliases only during a controlled migration window

## Canonical Driver Routes

| Purpose | Method | Canonical Route |
|---|---|---|
| Start tracking session | `POST` | `/api/driver/tracking/session/start` |
| Refresh tracking session | `POST` | `/api/driver/tracking/session/refresh` |
| Stop tracking session | `POST` | `/api/driver/tracking/session/stop` |
| Send single location point | `POST` | `/api/driver/location` |
| Send batched location points | `POST` | `/api/driver/location/batch` |
| Send presence heartbeat | `POST` | `/api/driver/presence/heartbeat` |
| Report spoofing alert | `POST` | `/api/driver/location/spoofing-alert` |
| Driver logout | `POST` | `/api/driver/logout` |

## Canonical Admin Routes

| Purpose | Method | Canonical Route |
|---|---|---|
| List live drivers | `GET` | `/api/admin/drivers/live` |
| List telemetry diagnostics | `GET` | `/api/admin/drivers/diagnostics` |
| Get latest driver location | `GET` | `/api/admin/drivers/{driverId}/location` |
| Get driver location history | `GET` | `/api/admin/drivers/{driverId}/history` |
| Get driver presence | `GET` | `/api/admin/drivers/{driverId}/presence` |

## Deprecated Legacy Aliases

These aliases still work for compatibility, but they are no longer the published contract:

| Deprecated Route | Canonical Successor |
|---|---|
| `/api/driver/location/update` | `/api/driver/location` |
| `/api/driver/location/update/batch` | `/api/driver/location/batch` |
| `/api/locations/spoofing-alert` | `/api/driver/location/spoofing-alert` |
| `/api/driver/tracking-session/start` | `/api/driver/tracking/session/start` |
| `/api/driver/tracking-session/refresh` | `/api/driver/tracking/session/refresh` |
| `/api/driver/tracking-session/stop` | `/api/driver/tracking/session/stop` |
| `/api/admin/telematics/live-drivers` | `/api/admin/drivers/live` |
| `/api/admin/telematics/driver-diagnostics` | `/api/admin/drivers/diagnostics` |
| `/api/admin/telematics/driver/{driverId}/location` | `/api/admin/drivers/{driverId}/location` |
| `/api/admin/telematics/driver/{driverId}/history` | `/api/admin/drivers/{driverId}/history` |
| `/api/admin/driver/{driverId}/presence` | `/api/admin/drivers/{driverId}/presence` |

## Deprecation Contract

Legacy aliases now return these response headers:
- `Deprecation: true`
- `Sunset: Tue, 30 Jun 2026 00:00:00 GMT`
- `Link: <canonical-path>; rel="successor-version"`

This means:
- clients should stop adding new uses of deprecated URLs immediately
- smoke tests and docs should probe canonical URLs only
- legacy alias coverage belongs in backend contract tests, not in new client code

## Migration Policy

1. Publish only canonical URLs in docs and examples.
2. Keep legacy aliases during the current compatibility window.
3. Move admin UI, Flutter, and validation scripts to canonical URLs first.
4. Monitor alias usage in access logs.
5. Remove aliases only after the compatibility window closes and clients are confirmed migrated.

## Verification

Canonical and legacy routing behavior is verified in:
- `tms-telematics-api` contract tests
- driver app tests
- admin UI unit tests
- shell smoke scripts using canonical URLs

## Source Of Truth

The code contract lives in:
- `tms-telematics-api/src/main/java/com/svtrucking/telematics/controller/DriverLocationController.java`
- `tms-telematics-api/src/main/java/com/svtrucking/telematics/controller/admin/AdminLiveTrackController.java`
- `tms-telematics-api/src/test/java/com/svtrucking/telematics/TelematicsContractTest.java`
