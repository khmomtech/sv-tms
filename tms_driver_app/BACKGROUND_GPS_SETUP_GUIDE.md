# 📍 Background GPS Tracking Setup Guide

## ✅ Current Status

Your app **already has a complete background GPS tracking system** with:

- ✅ Android Foreground Service (survives app closure)
- ✅ Boot receiver (auto-starts on device boot)
- ✅ Lifecycle hooks (restarts on app resume)
- ✅ Offline queue (stores data when offline)
- ✅ REST API fallback (HTTP POST every 15 seconds)
- ✅ Battery optimization handling
- ✅ Network connectivity monitoring

## 🔧 Configuration Steps

### 1️⃣ **Ensure Service Starts on Login**

Add this to `sign_in_provider.dart` after successful login (around line 350):

```dart
// After userProvider.login() call
userProvider.login(userId, email, accessToken, roles);

// 🆕 START BACKGROUND GPS SERVICE
await NativeServiceBridge.startServiceOnce(
  token: accessToken,
  driverId: driverId,
);
debugPrint('[SignIn] Background GPS service started for driver: $driverId');

await TopicSubscriptionService().subscribeToDynamicTopics();
```

### 2️⃣ **User Permissions Required**

The driver must grant these permissions **in order**:

#### A. **Location While Using App** (First)

```dart
// Already requested in app - check permissions_screen.dart
await Permission.location.request();
```

#### B. **Background Location** (Second - Critical!)

```dart
// Android 10+ requires this for background tracking
await Permission.locationAlways.request();
```

#### C. **Disable Battery Optimization** (Third)

```dart
// Prevents Android from killing the service
await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
```

### 3️⃣ **Test the Setup**

#### **Test 1: Service Running Check**

```bash
# After driver logs in, run this in terminal:
adb shell dumpsys activity services | grep LocationService
```

Expected output:

```
ServiceRecord{...} com.svtrucking.svdriverapp/.LocationService
```

#### **Test 2: Location Updates**

```bash
# Watch logcat for location updates
adb logcat | grep "LocationService"
```

Expected output every ~15 seconds:

```
I/LocationService: 📍 Sending location: lat=13.xxx, lng=104.xxx
I/LocationService: ✅ Location sent via REST: 200
```

#### **Test 3: Survive App Kill**

1. Login as driver
2. Go to Home screen
3. Kill app: `Settings → Apps → Smart Truck Driver → Force Stop`
4. Check service still running:
   ```bash
   adb shell dumpsys activity services | grep LocationService
   ```
5. **Expected:** Service should STILL be running (Foreground Service survives app kill)

#### **Test 4: Survive Device Reboot**

1. Login as driver
2. Reboot device
3. After boot completes (wait 30 seconds)
4. Check service auto-started:
   ```bash
   adb logcat -d | grep "BootCompletedReceiver"
   ```
5. **Expected:** `BootCompletedReceiver: Scheduled LocationService start`

### 4️⃣ **Backend Verification**

Check if backend receives GPS data:

```bash
# Watch backend logs
cd tms-backend
./mvnw spring-boot:run

# Look for driver location updates
tail -f logs/app.log | grep "driver.*location"
```

Expected backend logs:

```
POST /api/driver/{driverId}/location - 200 OK
Received location: driverId=123, lat=13.xxx, lng=104.xxx, accuracy=15.0m
```

### 5️⃣ **Common Issues & Fixes**

#### ❌ **Issue 1: Service Stops After App Kill**

**Cause:** Battery optimization enabled  
**Fix:**

```dart
// Request battery whitelist in permissions_screen.dart
await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
```

**Manual Fix:**

- `Settings → Apps → Smart Truck Driver`
- `Battery → Unrestricted`

#### ❌ **Issue 2: No Background Location**

**Cause:** `ACCESS_BACKGROUND_LOCATION` permission not granted  
**Fix:**

1. `Settings → Apps → Smart Truck Driver → Permissions → Location`
2. Choose: **"Allow all the time"** (not "While using the app")

**Code Check:**

```dart
// In main.dart or permissions_screen.dart
final bgStatus = await Permission.locationAlways.status;
if (!bgStatus.isGranted) {
  await Permission.locationAlways.request();
}
```

#### ❌ **Issue 3: Service Doesn't Start on Login**

**Cause:** Missing auto-start call in sign-in flow  
**Fix:** Add the code from **Step 1** above

#### ❌ **Issue 4: "Too many unauthorized errors" (WebSocket 401)**

**Cause:** Token expired before service start  
**Fix:** Service now uses **REST API fallback** (HTTP POST). Check these files:

- `LocationService.kt` line ~540: `postLocationRest()`
- Endpoint: `POST /api/driver/{driverId}/location`

**Verify REST fallback is working:**

```bash
adb logcat | grep "postLocationRest"
```

Expected:

```
D/LocationService: 📍 postLocationRest: POST http://192.168.1.8:8080/api/driver/123/location
I/LocationService: ✅ REST response: 200
```

#### ❌ **Issue 5: Device-Specific Battery Savers**

Some manufacturers aggressively kill background services:

**Xiaomi/MIUI:**

- `Settings → Battery & Performance → Manage apps' battery usage`
- Find app → `No restrictions`
- `Settings → App permissions → Autostart` → Enable

**Huawei/EMUI:**

- `Settings → Battery → App launch`
- Find app → `Manage manually`
- Enable all options

**Samsung/One UI:**

- `Settings → Apps → Smart Truck Driver`
- `Battery → Unrestricted`
- `Settings → Device care → Battery → Background usage limits`
- Remove app from list

**Oppo/ColorOS:**

- `Settings → Battery → App Battery Management`
- Disable for app

### 6️⃣ **Production Checklist**

Before releasing to drivers:

- [ ] Battery optimization dialog shown on first launch
- [ ] Background location permission requested (not just foreground)
- [ ] Service starts automatically on login
- [ ] Service survives app force-stop (test on 3+ devices)
- [ ] Service auto-starts on device boot
- [ ] Offline queue tested (turn off WiFi, kill app, reboot)
- [ ] Backend receives location every 15 seconds
- [ ] Driver can see their own location on map
- [ ] Notification shows "Tracking active" when service running

### 7️⃣ **Monitoring in Production**

#### **Backend Monitoring**

```sql
-- Check last location update time per driver
SELECT
  d.id,
  d.first_name,
  d.last_name,
  d.last_location_at,
  TIMESTAMPDIFF(MINUTE, d.last_location_at, NOW()) as minutes_since_last_update
FROM drivers d
WHERE d.status = 'ACTIVE'
ORDER BY minutes_since_last_update DESC;
```

**Alert if:** `minutes_since_last_update > 5` (service may be down)

#### **App-Side Monitoring**

Add health check to `DriverProvider`:

```dart
Future<void> checkLocationServiceHealth() async {
  final running = await NativeServiceBridge.isServiceRunning();
  if (!running) {
    debugPrint('🚨 Location service is DOWN! Attempting restart...');
    await NativeServiceBridge.startServiceOnce();
  }
}

// Call periodically in driver_provider.dart init()
Timer.periodic(Duration(minutes: 5), (_) => checkLocationServiceHealth());
```

## 🎯 Expected Behavior

✅ **When Working Correctly:**

1. Driver logs in → Service starts automatically
2. Driver closes app → Service keeps running (notification visible)
3. Driver kills app → Service survives (Android Foreground Service)
4. Device reboots → Service auto-starts after boot
5. Network drops → Locations queued, sent when back online
6. Token expires → Service refreshes token automatically
7. Backend sees location updates every 15 seconds

## 📊 Performance Tuning

### Battery vs Accuracy Trade-offs

Current settings (optimized for balance):

```kotlin
// LocationService.kt
private val LOCATION_UPDATE_INTERVAL_MS = 15_000L  // 15 seconds
private val CLIENT_MIN_TIME_MS = 6_000L            // Min time between sends
private val CLIENT_MIN_DIST_M  = 15.0              // Min distance (meters)
```

**For Better Battery:**

```kotlin
private val LOCATION_UPDATE_INTERVAL_MS = 30_000L  // 30 seconds
private val CLIENT_MIN_DIST_M  = 50.0              // 50 meters
```

**For Better Accuracy:**

```kotlin
private val LOCATION_UPDATE_INTERVAL_MS = 10_000L  // 10 seconds
private val CLIENT_MIN_DIST_M  = 10.0              // 10 meters
```

## 🔍 Debug Commands

```bash
# Check service running
adb shell dumpsys activity services com.svtrucking.svdriverapp

# Check permissions
adb shell dumpsys package com.svtrucking.svdriverapp | grep permission

# Check battery whitelist
adb shell dumpsys deviceidle whitelist | grep svtrucking

# Force stop app (test service survives)
adb shell am force-stop com.svtrucking.svdriverapp

# Restart service manually
adb shell am startservice -n com.svtrucking.svdriverapp/.LocationService \
  -a com.svtrucking.svdriverapp.ACTION_START_LOCATION

# Watch real-time logs
adb logcat -s LocationService:* MainActivity:* NativeServiceBridge:*
```

## 📝 Quick Reference

| Feature              | Status              | File                              |
| -------------------- | ------------------- | --------------------------------- |
| Foreground Service   | ✅ Implemented      | `LocationService.kt`              |
| Boot Receiver        | ✅ Implemented      | `BootCompletedReceiver.kt`        |
| Battery Opt Handling | ✅ Implemented      | `BatteryOptimizationService.dart` |
| Offline Queue        | ✅ Implemented      | `LocationService.kt` line 118-125 |
| REST Fallback        | ✅ Implemented      | `LocationService.kt` line ~540    |
| Token Refresh        | ✅ Implemented      | `ApiConstants.dart` line 497      |
| Auto-start on Login  | ⚠️ **NEEDS ADDING** | `sign_in_provider.dart`           |
| Health Monitoring    | ⚠️ **Optional**     | `driver_provider.dart`            |

## 🚀 Next Steps

1. **Add service start to login flow** (see Step 1 above)
2. **Test on 3+ physical devices** (different manufacturers)
3. **Monitor backend for continuous location updates**
4. **Document device-specific settings for drivers** (printable guide)
5. **Set up alerting for drivers offline > 10 minutes**

---

**Need Help?** Check logs with: `adb logcat | grep -E "LocationService|NativeServiceBridge|DriverProvider"`
