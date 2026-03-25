> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Manual Testing Guide - License Class Validation Fix

## Quick Start

### Prerequisites
1. Backend running on `http://localhost:8080`
2. Frontend running on `http://localhost:4200`
3. Valid JWT token (login first if needed)
4. Database seeded with drivers and vehicles

---

## Test Case 1: Driver WITH License Class + TRUCK Vehicle

**Expected Behavior:** No warning, "Assign Vehicle" button ENABLED

### Steps:

1. **Navigate to Driver 1 Detail Page**
   ```
   URL: http://localhost:4200/drivers/1?tab=vehicle
   ```

2. **Verify Driver Data Loaded**
   - Driver name should be displayed
   - Look in the Info tab to verify driver has a license class (e.g., "CDL")

3. **Open Browser DevTools (F12)**
   - Go to **Console** tab
   - Run this command:
   ```javascript
   ng.probe(document.querySelector('app-driver-detail')).componentInstance.driverForm.get('licenseClass').value
   ```
   - **Expected Output:** `"CDL"` or other valid license class (NOT null or empty)

4. **Search for TRUCK Vehicle**
   - In the "Assign New Vehicle" section
   - Type vehicle license plate: `3F-0745` (or any TRUCK type vehicle)
   - Click on the suggestion to select it

5. **Verify Preview**
   - Selected vehicle should show in preview box below search
   - Assignment type should show "Permanent"

6. **Check Warning Message**
   - **Expected:** ❌ NO warning message appears
   - **Expected:** "Assign Vehicle" button is ENABLED (not grayed out)

7. **Test Result**
   ```
   PASS if:
     - License class value is "CDL" or similar
     - No warning shows
     - Assign button is enabled
   
   ❌ FAIL if:
     - Warning shows (old bug)
     - Button is disabled
   ```

---

## Test Case 2: Driver WITHOUT License Class + TRUCK Vehicle

**Expected Behavior:** ⚠️ Warning shows, "Assign Vehicle" button DISABLED

### Steps:

1. **Navigate to Driver 2 Detail Page**
   ```
   URL: http://localhost:4200/drivers/2?tab=vehicle
   ```

2. **Verify Driver Data**
   - Driver name should display
   - Check Info tab - should have NO license class

3. **Open Browser DevTools (F12)**
   - Go to **Console** tab
   - Run this command:
   ```javascript
   ng.probe(document.querySelector('app-driver-detail')).componentInstance.driverForm.get('licenseClass').value
   ```
   - **Expected Output:** `null` or empty string `""`

4. **Search for TRUCK Vehicle**
   - Type vehicle license plate: `3F-0745` (or any TRUCK type vehicle)
   - Click suggestion to select

5. **Verify Preview**
   - Selected vehicle shows with license plate and model
   - Assignment type shows "Permanent"

6. **Check Warning Message**
   - **Expected:** WARNING appears in yellow box:
     ```
     ⚠️ This driver needs a commercial license class to assign to trucks. 
     Go to Licenses tab.
     ```
   - **Expected:** ❌ "Assign Vehicle" button is DISABLED (grayed out)

7. **Try to Assign (Should Fail)**
   - Try clicking "Assign Vehicle" button
   - Expected: Button doesn't respond (disabled)

8. **Test Result**
   ```
   PASS if:
     - License class is null/empty
     - Warning appears
     - Button is disabled
   
   ❌ FAIL if:
     - No warning shows (regression)
     - Button is enabled (regression)
   ```

---

## Test Case 3: Driver WITHOUT License + Non-TRUCK Vehicle

**Expected Behavior:** No warning, "Assign Vehicle" button ENABLED

### Steps:

1. **Stay on Driver 2 page**
   ```
   URL: http://localhost:4200/drivers/2?tab=vehicle
   ```

2. **Verify License is Still Missing**
   - Run in console (as before):
   ```javascript
   ng.probe(document.querySelector('app-driver-detail')).componentInstance.driverForm.get('licenseClass').value
   ```
   - Confirm output is `null` or `""`

3. **Clear Previous Selection**
   - Click the "X" button in the selected vehicle preview box
   - Or clear the search input

4. **Search for VAN Vehicle**
   - Type: `ABC-123` (or any non-TRUCK vehicle)
   - Click suggestion to select

5. **Verify Preview**
   - Vehicle shows in preview (e.g., "ABC-123 (Van Model)")
   - Assignment type shows "Permanent"

6. **Check Warning and Button**
   - **Expected:** ❌ NO warning appears
   - **Expected:** "Assign Vehicle" button is ENABLED

7. **Test Result**
   ```
   PASS if:
     - No warning shows
     - Button is enabled
     - Can proceed with assignment
   
   ❌ FAIL if:
     - Warning shows (over-validation)
   ```

---

## Quick Validation Checklist

Use this checklist to verify all scenarios:

| Test # | Driver | Vehicle Type | Has License | Expected Warning | Expected Button | Result |
|--------|--------|--------------|-------------|-----------------|-----------------|--------|
| 1 | 1 | TRUCK | YES (CDL) | ❌ NO | ENABLED | [ ] |
| 2 | 2 | TRUCK | NO (null) | YES | ❌ DISABLED | [ ] |
| 3 | 2 | VAN | NO (null) | ❌ NO | ENABLED | [ ] |

---

## Network Tab Verification

To verify the API is returning correct data:

1. **Open DevTools → Network Tab**
2. **Refresh the page** to capture all requests
3. **Filter for:** `/api/admin/drivers/1`
4. **Click the request** to see response
5. **Find the response data section** and look for:
   ```json
   {
     "success": true,
     "data": {
       "id": 1,
       "firstName": "John",
       "lastName": "Doe",
       "licenseClass": "CDL",  // <-- THIS SHOULD HAVE VALUE
       "phone": "+1234567890",
       ...
     }
   }
   ```

### Expected Differences:

**Driver 1 Response:**
```json
"licenseClass": "CDL"  // Has value
```

**Driver 2 Response:**
```json
"licenseClass": null   // No value
```

---

## Console Debug Commands

Useful commands to run in browser console while testing:

### Get Current License Class Value
```javascript
ng.probe(document.querySelector('app-driver-detail')).componentInstance.driverForm.get('licenseClass').value
```

### Get Selected Vehicle ID
```javascript
ng.probe(document.querySelector('app-driver-detail')).componentInstance.selectedVehicleForAssignment
```

### Get Selected Vehicle Details
```javascript
const comp = ng.probe(document.querySelector('app-driver-detail')).componentInstance;
comp.vehicleList.find(v => v.id === comp.selectedVehicleForAssignment)
```

### Check if License Requirement is Met
```javascript
ng.probe(document.querySelector('app-driver-detail')).componentInstance.isLicenseRequirementMet()
```

### Check Warning Message
```javascript
ng.probe(document.querySelector('app-driver-detail')).componentInstance.getLicenseRequirementMessage()
```

### Watch Form Changes in Real-time
```javascript
const comp = ng.probe(document.querySelector('app-driver-detail')).componentInstance;
comp.driverForm.get('licenseClass').valueChanges.subscribe(v => console.log('License Class Updated:', v))
```

---

## Database Queries for Verification

Check what's actually in the database:

```sql
-- Check driver license classes
SELECT id, firstName, lastName, licenseClass 
FROM driver 
WHERE id IN (1, 2);

-- Output should show:
-- id=1, firstName=John, lastName=Doe, licenseClass=CDL
-- id=2, firstName=Jane, lastName=Smith, licenseClass=NULL

-- Check vehicles by type
SELECT id, licensePlate, model, type 
FROM vehicle 
WHERE type IN ('TRUCK', 'VAN');
```

---

## Troubleshooting

### Issue: License Class Not Loading
**Symptom:** Form shows empty even though DB has value

**Solution:**
1. Check Network tab → `/api/admin/drivers/1` response
2. Verify `licenseClass` field is in response JSON
3. Clear browser cache and reload
4. Check for any JavaScript errors in console

### Issue: Warning Always Shows
**Symptom:** Warning shows even for drivers with licenses

**Solution:**
1. Run console command to check actual form value
2. Verify API response includes license class
3. Check if form initialization is correct in component
4. Clear form state: `ng.probe(document.querySelector('app-driver-detail')).componentInstance.driverForm.reset()`

### Issue: Button Stays Disabled
**Symptom:** Assignment button won't enable even with valid license

**Solution:**
1. Check browser console for any JavaScript errors
2. Run `isLicenseRequirementMet()` in console
3. Verify selected vehicle is TRUCK type
4. Try selecting a different vehicle

### Issue: Cannot Get Component Instance
**Symptom:** Console command returns undefined

**Solution:**
1. Make sure DevTools console is focused
2. Make sure the page is fully loaded (wait for data)
3. Try typing in the console directly (don't paste)
4. Ensure you're on the driver detail page

---

## Success Criteria

**All Tests Pass If:**
- Test 1: No warning for driver WITH license assigning TRUCK
- Test 2: Warning appears for driver WITHOUT license assigning TRUCK  
- Test 3: No warning for driver assigning non-TRUCK regardless of license
- Console commands return expected values
- API responses include correct license class data
- No JavaScript errors in console

❌ **Tests Fail If:**
- Any of the above conditions are not met
- Warning shows inconsistently
- Button state doesn't match expected
- Form value doesn't match API response

---

## Next Steps

After successful testing:

1. **Commit the fix:**
   ```bash
   git add tms-frontend/src/app/components/drivers/driver-detail/driver-detail.component.ts
   git commit -m "fix: license class validation for truck assignments"
   ```

2. **Deploy to staging** and perform full regression testing

3. **Monitor in production** for any edge cases

4. **Update documentation** if validation logic changes

---

**Test Completed:** _________________ **Date:** _________________

**Tester Name:** _________________ **Signature:** _________________

