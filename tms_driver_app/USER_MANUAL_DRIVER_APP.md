# Driver App — User Manual

This manual helps drivers and operators install, configure, and use the Driver mobile app (Flutter). It also provides troubleshooting tips, common commands for local development, and support contacts.

**Target audience:** drivers using the mobile app, and developers/operators who assist drivers in setup or troubleshooting.

---

## 1. Overview

The Driver mobile app is a Flutter application used by drivers to: view and accept jobs, navigate to pickup/delivery locations, upload proof-of-delivery (images/signatures), update status and location, and receive realtime job updates.

Key features:
- Job list and job details
- Map view with routing and live location updates
- Camera/photo uploads and file attachments
- Push notifications and realtime updates via WebSocket/STOMP
- Offline-friendly UI for intermittent connectivity
- Multi-language support (i18n)


## 2. Prerequisites

- Mobile device with Android (recommended) or iOS supported OS version for your build.
- Installed Flutter toolchain for development or an app bundle (APK/IPA) for production installs.
- For local development: `flutter` installed and `flutter doctor` passing core checks.
- Backend API and WebSocket endpoints (the backend is `driver-app` in this workspace).
- Firebase service account/credentials if push notifications or Firebase features are enabled.


## 3. Quick Install (Drivers)

If you receive an APK or App Store link, install it directly on the device.

If you need to build locally (developer or QA):

- Install Flutter: https://flutter.dev/docs/get-started/install
- From project root `driver_app` run:

```bash
cd tms_driver_app
flutter pub get
flutter build apk --release   # Android release
flutter build ios --release   # iOS (macOS with Xcode/mac signing)
```

For debugging on a device:

```bash
cd tms_driver_app
flutter pub get
flutter run --release -d <device_id>
```


## 4. Configuration (Operators / Devs)

Important files and envs:
- `tms_driver_app/lib/config/` (app config constants)
- Backend base URL: set in app config or via build-time environment variables
- Firebase credentials (if required): do NOT commit service account files. Use secure distribution.

When building for QA/Dev, ensure the app points to the proper backend environment (dev/staging/production).

Backend considerations (from repo guidance):
- Backend is located in `driver-app/` and is the API authority. Use the Maven wrapper when building it (`./mvnw`).
- Local dev stack can be started with Docker Compose: 

```bash
# from workspace root
docker compose -f docker-compose.dev.yml up --build
```

This brings up backend + MySQL + optional mocks.


## 5. Authentication & First Run

- Drivers will be given credentials by the operator (username/password or invited via backend flow).
- On first run, the app may require permissions:
  - Location (for navigation and live tracking)
  - Camera & storage (for photo uploads)
  - Notifications (push)

Follow platform prompts and grant permissions for full functionality.


## 6. Using the App (Driver workflow)

Common driver tasks:

- Sign in: Enter credentials, accept any first-run prompts.
- View job list: New and active jobs appear in the list.
- Open job details: Tap a job to see addresses, items, instructions, contact details, and required proofs.
- Accept job: Tap Accept (if the flow requires acceptance).
- Navigate: Use the map to start navigation. The app will provide a route and may open your default map/navigation app if configured.
- Start job: Mark job as started when you arrive at pickup.
- Complete job: Capture proof (photo/signature), add notes, and tap Complete.
- Upload failures: If upload fails due to connectivity, the app will queue uploads and retry when network is available.

Realtime behavior:
- The app subscribes to updates via WebSocket/STOMP. Job updates from dispatch appear live.
- Location updates are sent periodically to the backend for live tracking.


## 7. Proofs & Uploads

- Photos: Use the in-app camera or select from gallery.
- Signatures: If enabled, capture signature on-screen.
- Upload queue: The app stores pending uploads locally and retries automatically.
- File storage: Backend persists uploads to the shared `uploads/` directory (or cloud bucket in production). Operators should ensure the backend storage path and permissions are correct.


## 8. Offline & Connectivity

- The app is designed to tolerate intermittent connectivity:
  - Actions are queued locally when offline (status updates, proofs).
  - Sync occurs when connectivity is restored.
- For long offline periods, drivers should avoid restarting the app until connectivity returns to allow automatic retry/sync.


## 9. Troubleshooting (Driver-side)

- App crashes on startup:
  - Ensure OS version is supported.
  - Clear app data and try again.
  - Reinstall the app.
- Cannot sign in / invalid credentials:
  - Verify credentials with dispatcher / admin.
  - Check backend availability.
- Location not updating:
  - Verify location permission granted.
  - Ensure device GPS is enabled and has a clear view to satellites.
- Photos failing to upload:
  - Check network connectivity.
  - Check app storage permission.
- Notifications not received:
  - Verify notification permission.
  - Check Firebase configuration on backend and that APNs/FCM keys are valid.

If issues persist, gather logs (see Developer troubleshooting) and contact ops/support.


## 10. Developer / Operator Troubleshooting

Useful commands & local dev tips (workspace root):

- Start full dev stack (backend + DB + mocks):

```bash
docker compose -f docker-compose.dev.yml up --build
```

- Backend (manual run):

```bash
cd driver-app
./mvnw spring-boot:run
```

- Angular admin (dispatcher) dev server:

```bash
cd tms-frontend
npm ci
npm run start -- --host 0.0.0.0
```

- Flutter app (local debug):

```bash
cd tms_driver_app
flutter pub get
flutter run
```

Common checks:
- Ensure backend `application.properties` or environment settings set correct `app.legacy-controllers.enabled` and API base URL.
- If Map or geocoding features fail, verify API keys (Map provider, Google Maps, etc.) are set in app config and backend settings.
- Uploads: Check `uploads/` folder permissions and free disk space.

Logs and tests:
- Backend tests use H2 for unit tests; use `./mvnw clean package` to run tests and regenerate MapStruct/Lombok code.
- Focused tests helpful for driver flows: `AuthIntegrationTest`, `DriverLocationControllerTest`, `DriverDocumentIntegrationTest` (names per repo guidance).


## 11. Security & Privacy

- Do not store service account keys or secrets in app code or committed files.
- Use secure configuration (environment variables, CI secrets) for Firebase and backend credentials.
- The app transmits driver location and personal data; follow local privacy regulations and only collect data required for operations.


## 12. Localization

- The app supports i18n. Translation files are in `tms_driver_app/lib/l10n` (or `assets/i18n`) depending on project structure. Use the existing locale files to add or update translations.


## 13. FAQ

- Q: What if the driver changes device?
  - A: Reinstall the app, sign in with existing credentials. If device-specific pairing exists, contact dispatch to transfer device authorization.
- Q: How long are photos retained?
  - A: Retention policy is defined by backend config and storage management. Contact admin for retention rules.
- Q: Can drivers edit completed job details?
  - A: Usually no — completed jobs are final. Contact dispatch to reopen if allowed by backend.


## 14. Support & Contact

- Primary support: Dispatcher / Operations team
- Developer contact: See project `CONTRIBUTING.md` or `DEVELOPER_QUICK_START.md` in repository root.
- For backend issues: check `driver-app` logs and run focused tests locally.


## 15. Change Log & Notes

- Keep this manual updated when features change (maps, notification flow, proof types).
- When migrating backend controllers (legacy → new), coordinate app version releases so drivers are not disrupted.


---

If you want, I can:
- Produce an abbreviated one-page Quick Start for drivers.
- Generate a printable PDF of this manual.
- Create a developer-focused README with exact file paths and config examples for `driver_app` and `driver-app` backend.

Please tell me which follow-up you'd prefer.
