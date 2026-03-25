Upload instructions

1. Open Xcode: `ios/Runner.xcworkspace`.
2. Select Runner scheme and the correct Team in Signing & Capabilities.
3. Product → Archive. After archive completes, click Distribute App.
4. Choose "App Store" and follow the prompts to upload, or export an IPA using `exportOptions.plist`.

CLI alternative (requires signing credentials configured):

```bash
# Archive (example - adjust scheme/workspace/product)
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/ios/archive/Runner.xcarchive archive

# Export (requires valid provisioning/certs; ensure exportOptions.plist has your team ID)
xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive -exportOptionsPlist ios/exportOptions.plist -exportPath build/ios/ipa
```

If you do not have an Admin to fill App Privacy in App Store Connect, ask them to:
- Open App Store Connect → My Apps → select app → App Privacy → provide the tracking/analytics data usage details for this app build.

Notes:
- We added `NSUserTrackingUsageDescription` in `ios/Runner/Info.plist` because linked SDKs reference AppTracking APIs.
- If you want zero tracking detection, request that I remove Google/Firebase measurement pods; this may remove analytics/ads functionality.
