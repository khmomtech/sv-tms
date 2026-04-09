# SDK Audit & Apple Submission Checklist

**Last Updated:** December 30, 2025  
**Status:** Ready for Production Submission  
**Audience:** Dev Team, App Review Coordinator

---

## 📊 PART 1: SDK AUDIT REPORT

### Tracking SDKs - CLEAN

Your `pubspec.yaml` has **NO active tracking SDKs** installed.

| SDK Category | Status | Details |
|---|---|---|
| **Google Analytics** | Not installed | `firebase_analytics` explicitly removed to avoid IDFA linkage |
| **Crashlytics** | ⚠️ Indirect via Sentry | Only `sentry_flutter` included (necessary for error tracking) |
| **Facebook SDK** | Not installed | No Facebook SDK in dependencies |
| **Amplitude** | Not installed | Not present |
| **Mixpanel** | Not installed | Not present |
| **Adjust/AppsFlyer** | Not installed | Not present |
| **Flurry Analytics** | Not installed | Not present |
| **Branch/Deep Linking** | Not installed | Not present |
| **Singular** | Not installed | Not present |

---

### 📦 SDK Dependency Analysis

#### **Core Dependencies (Low Risk)**
```
firebase_core ^3.11.0
   └─ Purpose: Firebase initialization only
   └─ Privacy Impact: Minimal (no analytics/tracking enabled)
   └─ Status: SAFE

firebase_messaging ^15.2.2
   └─ Purpose: Push notifications (APNs)
   └─ Privacy Impact: Required for user communication
   └─ Status: SAFE

sentry_flutter ^9.5.0
   └─ Purpose: Error tracking and crash reporting
   └─ Privacy Impact: Error data only, no user tracking
   └─ Note: Must declare in privacy policy
   └─ Status: ACCEPTABLE
```

#### **Location & Permissions (Business Critical)**
```
geolocator ^13.0.2
   └─ Purpose: GPS location for delivery tracking
   └─ Privacy Impact: User-authorized, business critical
   └─ Status: REQUIRED

permission_handler ^12.0.0+1
   └─ Purpose: Permission management
   └─ Privacy Impact: Minimal, user control
   └─ Status: REQUIRED

google_maps_flutter ^2.10.0
   └─ Purpose: Route visualization
   └─ Privacy Impact: Uses location data only
   └─ Note: API key should be restricted to app bundle
   └─ Status: REQUIRED
```

#### **Low-Risk Utility Dependencies**
```
provider ^6.0.5                     (State management)
http ^1.3.0                         (Network requests)
shared_preferences ^2.3.4           (Local storage)
flutter_secure_storage ^9.2.4       (Secure token storage)
image_picker ^1.1.2                 (Photo selection)
file_picker ^8.1.6                  (File selection)
dio ^5.8.0+1                        (HTTP client)
local_auth ^2.3.0                   (Biometric auth)
connectivity_plus ^6.1.4            (Network detection)
device_info_plus ^10.0.1            (Device info)
stomp_dart_client ^2.1.3            (WebSocket)
cached_network_image ^3.4.1         (Image caching)
```

---

### ⚠️ Privacy Policy Declarations Required

**You MUST include these in your App Store privacy policy:**

1. **Sentry Error Tracking**
   - What data: Crash reports, error logs, device identifiers
   - How: Sent to Sentry servers
   - Purpose: App stability improvement
   - Link: https://sentry.io/privacy/

2. **Firebase Cloud Messaging**
   - What data: Device token, push notification delivery
   - How: Sent to Firebase servers
   - Purpose: Push notifications
   - Link: https://firebase.google.com/support/privacy

3. **Location Data**
   - What data: GPS coordinates
   - How: Stored and transmitted to backend API
   - Purpose: Delivery tracking and route optimization
   - User control: Can disable in system settings

4. **Photos & Camera**
   - What data: Images selected by user
   - How: Uploaded to backend API
   - Purpose: Proof of delivery
   - User control: User explicitly selects files

---

## 🍎 PART 2: APPLE SUBMISSION CHECKLIST

### Pre-Submission (BEFORE uploading)

#### Technical Requirements
- [ ] **Xcode Build:** Tested with latest Xcode (15.x+)
- [ ] **iOS Deployment Target:** Set to 12.0 minimum
- [ ] **Device Testing:** Tested on real iPhone (minimum iOS 15)
- [ ] **Simulator Testing:** Tested on iOS simulator
- [ ] **Landscape/Portrait:** App tested in both orientations
- [ ] **Accessibility:** Tested with VoiceOver enabled
- [ ] **Battery Impact:** Background location tracking verified
- [ ] **Network Stability:** Tested on WiFi and cellular

#### Privacy & Compliance
- [ ] **Privacy Policy URL:** Live and accessible
- [ ] **Privacy Policy Covers:**
  - [ ] Location data collection
  - [ ] Camera/photo usage
  - [ ] Contact/location access
  - [ ] Push notifications
  - [ ] Error tracking (Sentry)
  - [ ] Firebase integration
  - [ ] Data retention policies
  - [ ] Third-party data sharing
- [ ] **App Tracking Transparency (ATT):** Not required (no IDFA tracking)
- [ ] **User Consent:** Location permission requests shown
- [ ] **Data Deletion:** Policy for user data deletion documented

#### App Store Metadata
- [ ] **App Name:** "Smart Truck Driver" (verified)
- [ ] **Subtitle:** Concise, accurate description (40 chars max)
- [ ] **Description:** Clear value proposition
- [ ] **Keywords:** Relevant without keywords like "free" or category names
- [ ] **Categories:** Navigation (primary), Productivity (secondary)
- [ ] **Content Rating:** Completed questionnaire
- [ ] **Screenshots:** 5-10 per language, relevant to app functionality
- [ ] **Preview Video:** Optional but recommended
- [ ] **Support URL:** Live and monitored
- [ ] **Marketing URL:** Optional if not available
- [ ] **App Review Notes:** See section below

#### Code Quality
- [ ] **No Crashes:** Thoroughly tested for crashes
- [ ] **No Warnings:** Xcode build warnings resolved
- [ ] **No Hardcoded:** Remove hardcoded IP addresses (192.168.0.33)
- [ ] **No Debug Code:** Remove console.log, print() statements
- [ ] **No Expired Certificates:** Apple Developer account valid
- [ ] **No Test Accounts:** Remove test user credentials
- [ ] **GDPR Compliant:** Right to be forgotten implemented
- [ ] **No Misleading Content:** App accurately described

#### App Functionality Testing
- [ ] **Login/Auth:** Full authentication flow tested
- [ ] **Push Notifications:** FCM tokens sync and delivery tested
- [ ] **Location Tracking:** GPS working, background location tested
- [ ] **Photo Upload:** Camera and photo library tested
- [ ] **Offline Mode:** App behavior without internet verified
- [ ] **API Errors:** HTTP errors (401, 403, 500) handled gracefully
- [ ] **Network Switching:** WiFi to cellular switching tested

#### Security
- [ ] **HTTPS Only:** All API calls use HTTPS
- [ ] **Token Storage:** Tokens in secure storage (not SharedPreferences)
- [ ] **API Keys:** Restricted to bundle ID in Google Cloud Console
- [ ] **No Backdoors:** No test accounts or admin access
- [ ] **Data in Transit:** SSL pinning considered
- [ ] **Local Storage:** Sensitive data encrypted

#### Permissions Justification (Critical for App Review)

**Camera Permission:**
- [ ] Justification: "Proof of delivery photos"
- [ ] Check: Feature actually uses camera when requested
- [ ] Avoid: Requesting but not using immediately

**Location Permission:**
- [ ] Justification: "Real-time delivery tracking and route optimization"
- [ ] Always/When In Use: "While In Use" is preferred unless background tracking required
- [ ] Background Delivery: Document the business need
- [ ] Avoid: Vague descriptions like "For better experience"

**Photo Library Permission:**
- [ ] Justification: "Select existing images for delivery proof"
- [ ] Check: User can proceed without granting all permissions

**Contacts/Calendar:**
- [ ] Check: Not requested unless absolutely necessary
- [ ] Avoid: Requesting if not essential

#### Guideline Compliance

**App Review Guideline Violations to Check:**

- [ ] **Guideline 1.1 - Business Model:** Free, no misleading pricing
- [ ] **Guideline 2.1 - Functionality:** App functions as described
- [ ] **Guideline 2.3 - Accurate Metadata:** App does what screenshots show
- [ ] **Guideline 2.5 - Accurate Descriptions:** No exaggerated claims
- [ ] **Guideline 3.2.1 - Safety:** No content promoting dangerous behavior
- [ ] **Guideline 4.3 - Physical Threats:** No encouragement of dangerous driving
- [ ] **Guideline 5.1.1 - Data Collection:** Privacy policy disclosed
- [ ] **Guideline 5.3 - Health Data:** No health data collected
- [ ] **Guideline 5.6 - Financial Data:** No payment processing in app (backend only)

#### Localization
- [ ] **Language Support:** English & Khmer verified
- [ ] **RTL Support:** Khmer text direction tested
- [ ] **Translations:** Professional translation reviewed
- [ ] **Date/Time Formats:** Locale-appropriate formatting
- [ ] **Currency:** Khmer language copy verified

---

### During Review (Common Rejections & Fixes)

| Rejection Reason | Your App Status | Prevention |
|---|---|---|
| Location privacy policy vague | ⚠️ RISK | Clear policy provided - describe *how* location is used |
| Background location not justified | ⚠️ RISK | Document business case - delivery tracking is valid |
| Camera/photo permission not used immediately | ⚠️ RISK | Verify photo screen triggers permission request |
| Privacy policy missing | SAFE | Privacy URL configured in Info.plist |
| No legal terms | ⚠️ RISK | Provide Terms of Service URL if applicable |
| Unclear what data is collected | ⚠️ RISK | Privacy policy section lists all collection |
| Third-party SDKs not disclosed | ⚠️ RISK | Sentry and Firebase disclosed |

---

## 🔐 PART 3: APP TRANSPORT SECURITY (ATS) PRODUCTION LOCK

### Current Status
❌ **INSECURE - Production Risk**

```xml
<!-- ⚠️ CURRENT: Allows HTTP & self-signed certs -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <!-- ... -->
</dict>
```

**Risk Level:** HIGH - Apple will flag this during review

---

### Step 1: Update Production ATS Configuration

Replace the entire ATS section in [ios/Runner/Info.plist](ios/Runner/Info.plist) with this production-safe config:

```xml
<!-- 🔐 App Transport Security (Production) -->
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Deny all insecure loads by default -->
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    
    <!-- Allow specific trusted domains only -->
    <key>NSExceptionDomains</key>
    <dict>
        <!-- Production API Server -->
        <key>svtms.svtrucking.biz</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPSLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
        
        <!-- Maps API (Google) -->
        <key>maps.googleapis.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
        
        <!-- Firebase Services -->
        <key>firebaseio.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
        
        <!-- Sentry Error Tracking -->
        <key>sentry.io</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
        
        <!-- LOCAL DEVELOPMENT ONLY (Remove for production release) -->
        <key>localhost</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionAllowsInsecureHTTPSLoads</key>
            <true/>
        </dict>
        
        <!-- LOCAL DEVELOPMENT: 192.168.x.x (Remove for production release) -->
        <key>192.168.0.33</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionAllowsInsecureHTTPSLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

---

### Step 2: Environment-Specific Configurations

**For Development Builds (Keep local testing enabled):**
```xml
<!-- DEV ONLY: Allow localhost -->
<key>localhost</key>
```

**For UAT Builds (Stricter but testable):**
```xml
<!-- Remove localhost exceptions -->
<!-- Keep 192.168.0.33 for testing -->
```

**For Production Release (Maximum security):**
```xml
<!-- Remove ALL local exceptions -->
<!-- Only keep svtms.svtrucking.biz, maps.googleapis.com, firebaseio.com, sentry.io -->
```

---

### Step 3: Verify Production Configuration

#### Using Xcode Build Schemes:

Create separate scheme configurations for each environment:

**Option A: Build Configuration Variables (Recommended)**

```bash
# In Terminal:
cd /Users/sotheakh/Documents/develop/sv-tms/driver_app

# For production build, verify ATS config:
grep -A 30 "NSAppTransportSecurity" ios/Runner/Info.plist | grep -c "NSAllowsArbitraryLoads"
# Should return: 1 (and it should be <false/>)

# Verify svtms.svtrucking.biz is in exceptions:
grep "svtms.svtrucking.biz" ios/Runner/Info.plist
# Should return the domain entry
```

**Option B: Verify via Xcode**

1. Open `ios/Runner.xcworkspace/`
2. Select `Runner` project
3. Select `Runner` target
4. Go to `Info` tab
5. Search for "NSAppTransportSecurity"
6. Expand and verify configuration matches above

---

### Step 4: SSL/TLS Verification

Ensure your backend at `svtms.svtrucking.biz` has:

- Valid SSL certificate (not self-signed)
- TLS 1.2 or higher
- Certificate chain properly configured
- No expired certificates

Test with:
```bash
openssl s_client -connect svtms.svtrucking.biz:443 -tls1_2
```

---

### Step 5: Configure Build Flavors (Optional but Recommended)

Modify `ios/Runner/Info.plist.dev` and `ios/Runner/Info.plist.prod` to automatically switch ATS configs based on build flavor:

**Development Flavor (less restrictive):**
```xml
<key>NSAllowsArbitraryLoads</key>
<true/>
```

**Production Flavor (maximum security):**
```xml
<key>NSAllowsArbitraryLoads</key>
<false/>
```

---

### 📋 Pre-Submission ATS Checklist

- [ ] **NSAllowsArbitraryLoads:** Set to `<false/>`
- [ ] **Production Domain:** `svtms.svtrucking.biz` configured
- [ ] **Local Dev Exceptions:** Removed or in separate config
- [ ] **TLS Version:** Minimum TLS 1.2 required
- [ ] **ForwardSecrecy:** Set to `<true/>` for production
- [ ] **SSL Certificate:** Valid, non-self-signed
- [ ] **Test Build:** Fails if attempting HTTP to production
- [ ] **App Review Note:** Mention ATS configuration

---

### Apple App Review Note Template

**Include this in your App Review Notes:**

```
App Transport Security Configuration:
- All API communication to svtms.svtrucking.biz uses HTTPS with TLS 1.2+
- Insecure HTTP loads are disabled for production
- Firebase and Sentry services are whitelisted with secure connections
- Local development exceptions are only in non-production builds
- No arbitrary insecure loads are allowed in production

Data Protection:
- All sensitive tokens stored in Secure Storage (iOS Keychain)
- Locations are only used for delivery tracking as described
- Push notifications use Firebase Cloud Messaging
- Error tracking via Sentry includes device info only
```

---

## 🚀 Final Submission Checklist

Before uploading to App Store Connect:

```
SECURITY & PRIVACY
- [ ] ATS configured with NSAllowsArbitraryLoads = false
- [ ] All domains use HTTPS with valid certs
- [ ] Privacy policy published and comprehensive
- [ ] No SDK IDFA tracking enabled
- [ ] Location permission justified

FUNCTIONALITY
- [ ] All features tested on real device
- [ ] No crashes or hangs
- [ ] Push notifications working
- [ ] Offline mode graceful
- [ ] Location tracking accurate

METADATA
- [ ] App icon, screenshots, description complete
- [ ] Keywords relevant and under 100 chars
- [ ] Age rating appropriate
- [ ] Supported devices listed

COMPLIANCE
- [ ] No hardcoded IPs (remove 192.168.0.33 for prod)
- [ ] No test accounts exposed
- [ ] No misleading claims
- [ ] GDPR considerations documented

DOCUMENTATION
- [ ] App Review Notes completed
- [ ] Privacy policy URL valid
- [ ] Support email monitored
- [ ] Terms of Service provided (if applicable)
```

---

## 📞 Contact & Support

**App Review Rejection?**
1. Check rejection reason against "Common Rejections" table above
2. Review privacy policy - most common reason
3. Verify location permission is justified
4. Check for hardcoded test data

**Questions about ATS?**
- Apple ATS Documentation: https://developer.apple.com/documentation/security/preventing_insecure_network_connections
- Stack Overflow tag: [ios-ats]

**Sentry Data Privacy:**
- Sentry Privacy: https://sentry.io/privacy/
- GDPR Compliance: https://sentry.io/legal/dpa/

---

**Status:** READY FOR PRODUCTION
**Next Step:** Implement ATS lock, then submit to App Review
