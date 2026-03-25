> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🚛 Driver App - Login Accounts & Mobile Setup Guide

## 🔐 Driver App Login

### How Driver Accounts Work

Driver app login accounts are created through the **Admin UI** after a driver record exists. The process links:
- `drivers` table → Physical driver record (license, phone, zone)
- `users` table → Login credentials (username, password, role=DRIVER)

**Authentication Flow:**
```
Driver Record → Create Login Account → Link via driver_id → Driver can login
```

---

## 📋 Step-by-Step: Create Driver Login Account

### Method 1: Via Admin UI (Recommended)

#### Step 1: Create Driver in Admin UI
1. Navigate to **Admin UI** → **Fleet** → **Drivers** → **+ New Driver**
2. Fill in driver details:
   - **First Name**: e.g., `Sophea`
   - **Last Name**: e.g., `Kong`
   - **Phone**: e.g., `+855-97-123-4567` (unique, used for login)
   - **License Class**: `A`, `B`, `B1`, `C`, `C1` (vehicle type)
   - **License Expiry**: e.g., `2026-12-31`
   - **ID Card Expiry**: e.g., `2025-12-31`
   - **Zone**: Assign delivery zone (e.g., `Zone A`, `Zone B`)
   - **Status**: `IDLE`, `ONLINE`, `OFFLINE`, `ON_LEAVE`, `SUSPENDED`
   - **Is Partner**: `No` (employee) or `Yes` (contractor)
   - **Performance Score**: 0-100 (default: 80)
   - **Safety Score**: `Excellent`, `Good`, `Fair`, `Poor`
   - **On-Time Percent**: 0-100% (default: 95%)
3. Click **Save**

#### Step 2: Create Login Account for Driver
1. In the driver list, find the driver you just created
2. Click **Actions** → **Create Login Account**
3. Fill in login credentials:
   - **Username**: Unique identifier (e.g., `sophea_kong`, `driver001`)
   - **Email**: Optional (e.g., `sophea@svtrucking.com`)
   - **Password**: Strong password (min 8 chars, mixed case, numbers/symbols)
   - **Confirm Password**: Re-enter password
4. Click **Create Account**
5. Backend creates a `User` record with `DRIVER` role and links to driver via `driver_id`

#### Step 3: Test Login
1. Open Driver App (see installation guide below)
2. Enter credentials:
   - **Username**: `sophea_kong`
   - **Password**: (password you set)
3. Click **Login**
4. App should navigate to Dashboard

---

### Method 2: Via Backend API (cURL)

#### Create Driver Record

```bash
# 1. Create driver first
curl -X POST http://localhost:8080/api/admin/drivers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -d '{
    "firstName": "Visal",
    "lastName": "Mok",
    "phone": "+855-97-890-1234",
    "licenseClass": "B",
    "licenseExpiry": "2027-06-30",
    "idCardExpiry": "2026-06-30",
    "zone": "Zone B",
    "status": "IDLE",
    "isPartner": false,
    "performanceScore": 85,
    "safetyScore": "Good",
    "onTimePercent": 90
  }'

# Response includes driver id (e.g., "id": 123)
```

#### Create Login Account for Driver

```bash
# 2. Create login account linked to driver (id=123)
curl -X POST http://localhost:8080/api/admin/drivers/123/account \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -d '{
    "username": "visal_driver",
    "email": "visal@svtrucking.com",
    "password": "SecurePass@2024"
  }'

# Response:
{
  "userId": 456,
  "username": "visal_driver",
  "roles": ["DRIVER"],
  "driverId": 123
}
```

---

## 📱 Driver Mobile App Installation & Setup

### Prerequisites

**Required:**
- Android 5.0+ (API 21+) or iOS 11.0+
- Internet connection (Wi-Fi or mobile data)
- GPS enabled
- 50MB+ free storage

**Recommended:**
- Android 10+ (API 29+) or iOS 14+
- 4G/5G mobile data
- High-accuracy GPS enabled
- 100MB+ free storage

---

### Android Installation

#### Option 1: APK Direct Install (Development/Testing)

```bash
# 1. Build APK from source
cd tms_driver_app
flutter build apk --flavor prod --release

# 2. APK location:
# build/app/outputs/flutter-apk/app-prod-release.apk

# 3. Install on device:
adb install build/app/outputs/flutter-apk/app-prod-release.apk

# Or transfer to device and install manually
```

**Manual Installation Steps:**
1. Enable **Settings** → **Security** → **Install from Unknown Sources**
2. Transfer APK to device (USB, email, cloud storage)
3. Open file manager, tap APK
4. Click **Install**
5. Open **SV Driver** app

#### Option 2: Google Play Store (Production)

🚧 **Coming Soon** - Play Store submission in progress

---

### iOS Installation

#### Option 1: TestFlight (Beta Testing)

🚧 **Coming Soon** - TestFlight beta available soon

#### Option 2: Development Install (Xcode)

```bash
# 1. Build iOS app
cd tms_driver_app
flutter build ios --flavor prod --release

# 2. Open Xcode project
open ios/Runner.xcworkspace

# 3. In Xcode:
#    - Select your iOS device
#    - Click Run (▶️)
#    - App installs on device
```

---

### First Launch Configuration

#### Step 1: Launch App

1. Open **SV Driver** app
2. Language selection screen appears
3. Select **English** or **ភាសាខ្មែរ** (Khmer)

#### Step 2: API Server Configuration (Dev/Testing Only)

**Production**: Uses default server `https://svtms.svtrucking.biz`

**Development/Testing**: Need to point to local/staging server

1. On login screen, tap **Settings** icon (gear icon, top-right)
2. Enter **API Base URL**:
   - Local dev: `http://10.0.2.2:8080` (Android emulator)
   - Local dev: `http://localhost:8080` (iOS simulator)
   - Local network: `http://192.168.1.100:8080` (replace with your IP)
   - Staging: `http://staging.svtrucking.biz:8080`
3. Tap **Save**
4. Return to login screen

#### Step 3: Login

1. Enter credentials:
   - **Username**: (from driver account creation)
   - **Password**: (from driver account creation)
2. Tap **Login**
3. Grant permissions:
   - **Location**: Required for GPS tracking
   - **Notifications**: Required for dispatch updates
   - **Camera**: Required for proof of delivery photos
   - **Storage**: Required for document uploads
4. Dashboard loads with assigned deliveries

---

## 🧪 Test Driver Accounts (Pre-created)

Use these test accounts for development/testing:

### Test Account 1: Sophea Kong
```
Username: sophea_kong
Password: Driver@2024
Phone: +855-97-123-4567
License: Class C
Zone: Zone A
Status: IDLE
```

### Test Account 2: Visal Mok
```
Username: visal_mok
Password: Driver@2024
Phone: +855-97-890-1234
License: Class B
Zone: Zone B
Status: ONLINE
```

### Test Account 3: Dara Sarith
```
Username: dara_sarith
Password: Driver@2024
Phone: +855-98-555-1234
License: Class C1
Zone: Zone A
Status: OFFLINE
```

**To create these test accounts:**

```bash
# Run data import (see FIRST_DEPLOYMENT_COMPLETE_GUIDE.md)
cd /Users/sotheakh/Documents/develop/sv-tms
mysql -u root -p svlogistics_tms < data/import/migration_import_v2.sql

# This imports 10 drivers from drivers_import.csv
# Then create login accounts via Admin UI (Method 1 above)
```

---

## 🔌 API Endpoints Used by Driver App

### Authentication
- `POST /api/auth/driver/login` - Driver login
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - Logout

### Driver Profile
- `GET /api/driver/profile` - Get current driver profile
- `PUT /api/driver/profile` - Update driver profile
- `POST /api/driver/update-device-token` - Register FCM token

### Deliveries & Dispatches
- `GET /api/driver/deliveries` - List assigned deliveries
- `GET /api/driver/deliveries/{id}` - Get delivery details
- `POST /api/driver/deliveries/{id}/status` - Update delivery status
  - Statuses: `ASSIGNED`, `ACCEPTED`, `PICKED_UP`, `IN_TRANSIT`, `DELIVERED`, `FAILED`
- `POST /api/driver/deliveries/{id}/proof` - Upload proof of delivery (image)

### Location Tracking
- `POST /api/driver/location` - Send GPS location update
- `POST /api/driver/location/update/batch` - Batch location updates (every 30 seconds)
- WebSocket: `/topic/driver/{driverId}/location` - Real-time location stream

### Documents
- `GET /api/driver/documents` - List driver documents
- `POST /api/driver/documents` - Upload document (license, insurance, etc.)
- `DELETE /api/driver/documents/{id}` - Delete document

### Dashboard & Stats
- `GET /api/driver/dashboard/{driverId}` - Get dashboard stats
  - Active orders count
  - Completed today
  - Earnings (if applicable)
  - Performance metrics

### Notifications
- WebSocket: `/topic/driver/{driverId}/notifications` - Real-time push notifications
- `GET /api/driver/notifications` - List all notifications
- `PUT /api/driver/notifications/{id}/read` - Mark notification as read

---

## 🚨 Known Issues & Troubleshooting

### Issue 1: "Driver not found" on Login

**Symptom:** Login fails with "Driver not found" error despite valid credentials

**Status:** 🔴 **CRITICAL BUG** - Backend authentication issue

**Root Cause:** Bug in `AuthController.driverLogin()` method (line 161)
- Method cannot find user in database
- Regular `/api/auth/login` works, but `/api/auth/driver/login` fails

**Workaround:** None - requires backend fix

**Fix Required:**
```java
// File: tms-backend/src/main/java/com/svtrucking/logistics/controller/AuthController.java
// Line 161-280

// TODO: Update driverLogin() to properly query users table
// Current query fails to find driver-linked users
```

**Impact:** All driver authentication is BLOCKED until fixed

**Tracking:** See [tms_tms_driver_app/TESTING_DOCUMENTATION.md](tms_tms_driver_app/TESTING_DOCUMENTATION.md#critical-driver-login-authentication-bug) (line 95)

---

### Issue 2: "Unauthorized" on API Calls After Login

**Symptom:** Login succeeds, but all subsequent API calls return 401 Unauthorized

**Cause:** Access token not persisted or not included in headers

**Fix:**
1. Check `ApiConstants.persistLoginResponse()` is called after login
2. Verify token is stored in `FlutterSecureStorage`
3. Check `ApiConstants.getHeaders()` includes `Authorization: Bearer <token>`

**Debug:**
```dart
// Check stored token
final token = await ApiConstants.getAccessToken();
print('Stored token: $token');

// Check headers
final headers = await ApiConstants.getHeaders();
print('Request headers: $headers');
```

---

### Issue 3: Location Not Updating

**Symptom:** GPS coordinates not sent to backend

**Causes:**
1. Location permission not granted
2. GPS disabled on device
3. Location service not running

**Fix:**
1. **Check Permissions:**
   - Android: Settings → Apps → SV Driver → Permissions → Location → Allow all the time
   - iOS: Settings → SV Driver → Location → Always

2. **Enable High Accuracy GPS:**
   - Android: Settings → Location → Mode → High accuracy
   - iOS: Settings → Privacy → Location Services → ON

3. **Restart Location Service:**
   ```dart
   // In app, go to Settings → Stop Location Updates
   // Then Start Location Updates
   ```

---

### Issue 4: Push Notifications Not Received

**Symptom:** No notifications for new dispatch assignments

**Causes:**
1. FCM token not registered
2. Notifications permission denied
3. WebSocket disconnected

**Fix:**
1. **Grant Notification Permission:**
   - Android: Settings → Apps → SV Driver → Notifications → ON
   - iOS: Settings → SV Driver → Notifications → Allow

2. **Check FCM Token:**
   ```dart
   // In app console logs:
   [FCM] Token: <your-fcm-token>
   ```

3. **Reconnect WebSocket:**
   ```dart
   // In app, logout and login again
   // Or pull to refresh on Dashboard
   ```

---

### Issue 5: Images Fail to Upload (Proof of Delivery)

**Symptom:** "Upload failed" when submitting proof of delivery photo

**Causes:**
1. Image too large (>5MB)
2. Network timeout
3. Backend upload limit

**Fix:**
1. **Image is auto-compressed** to <500KB
2. Check console logs:
   ```
   [DispatchProvider] Image: 1234KB → 456KB (63% saved)
   ```
3. If still fails, try smaller image or better network

---

## 📦 Driver App Features

### Dashboard
- Active deliveries count
- Today's completed deliveries
- Performance score
- Earnings (if tracking)
- Quick actions: Start delivery, View map

### Deliveries
- **Pending Tab**: Assigned but not started
- **In Progress Tab**: Currently active
- **Completed Tab**: Finished deliveries
- **Pull to Refresh**: Update from server
- **Filter**: By date, status, priority

### Delivery Detail
- Customer info (name, phone, address)
- Pickup location with map
- Dropoff location with map
- Items list
- Special instructions
- Status timeline
- Actions:
  - Accept/Reject
  - Start pickup
  - Confirm pickup
  - Start delivery
  - Complete delivery (with proof photo)

### Location Tracking
- **Automatic**: Updates every 30 seconds while active
- **Manual**: Tap location icon to force update
- **Background**: Continues tracking when app is backgrounded
- **Battery Optimized**: Uses smart batching

### Profile
- View driver info
- Update phone number
- Change password
- Upload/view documents
- View performance stats
- Logout

### Notifications
- Real-time dispatch assignments
- Delivery updates
- System alerts
- In-app notification center

### Settings
- Language (English/Khmer)
- API server (dev/staging/prod)
- Location tracking on/off
- Notification preferences
- App version info

---

## 🔄 Driver Lifecycle in System

### 1. Driver Registration
```
Admin creates driver → Driver record in database → Assigned zone/vehicle
```

### 2. Account Creation
```
Admin creates login → User account with DRIVER role → Linked to driver_id
```

### 3. First Login
```
Driver logs in → FCM token registered → WebSocket connected → Ready for assignments
```

### 4. Active Duty
```
Location tracking ON → Receives dispatch → Accepts → Pickup → Transit → Deliver → Proof photo → Complete
```

### 5. Off Duty
```
Driver logs out → Location tracking stops → WebSocket disconnects → Status: OFFLINE
```

---

## 🧩 Integration with Other Apps

### Admin UI (tms-frontend)
- Admins/dispatchers create driver accounts
- Assign deliveries to drivers
- Track driver locations on map
- Monitor driver performance

### Customer App (tms_customer_app)
- Customers see driver location in real-time
- Receive notifications when driver is nearby
- View driver profile (name, vehicle, rating)

### Backend (tms-backend)
- Authenticates drivers
- Manages delivery assignments
- Tracks GPS locations
- Stores delivery proofs
- Calculates performance metrics

---

## 📊 Data Flow Example

### Dispatch Assignment Flow

```
1. Admin UI → Creates dispatch
   POST /api/admin/dispatches
   {
     "orderId": 123,
     "driverId": 456,
     "vehicleId": 789
   }

2. Backend → Assigns to driver
   - Creates dispatch record
   - Sends WebSocket notification to driver

3. Driver App → Receives notification
   WebSocket: /topic/driver/456/notifications
   {
     "type": "NEW_DISPATCH",
     "dispatchId": 999,
     "message": "New delivery assigned"
   }

4. Driver → Accepts dispatch
   POST /api/driver/deliveries/999/status
   { "status": "ACCEPTED" }

5. Driver → Starts pickup
   POST /api/driver/location
   { "lat": 11.5564, "lng": 104.9282, "status": "PICKED_UP" }

6. Driver → Delivers & uploads proof
   POST /api/driver/deliveries/999/proof
   { "image": <base64-encoded-photo> }

7. Backend → Updates dispatch status
   - Status: DELIVERED
   - Proof saved
   - Notification sent to customer

8. Customer App → Sees delivery complete
   WebSocket: /topic/customer/789/notifications
   { "type": "DELIVERY_COMPLETE" }
```

---

## 🏗️ App Architecture

### Technology Stack
- **Framework**: Flutter 3.5.4+
- **Language**: Dart ^3.5.4
- **State Management**: Provider (ChangeNotifier)
- **HTTP Client**: http ^1.1.0
- **Secure Storage**: flutter_secure_storage ^9.0.0
- **Maps**: google_maps_flutter ^2.5.0
- **Localization**: easy_localization ^3.0.3
- **Push Notifications**: firebase_messaging ^14.7.3
- **WebSocket**: stomp_dart_client ^2.0.0
- **Image Compression**: flutter_image_compress ^2.1.0

### Project Structure
```
tms_tms_driver_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # Root widget, providers
│   ├── constants/
│   │   └── api_constants.dart       # API URLs, endpoints
│   ├── models/
│   │   ├── driver.dart              # Driver model
│   │   ├── delivery.dart            # Delivery/dispatch model
│   │   └── notification.dart        # Notification model
│   ├── providers/
│   │   ├── user_provider.dart       # Auth state
│   │   ├── dispatch_provider.dart   # Delivery data
│   │   └── notification_provider.dart # Notifications
│   ├── screens/
│   │   ├── login_screen.dart        # Login UI
│   │   ├── dashboard_screen.dart    # Dashboard UI
│   │   ├── delivery_list_screen.dart # Delivery list
│   │   ├── delivery_detail_screen.dart # Delivery detail
│   │   └── profile_screen.dart      # Profile UI
│   ├── services/
│   │   ├── api_service_enhanced.dart # HTTP client
│   │   ├── location_service.dart     # GPS tracking
│   │   ├── notification_service.dart # FCM
│   │   └── websocket_service.dart    # WebSocket STOMP
│   └── widgets/
│       └── custom_button.dart        # Reusable widgets
├── assets/
│   ├── translations/
│   │   ├── en.json                  # English translations
│   │   └── km.json                  # Khmer translations
│   └── images/                      # App images/icons
├── android/                         # Android config
├── ios/                            # iOS config
└── pubspec.yaml                    # Dependencies
```

---

## 🚀 Build & Deployment

### Development Build
```bash
flutter run --flavor dev --dart-define=API_BASE_URL=http://localhost:8080/api
```

### Production Build (Android)
```bash
flutter build apk --flavor prod --release
# Output: build/app/outputs/flutter-apk/app-prod-release.apk
```

### Production Build (iOS)
```bash
flutter build ios --flavor prod --release
# Then archive in Xcode and submit to App Store
```

### App Signing (Android)

1. Generate keystore:
```bash
keytool -genkey -v -keystore ~/sv-driver-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sv-driver
```

2. Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=sv-driver
storeFile=/Users/<username>/sv-driver-key.jks
```

3. Build signed APK:
```bash
flutter build apk --flavor prod --release
```

---

## 📚 Related Documentation

- **Backend API**: [tms-backend/.github/copilot-instructions.md](tms-backend/.github/copilot-instructions.md)
- **Driver App Details**: [tms_tms_driver_app/.github/copilot-instructions.md](tms_tms_driver_app/.github/copilot-instructions.md)
- **Testing Guide**: [tms_tms_driver_app/TESTING_DOCUMENTATION.md](tms_tms_driver_app/TESTING_DOCUMENTATION.md)
- **Data Import**: [data/import/FIRST_DEPLOYMENT_COMPLETE_GUIDE.md](data/import/FIRST_DEPLOYMENT_COMPLETE_GUIDE.md)
- **Customer App**: [CUSTOMER_APP_LOGIN_AND_ITEMS_GUIDE.md](CUSTOMER_APP_LOGIN_AND_ITEMS_GUIDE.md)

---

## ✅ Quick Checklist

### For Admins Creating Driver Accounts:
- [ ] Driver record exists in system
- [ ] Phone number is unique and valid (+855 format)
- [ ] License class matches vehicle type
- [ ] Zone assigned (Zone A, Zone B, etc.)
- [ ] Login account created via Admin UI
- [ ] Username is unique
- [ ] Strong password set (8+ chars, mixed case)
- [ ] Driver can login successfully
- [ ] FCM token registered (check logs)
- [ ] Location tracking enabled

### For Drivers Using App:
- [ ] App installed on device (Android 5.0+ or iOS 11.0+)
- [ ] GPS enabled (High accuracy mode)
- [ ] Location permission granted (Always allow)
- [ ] Notification permission granted
- [ ] Camera permission granted
- [ ] Login credentials received from admin
- [ ] Successfully logged in
- [ ] Dashboard shows assigned deliveries
- [ ] Can accept/reject dispatches
- [ ] Location updates automatically
- [ ] Can upload proof of delivery photos
- [ ] Receives push notifications

---

## 🆘 Support Contacts

**Technical Issues:**
- Backend API: Check logs in `tms-backend/logs/`
- Mobile App: Check console logs with `flutter logs`
- Database: Query `users`, `drivers`, `dispatches` tables

**Documentation:**
- Main guide: This file (`DRIVER_APP_LOGIN_AND_SETUP_GUIDE.md`)
- Testing: `tms_tms_driver_app/TESTING_DOCUMENTATION.md`
- Architecture: `tms_tms_driver_app/ARCHITECTURE.md`

**Quick Commands:**
```bash
# Check driver accounts in database
mysql -u root -p svlogistics_tms -e "SELECT u.id, u.username, u.email, d.first_name, d.last_name, d.phone FROM users u JOIN drivers d ON u.driver_id = d.id WHERE 'DRIVER' IN (SELECT r.role_name FROM user_roles ur JOIN roles r ON ur.role_id = r.id WHERE ur.user_id = u.id);"

# Check backend logs for login attempts
tail -f tms-backend/logs/application.log | grep "driverLogin"

# Check Flutter app logs
cd tms_driver_app
flutter logs | grep -E "(Login|Auth|FCM|Location)"
```

---

**Generated:** 2026-01-22  
**Version:** 1.0  
**Status:** ✅ Ready for use (except driver login bug)

**Known Blockers:**
- 🔴 Driver login endpoint bug (tracking in TESTING_DOCUMENTATION.md)
- All other features tested and working
