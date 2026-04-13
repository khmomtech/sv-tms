# Driver App Admin UI Guide

Last updated: 2026-04-08
Audience: Admin, Ops, Dispatch Supervisor, Support

## Purpose

This guide explains how to manage the driver mobile app from the admin web UI without shipping a new app build for every operational change.

It covers:
- force update and optional update
- minimum supported version
- maintenance mode
- info banners and alerts
- dynamic feature and screen management
- recommended rollout and rollback steps
- important limits for old app versions and offline phones

## Main Admin Entry Point

Open:

`Settings -> Driver App Management`

This hub is implemented in:
- [driver-app-hub.component.ts](/Users/sotheakh/Documents/develop/sv-tms/tms-admin-web-ui/src/app/admin/settings/pages/driver-app-hub/driver-app-hub.component.ts)

From this page, admin can open:
- `App Version & Updates`
- `Maintenance & Info Alerts`
- `Module & Feature Toggles`
- `Banner Management`
- `Driver Notifications`
- `Notification Settings`

## What Admin Can Control

### 1. App Version and Update Policy

Open:

`Settings -> Driver App Management -> App Version & Updates`

Page source:
- [app-version-management.component.ts](/Users/sotheakh/Documents/develop/sv-tms/tms-admin-web-ui/src/app/admin/settings/pages/app-version-management/app-version-management.component.ts)
- [app-version.service.ts](/Users/sotheakh/Documents/develop/sv-tms/tms-admin-web-ui/src/app/services/app-version.service.ts)

Main fields:
- `Latest Version`
  - target version you want drivers to use
- `Min Supported Version`
  - oldest version still allowed when force update is enabled
- `Force Update (mandatory)`
  - blocks app usage for unsupported versions
- `Play Store URL`
- `App Store URL`
- `Release Note (EN/KM)`
- `Android Override`
  - Android-specific version and force-update policy
- `iOS Override`
  - iOS-specific version and force-update policy

How to use:
- use `Latest Version` for the recommended release
- use `Min Supported Version` for the hard cutoff
- enable `Force Update` only when the store release is already published and verified
- use Android/iOS override only when one platform must move faster than the other

Recommended meaning:
- `Latest Version = 2.5.0`
  - app should suggest update to 2.5.0
- `Min Supported Version = 2.3.0`
  - any app below 2.3.0 is no longer supported
- `Force Update = true`
  - versions below `2.3.0` are blocked by backend and current app startup checks

## 2. Maintenance Mode

Maintenance is configured on the same `App Version & Updates` page.

Fields:
- `Maintenance Mode Active`
- `Maintenance Until`
- `Message (EN)`
- `Message (KM)`

Behavior:
- when enabled, the driver app shows a maintenance screen
- normal usage is blocked until maintenance is turned off or the maintenance window ends
- bilingual messages should be filled for clear driver communication

Best practice:
- always set `Maintenance Until`
- always write a short reason
- use this only for planned outage or emergency stop

Good example:
- EN: `System maintenance in progress. Please wait and reopen the app at 10:30 PM.`
- KM: localized equivalent for the same instruction

## 3. Info Banner / Info Strip

This is also controlled on the version page.

Use it for:
- operational notice
- store update reminder
- short driver instruction

Use info banner for:
- `Please update today after trip close`
- `GPS service maintenance tonight 10:00 PM`

Do not use info banner for:
- emergency hard stop
- forced logout workflow
- long instructions

## 4. Dynamic Screens, Features, and Policies

Open:

`Settings -> Driver App Management -> Module & Feature Toggles`

Page source:
- [app-management.component.ts](/Users/sotheakh/Documents/develop/sv-tms/tms-admin-web-ui/src/app/admin/settings/pages/app-management/app-management.component.ts)
- [settings.service.ts](/Users/sotheakh/Documents/develop/sv-tms/tms-admin-web-ui/src/app/services/settings.service.ts)

Admin can manage:
- screens
- features
- policies
- navigation items
- bottom tabs
- home quick actions
- dispatch action behavior

Scopes:
- `GLOBAL`
- `ROLE`
- `USER`

Resolution model:
- more specific scope overrides less specific scope
- practical order is `GLOBAL -> ROLE -> USER`

Safe workflow:
1. Start at `GLOBAL`.
2. Test with one `ROLE` if piloting a change.
3. Use `USER` only for exceptions or troubleshooting.

Key capabilities:
- hide or show menu items
- hide or show quick actions
- change dispatch action rules
- preview effective config for a specific user
- inspect per-key audit history

This area is the right place for runtime UI changes that do not require a mobile release.

## 5. Banners and Notifications

From the driver app hub, admin can also manage:
- app banners
- targeted notifications
- broadcast notifications
- delivery-channel settings

Use these for communication, not version enforcement.

Recommended split:
- version page = app entry control
- app management = runtime features and menus
- banners/notifications = communication and campaigns

## Recommended Release Rollout

### Optional Update Rollout

Use when:
- release is recommended but not urgent

Steps:
1. Publish app build to store.
2. Set `Latest Version`.
3. Keep `Force Update = false`.
4. Add release notes and info banner.
5. Monitor adoption.

### Forced Update Rollout

Use when:
- old build is broken
- auth/security behavior changed
- telemetry contract changed
- major production fix is required

Steps:
1. Publish and verify the new store build first.
2. Set `Latest Version`.
3. Set `Min Supported Version`.
4. Verify Play Store / App Store URLs.
5. Enable `Force Update`.
6. Notify supervisors and drivers.
7. Monitor login, update, and support tickets.

### Maintenance Rollout

Use when:
- planned server maintenance
- emergency platform stop

Steps:
1. Set bilingual maintenance messages.
2. Set `Maintenance Until`.
3. Enable `Maintenance Mode Active`.
4. Confirm app blocks normal usage.
5. Disable maintenance when service is restored.

## Rollback

### Rollback Force Update

If force update was enabled too early:
1. Turn `Force Update` off.
2. Lower or clear `Min Supported Version` if needed.
3. Save.
4. Add an info banner telling drivers what to do next.

### Rollback Maintenance

1. Turn `Maintenance Mode Active` off.
2. Save.
3. Ask drivers to reopen the app if necessary.

### Rollback Runtime Feature Change

1. Open `App Management`.
2. View audit history for the changed key.
3. Restore the prior value.
4. Save with reason.

## Important Operational Limits

### Old App Versions

Current production behavior:
- new builds enforce update at app startup/resume
- backend can also block unsupported old builds using the version policy

But there are limits:
- a phone that is powered off cannot receive new policy until it reconnects
- an offline phone cannot be forced immediately
- very old app behavior still depends on what that binary sends and supports

Professional expectation:
- server-side enforcement blocks unsupported versions when they reconnect
- client-side enforcement improves UX for current builds

### Offline Phones

Admin cannot force anything instantly on:
- a powered off phone
- a phone with no network
- a phone that never reopens the app

When the device reconnects:
- version policy applies again
- maintenance mode applies again
- runtime bootstrap config applies again

### Force Update Does Not Equal Device Management

This is application-level control, not MDM.

It can:
- block unsupported app usage
- require update before normal use
- show messages and maintenance screen

It cannot:
- remotely install the store update
- power on a phone
- guarantee instant action on offline devices

## Recommended Admin Policy

### Normal Operations

- keep `Force Update` off by default
- use `Latest Version` and info banner for normal releases
- use `App Management` for runtime feature changes

### Urgent Operations

- publish build first
- then set `Min Supported Version`
- then turn `Force Update` on

### Planned Maintenance

- enable maintenance with bilingual message
- include expected finish time
- remove it immediately after verification

## Suggested Support Checklist

When a driver says the app is blocked:
1. Check current version policy in admin.
2. Confirm whether maintenance mode is active.
3. Confirm the driver’s installed version.
4. If force update is active, verify store URLs.
5. If the driver is on an old build, instruct update.

When a driver says a menu is missing:
1. Check `App Management` scope.
2. Preview effective config for that user.
3. Check `GLOBAL`, then `ROLE`, then `USER` overrides.
4. Review audit history for recent changes.

## Recommended Future Improvements

The admin UI is already useful, but these additions would improve operations further:
- bulk driver session revoke from admin UI
- per-driver diagnostics for auth/version/bootstrap failures
- version adoption dashboard
- stale-device report for drivers who have not checked in after rollout
- explicit audit export for force-update and maintenance events

## Related Documents

- [SOP_DYNAMIC_DRIVER_APP_CONTROL.md](/Users/sotheakh/Documents/develop/sv-tms/docs/guides/SOP_DYNAMIC_DRIVER_APP_CONTROL.md)
- [DRIVER_APP_RUNTIME_FLOW.md](/Users/sotheakh/Documents/develop/sv-tms/docs/guides/DRIVER_APP_RUNTIME_FLOW.md)
- [TELEMATICS_API_MIGRATION_NOTE.md](/Users/sotheakh/Documents/develop/sv-tms/docs/guides/TELEMATICS_API_MIGRATION_NOTE.md)
