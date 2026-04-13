Fastlane / App Store build guide (driver app)

Quick steps
1. Verify the live review backend is healthy:
   - `https://svtms.svtrucking.biz/api/auth/driver/login`
   - review account: `drivertest / 123456`
2. Build the review IPA with the production API pinned:

```bash
cd tms_driver_app
flutter clean
flutter pub get
flutter build ipa \
  --flavor prod \
  --export-options-plist ios/exportOptions.plist \
  --dart-define=REVIEWER_MODE=true \
  --dart-define=API_BASE_URL=https://svtms.svtrucking.biz/api \
  --dart-define=REVIEWER_USERNAME=drivertest \
  --dart-define=REVIEWER_PASSWORD=123456
```

3. Or upload via Fastlane:

```bash
cd tms_driver_app
bundle exec fastlane ios upload_reviewer
```

What this guarantees
- Uses the `prod` flavor for iOS.
- Pins the app to `https://svtms.svtrucking.biz/api`.
- Enables the App Review helper button on the sign-in screen.
- Autofills the live review account `drivertest / 123456`.

App Store Connect review notes
- Sign-in required: `Yes`
- Username: `drivertest`
- Password: `123456`
- Review server URL: `https://svtms.svtrucking.biz/api`
- Expected first step: tap `App Review Login`, then tap `Login`.

Do not use
- `svtmsapi.svtrucking.biz`
- staging/demo credentials such as `reviewer@test.sv`
- builds created without `--flavor prod`
