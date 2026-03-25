# SV Loading App (Team G + Driver) - MVP

This Flutter project provides a working MVP app to support KHB factory loading operations integrated into SV TMS.

## Features
- Login (token saved in secure storage)
- Trip Scan (QR or manual Trip ID)
- Gate Safety Check (G-01)
- Queue Registration
- Start/End Loading (timestamps, pallets, seal)
- Pallet Verification list (L-01 / L-02 style)
- Empties Return (E-01)
- Documents Upload (invoice/pod/etc. images)
- Offline queue for all actions + Sync button
- Khmer + English localization (easy_localization)

## Setup
1. Install Flutter 3.22+ (Dart 3.3+).
2. `flutter pub get`
3. Update API base URL in `lib/main.dart`:
   - `ApiClient.create('https://api.sv-tms.com')`

## Run
- Android: `flutter run`
- iOS: `flutter run`

## Backend endpoints (default)
See `lib/core/api/endpoints.dart`. Adjust to match your Spring Boot API.

## Notes
- Offline document upload re-sends local file paths when syncing. Ensure files still exist on device.
