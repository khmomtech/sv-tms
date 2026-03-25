# 📱 Driver App - Permission Setup Guide

## Required Permissions for GPS Tracking

To ensure the app can track your location even when closed, you need to grant these permissions:

---

## Step 1: Location Permission ✅

### When Prompted:

1. App will ask: **"Allow Smart Truck Driver to access this device's location?"**
2. **Select:** "While using the app"
3. **Tap:** "Allow"

---

## Step 2: Background Location Permission ✅✅

### When Prompted:

1. App will ask: **"Allow Smart Truck Driver to access your location all the time?"**
2. This is **REQUIRED** for tracking to work when app is closed
3. **Select:** "Allow all the time" (NOT "While using the app")
4. **Tap:** "Allow"

### If You Missed It:

1. Open phone **Settings**
2. Go to **Apps** → **Smart Truck Driver**
3. Tap **Permissions** → **Location**
4. Select: **"Allow all the time"**

---

## Step 3: Battery Optimization ✅✅✅

### Why?

Without this, Android will kill the tracking service to save battery.

### Setup:

1. App will show a prompt about battery optimization
2. **Tap:** "Settings"
3. Find **Smart Truck Driver** in the list
4. **Tap** on it
5. Select: **"Don't optimize"** or **"Allow"**
6. **Tap:** "Done"

### Manual Setup (if you missed the prompt):

1. Open phone **Settings**
2. Go to **Apps** → **Smart Truck Driver**
3. Tap **Battery** → **Battery optimization**
4. Select: **"Don't optimize"** or **"Unrestricted"**

---

## Device-Specific Settings

### Samsung Phones

1. **Settings** → **Apps** → **Smart Truck Driver**
2. **Battery** → **Background usage limits**
3. Ensure app is **NOT** in the restricted list
4. **Settings** → **Device care** → **Battery**
5. **App power management** → **Apps that won't be put to sleep**
6. Add **Smart Truck Driver**

### Xiaomi/MIUI Phones

1. **Settings** → **Apps** → **Manage apps**
2. Find **Smart Truck Driver**
3. **Battery saver** → **No restrictions**
4. **Autostart** → **Enable**
5. **Settings** → **Battery & performance**
6. **Choose apps** → Find **Smart Truck Driver** → **No restrictions**

### Huawei Phones

1. **Settings** → **Apps** → **Apps** → **Smart Truck Driver**
2. **Battery** → **App launch**
3. Toggle OFF automatic management
4. Enable:
   - Auto-launch
   - Secondary launch
   - Run in background

### Oppo/Realme Phones

1. **Settings** → **Battery** → **Smart Truck Driver**
2. Select: **"Don't optimize"**
3. **Settings** → **Additional settings** → **Privacy**
4. **App auto-start** → Enable for **Smart Truck Driver**

---

## How to Verify It's Working

### ✅ Check 1: Notification

You should see a persistent notification:

- **Title:** "Tracking Active" or "Smart Truck Driver"
- **Message:** "Location tracking is active"
- This notification **cannot be dismissed** (this is normal for tracking apps)

### ✅ Check 2: After Login

1. Login to the app
2. Look for the GPS icon on the Dashboard
3. It should show: **"GPS Active"** or **"Tracking"**

### ✅ Check 3: Close App Test

1. Press the **Home** button
2. Wait 2 minutes
3. Open the notification panel
4. The tracking notification should still be visible
5. ✅ **If visible:** Tracking is working!
6. ❌ **If gone:** Check battery optimization settings above

### ✅ Check 4: Reboot Test

1. Restart your phone
2. Wait 1 minute after boot completes
3. Check notifications for "Tracking Active"
4. ✅ **If visible:** Auto-start is working!

---

## Common Issues

### ❌ "Location not tracking"

**Solution:**

1. Open app **Settings** inside the driver app
2. Check GPS status shows "Active" or "Connected"
3. If not, logout and login again
4. Grant all permissions again

### ❌ "Tracking stops when I close the app"

**Solution:**

1. Check battery optimization is disabled (Step 3 above)
2. Check background location is "Allow all the time" (Step 2)
3. For Samsung/Xiaomi: Check device-specific settings

### ❌ "No GPS notification showing"

**Solution:**

1. Logout from the app
2. Login again
3. Grant all permissions when prompted
4. Notification should appear within 10 seconds

### ❌ "Tracking stops after few hours"

**Solution:**

1. Your phone is aggressively killing background apps
2. Check device-specific settings (Samsung, Xiaomi, Huawei, Oppo sections above)
3. Ensure app is in "Don't optimize" or "No restrictions" list
4. Enable "Autostart" if your phone has this setting

---

## Important Notes

📌 **Notification Cannot Be Dismissed**

- The "Tracking Active" notification is **REQUIRED** by Android
- It ensures the tracking service stays alive
- Dismissing it will **STOP** tracking
- This is normal for GPS tracking apps

📌 **Battery Impact**

- GPS tracking uses battery (approximately 5-10% per day)
- Make sure phone is charged before shift
- Consider car charger for long shifts

📌 **Data Usage**

- App sends location every 15 seconds
- Uses approximately 5-10 MB per day
- Works on WiFi or mobile data
- Locations are queued if offline and sent when connection returns

📌 **Privacy**

- Location is only tracked when you are logged in
- Logout stops all tracking
- Your location is only visible to dispatchers, not other drivers

---

## Need Help?

Contact your fleet manager or IT support if:

- Tracking keeps stopping
- Permissions keep resetting
- Notification doesn't appear after login
- GPS shows "Disconnected" constantly

---

**Last Updated:** March 2026  
**App Version:** 1.0.0  
**Supported Android:** 8.0 and above
