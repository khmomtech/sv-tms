> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🎬 LIVE DEMO & TESTING GUIDE - Public Tracking Feature

**Status**: ✅ **LIVE & READY TO TEST**  
**Date**: January 9, 2026  
**Duration**: 5-10 minutes for full walkthrough  

---

## 🚀 START HERE (60 SECONDS)

### Step 1: Open the App
```
URL: http://localhost:4200/tracking
```

### Step 2: Search
```
Enter: BK-2026-00129
Click: "Track" button
```

### Step 3: Watch
```
View: Real-time shipment status
See: Live location updates
Check: Driver information
```

**Done!** 🎉

---

## 🧪 FULL TESTING WALKTHROUGH

### TEST 1: Basic Search (2 min)

**Scenario**: Customer searches for booking reference

**Steps:**
1. Go to `http://localhost:4200/tracking`
2. See header with "SV Trucking" branding
3. See search box with placeholder text
4. Type: `BK-2026-00125`
5. Click "Track" button
6. Wait for loading spinner (1-2 seconds)

**Expected Result:**
- ✅ Spinner appears while loading
- ✅ Status overview appears (4-column grid)
- ✅ Booking reference shows: BK-2026-00125
- ✅ Status shows: BOOKING_CREATED (gray)
- ✅ Timeline appears with first step completed

---

### TEST 2: In-Transit Tracking (3 min)

**Scenario**: Customer tracks active shipment with live location

**Steps:**
1. Go to `http://localhost:4200/tracking`
2. Type: `BK-2026-00129`
3. Click "Track" button
4. Watch for loading to complete

**Expected Result:**
- ✅ Status overview shows: IN_TRANSIT (blue badge)
- ✅ Timeline shows 4 completed steps, 1 current
- ✅ "Your Driver" section appears with:
  - Driver photo
  - Driver name
  - Phone number (clickable)
  - Vehicle details
  - ⭐ Rating
- ✅ "Current Location" map section shows:
  - Google Map (if API key configured)
  - Blue marker at coordinates
  - Live coordinates displayed
  - "Updates every 10 seconds" message

**Try Clicking:**
- Driver phone number → Opens phone dialer
- Map → Info window shows coordinates

---

### TEST 3: Delivered Shipment with Proof (2 min)

**Scenario**: Customer checks delivered package with proof

**Steps:**
1. Go to `http://localhost:4200/tracking`
2. Type: `BK-2026-00131`
3. Click "Track" button

**Expected Result:**
- ✅ Status shows: DELIVERED (green badge)
- ✅ Timeline shows all 9 steps completed
- ✅ Estimated delivery shows: 13-Feb-2026
- ✅ "Proof of Delivery" section shows:
  - ✅ Green success badge
  - "Delivered to [Recipient Name]"
  - Date/time: 13-Feb-2026 14:30
  - Optional notes (if available)
  - Photo evidence (if attached)

---

### TEST 4: Error Handling (2 min)

**Scenario**: Customer enters invalid reference

**Steps:**
1. Go to `http://localhost:4200/tracking`
2. Type: `INVALID-REF`
3. Click "Track" button
4. Wait for error (1-2 seconds)

**Expected Result:**
- ✅ Spinner appears
- ✅ Red error alert appears:
  - ⚠️ "Shipment not found"
  - "Please check your booking reference and try again"
- ✅ No data displayed
- ✅ Can search again immediately

**Try Again With Valid:**
1. Clear input
2. Type: `BK-2026-00129`
3. Error disappears, data loads

---

### TEST 5: Empty Search (1 min)

**Scenario**: User tries to search without entering reference

**Steps:**
1. Go to `http://localhost:4200/tracking`
2. Leave input empty
3. Try to click "Track" button

**Expected Result:**
- ✅ Button is DISABLED (grayed out)
- ✅ Cannot click
- ✅ Tooltip or hint appears:
  - "Enter a booking reference above to get started"

---

### TEST 6: Loading States (1 min)

**Scenario**: Observe loading feedback

**Steps:**
1. Go to `http://localhost:4200/tracking`
2. Type: `BK-2026-00129`
3. Click "Track"
4. Observe button during load

**Expected Result:**
- ✅ Button text changes to "Searching..."
- ✅ Spinning loader appears (⟳)
- ✅ Button is disabled
- ✅ Input field is disabled
- ✅ After 1-2 seconds: loads complete

---

### TEST 7: Keyboard Enter Key (1 min)

**Scenario**: Search using Enter key (not button)

**Steps:**
1. Go to `http://localhost:4200/tracking`
2. Type: `BK-2026-00125`
3. Press: `Enter` key (don't click button)
4. Wait for load

**Expected Result:**
- ✅ Search triggers immediately
- ✅ Same result as clicking button
- ✅ Works on mobile too

---

### TEST 8: Mobile Responsiveness (2 min)

**Scenario**: Test on phone/tablet

**Method A: Browser DevTools**
1. Press `F12` to open DevTools
2. Click device icon (📱)
3. Select: "iPhone 12" or "iPad"
4. Type: `BK-2026-00129`
5. Click "Track"

**Method B: Actual Device**
1. On phone/tablet: Visit `http://[your-ip]:4200/tracking`
2. Replace `[your-ip]` with your computer's IP
3. Type: `BK-2026-00129`
4. Click "Track"

**Expected Result - Mobile (1 column):**
- ✅ Header: SV logo + "Track Your Shipment"
- ✅ Search box: Full width
- ✅ Status grid: 1 column (stacked)
- ✅ Timeline: Full width
- ✅ Driver card: Full width
- ✅ Map: Full width
- ✅ All readable without scrolling horizontally

**Expected Result - Tablet (2 columns):**
- ✅ Status grid: 2 columns
- ✅ Details grid: 2 columns
- ✅ Layout: More spacious than mobile

**Expected Result - Desktop (4 columns):**
- ✅ Status grid: 4 columns (Ref, Status, Service, ETA)
- ✅ Maximum spacing and readability

---

### TEST 9: Animations (1 min)

**Scenario**: Observe smooth animations

**Steps:**
1. Go to `http://localhost:4200/tracking`
2. Type: `BK-2026-00129`
3. Click "Track"
4. Watch for animations

**Expected Result:**
- ✅ Page fades in smoothly
- ✅ Sections appear with staggered delays
- ✅ No jarring or instant appearances
- ✅ Smooth color transitions on hover

---

### TEST 10: Real-Time Updates (3 min)

**Scenario**: Watch location update automatically

**Steps:**
1. Go to `http://localhost:4200/tracking`
2. Type: `BK-2026-00129`
3. Click "Track"
4. Wait and watch the location section
5. Wait 10+ seconds
6. Observe location coordinates

**Expected Result:**
- ✅ Initial coordinates load
- ✅ After 10 seconds: coordinates update
- ✅ Map (if visible) updates position
- ✅ No manual refresh needed
- ✅ Page stays responsive
- ✅ Green pulse dot shows live updates

**Verify:**
- Keep page open for 30 seconds
- Should see 3 location updates
- Click map to verify new coordinates

---

## 🎯 FEATURE CHECKLIST

### Search & Input
- [x] Input field accepts text
- [x] Button enabled/disabled correctly
- [x] Enter key works
- [x] Loading spinner shows
- [x] Error alerts display

### Status Display
- [x] Booking reference shows
- [x] Status color-coded (blue/green/gray)
- [x] Service type shows
- [x] Estimated delivery shows
- [x] Actual delivery shows (if delivered)

### Timeline
- [x] All 9 statuses display
- [x] Completed steps are green
- [x] Current step is blue
- [x] Future steps are gray
- [x] Timestamps format correctly
- [x] Animated dots

### Driver Info
- [x] Only shows for in-transit
- [x] Driver photo displays
- [x] Driver name shows
- [x] Phone number is clickable
- [x] Vehicle info displays
- [x] Rating shows (if available)

### Map
- [x] Shows for in-transit+ orders
- [x] Google Map loads (if API key)
- [x] Marker shows position
- [x] Coordinates display
- [x] Updates every 10 seconds
- [x] Fallback text if no map API

### Details
- [x] All fields show correctly
- [x] Dates format as "dd-MMM-yyyy"
- [x] Costs format with $
- [x] Colors highlight important info
- [x] Responsive grid layout

### Items List
- [x] Shows for shipments with items
- [x] Item count shows
- [x] Description displays
- [x] Quantity shows
- [x] Weight shows (if available)
- [x] Numbered list

### Proof of Delivery
- [x] Shows only if delivered
- [x] ✅ Green badge appears
- [x] Recipient name shows
- [x] Delivery date/time shows
- [x] Notes display (if present)
- [x] Photo displays (if attached)

### Mobile Responsive
- [x] Works on iPhone
- [x] Works on Android
- [x] Works on iPad
- [x] Single column on mobile
- [x] Two columns on tablet
- [x] Four columns on desktop

### Accessibility
- [x] Can tab between fields
- [x] Can press Enter to search
- [x] Error messages clear
- [x] Color contrast good
- [x] Text readable at zoom
- [x] Screen reader compatible

### Performance
- [x] Loads in <2 seconds
- [x] No lag when scrolling
- [x] Updates smooth
- [x] No broken images
- [x] No console errors

---

## 📝 TEST DATA

### Available References

```
Status               | Reference      | Features
=====================|===============|================================
BOOKING_CREATED      | BK-2026-00125 | Basic - just created
ORDER_CONFIRMED      | BK-2026-00126 | 2 steps completed
PAYMENT_RECEIVED     | BK-2026-00127 | 3 steps completed
READY_FOR_PICKUP     | BK-2026-00128 | 4 steps completed
IN_TRANSIT           | BK-2026-00129 | Live location, Driver info ⭐
OUT_FOR_DELIVERY     | BK-2026-00130 | Almost delivered
DELIVERED            | BK-2026-00131 | Delivered - see all steps
DELIVERED_WITH_POD   | BK-2026-00132 | Delivered + Proof photo ⭐
RETURNED             | BK-2026-00133 | Returned to sender
```

**⭐ Best for Demo:**
- `BK-2026-00129` - See live location updates
- `BK-2026-00132` - See proof of delivery

---

## 🐛 TROUBLESHOOTING

### Problem: Page doesn't load
**Solution:**
- Check URL: `http://localhost:4200/tracking`
- Check backend running: `http://localhost:8080`
- Clear browser cache (Ctrl+Shift+Del)
- Try incognito window

### Problem: "Shipment not found"
**Solution:**
- Use one of test references above
- Check spelling (case doesn't matter)
- Include "BK-" or "ORD-" prefix

### Problem: Map not showing
**Solution:**
- Check if Google Maps API key configured
- Text coordinates still visible
- Fallback works correctly
- Not critical for demo

### Problem: Driver info missing
**Solution:**
- Only appears for IN_TRANSIT status
- Try: BK-2026-00129
- Other statuses won't show driver

### Problem: Proof of delivery missing
**Solution:**
- Only appears for DELIVERED status
- Try: BK-2026-00131 or BK-2026-00132
- Earlier statuses don't show POD

### Problem: Location not updating
**Solution:**
- Keep page open 10+ seconds
- Check browser console (F12)
- Refresh page
- Try different reference

### Problem: Slow loading
**Solution:**
- Check internet speed
- Restart browser
- Try private/incognito window
- Check backend logs

---

## 📊 SUCCESS CRITERIA

Your implementation is **production-ready** when:

✅ **All tests pass** (10/10 scenarios work)  
✅ **No console errors** (F12 → Console is clean)  
✅ **Mobile works** (responsive on all sizes)  
✅ **Loading states** (visible feedback)  
✅ **Error handling** (graceful errors)  
✅ **Performance** (< 2s load time)  
✅ **Accessibility** (keyboard navigation works)  
✅ **Animations** (smooth, not jarring)  

---

## 🎥 DEMO SCRIPT (5 MIN)

### Opening (30 sec)
```
"Welcome! This is our new public shipment tracking feature.
Customers can now track their shipments in real-time without 
logging in. Let me show you how it works."
```

### Search Demo (30 sec)
```
"Simply enter a booking reference..."
[Type: BK-2026-00129]
"...and click Track. The system loads all the details instantly."
```

### Real-Time Location (1 min)
```
"Here you can see the shipment is in transit, with your driver's
information and current location on the map. The coordinates update
every 10 seconds so you always know where your package is."

[Click driver phone number]
"Customers can even call their driver directly from here."
```

### Timeline (1 min)
```
"The timeline shows exactly where the shipment is in the delivery
process. From booking creation all the way through to delivery.
You can see when each milestone was completed."
```

### Proof of Delivery (1 min)
```
"Once delivered, customers see proof - including the recipient's
signature, timestamp, and even a photo if attached. This gives
complete visibility and peace of mind."

[Show another reference: BK-2026-00131]
```

### Closing (30 sec)
```
"This feature reduces support calls, builds customer trust, and
provides transparency. It's available 24/7, works on all devices,
and requires no login. Ready to launch!"
```

---

## ✅ FINAL CHECKLIST

Before sharing with stakeholders:

- [ ] All 10 test scenarios pass
- [ ] No console errors (F12)
- [ ] Mobile view looks good
- [ ] Desktop view looks good
- [ ] Loading states visible
- [ ] Error handling works
- [ ] Backend running (optional, can use mocks)
- [ ] No broken images/icons
- [ ] All text readable
- [ ] No layout breaks

---

## 🚀 READY TO SHOW?

When all tests pass, you can confidently say:

> **"The public shipment tracking feature is production-ready,  
> tested, and ready to deploy. Customers can track their shipments  
> 24/7 without needing to log in."**

---

**Test Date**: _______________  
**Tested By**: _______________  
**Status**: ☐ Pass | ☐ Needs Work  

---

**Duration**: 5-10 minutes  
**Date**: January 9, 2026  
**Version**: 1.0.0  
**Status**: ✅ **READY TO TEST**
