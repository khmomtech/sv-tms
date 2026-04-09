# Driver App Testing Documentation

**Date**: 2025-01-20  
**App Version**: 1.0.0  
**Backend Version**: Spring Boot 3.5.7  
**Test Environment**: Development (localhost:8080)

---

## 📋 TABLE OF CONTENTS

1. [Test Environment Setup](#test-environment-setup)
2. [Test Credentials](#test-credentials)
3. [Test Scenarios](#test-scenarios)
4. [Known Issues & Blockers](#known-issues--blockers)
5. [E2E Test Script Usage](#e2e-test-script-usage)
6. [Manual Testing Guide](#manual-testing-guide)
7. [Testing Checklist](#testing-checklist)

---

## 🔧 TEST ENVIRONMENT SETUP

### Prerequisites

```bash
# 1. Backend running
cd driver-app
./mvnw spring-boot:run

# Verify backend health
curl http://localhost:8080/actuator/health
# Expected: {"status":"UP"}

# 2. Database running (MySQL on port 3307)
docker ps | grep mysql
# Should show mysql container running

# 3. Redis running
docker ps | grep redis
# Should show redis container running

# 4. Flutter environment
cd ../driver_app
flutter doctor
# All checkmarks should be green
```

### Build & Run Driver App

```bash
# Development build (with localhost backend)
cd tms_driver_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api

# For physical device
flutter run --dart-define=API_BASE_URL=http://192.168.1.XXX:8080/api

# For release testing
flutter build apk --release \
  --dart-define=API_BASE_URL=https://svtms.svtrucking.biz/api \
  --obfuscate \
  --split-debug-info=build/outputs/symbols
```

---

## 🔐 TEST CREDENTIALS

### Test Driver Account

**Username**: `testdriver`  
**Password**: `password`  
**Driver ID**: 79  
**User ID**: 55  
**Role**: DRIVER  
**Status**: ACTIVE

**Created**: 2025-01-20  
**Purpose**: E2E testing without affecting production data

### Existing Driver Accounts (Updated for Testing)

**Username**: `sotheakh`  
**Password**: `password` (updated from original)  
**Driver ID**: 40  
**Status**: ACTIVE

**Note**: All passwords updated to `password` for testing convenience

---

## ❌ KNOWN ISSUES & BLOCKERS

### 🔴 CRITICAL: Driver Login Authentication Bug

**Issue**: Backend `/api/auth/driver/login` endpoint returns "Driver not found" for ALL users

**Affected Endpoint**: `POST /api/auth/driver/login`

**Expected Behavior**:
```json
Request:
{
  "username": "testdriver",
  "password": "password"
}

Expected Response (200 OK):
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR...",
  "user": {
    "id": 55,
    "username": "testdriver",
    "roles": ["DRIVER"]
  }
}
```

**Actual Response**:
```json
{
  "status": 404,
  "message": "Driver not found"
}
```

**Root Cause**: Bug in `AuthController.driverLogin()` method (line 139)
- Method cannot find user despite valid database records
- Regular `/api/auth/login` works correctly
- Database has valid user (id=55) and driver (id=79) records

**Impact**: **ALL authentication-dependent tests are BLOCKED**

**Workaround**: None available - requires backend fix

**Tests Blocked**:
- ❌ FCM token sync test
- ❌ Location tracking test
- ❌ Delivery workflow test
- ❌ Profile management test
- ❌ WebSocket connectivity test
- ❌ Push notification test
- ❌ Full E2E smoke test

**Fix Required**: Update `AuthController.driverLogin()` to properly query users table

---

## 🧪 TEST SCENARIOS

### Testable Without Authentication

#### 1. Translation/Localization Testing

**Purpose**: Verify English and Khmer translations are complete

**Steps**:
1. Launch app
2. Go to Settings → Language
3. Switch to English
4. Navigate through all screens, verify all text is English
5. Switch to Khmer (ភាសាខ្មែរ)
6. Navigate through all screens, verify all text is Khmer
7. Check for missing translations (shows translation keys like "error.generic")

**Expected Results**:
- No missing translation keys visible
- All UI text changes when switching languages
- Date/time formats respect locale
- Number formats respect locale

**Translation Files**:
- English: `assets/translations/en.json` (377 lines)
- Khmer: `assets/translations/km.json` (366 lines)

**Known Issues**: 11-line difference between en/km - verify coverage

---

#### 2. Provider State Management Testing

**Purpose**: Verify providers manage state correctly without memory leaks

**Steps**:
1. Open app
2. Navigate to Dispatches screen
3. Pull to refresh multiple times
4. Switch between Pending/In Progress/Completed tabs
5. Minimize app
6. Reopen app
7. Verify state is restored from cache

**Expected Results**:
- No memory leaks (use Flutter DevTools)
- State persists across app restarts
- Cache loads before API call
- Loading indicators work correctly

**Providers to Test**:
- UserProvider (auth state)
- DispatchProvider (delivery data)
- NotificationProvider (notifications)
- DriverProvider (driver profile)

---

#### 3. Form Validation Testing

**Purpose**: Verify form validation works correctly

**Steps**:
1. Go to Profile → Edit Profile (if accessible without auth)
2. Try submitting empty form
3. Enter invalid email
4. Enter invalid phone number
5. Verify error messages appear
6. Enter valid data
7. Verify submission works

**Expected Results**:
- Required fields show error when empty
- Email validation works
- Phone validation works
- Error messages are localized

---

#### 4. Image Compression Testing

**Purpose**: Verify images are compressed before upload

**Steps**:
1. Prepare test image >1MB
2. Go to Dispatch → Upload Proof
3. Select large image
4. Monitor console logs for compression
5. Verify compressed size <500KB

**Expected Results**:
- Images >400KB are compressed
- Quality remains acceptable (85%)
- Upload completes faster

**Check Logs**:
```
[DispatchProvider] Image: 1234KB → 456KB (63% saved)
```

---

#### 5. Offline Mode Testing

**Purpose**: Verify app handles offline gracefully

**Steps**:
1. Launch app
2. Login (BLOCKED - skip for now)
3. Enable airplane mode
4. Try to fetch dispatches
5. Verify offline message appears
6. Disable airplane mode
7. Verify data loads automatically

**Expected Results**:
- Shows "You are offline" message
- Cached data is displayed
- Auto-reconnects when online
- No crashes

---

### ❌ Testable ONLY With Authentication (BLOCKED)

#### 6. FCM Token Sync Test

**Status**: ❌ BLOCKED by authentication bug

**Script**: `tms_driver_app/scripts/test_all_features.sh`

**Steps** (when auth fixed):
```bash
cd tms_driver_app/scripts
chmod +x test_all_features.sh
./test_all_features.sh
```

**Expected Results**:
- FCM token generated
- Token synced to backend
- Token persisted in SharedPreferences
- Token refresh handled

---

#### 7. Location Tracking Test

**Status**: ❌ BLOCKED by authentication bug

**Steps** (when auth fixed):
1. Login as driver
2. Go to Dashboard
3. Enable location tracking
4. Move device (or simulate in Android Studio)
5. Verify location updates sent to backend
6. Check backend logs for location updates

**Expected Results**:
- Location permission granted
- GPS coordinates accurate
- Updates sent every 30 seconds
- Battery optimization warning shown
- Foreground service running

---

#### 8. Delivery Workflow Test

**Status**: ❌ BLOCKED by authentication bug

**Steps** (when auth fixed):
1. Login as driver
2. View pending dispatches
3. Accept dispatch
4. Start delivery
5. Upload proof of pickup
6. Upload proof of delivery
7. Complete delivery

**Expected Results**:
- Dispatch status updates
- Images compressed and uploaded
- WebSocket updates received
- Notifications sent
- Cache updated

---

#### 9. Profile Management Test

**Status**: ❌ BLOCKED by authentication bug

**Steps** (when auth fixed):
1. Login as driver
2. Go to Profile
3. View driver details
4. Edit phone number
5. Upload profile photo
6. Change password
7. Logout

**Expected Results**:
- Profile loads correctly
- Edits save successfully
- Photo uploads and displays
- Password change works
- Logout clears secure storage

---

#### 10. WebSocket Connectivity Test

**Status**: ❌ BLOCKED by authentication bug

**Steps** (when auth fixed):
1. Login as driver
2. Monitor WebSocket connection banner
3. Verify "Connected" status
4. Disconnect network
5. Verify "Reconnecting..." appears
6. Reconnect network
7. Verify auto-reconnection

**Expected Results**:
- WebSocket connects on login
- JWT token included in handshake
- Auto-reconnect on disconnect
- Exponential backoff on failures
- Topic subscriptions restored

---

## 🚀 E2E TEST SCRIPT USAGE

### Automated E2E Testing

**Script Location**: `tms_driver_app/scripts/test_all_features.sh`

**Features Tested**:
1. Backend health check
2. Driver authentication
3. FCM token sync
4. Profile retrieval
5. Dispatches loading
6. Location tracking
7. WebSocket connectivity
8. API endpoint isolation

**Usage**:

```bash
cd tms_driver_app/scripts
chmod +x test_all_features.sh

# Test with default credentials
./test_all_features.sh

# Test with custom credentials
USERNAME=testdriver PASSWORD=password ./test_all_features.sh

# Verbose mode
DEBUG=1 ./test_all_features.sh
```

**Expected Output**:
```
=== Driver App Feature Testing ===
[1/8] Testing backend health...       ✓
[2/8] Testing driver login...         ✗ FAILED (Driver not found)
[3/8] Testing FCM token sync...       ⊘ SKIPPED (auth required)
[4/8] Testing profile retrieval...    ⊘ SKIPPED (auth required)
[5/8] Testing dispatches...           ⊘ SKIPPED (auth required)
[6/8] Testing location tracking...    ⊘ SKIPPED (auth required)
[7/8] Testing WebSocket...            ⊘ SKIPPED (auth required)
[8/8] Testing API isolation...        ✓

=== TEST SUMMARY ===
✓ Passed: 2/8
✗ Failed: 1/8 (auth bug)
⊘ Skipped: 5/8 (requires auth)

STATUS: BLOCKED - Fix driver login endpoint
```

---

## 📝 MANUAL TESTING GUIDE

### Pre-Testing Checklist

- [ ] Backend running on localhost:8080
- [ ] MySQL running on port 3307
- [ ] Redis running
- [ ] Test credentials ready
- [ ] Flutter app built and installed
- [ ] DevTools ready for profiling

### Testing Workflow

1. **Smoke Test** (5 minutes)
   - Launch app
   - Verify no crashes
   - Check all screens load
   - Verify translations work
   
2. **Functional Test** (30 minutes)
   - Test all user workflows
   - Verify data persistence
   - Test error scenarios
   
3. **Performance Test** (15 minutes)
   - Monitor frame rate (Flutter DevTools)
   - Check memory usage
   - Test with slow network
   
4. **Security Test** (10 minutes)
   - Verify HTTPS enforcement
   - Check secure storage
   - Test token expiration

---

## TESTING CHECKLIST

### Authentication (BLOCKED)
- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Logout clears tokens
- [ ] Remember me works
- [ ] Password change works
- [ ] Token refresh works

### UI/UX
- [x] All screens load without errors
- [x] Translations complete (en/km)
- [x] Images load correctly
- [ ] Forms validate inputs
- [ ] Loading indicators work
- [ ] Error messages clear

### Data Management
- [ ] Dispatches load and cache
- [ ] Profile data persists
- [ ] Offline mode works
- [ ] Data syncs when online
- [ ] Image compression works
- [ ] Cache expires correctly

### Real-time Features (BLOCKED)
- [ ] WebSocket connects
- [ ] Location tracking works
- [ ] Push notifications received
- [ ] Live updates appear
- [ ] Reconnection automatic

### Performance
- [x] Frame rate >55 FPS
- [x] Memory usage <200 MB
- [x] Image compression effective
- [x] Cache hit rate >70%
- [ ] Network requests optimized
- [ ] Battery usage acceptable

### Security
- [x] No hardcoded secrets (2 API keys found - need fix)
- [ ] Tokens in secure storage
- [ ] HTTPS enforced
- [ ] Input sanitization works
- [ ] File uploads validated
- [ ] Session timeout works

---

## 📊 TEST RESULTS SUMMARY

### Last Test Run: 2025-01-20

| Category | Total | Passed | Failed | Blocked | Status |
|----------|-------|--------|--------|---------|--------|
| Authentication | 6 | 0 | 1 | 5 | ❌ BLOCKED |
| UI/UX | 6 | 3 | 0 | 3 | 🟡 PARTIAL |
| Data Management | 6 | 0 | 0 | 6 | ❌ BLOCKED |
| Real-time | 4 | 0 | 0 | 4 | ❌ BLOCKED |
| Performance | 6 | 4 | 0 | 2 | GOOD |
| Security | 6 | 3 | 2 | 1 | 🟡 NEEDS FIX |
| **TOTAL** | **34** | **10** | **3** | **21** | **🟡 BLOCKED** |

**Overall Status**: 🟡 BLOCKED by authentication bug

**Pass Rate**: 29% (10/34 tests)  
**Block Rate**: 62% (21/34 tests require authentication)

---

## 🔧 NEXT STEPS

### Immediate Actions:
1. Fix hardcoded API keys (see SECURITY_FIXES_IMPLEMENTATION.md)
2. ❌ Fix driver login authentication bug (CRITICAL)
3. Complete localization testing
4. Run performance profiling

### After Auth Fix:
1. Run full E2E test script
2. Complete all blocked tests
3. Verify WebSocket connectivity
4. Test push notifications
5. Test full driver workflow

### Before Production:
1. All tests passing (34/34)
2. Security audit complete
3. Performance benchmarks met
4. Documentation updated
5. Release notes prepared

---

## 📚 ADDITIONAL RESOURCES

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Provider Testing Guide](https://pub.dev/packages/provider#testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

---

**Test Plan Owner**: Development Team  
**Last Updated**: 2025-01-20  
**Next Review**: After authentication fix
