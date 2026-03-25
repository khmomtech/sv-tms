## SVTMS Safety Check (Flutter)

Mobile app for factory gate safety officers to scan dispatch QR codes and submit pre-loading safety checks.

### Prerequisites
- Flutter 3.19+ (`flutter doctor` clean)
- Android Studio / Xcode toolchains for device builds
- Backend base URL available (set via `API_BASE_URL`)

### Setup
```bash
cd svtms_safety_check
flutter pub get
```

### Run
```bash
flutter run --dart-define API_BASE_URL=https://api.example.com
```
`API_BASE_URL` should point to the Spring Boot host (e.g., `http://10.0.2.2:8080` for Android emulator).

### Features
- JWT login (`POST /api/auth/login`) with secure token storage (`flutter_secure_storage`).
- QR scan via `mobile_scanner` supporting payloads:
  - `{"dispatchId":125}`
  - `DISPATCH:125`
  - `svtms://dispatch/125`
- Driver flow: scan QR → app fetches driver’s active dispatches and lets the officer pick the correct trip (scanned one pre-selected).
- Safety checklist screen:
  - Loads dispatch info + latest safety check.
  - Checklist toggles, PASS/FAIL with required reason on fail.
- Offline queue: failed submissions cached in Hive and retried.
- Optional photo proof (POST `/api/pre-loading-safety/{id}/proof`, stored on backend).
- State management: Provider used for auth, services, and offline queue.
- Localization: English + Khmer (`easy_localization`), translations in `assets/translations/`.

### Security & Offline recommendations

- Encrypt Hive boxes used for offline caching (use `HiveCipher` / encrypted boxes) to protect PHI and sensitive proofs while offline.
- Include a client-generated UUID (`client_uuid`) in each safety-check submission payload to make offline retries idempotent. The backend should accept `client_uuid` and ignore duplicate submissions.
- Store minimal transient photo proofs locally and delete them after successful upload; prefer streaming multipart upload during sync to avoid storing large files unencrypted.
- Ensure `flutter_secure_storage` is used for JWTs and keys; rotate keys per install where feasible.

### Payload / API notes

- Safety check POST payload should include `client_uuid` (UUID v4), optional `location_lat`/`location_lng`, and a single-level `result` with values `PASS`, `FAIL`, or `RECHECK`.
- On `FAIL`, the `fail_reason` field must be provided.


### Folder layout
- `lib/screens/` — UI screens (login, scan, safety checklist)
- `lib/services/` — API client, auth, safety + offline queue
- `lib/models/` — DTOs for dispatch and safety payloads
- `assets/translations/` — `en.json`, `km.json`

### Notes
- Large buttons and Khmer labels are provided for gate usage.
- Offline submissions show a banner and sync when connectivity returns (tap refresh icon).
- Photo proof upload is optional; backend endpoint should accept multipart `file` at `/api/pre-loading-safety/{id}/proof`.
