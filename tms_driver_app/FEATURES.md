# SV‑TMS Driver App — Features & Runbook

This document maps core features of the Flutter Driver App to concrete file paths and provides quick runbooks for development, manual checks, and testing.

## Quick Start

- Run backend + DB (or use existing stack): see repo root docs or Docker compose files.
- Start the app in dev:

```sh
cd tms_driver_app
flutter pub get
flutter run
```

- Run tests (full suite):

```sh
cd tms_driver_app
flutter test -r expanded
```

- API smoke tests (login, protected endpoint, refresh):

```sh
cd tms_driver_app
flutter test test/api/api_smoke_test.dart -r expanded
```

Backend dev base: `http://localhost:8080/api` (configurable in `core/network/api_constants.dart`).

---

## Auth & Session

- HTTP client and auth/refresh interceptor:
  - `lib/core/network/dio_client.dart`
  - `lib/core/network/api_constants.dart` (token store, refresh flow, base URL)
  - `lib/core/network/api_response.dart`

Runbook:
- Login via API smoke test to validate access/refresh tokens.
- Refresh token contract: send refresh token in `Authorization: Bearer <refreshToken>` header to `POST /api/auth/refresh`.
- Use `ApiConstants.setBaseUrlOverride()` in dev settings (if present) to target a different backend.

---

## Routing & Shell

- Entrypoints: `lib/main.dart`, `lib/main_common.dart`, `lib/main_dev.dart`, `lib/main_uat.dart`, `lib/main_prod.dart`
- Routes: `lib/routes/`
- Splash & Sign-in: `lib/screen/splash_screen.dart`, `lib/screen/sign_in_screen.dart`

Runbook:
- Switch build flavors with the respective `main_*.dart` when running.
- Confirm splash → sign-in → dashboard flow on cold start.

---

## State Management (Providers)

- Aggregator: `lib/providers/app_providers.dart`
- Auth/session: `lib/providers/auth_provider.dart`, `lib/providers/sign_in_provider.dart`
- Domain: deliveries/dispatch/driver dashboard/notifications/etc.
  - `lib/providers/delivery_provider.dart`
  - `lib/providers/dispatch_provider.dart`
  - `lib/providers/driver_dashboard_provider.dart`
  - `lib/providers/notification_provider.dart`
  - `lib/providers/location_provider.dart`
  - `lib/providers/settings_provider.dart`, `lib/providers/theme_provider.dart`

Runbook:
- Add a provider → register in `app_providers.dart` → inject via `MultiProvider` in app shell.
- Prefer `DioClient` for network calls; keep multipart in stable `http` if necessary.

---

## Driver Workflow

- Deliveries & tasks: `lib/screen/shipment/deliveries_screen.dart`, `lib/screen/shipment/load_task_detail_screen.dart`, `lib/screen/shipment/unload_task_detail_screen.dart`
- Dispatch: `lib/screen/shipment/dispatch_detail_screen.dart`
- Issues: `lib/screen/shipment/issue_form_screen.dart`, `lib/screen/shipment/report_issue_screen.dart`, `lib/screen/shipment/report_history_screen.dart`

Runbook:
- Verify end-to-end: list → detail → action → confirmation.
- Use backend seeded data or create fixtures to navigate.

---

## Realtime & Notifications

- WebSocket/STOMP:
  - `lib/services/web_socket_service.dart`
  - `lib/services/web_socket_manager.dart`
  - `lib/services/topic_subscription_service.dart`
- Push notifications (FCM): `lib/services/firebase_messaging_service.dart`
- Notification UI: `lib/screen/notification_screen.dart`, `lib/screen/notifications/`

Runbook:
- Validate JWT handshake on WS connect: token from `ApiConstants.ensureFreshAccessToken()`.
- Confirm topic subscriptions refresh after token rotation.
- For FCM, ensure device receives a token and server updates occur.

---

## Location & Maps

- Location pipeline: `lib/services/location_service.dart`
- Map/route screens: `lib/screen/shipment/driver_map_screen.dart`, `lib/screen/shipment/live_map_view_screen.dart`, `lib/screen/route_map_screen.dart`, `lib/screen/shipment/map_preview_screen.dart`

Runbook:
- On device/emulator grant location permissions.
- Ensure periodic upload; monitor server logs for ingested batches.
- Verify live map updates over WS where applicable.

---

## Documents & Proofs

- Proof of Delivery (photos + signature): `lib/widgets/load_task_full_screen.dart`
- Fullscreen viewers: `lib/screen/fullscreen_image_viewer.dart`, `lib/screen/shipment/fullscreen_image_viewer*.dart`

Runbook:
- Capture up to 4 images (camera), collect signature, submit.
- Ensure multipart endpoints are reachable and responses handled.

---

## Contacts & Directory

- Screens: `lib/screen/contact_screen.dart`, `lib/screen/phone_book_screen.dart`, `lib/screen/employee_directory_screen.dart`
- Provider: `lib/providers/contact_provider.dart`

Runbook:
- Search/filter contacts; verify call/message intents if enabled.

---

## Settings & Account

- Profile & password: `lib/screens/shipment/profile_screen_modern.dart`, `lib/screens/auth/change_password_screen.dart`
- Permissions overview: `lib/screen/permissions_screen.dart`
- App settings/theme: `lib/screen/settings_screen.dart`, `lib/providers/theme_provider.dart`

Runbook:
- Validate password change with backend endpoint.
- Toggle theme; confirm persistence.

---

## Device & Background

- Device approval gate: `lib/screen/device_approval_pending_screen.dart`
- Background/tasks: `lib/services/work_manager_service.dart`
- Battery optimization guidance: `lib/services/battery_optimization_service.dart`
- Native interop: `lib/services/native_service_bridge.dart`

Runbook:
- Sign-in as driver on unapproved device → expect gate screen.
- Confirm background location uploads under OS constraints.

---

## Networking Details

- Client & interceptors: `lib/core/network/dio_client.dart`
- API config & tokens: `lib/core/network/api_constants.dart`

Runbook:
- Update base URL per environment in `ApiConstants`.
- Refresh logic tries header-first, then JSON fallback; persisted via SharedPreferences.

---

## Internationalization & Theming

- i18n assets: `lib/l10n/`
- Themes: `lib/themes/`

Runbook:
- Add/modify ARB files; run `flutter gen-l10n` if configured or rebuild to regenerate.
- Verify RTL/LTR and font fallbacks.

---

## Tests & Tooling

- API smoke tests: `test/api/api_smoke_test.dart`
- Core/network tests: `test/core_network/api_constants_test.dart`
- Widget sample: `test/widget_test.dart`

Runbook:
- Ensure backend is healthy; run the smoke test to validate login and token refresh.
- Keep tests hermetic where possible; mock endpoints for pure unit tests.

---

## Planned / Scaffolded

- QR Attendance (scanner placeholder): `lib/screen/qr_code_attendance_screen.dart`

Runbook:
- Integrate `mobile_scanner` (or similar), wire navigation from menu, and post scan event to backend.

---

## Troubleshooting Tips

- Backend unreachable: confirm Docker stack (`docker compose -f docker-compose.dev.yml up --build`) or local Spring Boot run.
- Token refresh 401: ensure using Authorization header with refresh token to `/api/auth/refresh`.
- Android emulator can’t reach `localhost`: `ApiConstants` rewrites `localhost` to `10.0.2.2` in dev.
