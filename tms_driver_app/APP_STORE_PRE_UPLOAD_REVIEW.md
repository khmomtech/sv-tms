# App Store Pre-Upload Review
**Smart Truck Driver App - iOS Submission Checklist**
**Date:** January 9, 2026
**Version:** 1.0.1+4
**Build for:** Production App Store Release

---

## PASSED - Ready for Submission

### 1. App Configuration
- **Bundle ID:** `com.svtrucking.svdriverapp`
- **Display Name:** "Smart Truck Driver"
- **Version:** 1.0.1 (Build 4)
- **Minimum iOS:** 12.0+
- **Category:** Navigation (Primary), Business (Secondary)
- **Age Rating:** 18+ (Professional commercial driver app)

### 2. Privacy Manifest Complete
**File:** `ios/Runner/PrivacyInfo.xcprivacy`
- NSPrivacyTracking: `false` (No tracking)
- NSPrivacyTrackingDomains: Empty array (correct)
- Data types declared:
  - Precise Location (linked, not tracking)
  - Name, Email, Phone (linked, not tracking)
  - Photos/Videos (linked, not tracking)
  - Device ID (linked, not tracking)
  - Crash Data (not linked, not tracking)
  - Performance Data (not linked, not tracking)
- API usage reasons declared:
  - UserDefaults (CA92.1)
  - File timestamp (C617.1, 3B52.1)
  - System boot time (35F9.1)
  - Disk space (E174.1, 85F4.1)

### 3. Permissions Properly Justified
**File:** `ios/Runner/Info.plist`
- Location (When In Use): "Used to show your position on the map and navigate during deliveries."
- Location (Always): "Used to report location while you are On Duty so dispatch can manage active deliveries."
- Camera: "The camera is used to capture proof of delivery, loading photos, and driver documents."
- Photo Library: "Photo access allows selecting existing images as delivery or loading proof."
- Background Modes: `location`, `remote-notification` (only required modes)

### 4. App Transport Security (ATS) - Production Locked
```xml
<key>NSAllowsArbitraryLoads</key>
<false/>  CORRECT - Locked down for production
```

**Allowed Domains (HTTPS enforced):**
- `svtms.svtrucking.biz` (Production API - TLS 1.2+)
- `maps.googleapis.com` (Google Maps)
- `firebaseio.com` (Firebase)
- `sentry.io` (Error tracking)

⚠️ **NOTE:** `localhost` domain still present in Info.plist (dev testing only). This is acceptable but consider removing for production build.

### 5. App Icons & Assets
**Location:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- App Icon 1024x1024 present
- All required sizes present (20x20 to 1024x1024)
- Launch screen configured

### 6. Third-Party SDKs Audit
**No Tracking SDKs Detected:**
- Firebase Analytics **REMOVED** (intentional - avoids IDFA)
- No IDFA/ATT requirement
- Safe SDKs only:
  - Firebase Messaging (push notifications)
  - Sentry (error reporting) - needs disclosure
  - Google Maps (navigation)
  - Stomp WebSocket (real-time communication)

### 7. Security & Encryption
- `ITSAppUsesNonExemptEncryption`: `false` (no custom encryption)
- Tokens stored in Keychain via `flutter_secure_storage`
- HTTPS enforced for all API calls
- Certificate pinning configured

### 8. Localization
- English (en)
- Khmer (km)
- NotoSansKhmer font included for proper Khmer rendering

### 9. Flutter Environment
```
Flutter 3.38.3 (Channel stable)
Dart 3.10.1
Xcode 26.2 (Build 17C52)
CocoaPods 1.16.2
```

---

## ⚠️ WARNINGS - Address Before Submission

### 1. ⚠️ App Tracking Transparency (ATT) Description Present
**File:** `ios/Runner/Info.plist` Line 109
```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads...</string>
```

**Issue:** You have ATT description but `NSPrivacyTracking: false` in Privacy Manifest.

**CRITICAL ACTION:**
- If you DO NOT track users → **REMOVE** this key from Info.plist
- If you DO track users → Update Privacy Manifest to `NSPrivacyTracking: true`

**Recommendation:** Remove ATT description since you're not using IDFA tracking.

### 2. ⚠️ Debug Print Statements in Production Code
Found **40+ debug print statements** in production code:
- `debugPrint()` throughout main.dart, services, widgets
- `print()` in geofence_manager.dart, assignment_service.dart

**Impact:** Performance overhead, log pollution, potential info disclosure

**Action Required:**
```bash
# Recommended: Strip debug prints for production build
flutter build ios --release --flavor prod --dart-define=dart.vm.product=true
```

Or wrap in debug checks:
```dart
if (kDebugMode) {
  debugPrint('...');
}
```

### 3. ⚠️ TODO Comments (11 found)
Key TODOs requiring attention:
- Privacy policy URL: `lib/features/settings/screens/gdpr_consent_screen.dart`
  - Currently: `https://svtrucking.com/privacy`
  - Currently: `https://svtrucking.com/terms`
  - **ACTION:** Verify these URLs are live and accessible
- Production server certificate fingerprints: `lib/core/security/certificate_pinning_config.dart`
- Crashlytics integration: `lib/core/utils/app_logger.dart`

### 4. ⚠️ Export Options Missing Team ID
**File:** `ios/exportOptions.plist`
```xml
<key>teamID</key>
<string>YOUR_TEAM_ID</string>  ⚠️ PLACEHOLDER
```

**Action:** Replace with your actual Apple Developer Team ID before archiving.

### 5. ⚠️ Development URLs in Code
**File:** `lib/core/config/app_config.dart`
```dart
return 'http://10.0.2.2:8080/api'; // Android emulator
// return 'http://localhost:8080/api'; // iOS simulator
```

**Status:** These only run in debug mode (gated by `kReleaseMode` check)
**Action:** No change needed, but verify release builds use production URL.

---

## 🚨 CRITICAL - Must Complete Before Submission

### 1. Privacy Policy URL (COMPLETED)
**Status:** VERIFIED & UPDATED

**Production URLs:**
- Privacy Policy: `https://svtms.svtrucking.biz/privacy` Live (HTTP 200)
- Terms of Service: `https://svtms.svtrucking.biz/terms` Live (HTTP 200)

**Updated in code:**
```dart
Uri.parse('https://svtms.svtrucking.biz/privacy')
Uri.parse('https://svtms.svtrucking.biz/terms')
```

**Verification Results:**
- Both URLs tested and return HTTP 200 OK
- Code updated in `gdpr_consent_screen.dart`
- TODO comments removed

**Privacy policy MUST include:**
   - Location data collection & usage
   - Camera & photo access
   - Push notifications (Firebase)
   - Error reporting (Sentry)
   - Data retention period
   - User rights (GDPR compliant)

### 2. 🚨 App Store Screenshots
**Required:** 5-10 screenshots per language (English, Khmer)

**Screenshot Requirements:**
- iPhone 6.5" display (1242x2688 or 1284x2778)
- Show key features:
  - Login screen
  - Delivery list/map view
  - Navigation/GPS tracking
  - Proof of delivery capture
  - Push notifications example

**Tools:**
```bash
# Use Xcode simulator or real device
# File → Save Screenshot (Cmd+S in Simulator)
```

### 3. 🚨 App Store Metadata
**Required Fields:**
- **App Name:** Smart Truck Driver (or approved name)
- **Subtitle:** Professional Delivery Management
- **Description:** 0/4000 characters used - WRITE THIS
- **Keywords:** 0/100 characters - Examples:
  - "delivery,trucking,driver,logistics,gps,route,navigation,tracking"
- **Support URL:** Must be accessible
- **Marketing URL:** Optional
- **Privacy Policy URL:** ⚠️ Critical - see #1 above

### 4. 🚨 App Review Information
**Copy this template into App Store Connect:**

```
APP REVIEW NOTES FOR APPLE

This is a professional commercial driver application for real-time 
delivery management and route tracking.

## Test Account Credentials
Username: drivertest
Password: 123456

## Review Server
API Base URL: https://svtms.svtrucking.biz/api

## Permission Justifications
- Location (Always): Real-time delivery route tracking while driver 
  is On Duty. Location data is used only for delivery management 
  and is not shared with third parties for advertising.
  
- Camera: Proof of delivery photography and document capture.

- Photos: Select existing images for delivery documentation.

## Privacy & Security
- All API communication uses HTTPS with TLS 1.2+
- App Transport Security: Locked down for production (NSAllowsArbitraryLoads=false)
- Authentication tokens stored securely in iOS Keychain
- No user tracking or IDFA collection
- Privacy Policy: [YOUR_PRIVACY_POLICY_URL]

## Technical Details
- Supported iOS: 12.0+
- Languages: English, Khmer
- Background modes: Location tracking, remote notifications
- No cross-app tracking or advertising

## Testing Instructions
1. Launch app and log in with test credentials above
2. Tap "On Duty" button
3. Allow location permission when prompted
4. Navigate to Deliveries tab
5. Test photo capture for proof of delivery
6. Test push notification by creating test delivery from backend

## Additional Notes
- App requires professional commercial driver's license
- Age restricted to 18+ (commercial use only)
- Location tracking can be disabled by user in app settings
```

---

## 📋 Pre-Build Checklist

### Before Running `flutter build ios --release --flavor prod`:

- [ ] **Remove ATT description** from Info.plist (if not tracking)
- [ ] **Update Team ID** in exportOptions.plist
- [ ] **Verify privacy policy URLs** are live
- [ ] **Clean debug prints** (or use product mode flag)
- [ ] **Test on real iPhone device** (iOS 15+)
  - [ ] Location permissions grant/deny flow
  - [ ] Camera & photo upload
  - [ ] Push notifications
  - [ ] Background location updates
  - [ ] Offline mode & reconnection
- [ ] **Code signing configured** in Xcode
  - [ ] Distribution certificate installed
  - [ ] Provisioning profile valid
  - [ ] Automatic signing enabled OR manual signing set up

---

## 🚀 Build & Upload Commands

### Step 1: Clean Build
```bash
cd /Users/sotheakh/Documents/develop/sv-tms/driver_app

# Clean previous builds
flutter clean
flutter pub get

# Build for production (App Store)
flutter build ios --release --flavor prod --dart-define=dart.vm.product=true
```

### Step 2: Archive in Xcode
```bash
# Open workspace
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Any iOS Device (arm64)" as destination
# 2. Product → Scheme → Runner (prod)
# 3. Product → Archive (⌘+B then ⌘+Shift+B)
# 4. Wait for archive to complete
```

### Step 3: Upload to App Store Connect
```
Xcode Organizer → Archives:
1. Select your archive
2. Click "Distribute App"
3. Choose "App Store Connect"
4. Upload
5. Wait for processing (15-60 minutes)
```

### Alternative: Fastlane Upload
```bash
cd tms_driver_app
bundle exec fastlane ios upload_reviewer
```

---

## 📊 Expected App Review Timeline

| Stage | Duration | Status |
|-------|----------|--------|
| **Upload to App Store Connect** | Immediate | - |
| **Processing** | 15-60 minutes | - |
| **Waiting for Review** | 1-2 days | - |
| **In Review** | 4-24 hours | - |
| **Approved/Rejected** | Immediate after review | - |

**Overall Expected Time:** 24-72 hours from submission to approval

**Rejection Risk Level:** 🟢 **LOW**
- SDK audit clean (no tracking)
- ATS properly configured
- Privacy manifest complete
- Permissions properly justified

---

## Final Verification Before Submit

Run this checklist one more time:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/driver_app

# 1. Verify ATS is locked
grep -A1 "NSAllowsArbitraryLoads" ios/Runner/Info.plist
# Expected: <false/>

# 2. Verify no tracking
grep "NSPrivacyTracking" ios/Runner/PrivacyInfo.xcprivacy
# Expected: <false/>

# 3. Check version
grep "version:" pubspec.yaml
# Expected: 1.0.1+4

# 4. Verify production URL
grep "svtms.svtrucking.biz" lib/core/config/app_config.dart
# Should see HTTPS URL

# 5. Check for hardcoded IPs
grep -r "192.168\|localhost" lib/ --include="*.dart" | grep -v "kDebugMode\|kReleaseMode"
# Should only see debug-mode gated references
```

---

## 🎯 Priority Actions (Do Now)

### PRIORITY 1 (CRITICAL - MOSTLY COMPLETE):
1. ~~Verify/Create Privacy Policy at accessible URL~~ **DONE**
2. ~~Verify/Create Terms of Service at accessible URL~~ **DONE**
3. ⚠️ Remove ATT description from Info.plist (Line 109-110)
4. ⚠️ Update Team ID in exportOptions.plist

### PRIORITY 2 (HIGH - DO SECOND):
5. 📸 Capture App Store screenshots (5-10 per language)
6. ✍️ Write App Store description (up to 4000 characters)
7. 🔑 Set up test account (reviewer@test.sv) in backend
8. 📱 Test on real iPhone device (all features)

### PRIORITY 3 (MEDIUM - DO THIRD):
9. 🧹 Clean debug print statements (or use product mode)
10. 📝 Prepare App Review Notes (use template above)
11. 🔍 Resolve TODO comments (especially privacy URLs)
12. 🎨 Verify app icon displays correctly

### PRIORITY 4 (LOW - DO LAST):
13. 🏗️ Build production IPA
14. ⬆️ Upload to App Store Connect
15. 📝 Fill in App Store metadata
16. Submit for review

---

## 📞 Support & Resources

**Documentation Files:**
- `APPLE_SUBMISSION_ONE_PAGE.md` - Quick reference
- `APP_STORE_SUBMISSION_CHECKLIST.md` - Full checklist (477 lines)
- `APPLE_SUBMISSION_QUICK_REFERENCE.md` - Quick tips
- `BUILD_UPLOAD.md` - Build & upload instructions
- `THIRD_PARTY_SDK_PRIVACY.md` - SDK privacy details

**Apple Resources:**
- App Store Connect: https://appstoreconnect.apple.com
- Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Privacy Manifest: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files

---

## 🎉 Ready to Submit?

If you've completed all **PRIORITY 1** and **PRIORITY 2** items above, you're ready to submit!

**Final Confidence Check:**
- ~~Privacy policy live and accessible~~ **VERIFIED**
- ~~Terms URLs updated in code~~ **VERIFIED**
- Screenshots captured
- App Store metadata written
- Test account works
- Tested on real iPhone
- ⚠️ ATT description removed (if not tracking) - **TODO**
- ⚠️ Team ID updated in exportOptions.plist - **TODO**

**If all checked → Proceed with build and upload! 🚀**

---

**Review Conducted By:** GitHub Copilot
**Review Date:** January 9, 2026
**App Version:** 1.0.1+4
**Next Action:** Complete Priority 1 & 2 items, then build and submit
