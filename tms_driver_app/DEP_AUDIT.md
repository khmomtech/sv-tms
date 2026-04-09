Dependency Audit — driver_app

Summary
- Scanned `pubspec.yaml` for packages that may affect App Store review (tracking, analytics, background permissions, and WebView/data sharing).

Flags and recommendations
- `app_tracking_transparency` (v2.0.0)
  - Purpose: iOS ATT prompt integration.
  - Risk: Triggers App Tracking Transparency flows; keep but gate prompt (already implemented via `SecurityConfig.appUsesTracking`). If you do not use IDFA or cross-app tracking, remove this package and its usage to simplify App Store privacy answers.

- `sentry_flutter` (v9.5.0)
  - Purpose: crash/error reporting.
  - Risk: Collects device identifiers and may require privacy justification. Acceptable if used only for crash reporting; set `Sentry` to opt-in if needed and document what data is sent.
  - Recommendation: Ensure you disclose crash reporting in App Store Connect and provide an option to disable in-app if needed.

- `firebase_messaging` / `firebase_core` (v15.2.2 / 3.11.0)
  - Purpose: Remote notifications.
  - Risk: FCM itself does not require ATT unless you use advertising features or IDFA. However Firebase Analytics was explicitly removed in `pubspec.yaml` (commented). Good.
  - Recommendation: Keep if needed for push notifications. Ensure no Analytics SDKs are enabled in `GoogleService-Info.plist` bundles used for App Store submission.

- `google_maps_flutter`, `geolocator`, `geocoding`
  - Purpose: Maps and location.
  - Risk: Location usage requires clear `Info.plist` strings and justification; you already added permission strings and deferred background location start until user action.
  - Recommendation: Verify `NSLocationAlwaysAndWhenInUseUsageDescription` is accurate and that background location is only requested when driver marks On Duty.

- `webview_flutter`, `url_launcher`, `share_plus`, `cached_network_image`
  - Purpose: Web content and sharing.
  - Risk: WebView content could load external trackers; ensure any WebView content is trusted and document it for reviewers.

Actionable items
- Remove `app_tracking_transparency` entirely if the app does not use IDFA or cross-app tracking, or keep it but ensure the prompt is never shown in App Store submission builds.
- Audit `sentry_flutter` config: ensure PII minimization and document data sent in App Store privacy section.
- Verify that `firebase` config files for the App Store build do not enable Analytics.
- Document all data collection in `BUILD_UPLOAD.md` for App Store Connect entries.
