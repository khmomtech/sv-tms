# Dynamic Driver App Control Keys (Admin Panel)

Use these keys in **Driver App Management** to control mobile behavior without app release.

## Screens / Features
- `app.screens.trips.visible`
- `app.screens.profile.visible`
- `app.screens.settings.visible`
- `app.screens.driver_id.visible`
- `app.features.notifications.enabled`
- `app.features.incident_report.enabled`
- `app.features.safety_check.enabled`
- `app.features.location_tracking.enabled`

## Navigation Policies
- `app.policies.nav.drawer.items`
  - Example: `home,my_vehicle,my_id_card,notifications,profile,report_issue_list,incident_report,incident_report_list,safety_history,maintenance,trip_report,daily_summary,settings,help`
- `app.policies.nav.bottom.items`
  - Example: `home,trips,report,profile,more`
- `app.policies.nav.home.quick_actions`
  - Example: `my_trips,incident_report,report_issue,documents,trip_report,help_center`

## Dispatch Action Policies
- `app.policies.dispatch.actions.hidden_statuses`
  - Hide action buttons by target status.
  - Example: `CANCELLED,FINANCIAL_LOCKED`
- `app.policies.dispatch.actions.allowed_statuses`
  - Optional allowlist by target status.
  - Example: `ARRIVED_LOADING,LOADING,LOADED,IN_TRANSIT,ARRIVED_UNLOADING,UNLOADING,DELIVERED,COMPLETED`
- `app.policies.dispatch.actions.require_driver_initiated`
  - `true` = hide non-driver-initiated actions.

## Notes
- Values accept comma-separated strings.
- Mobile app fetches effective config from `/api/driver-app/bootstrap`.
- Cache TTL is short; force refresh by relogin/reopen for immediate validation.
- Backend now validates these keys on save:
  - rejects unknown nav IDs
  - rejects unknown dispatch statuses
  - rejects duplicates
  - enforces bottom nav includes and starts with `home`
- API behavior:
  - `POST /api/admin/settings/value` returns `400 Bad Request` with clear error message for invalid dynamic policy values.
