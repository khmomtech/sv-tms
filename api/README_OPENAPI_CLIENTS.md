# OpenAPI Client Generation Guide

This repository uses the backend OpenAPI spec (`api/driver-app-openapi.json`) to generate strongly typed REST clients for:

- Angular (TypeScript, `typescript-fetch` generator)
- Flutter (Dart, `dart-dio` generator)

The goals:
- Eliminate hand-written repetitive HTTP code
- Keep API surface consistent across web + mobile
- Simplify token injection and refresh handling
- Accelerate maintenance when endpoints evolve

---
## 1. Source Specification
The spec is exported from the backend with a special `export` profile (Flyway disabled, schema generated via Hibernate create-drop against H2). File path:

```
api/driver-app-openapi.json
```

To re-export (from repository root):
```
./start-backend-dev.sh  # or docker compose stack ensuring backend runs with export profile
# Navigate to /v3/api-docs in browser or curl and save as api/driver-app-openapi.json
```
(If an automated script exists, prefer that; keep this section updated.)

---
## 2. TypeScript Client (Angular)
Configuration file: `openapi-generator-ts.json`

Example config snippet:
```json
{
  "generatorName": "typescript-fetch",
  "inputSpec": "api/driver-app-openapi.json",
  "output": "tms-frontend/src/app/generated",
  "additionalProperties": {
    "npmName": "svtms-client",
    "supportsES6": true
  }
}
```

Generate:
```
npx @openapitools/openapi-generator-cli generate -c openapi-generator-ts.json
```

Post-generation steps:
- Trim barrel exports in `index.ts` to avoid duplicate symbol conflicts.
- Wrap Promise-based calls in an Observable adapter when integrating with Angular services (see `driver-assignment.service.ts` for pattern).
- Inject authorization headers centrally (reuse existing auth/token service).

---
## 3. Dart Client (Flutter)
Current ephemeral output directory: `openapi-dart-temp/` (kept isolated to avoid polluting root or the app source). Config file: `openapi-generator-dart.json`

Example config snippet:
```json
{
  "generatorName": "dart-dio",
  "inputSpec": "api/driver-app-openapi.json",
  "output": "openapi-dart-temp",
  "additionalProperties": {
    "pubName": "sv_driver_app",
    "pubLibrary": "openapi",
    "useEnumExtension": true,
    "dateLibrary": "core",
    "serializationLibrary": "json_serializable",
    "nullableFields": true
  }
}
```

Generate:
```
npx @openapitools/openapi-generator-cli generate -c openapi-generator-dart.json
```

Integration strategy:
1. Use the temp folder as _staging_; do **not** commit its `pubspec.yaml` unless adopting as a standalone package.
2. Copy or sync selective `lib/src/api` and `lib/src/model` files into `tms_driver_app/lib/api/src/...` (the existing integrated client package `svtms_api_client`).
3. Maintain imports referencing `package:svtms_api_client/...` inside the Flutter app.
4. Implement high-level service wrappers (e.g., `DriverAssignmentsService`) to encapsulate authentication + error handling.

Service wrapper example: `tms_driver_app/lib/services/driver_assignments_service.dart` uses a Dio interceptor to inject headers returned by `ApiConstants.getHeaders()` and exposes simplified domain methods.

---
## 4. Authentication & Token Refresh
Flutter:
- Centralized in `tms_driver_app/lib/core/network/api_constants.dart`
- Always call `ApiConstants.ensureFreshAccessToken()` prior to requests (handled by interceptor in service wrapper).

Angular:
- Use existing auth service or an interceptor to attach `Authorization: Bearer <token>`.
- Consider adding automatic 401 handling + refresh path.

---
## 5. Regeneration Workflow Checklist
When backend endpoints change:
1. Export or update `api/driver-app-openapi.json`.
2. Run TS generator → adapt Angular services if new/renamed methods appear.
3. Run Dart generator → stage output under `openapi-dart-temp/`.
4. Diff staged API/model files against current integrated `tms_driver_app/lib/api/src/`.
5. Apply changes (prefer surgical updates to avoid losing local customizations).
6. Re-run Flutter `flutter pub get` if new model dependencies added.
7. Smoke test critical flows (assignment create/cancel/list) in both apps.

---
## 6. Conventions & Tips
- Avoid modifying generated files directly; wrap instead.
- Keep service wrappers small, focused on domain actions.
- Maintain consistent naming between Angular and Dart wrappers (`assignDriver`, `cancelAssignment`, etc.).
- Document any manual patching in this README under a new heading `Manual Adjustments`.

---
## 7. Quick Commands
```
# TypeScript regeneration
npx @openapitools/openapi-generator-cli generate -c openapi-generator-ts.json

# Dart regeneration (staging)
npx @openapitools/openapi-generator-cli generate -c openapi-generator-dart.json

# (Optional) Build runner if adopting json_serializable generated models
flutter pub run build_runner build --delete-conflicting-outputs
```

---
## 8. Next Improvements (Backlog)
- Introduce a shared response abstraction to unwrap `ApiResponse*` consistently.
- Add error mapping layer (HTTP status → domain error enums).
- Integrate token refresh retry logic directly inside a Dio interceptor for fewer explicit refresh calls.
- Generate WebSocket/STOMP message model helpers for realtime features.

---
**Maintainers:** Update this guide whenever the generation config or integration process changes.
