> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Quick Testing Guide

## One-Liner Setup

```bash
# Set these environment variables first:
export JWT_TOKEN="your_jwt_token_here"
export DB_PASSWORD="your_db_password"

# Then run the test script:
bash test-license-validation.sh
```

---

## Get JWT Token

```bash
# Login to get a token:
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Copy the token from response and export it:
export JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

## Browser Console Tests (Fastest)

Open `http://localhost:4200/drivers/1?tab=vehicle` and run:

### Test Driver 1 (with license)
```javascript
// Check license class value
ng.probe(document.querySelector('app-driver-detail')).componentInstance.driverForm.get('licenseClass').value
// Expected: "CDL" or similar

// Select a TRUCK vehicle (id 2)
ng.probe(document.querySelector('app-driver-detail')).componentInstance.selectedVehicleForAssignment = 2
ng.probe(document.querySelector('app-driver-detail')).componentInstance.vehicleSearchQuery = "3F-0745"

// Check if warning appears
ng.probe(document.querySelector('app-driver-detail')).componentInstance.getLicenseRequirementMessage()
// Expected: ""  (empty = no warning)

// Check if button should be enabled
ng.probe(document.querySelector('app-driver-detail')).componentInstance.isLicenseRequirementMet()
// Expected: true (button enabled)
```

### Test Driver 2 (without license)
Navigate to `http://localhost:4200/drivers/2?tab=vehicle` and run:
```javascript
// Check license class value
ng.probe(document.querySelector('app-driver-detail')).componentInstance.driverForm.get('licenseClass').value
// Expected: null or ""

// Select a TRUCK vehicle (id 2)
ng.probe(document.querySelector('app-driver-detail')).componentInstance.selectedVehicleForAssignment = 2

// Check if warning appears
ng.probe(document.querySelector('app-driver-detail')).componentInstance.getLicenseRequirementMessage()
// Expected: "⚠️ This driver needs a commercial license class to assign to trucks. Go to Licenses tab."

// Check if button should be disabled
ng.probe(document.querySelector('app-driver-detail')).componentInstance.isLicenseRequirementMet()
// Expected: false (button disabled)
```

---

## Expected Results Summary

| Scenario | Driver 1 + TRUCK | Driver 2 + TRUCK | Driver 2 + VAN |
|----------|-----------------|-----------------|----------------|
| License Class | `"CDL"` | `null` | `null` |
| Warning Message | `""` | Warning text | `""` |
| Button Enabled | true | ❌ false | true |
| Can Assign | YES | ❌ NO | YES |

---

## Verification Checklist

- [ ] Driver 1 + TRUCK: No warning, button enabled
- [ ] Driver 2 + TRUCK: Warning shows, button disabled
- [ ] Driver 2 + VAN: No warning, button enabled
- [ ] Form value matches API response
- [ ] No console errors
- [ ] API returns correct license class
- [ ] All manual tests pass

---

## Quick SQL Check

```bash
# Login to MySQL and check data:
mysql -u root -p tms_db -e "SELECT id, firstName, lastName, licenseClass FROM driver WHERE id IN (1, 2);"

# Expected output:
# id | firstName | lastName | licenseClass
# 1  | John      | Doe      | CDL
# 2  | Jane      | Smith    | NULL
```

---

## If Tests Fail

**Symptom:** Warning shows even with valid license

**Fix checklist:**
1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard reload page (Ctrl+Shift+R)
3. Check API response in Network tab
4. Verify database has correct data
5. Check for JavaScript errors in console
6. Restart frontend dev server: `npm run start`

**Symptom:** Form value is null but should have license

1. Check `/api/admin/drivers/1` response in Network tab
2. Verify `licenseClass` field is in JSON
3. Check if field name matches (case-sensitive)
4. Run database query to verify data exists

---

## Test Files

- `test-license-validation.sh` - Automated bash test
- `MANUAL_TESTING_GUIDE.md` - Step-by-step manual testing
- `LICENSE_CLASS_VALIDATION_FIX.md` - Technical details of the fix

