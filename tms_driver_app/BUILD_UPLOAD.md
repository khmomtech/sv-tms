Fastlane / TestFlight build & App Store prep (driver_app)

Quick steps (local)
1. Ensure backend staging has reviewer bypass enabled (see tms-backend/.env).
2. Create reviewer account (backend):

```bash
./tms-backend/scripts/create_reviewer.sh http://staging.example.com R3v!3w3r$S3cr3t_2026 reviewer@test.sv Review!234
```

3. Build IPA (reviewer mode enabled):

```bash
# From tms_driver_app/
flutter pub get
flutter build ipa --export-options-plist=ios/exportOptions.plist --dart-define=REVIEWER_MODE=true
```

4. Upload via Fastlane (uses credentials in `Fastfile` / match/ENV):

```bash
cd tms_driver_app
bundle exec fastlane ios upload_reviewer
```

App Store Connect privacy checklist (for submission)
- Tracking: No (unless you intentionally use IDFA). If `app_tracking_transparency` is present, ensure you do NOT show ATT prompt and declare No Tracking in App Store Connect.
- Data types: Location (yes — required for driving features). Clarify that location is used only while On Duty and for in-trip features.
- Crash reports: Sentry (declare and justify; explain anonymization).
- Advertising: No ads.
- Third-party data sharing: Document Firebase/FCM usage only for push notifications (no Analytics in build).

Reviewer instructions (copy into App Store Connect "Notes for Reviewers")
- Test account: reviewer@test.sv / Review!234
- Steps:
  1. Install TestFlight build.
  2. Launch app; test account auto-fills via TestFlight reviewer build (if reviewer mode enabled).
  3. Sign in, press "On Duty", allow foreground location when prompted, accept any push-notification permission.
  4. Create a delivery (or open existing job), upload proof-of-delivery image.

Unlisted distribution / internal notes
- If you want an unlisted distribution, set distribution type to Unlisted in App Store Connect when creating the release.

Security
- Do not leave `APP_REVIEWER_BYPASS=true` or secrets persisted in production. Rotate secrets after creating test accounts.
