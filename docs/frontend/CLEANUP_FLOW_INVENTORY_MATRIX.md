# Flow Inventory Matrix (Driver Flutter + Admin Angular + Split APIs)

Last updated: 2026-03-11
Owner: Platform cleanup stream

## Purpose
This is the single source of truth for cleanup.  
Rule: if a flow is not in this table, it is out of scope for this cleanup batch.

## Core Flows
| Flow ID | Driver Flutter Entry | Angular Entry (if any) | API Endpoints (public contract) | Owner Service |
|---|---|---|---|---|
| auth.login | `SignInScreen` | `LoginComponent` | `/api/auth/driver/login`, `/api/auth/login` | `tms-auth-api` |
| auth.refresh | `DioClient` auth interceptor | auth interceptor | `/api/auth/refresh` | `tms-auth-api` |
| auth.logout | profile/settings logout | admin logout | token clear client-side + auth lifecycle APIs | `tms-auth-api` |
| app.bootstrap | `AppBootstrapProvider` | N/A | `/api/driver-app/bootstrap` | `tms-driver-app-api` |
| home.banner | Home banner section | banner admin setup | `/api/driver/banners/**` | `tms-driver-app-api` |
| driver.profile.read | `DriverProvider.fetchDriverProfile` | driver management pages | `/api/driver/me/profile`, `/api/driver/{id}` | `tms-driver-app-api` |
| driver.profile.update | profile edit | driver management pages | `/api/driver/update/{id}` (legacy), `/api/driver/me/profile` | `tms-driver-app-api` |
| driver.profile.upload | profile photo upload | N/A | `/api/driver/{driverId}/upload-profile` | `tms-driver-app-api` |
| driver.assignment.current | home/assignment widgets | dispatch board visibility | `/api/driver/current-assignment`, `/api/driver/{id}/current-assignment` | `tms-driver-app-api` |
| driver.dispatch.list | `DispatchProvider` | dispatch modules | `/api/driver/dispatches/**` | `tms-driver-app-api` |
| driver.dispatch.action | accept/reject/load/unload/status | dispatch modules | `/api/driver/dispatches/{id}/**` | `tms-driver-app-api` |
| tracking.session | tracking manager | live monitoring views | `/api/driver/tracking/session/start`, `/refresh`, `/stop` | `tms-driver-app-api` |
| tracking.location | location service/ws fallback | live map | `/api/driver/location/**` + `/ws`, `/ws-sockjs/**` | `tms-driver-app-api` |
| notifications | notification screen | admin notification center | `/api/notifications/driver/{driverId}/**` | `tms-driver-app-api` |
| incidents | issue/incidents screens | incidents/cases/tasks | `/api/driver-app/incidents/**` | `tms-driver-app-api` |
| safety.check | safety screens | safety module | `/api/driver/safety-checks/**` | `tms-driver-app-api` |
| app.version | version checker | admin app mgmt | `/api/public/app-version/**` | `tms-driver-app-api` |
| device.approval | device approval screens | driver device admin | `/api/driver/device/**` | `tms-auth-api` |

## Explicit Ownership Guardrails
- Driver mobile app must not depend on `/api/admin/**`.
- `ws` and `ws-sockjs` are driver-app owned and must validate JWT from `tms-auth-api`.
- External paths remain stable during cleanup; only internals are normalized.
