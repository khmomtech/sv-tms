# Driver API Facade Map (Canonical)

Last updated: 2026-03-11
Applies to: `tms_driver_app`

## Goal
One canonical endpoint mapping per driver feature to avoid mixed/legacy usage.

## Canonical Map
| Feature | Endpoint(s) | Notes |
|---|---|---|
| Login | `/api/auth/driver/login` | Auth-owned |
| Refresh | `/api/auth/refresh` | Auth-owned |
| Device approval | `/api/driver/device/request-approval`, `/api/driver/device/register` | Auth-owned |
| Bootstrap | `/api/driver-app/bootstrap` | Driver-app owned |
| Current assignment | `/api/driver/current-assignment` | Fallback: `/api/driver/{driverId}/current-assignment` |
| Dispatch list/actions | `/api/driver/dispatches/**` | Driver-app owned |
| Tracking session | `/api/driver/tracking/session/start|refresh|stop` | Driver-app owned |
| Location update | `/api/driver/location/update`, `/api/driver/location/update/batch` | Driver-app owned |
| Banners | `/api/driver/banners/**` | Driver-app owned |
| Notifications | `/api/notifications/driver/{driverId}/**` | Driver-app owned |
| Incidents | `/api/driver-app/incidents/**` | Driver-app owned |
| Safety | `/api/driver/safety-checks/**` | Driver-app owned |
| App version | `/api/public/app-version/latest` | Driver-app owned public |
| About app | `/api/about-app` then `/api/public/about-app` | No `/api/admin/**` fallback in mobile |

## Rules
- Do not call `/api/admin/**` from `tms_driver_app`.
- Keep external path contract stable; migrate internals by replacing call-sites.
- If fallback is required, fallback must remain within driver/auth ownership boundaries.
