# Third-Party SDK Privacy Declaration
# App Store Privacy Nutrition Labels

## Overview
This document declares all third-party SDKs used in the Smart Truck Driverr app and their data collection practices. Required for App Store privacy nutrition labels and transparency.

---

## 1. Firebase (Google)

### SDKs Used
- `firebase_core: ^3.8.1`
- `firebase_messaging: ^15.1.5`
- `firebase_analytics: ^11.3.5`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| Device ID | Analytics, crash reporting | Yes | No |
| Usage Data | App performance monitoring | No | No |
| Crash Data | Crash diagnostics | No | No |
| FCM Token | Push notifications | Yes | No |

### Privacy Policy
https://firebase.google.com/support/privacy

### Data Retention
- Analytics: 2 months (configurable)
- Crash reports: 90 days
- FCM tokens: Until device unregisters

### User Control
- Analytics can be disabled via app settings
- Push notifications controlled via device settings

---

## 2. Google Maps Platform

### SDKs Used
- `google_maps_flutter: ^2.10.0`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| Precise Location | Map display, routing | Yes | No |
| Device ID | API quotas | Yes | No |
| Map Interactions | Service improvement | No | No |

### Privacy Policy
https://policies.google.com/privacy

### Data Retention
- Location data: Not stored by Google Maps SDK (only used for display)
- Cached map tiles: Temporary, cleared on app restart

### User Control
- Location permission required from device settings
- Can be disabled (map features unavailable)

---

## 3. Dio HTTP Client

### Package
- `dio: ^5.8.0+1`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| API Requests | Backend communication | Yes | No |
| Authentication Tokens | User session | Yes | No |
| Request Metadata | Error diagnostics | No | No |

### Privacy Notes
- All data transmitted to **our own backend** (api.svtrucking.com)
- No third-party data sharing by Dio itself
- SSL/TLS encryption enforced
- Certificate pinning implemented

---

## 4. Flutter Secure Storage

### Package
- `flutter_secure_storage: ^9.2.4`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| Tokens | Secure credential storage | Yes | No |
| User Preferences | App settings | Yes | No |

### Privacy Notes
- All data stored **locally on device**
- Uses iOS Keychain and Android Keystore
- Encrypted at rest
- No cloud sync or third-party transmission

---

## 5. Geolocator

### Package
- `geolocator: ^13.0.2`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| Precise Location | Real-time tracking | Yes | No |
| Location Updates | Route recording | Yes | No |

### Privacy Notes
- Location sent to **our backend only**
- No third-party location sharing
- Background location justified for delivery tracking
- User can disable (app features limited)

---

## 6. Image Picker

### Package
- `image_picker: ^1.1.2`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| Photos/Videos | Proof of delivery upload | Yes | No |
| Camera Access | Document capture | Yes | No |

### Privacy Notes
- Images accessed with explicit user permission
- Uploaded to **our backend only**
- No automatic cloud sync
- Temporary cache cleared after upload

---

## 7. Local Auth (Biometric)

### Package
- `local_auth: ^2.3.0`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| Biometric Data | Device authentication | No | No |

### Privacy Notes
- Biometric data **never leaves device**
- Uses iOS Face ID/Touch ID and Android BiometricPrompt
- No biometric templates stored by app
- Only receives success/failure result

---

## 8. Shared Preferences

### Package
- `shared_preferences: ^2.3.4`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| User Preferences | App settings | Yes | No |
| Consent Status | GDPR compliance | Yes | No |

### Privacy Notes
- All data stored **locally on device**
- No cloud sync
- Can be cleared by user (Settings > Delete Account)

---

## 9. URL Launcher

### Package
- `url_launcher: ^6.3.1`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| None | Opens external links | No | No |

### Privacy Notes
- No data collection by package
- External sites have their own privacy policies
- User aware when leaving app

---

## 10. Crypto (Certificate Pinning)

### Package
- `crypto: ^3.0.3`

### Data Collected
| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| None | Certificate validation | No | No |

### Privacy Notes
- No data collection
- Used for security (MITM attack prevention)
- Processes data locally only

---

## App Store Privacy Report Summary

### Data Linked to User
- Name, email, phone number (authentication)
- Precise location (delivery tracking)
- Photos/videos (proof of delivery)
- Device ID (analytics, notifications)
- Usage data (app performance)

### Data Not Linked to User
- Crash data
- Performance data
- Diagnostic data

### Data Used for Tracking
- **NONE** - We do not track users across apps/websites

### User Rights (GDPR)
- Right to Access: Export data via Settings
- Right to Rectification: Update profile
- Right to Erasure: Delete account
- Right to Portability: JSON export
- Right to Object: Granular consent controls

---

## Compliance Certifications

### GDPR (EU)
- Privacy manifest included
- Consent management implemented
- Data export/deletion features
- Privacy policy accessible

### CCPA (California)
- "Do Not Sell My Personal Information" - N/A (we don't sell data)
- Data disclosure provided
- Opt-out mechanisms available

### COPPA (Children's Privacy)
- App rated 18+ (commercial driver app)
- Not targeted at children under 13
- Age verification on signup

### Apple App Privacy
- PrivacyInfo.xcprivacy manifest included
- Required API usage reasons declared
- Background location justified

---

## Data Retention Policy

| Data Type | Retention Period | Deletion Method |
|-----------|------------------|-----------------|
| Account Data | Active + 90 days | Hard delete |
| Location History | 1 year | Auto-purge |
| Delivery Proofs | 7 years (legal) | Archived |
| Crash Logs | 90 days | Auto-delete |
| Analytics | 60 days | Auto-delete |

---

## Contact for Privacy

**Data Protection Officer**  
Email: privacy@svtrucking.com  
Address: [Company Address]

**User Requests**  
- Data export: Settings > Privacy > Export Data
- Data deletion: Settings > Privacy > Delete Account
- Privacy questions: privacy@svtrucking.com

---

## Last Updated
December 2, 2025

## Version
1.0

---

**Note for App Store Submission:**

When filling out App Store Connect privacy questions:

1. **Does your app collect data?** Yes
2. **Data types collected:**
   - Contact Info: Name, Email, Phone
   - Location: Precise Location
   - Identifiers: Device ID
   - Usage Data: Product Interaction
   - Diagnostics: Crash Data, Performance Data
   - Photos or Videos

3. **How is data used?**
   - App Functionality
   - Analytics
   - Product Personalization

4. **Is data linked to user?** Yes (except crash/performance)
5. **Is data used for tracking?** No
6. **Do you or third parties track?** No

7. **Third-party SDKs:** Firebase, Google Maps (as detailed above)
