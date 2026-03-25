# Loading Safety Module (SV TMS Backend)

## What was added
- Pre-loading safety check endpoints (`/api/pre-loading-safety`) with role enforcement for `ROLE_SAFETY`.
- QR payload + PNG generation for dispatches (`/api/dispatches/{id}/qr`, `/api/dispatches/{id}/qr.png`).
- Dispatch workflow guard to block queue/loading unless safety passed.
- Flyway migration `V503__create_pre_loading_safety_checks.sql`.
- Role bootstrapper creating `SAFETY`, `LOADING`, `DISPATCH_MONITOR` roles with basic permissions.
- Optional photo proof upload endpoint added (stores file and returns URL).

## How to run
1) Backend dependencies: `cd tms-backend && ./mvnw clean package -DskipTests`
2) Apply DB migrations (Flyway runs on startup). Ensure DB user has rights to create table/indexes.
3) Start API: `./mvnw spring-boot:run` or `./run-with-env.sh`.
4) Env to set for clients: `API_BASE_URL=http://localhost:8080` (use HTTPS in production).

## API Endpoints
- `POST /api/pre-loading-safety` — submit checklist (**ROLE_SAFETY**, or admin). Fails if status not ASSIGNED/ARRIVED_LOADING/SAFETY_*.
- `GET /api/pre-loading-safety/latest/{dispatchId}` — latest result (read-only roles: SAFETY, LOADING, DISPATCH_MONITOR, ADMIN).
- `GET /api/pre-loading-safety/dispatch/{dispatchId}` — history (same read roles).
- `GET /api/pre-loading-safety/pdf/{dispatchId}` — printable PDF.
- `POST /api/pre-loading-safety/{id}/proof` — multipart `file`, stores in `uploads/safety-proof/{id}` and returns URL.
- `GET /api/dispatches/{id}/qr` — QR payload string (`{"dispatchId":<id>}`).
- `GET /api/dispatches/{id}/qr.png?size=320` — QR PNG (ZXing).

## Roles & Guards
- `ROLE_SAFETY`: submit safety checks.
- `ROLE_LOADING`: queue/loading actions only; read-only safety.
- `ROLE_DISPATCH_MONITOR`: read-only monitoring.
- Guards: `DispatchWorkflowValidator.canEnterQueue` (only after SAFETY_PASSED), `canStartLoading` (only from IN_QUEUE).

## DB Migration
`tms-backend/src/main/resources/db/migration/V503__create_pre_loading_safety_checks.sql` creates:
- `pre_loading_safety_checks` table with checklist booleans, result enum text, fail reason, checked_by FK to `users`, dispatch FK to `dispatches`.
- Indexes on `dispatch_id`, `result`, `checked_at`, `checked_by_user_id`.

## Admin UI notes
- Dispatch list should show safety badge + action buttons.
- Queue/Loading buttons disabled unless status == SAFETY_PASSED.
- Example badge snippet:
```html
<span class="badge badge-success" data-status="SAFETY_PASSED">PASSED</span>
<span class="badge badge-danger" data-status="SAFETY_FAILED">FAILED</span>
<span class="badge badge-secondary" data-status="PENDING">PENDING</span>
```

## QR usage
- Default payload: `{"dispatchId":<id>}`; scanners must also accept `DISPATCH:<id>` and `svtms://dispatch/<id>`.
- PNG endpoint can be embedded in admin UI printouts or driver documents.
