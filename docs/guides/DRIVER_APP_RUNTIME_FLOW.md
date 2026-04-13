# Driver App Runtime Flow

## Purpose
This document captures the current runtime flow for driver login, startup, home loading, and dispatch handling.

It is intended to support:
- App Store review preparation
- post-approval runtime reconfiguration
- API/admin/VPS ownership clarity

## 1. Login Flow

### Credential Validation
1. Driver enters `username` and `password`.
2. App calls `/api/auth/driver/login`.
3. API validates credentials first.

### Hard Enforcement Owned by API/VPS
These controls stay server-side:
- `APP_DRIVER_SKIP_DEVICE_CHECK`
- `APP_DRIVER_LOGIN_BYPASS`
- `APP_DRIVER_REQUIRE_APPROVED_DEVICE_FOR_TRACKING`
- telematics service on/off
- nginx/upstream routing safety
- startup/runtime stability controls

### Runtime UX Controlled by Bootstrap/Admin
These settings are runtime-configurable:
- `auth.device_approval_required`
- `auth.login_requires_tracking_session`
- `auth.auto_approve_latest_login_device`
- `auth.review_login_button_enabled`

### Review-Safe Login Behavior
When configured for review:
- username/password success is enough to enter the app
- device approval does not block login
- tracking session failure does not block login
- latest login device can still be updated in background
- no device approval error should be shown to the user

## 2. Post-Login Continuation

After credentials succeed:
1. Access token and refresh token are stored.
2. App may attempt tracking session start.
3. App checks bootstrap/admin policy.
4. If `auth.login_requires_tracking_session=false`, login continues even if tracking start fails.
5. If `auth.device_approval_required=false`, approval UI should not block entry.
6. Latest device registration/approval can run in background when:
   - `auth.auto_approve_latest_login_device=true`

## 3. Splash and Startup Flow

### Current Behavior
1. Splash checks whether a fresh token can be obtained.
2. App no longer trusts token presence alone.
3. If refresh succeeds, app can go to dashboard.
4. If refresh fails or times out, app goes to sign-in.

### Goal
Avoid entering a broken dashboard with:
- stale session
- expired token
- half-failed bootstrap

## 4. Home Screen Flow

### First Render Strategy
Home is designed to render shell first:
- header
- quick actions
- bottom navigation
- placeholders / fallback cards

### Runtime Home Policies
- `driver.home.defer_bootstrap_refresh`
- `driver.home.lazy_load_enabled`
- `driver.home.quick_actions_always_visible`
- `driver.home.connect_ws_in_background`

### Intended Behavior
1. Home shell renders immediately.
2. Bootstrap/settings refresh can happen in background.
3. Notifications, banners, dispatches, and safety load lazily.
4. WebSocket connection runs in background when enabled.
5. Slow APIs must not block the first visible screen.

## 5. Feature Toggle Flow

### Runtime Feature Flags
- `driver.chat.enabled`
- `driver.incident_report.enabled`
- `driver.telematics_ui_enabled`

### Backward-Compatible Fallback Keys
- `incident_report.enabled`
- `location_tracking.enabled`

### Current Usage
- driver drawer respects feature visibility
- quick actions respect feature visibility
- help center chat CTA respects `driver.chat.enabled`
- messages inbox respects `driver.chat.enabled`

## 6. Dispatch Flow

### Dispatch List Loading
After login/home startup, app requests:
- `/api/driver/dispatches/me/pending`
- `/api/driver/dispatches/me/in-progress`
- `/api/driver/current-assignment`

These should load lazily and should not block home shell rendering.

### Trips Screen
1. Trips screen resolves the logged-in driver id.
2. It fetches pending and in-progress dispatches in parallel.
3. If one request fails, screen remains usable and shows retry/fallback behavior.

### Trip Detail Screen
Trip detail shows:
- stops
- items
- map/contact actions
- next dispatch action

### Driver Action Button Rule
The trip detail screen now shows:
- only one primary next action
- no cancel/reject destructive buttons on this driver screen

Status updates still use normal backend flow:
- first accept: `acceptDispatch(...)`
- later transitions: `updateDispatchStatus(dispatchId, nextStatus)`

### Typical Dispatch Progression
Backend remains the source of truth for allowed transitions. Typical flow:
- `ASSIGNED`
- `DRIVER_CONFIRMED`
- `ARRIVED_LOADING`
- `LOADING`
- `LOADED`
- `IN_TRANSIT`
- `ARRIVED_UNLOADING`
- `UNLOADING`
- `UNLOADED`
- `DELIVERED`
- `COMPLETED`

## 7. Review-State Configuration

### Recommended API/VPS State
- `APP_DRIVER_SKIP_DEVICE_CHECK=true`
- `APP_DRIVER_LOGIN_BYPASS=true`
- `APP_DRIVER_REQUIRE_APPROVED_DEVICE_FOR_TRACKING=false`

### Recommended Bootstrap/Admin State
- `auth.device_approval_required=false`
- `auth.login_requires_tracking_session=false`
- `auth.auto_approve_latest_login_device=true`
- `driver.home.defer_bootstrap_refresh=true`
- `driver.home.lazy_load_enabled=true`
- `driver.home.quick_actions_always_visible=true`
- `driver.home.connect_ws_in_background=true`

### Expected Result
- login validates credentials first
- device/tracking does not block review login
- home loads quickly
- trip/dispatch screens stay usable even if secondary APIs are slow

## 8. Post-Approval Normal State

After App Store approval, behavior can be restored by API/VPS/admin settings:
- `APP_DRIVER_SKIP_DEVICE_CHECK=false`
- `APP_DRIVER_LOGIN_BYPASS=false`
- `APP_DRIVER_REQUIRE_APPROVED_DEVICE_FOR_TRACKING=true`
- `auth.device_approval_required=true`
- `auth.login_requires_tracking_session=true`
- `auth.auto_approve_latest_login_device=false`
- `driver.telematics_ui_enabled=true`
- telematics services re-enabled on VPS

## 9. Known Remaining Risks

Current technical risks are mostly operational, not architectural:
- slow VPS/API responses
- `core-api` / `auth-api` warmup instability
- instrumented Flutter integration tests require a real simulator/device
- Apple upload still depends on proper signing/export on this Mac

## 10. Source of Truth

The intended ownership model is:
- API/VPS:
  - hard login/device/tracking enforcement
  - telematics enable/disable
  - infrastructure stability
- bootstrap/admin settings:
  - runtime UX behavior
  - feature visibility
  - lazy loading and non-blocking home behavior

## 11. Canonical Telematics Endpoints

The driver app should use only the canonical telematics routes:
- `POST /api/driver/tracking/session/start`
- `POST /api/driver/tracking/session/refresh`
- `POST /api/driver/tracking/session/stop`
- `POST /api/driver/location`
- `POST /api/driver/location/batch`
- `POST /api/driver/presence/heartbeat`
- `POST /api/driver/location/spoofing-alert`

Legacy aliases still exist for compatibility, but they are deprecated and return deprecation headers.

See [Telematics API Migration Note](./TELEMATICS_API_MIGRATION_NOTE.md) for the published URL contract and sunset policy.
