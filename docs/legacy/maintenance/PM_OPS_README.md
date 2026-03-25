> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# SV TMS PM Operations Hardening

## Overview
This pack adds alerts, KPI endpoints, notification outbox, and retention jobs for the PM module. It is optimized for SV Trucking Cambodia operations (Asia/Phnom_Penh).

## New Tables (Migration V512)
- `notification_settings`
- `notifications_outbox`
- `in_app_notifications`
- `job_locks`
- `maintenance_status_logs_archive`

## Notification Channels
- **Telegram (default)**
- **Email (optional)**
- **In-App (fallback)**

## Environment Variables
- `SV_TMS_TELEGRAM_BOT_TOKEN` (required for Telegram)
- `SV_TMS_TELEGRAM_CHAT_IDS` (comma-separated chat IDs)
- `SV_TMS_TELEGRAM_CHAT_ID` (single chat ID)
- `SV_TMS_SMTP_HOST` (optional)

## Scheduling (Asia/Phnom_Penh)
- PM run generation: `02:00` daily
- Overdue alerts: `07:30` daily
- Due soon alerts: `07:30` daily
- Critical overdue alerts: every 15 minutes
- No-show alerts: `18:00` daily
- Weekly report: Monday `08:00`
- Retention cleanup: 1st day monthly `03:15`
- Outbox sender: every 1 minute

## New Endpoints
- `GET /api/admin/pm/kpis?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `GET /api/admin/pm/weekly-report`
- `GET /api/admin/in-app-notifications`
- `GET /api/admin/in-app-notifications/count`
- `PUT /api/admin/in-app-notifications/{id}/read`
- `PATCH /api/admin/in-app-notifications/mark-all-read`
- `GET /api/admin/notification-settings`
- `PUT /api/admin/notification-settings/{channel}`

## Telegram Message Templates
- PM Overdue:
  - `PM Overdue: {Plate} {Item} due {DueDate}/{DueKm} overdue {Days}/{Km} (WO: {WO})`
- Due Soon:
  - `PM Due Soon: {Plate}\n- {Item} (Due {Date}/{Km})`
- Critical:
  - `[CRITICAL] PM Overdue: {Plate} {Item} ...`
- No-show:
  - `PM No-Show: {Plate} {Item} started but not completed > 8h`

## Notes
- `job_locks` prevents duplicate scheduler runs in multi-instance deployments.
- `notifications_outbox` ensures non-blocking retries with exponential backoff.
- `in_app_notifications` is separate from existing admin notification module.
