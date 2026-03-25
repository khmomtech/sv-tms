> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Profile Screen Not Showing New UI - SOLUTION

## Problem
The profile screen is showing:
- ❌ Old "មិនមានព័ត៌មាន" (no data) message
- ❌ Green button at bottom (old logout button)
- ❌ None of the new UI (performance card, documents grid, settings menu)

## Root Causes

### 1. Hot Reload Issue
**Major structural changes require HOT RESTART**, not hot reload:
- Changed widget tree structure significantly
- Removed/added multiple sections
- Modified state initialization

### 2. Profile Data Not Loading
The `driverProvider.driverProfile` is `null`, which could be caused by:
- Backend not running at 192.168.0.33:8080
- API authentication failing
- Driver ID not stored in SharedPreferences
- Network connectivity issues

## IMMEDIATE FIX

### Step 1: Hot Restart the App

**In VS Code Terminal (where flutter run is active):**

1. Press `R` (capital R) for **HOT RESTART**
   - **NOT** `r` (lowercase) which is hot reload
   
2. Or run this command in terminal:
   ```bash
   cd tms_driver_app
   flutter run
   ```
   Then press `R` when app is running

**Expected Result:**
- App will fully restart
- New UI structure will load
- You'll see the new profile card, performance summary, documents grid, settings menu

### Step 2: Check Backend Connection

**Verify backend is running:**
```bash
cd driver-app
./mvnw spring-boot:run
```

**Expected console output:**
```
Started DriverAppApplication in X.XXX seconds
```

**Test API manually:**
```bash
# Replace with your actual access token
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://192.168.0.33:8080/admin/drivers/72
```

### Step 3: Check Driver Session

The app might not have driver ID stored. Check terminal logs for:
```
[DriverProvider] No driver ID found; cannot initialize session
```

If you see this, you need to **login again** to store the driver ID.

## Detailed Troubleshooting

### Check 1: Verify Flutter is Running

In the terminal where you ran `flutter run`, you should see:
```
Application finished.
```

If app is still running, press:
- `R` - Hot restart (USE THIS!)
- `r` - Hot reload (doesn't work for structural changes)
- `q` - Quit

### Check 2: Check Terminal Logs

Look for these errors:

**Network Error:**
```
Failed to load profile: SocketException: Failed to connect to 192.168.0.33:8080
```
**Solution:** Start backend or update IP in ApiConstants

**Auth Error:**
```
Failed to load profile: Response status: 401
```
**Solution:** Login again to refresh token

**No Driver ID:**
```
[DriverProvider] No driver ID found
```
**Solution:** Login again

### Check 3: Profile Data Loading

After hot restart, watch the terminal for:

**Success:**
```
[DriverProvider] fetchDriverProfile: fetching for driver 72
[DriverProvider] fetchDriverProfile: success
```

**Failure:**
```
[DriverProvider] fetchDriverProfile: Error: ...
```

## Expected UI After Fix

### Correct UI Should Show:

1. **Header**
   - ប្រវត្តិរូប
   - Smart Truck Driver Profile
   - Menu button (⋮)

2. **Profile Card**
   - Circular avatar with "SK" or photo
   - Name: "Sotheakh KHET"
   - Driver ID: DR-10238 • Tel: 012 345 678
   - 🟢 Online badge
   - 🚚 Main Driver badge
   - Two buttons: កំណត់ | គ្រប់គ្រង

3. **Performance Summary Card**
   - សេចក្តីសង្ខេបសមត្ថភាពក្រុបក្រុចំខែ
   - Score: 92/100 (green)
   - 🏆 Gold Rank badge (top-right)
   - Stats: 4.9, 98%, Excellent
   - Progress bar

4. **Vehicle Section**
   - រថយន្តដែលត្រូវប្រើ / Assigned Vehicle
   - Truck icon with details

5. **Documents Grid (2x2)**
   - បណ្ណបើក, អត្តសញ្ញាណបណ្ណ
   - វិញ្ញាបនបណ្ណ, កិត្តិសញ្ញា

6. **Settings Menu (6 items)**
   - Account Settings
   - Change Password
   - Reports & History
   - Contact Admin
   - App Information
   - 🚪 Logout (red)

## Quick Commands

### Force Complete Restart:
```bash
# Stop current flutter run (press 'q' in terminal)
cd /Users/sotheakh/Documents/develop/sv-tms/driver_app
flutter clean
flutter pub get
flutter run
```

### Check Backend Status:
```bash
# In another terminal
cd /Users/sotheakh/Documents/develop/sv-tms/driver-app
./mvnw spring-boot:run
```

### View Real-time Logs:
```bash
# While app is running, watch for errors
# Terminal will show API calls, errors, debug prints
```

## Still Not Working?

### Nuclear Option - Clean Rebuild:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/driver_app

# 1. Stop flutter run (press 'q')

# 2. Clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock
rm -rf .dart_tool

# 3. Reinstall
flutter pub get
cd ios && pod install && cd ..

# 4. Run again
flutter run
```

### Check Code Changes Applied:

Search in terminal output after hot restart for:
```
Restarted application
```

If you see `Reloaded` instead, press `R` again (capital R).

## Summary

### TL;DR - Do This Now:

1. **In the terminal running Flutter:**
   - Press `R` (capital R) for hot restart
   - Wait for "Restarted application"

2. **Check backend is running:**
   - Terminal: `cd driver-app && ./mvnw spring-boot:run`

3. **Pull to refresh** in app:
   - Swipe down on profile screen
   - Should load data and show new UI

### Expected Timeline:
- Hot restart: 5-10 seconds
- Backend start: 20-30 seconds
- Data load: 1-2 seconds

### Success Indicators:
New UI visible (performance card, documents grid, settings)
Profile data shows (name, ID, status)
No "profile_not_found" message
Green refresh button replaced with settings menu

---

**If still having issues after hot restart, check:**
1. Terminal logs for specific errors
2. Backend console for API errors
3. Network connectivity (ping 192.168.0.33)
