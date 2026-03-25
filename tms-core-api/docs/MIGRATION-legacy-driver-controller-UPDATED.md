# Migration: Legacy `DriverController`

Summary
-------

The legacy `DriverController` has been deprecated and its methods moved into specialized controllers:

- `DriverManagementController` — CRUD, profile uploads
- `DriverNotificationAdminController` — notifications, broadcasts
- `DriverDocumentController` — driver documents
- `DriverLocationAdminController` — location history
- `DriverAssignmentController` — assignments

What changed
------------

- The legacy controller is conditionally loaded using the property `app.legacy-controllers.enabled` and is disabled by default in this branch. This prevents ambiguous Spring MVC mappings while migration is in progress.
- Its base request mapping has been set to `/api/admin/legacy/drivers` to make any remaining legacy endpoints explicit and isolated.
- Focused integration tests covering auth, location, and document flows were executed and passed locally.

Verification
------------

Run locally in `driver-app`:

```bash
./mvnw compile
./mvnw test -Dtest=AuthIntegrationTest,DriverLocationControllerTest,DriverDocumentIntegrationTest
./mvnw test
```

All tests passed when this branch was prepared.

Recommended next steps
----------------------

1. Leave the legacy controller disabled (`app.legacy-controllers.enabled=false`) for at least one full release cycle while clients migrate.
2. Coordinate with front-end/mobile teams to ensure no remaining usage of legacy paths.
3. After a migration window, remove `DriverController` entirely and update changelog and release notes.
4. Optionally: add monitoring to log requests hitting `/api/admin/legacy/drivers` for one release to catch rare legacy clients.

Notes
-----

- This migration is reversible: re-enable `app.legacy-controllers.enabled=true` to restore the bean.
- The change is intentionally conservative — methods return `410 GONE` where functionality was moved, to encourage client updates.

Author: automated migration agent
Date: 2025-11-20

## Smoke tests and client-run status

Summary of recent verification performed on the running backend and client tooling in the local environment used to prepare this branch:

- `GET /api/health` → `200 OK`, payload: `{ "service": "sv-tms-backend", "status": "UP", ... }`
- `GET /api/health/detailed` → `200 OK`, includes `uploads` metadata: `readable: true, writable: true, fileCount: 5`.
- `POST /api/driver/location/update` (unauthenticated) → `403 Forbidden` (security enforced; expected behavior).

Client tooling attempts and results:

- Angular dev server (`tms-frontend`): attempt to run `npm run start -- --host 0.0.0.0` failed locally because the installed Node.js is `v18.20.8` while the Angular CLI used in this workspace requires a minimum Node.js version `v20.19` (or `v22.12`). To start the dev server locally update Node.js (recommend `nvm` to install `v20.19` or `v22.12`).
- Flutter driver app (`driver_app`): `flutter` is available. `flutter pub get` completed successfully and dependencies were resolved (95 packages reported with newer versions available). Running the app on a device/emulator was not attempted here (requires a connected device or emulator).

Branch & PR

- Branch: `chore/migrate-legacy-driver-controller` (pushed to remote).
- PR: If you prefer the PR opened automatically, run the GitHub CLI command locally since the environment used here did not have `gh` available for automated PR creation.

Recommendation (quick)

- Update Node.js on the development machine used by frontend teams (or CI) to v20.19+ so the Angular dev server can start for integrated testing.
- Run `flutter run` on a developer machine with an emulator or device to exercise driver mobile flows against this backend (or use the existing CI pipeline for mobile E2E where available).
