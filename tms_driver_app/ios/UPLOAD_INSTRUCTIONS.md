Upload instructions

1. Open Xcode: `ios/Runner.xcworkspace`.
2. Select the `prod` scheme and confirm Team `ZN6U6B24Y9` in Signing & Capabilities.
3. Product → Archive. The shared `prod` scheme now archives with `Release-prod`.
4. After archive completes, click Distribute App.
5. Choose "App Store" and follow the prompts to upload, or export an IPA using `exportOptions.plist`.

CLI alternative (requires signing credentials configured):

```bash
# Archive using the production flavor
xcodebuild -workspace ios/Runner.xcworkspace -scheme prod -configuration Release-prod -archivePath build/ios/archive/Runner.xcarchive archive

# Export (requires valid provisioning/certs; ensure exportOptions.plist has your team ID)
xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive -exportOptionsPlist ios/exportOptions.plist -exportPath build/ios/ipa
```

If you do not have an Admin to fill App Privacy in App Store Connect, ask them to:
- Open App Store Connect → My Apps → select app → App Privacy.
- Declare precise location, contact info, photos/videos, device ID, and diagnostics as used for app functionality.
- Do not declare cross-app tracking for this build.

Notes:
- This iOS build does not request App Tracking Transparency permission and does not include `NSUserTrackingUsageDescription`.
- Background location, notifications, camera, microphone, and photo library usage descriptions are present in `ios/Runner/Info.plist`.
- Verify the production Firebase plist and push notification entitlement before upload.
