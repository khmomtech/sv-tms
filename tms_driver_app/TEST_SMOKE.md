Driver App — Smoke Test Guide

Purpose
- Quick steps to validate register → sign in → dashboard on a clean install using a test backend.

Prereqs
- Flutter SDK installed and on PATH
- An iOS simulator or Android emulator (or a connected device)
 - A reachable test backend with `/auth/registerdriver` and `/auth/driver/login`

Quick commands

1) Install deps

```bash
cd tms_driver_app
flutter pub get
```

2) Start app pointing to test API

```bash
# Example using Android emulator mapping to host
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api

# Or remote test server
flutter run --dart-define=API_BASE_URL=https://test-api.example.com/api
```

Manual smoke-test flow
1. Launch app (fresh install / emulator).
2. Accept the consent screen (Essential required; Marketing off by default).
3. Tap `Create Account` and register a driver account.
4. Return to Login and sign in with those credentials.
5. Confirm the dashboard loads and that background topic subscriptions proceed.

Troubleshooting
- If the app reports device-approval errors, the client will retry without `deviceId` (public reviewer flow). Check logs for `Retrying login without deviceId`.
	- If registration fails, confirm the backend supports `/auth/registerdriver` and the payload shape matches the server API.
- For iOS simulator networking to host machine, prefer `--dart-define=API_BASE_URL=http://127.0.0.1:8080/api` and use simulator <-> host network mapping.

If you want, provide a test base URL and test credentials and I will attempt an automated run here and report logs.