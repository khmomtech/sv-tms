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
