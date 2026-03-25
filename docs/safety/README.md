# Driver Daily Safety Check Module

## Overview
This module implements daily safety checks per driver + vehicle + day, with admin approval and dispatch blocking until approved.

## Key Rules
- One safety check per driver + vehicle + day (unique constraint).
- Driver must submit; admin/safety officer must approve.
- Dispatch/trip creation is blocked unless status is `APPROVED`.
- Risk calculation:
  - Any item severity = HIGH → risk = HIGH
  - Else if total issues ≥ 3 → risk = MEDIUM
  - Else → risk = LOW

## Backend
- Migration: `tms-backend/src/main/resources/db/migration/V508__create_driver_daily_safety_checks.sql`
- Migration: `tms-backend/src/main/resources/db/migration/V509__create_safety_master_data.sql`
- Migration: `tms-backend/src/main/resources/db/migration/V510__safety_master_auto_increment.sql`
- Models:
  - `SafetyCheck`, `SafetyCheckItem`, `SafetyCheckAttachment`, `SafetyCheckAudit`
  - `SafetyCheckCategory`, `SafetyCheckMasterItem`
 - Master data is seeded from the Excel daily safety report (vehicle inspection items) plus workflow categories for driver health, safety equipment, load, and environment.
- Service: `SafetyCheckService`
- Controllers:
  - Driver: `/api/driver/safety-checks/...`
  - Admin: `/api/admin/safety-checks/...`
  - Admin Master Data: `/api/admin/safety-master/...`
  - Dispatch Gate: `/api/dispatch/safety-eligibility`

## Driver App (Flutter)
- Provider: `SafetyProvider`
- Screens:
  - `DriverSafetyCheckScreen` (wizard)
  - `SafetyHistoryScreen`
  - `SafetyDetailScreen`
- Home integration:
  - Daily Safety Check status card
  - Home menu with Safety Check, History, and Start Trip gating

## Admin Portal (Angular)
- Feature module: `tms-frontend/src/app/features/safety`
- List page with KPI cards and filters
- Detail page with approve/reject + photos
- Master Data pages (Categories + Items) with Excel import

## APIs
Driver:
- `GET  /api/driver/safety-checks/today?vehicleId=`
- `POST /api/driver/safety-checks/draft`
- `POST /api/driver/safety-checks/{id}/attachments`
- `POST /api/driver/safety-checks/{id}/submit`
- `GET  /api/driver/safety-checks?from=&to=`

Admin:
- `GET  /api/admin/safety-checks`
- `GET  /api/admin/safety-checks/{id}`
- `POST /api/admin/safety-checks/{id}/approve`
- `POST /api/admin/safety-checks/{id}/reject`

Admin Master Data:
- `GET    /api/admin/safety-master/categories?activeOnly=`
- `POST   /api/admin/safety-master/categories`
- `PUT    /api/admin/safety-master/categories/{id}`
- `DELETE /api/admin/safety-master/categories/{id}`
- `GET    /api/admin/safety-master/items?categoryId=&activeOnly=`
- `POST   /api/admin/safety-master/items`
- `PUT    /api/admin/safety-master/items/{id}`
- `DELETE /api/admin/safety-master/items/{id}`
- `POST   /api/admin/safety-master/import` (multipart `file`)

Dispatch Gate:
- `GET /api/dispatch/safety-eligibility?driverId=&vehicleId=&date=`

## Notes
- Audit logs are created for draft saves, submission, approval, rejection, and attachment uploads.
- Safety checklist templates are Khmer-first and aligned with the legacy Excel report structure.

## Import From Excel (Admin)
1. Go to `សុវត្ថិភាព` → `ទិន្នន័យមេ` → `ធាតុត្រួតពិនិត្យសុវត្ថិភាព`.
2. Click **នាំចូល** and select the Excel file (expects sheets `Category` and `របាយការណ៍ប្រចាំថ្ងៃ`).
3. The system will merge categories/items by code and item_key (`item_{id}`).
