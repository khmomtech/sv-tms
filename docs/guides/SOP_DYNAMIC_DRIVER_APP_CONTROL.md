# SOP: Dynamic Driver App Control (Admin Panel)

Last updated: 2026-03-11
Audience: Admin/Ops (non-developer friendly)

## What this does
You can control driver app menu/actions **without new mobile release**:
- Drawer menu items
- Home quick actions
- Bottom navigation
- Dispatch action button visibility

## Where to configure
1. Open admin web.
2. Go to `Settings -> Driver App Management -> App Management`.
3. Choose scope:
   - `GLOBAL` for all drivers
   - `ROLE` for one role/group
   - `USER` for one user

## Keys you can change
## Navigation
- `app.policies.nav.drawer.items`
- `app.policies.nav.bottom.items`
- `app.policies.nav.home.quick_actions`

## Dispatch action flow
- `app.policies.dispatch.actions.hidden_statuses`
- `app.policies.dispatch.actions.allowed_statuses`
- `app.policies.dispatch.actions.require_driver_initiated`

## Safe starter values
- `app.policies.nav.drawer.items`
  - `home,my_vehicle,my_id_card,notifications,profile,report_issue_list,incident_report,incident_report_list,safety_history,maintenance,trip_report,daily_summary,settings,help`
- `app.policies.nav.bottom.items`
  - `home,trips,report,profile,more`
- `app.policies.nav.home.quick_actions`
  - `my_trips,incident_report,report_issue,documents,trip_report,help_center`
- `app.policies.dispatch.actions.require_driver_initiated`
  - `true`

## How to apply safely
1. Change one key only.
2. Save with reason (example: `Hide incident menu for pilot role`).
   - If value is invalid, admin UI now blocks save immediately.
   - Backend also enforces the same rules and returns `400` for invalid values.
   - Use the **Use Recommended** button for fast safe defaults on dynamic keys.
3. Driver re-login (or wait cache TTL) and verify.
4. If wrong, revert value immediately.

## Smoke check after each change
1. Driver can still login and open home.
2. Drawer shows expected items.
3. Bottom nav has expected tabs.
4. Quick actions open correct routes.
5. Dispatch detail shows valid action button(s).
6. In Admin `Preview Effective Config`, verify simulator cards (drawer/bottom/quick-actions/dispatch policy) show no red validation warning.

## Rollback
1. Restore previous value from audit history in App Management page.
2. Save.
3. Re-login on driver app and confirm behavior restored.
