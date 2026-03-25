> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🧪 Incidents Feature - Visual Testing Guide

## Quick Test Checklist ✓

Use this guide to verify the Incidents feature works end-to-end.

---

## 🚀 Setup (5 minutes)

### 1. Start Backend
```bash
cd tms-backend
./mvnw spring-boot:run
# Wait for: "Started TmsBackendApplication in X seconds"
```

### 2. Start Frontend
```bash
cd tms-frontend
npm run start
# Opens: http://localhost:4200
```

### 3. Login
- Username: Your admin account
- Password: Your password
- Required Permission: `incident:create`, `incident:view`, `incident:list`

---

## Test 1: Create Incident (2 minutes)

### Steps:
1. Navigate to: **http://localhost:4200/incidents/new**
2. You should see:
   - Breadcrumb: "Incidents / New Incident"
   - 2-column grid form (looks professional)
   - All fields visible (Title, Description, Group, Type, etc.)

### Fill Form:
```
Title: Test Incident - Data Alignment Check
Description: Testing frontend-backend integration after model fixes
Incident Group: VEHICLE
Incident Type: Other
Severity: MEDIUM
Driver: (select any)
Vehicle: (select any)
Location: Test Location
```

### Expected Result:
- Form submits without errors
- Redirects to incidents list
- New incident appears in table
- Code generated: **INC-2025-XXXX**

### ❌ If It Fails:
Check browser console for errors. Common issues:
- 401 Unauthorized → Check JWT token
- 403 Forbidden → Missing permission `incident:create`
- 400 Bad Request → Validation error (check required fields)

---

## Test 2: View Incident List (1 minute)

### Steps:
1. Navigate to: **http://localhost:4200/incidents**
2. You should see:
   - Statistics cards at top (Total, New, Validated, etc.)
   - Filter section (Status, Group, Severity dropdowns)
   - Table with incidents
   - Pagination controls

### Test Filters:
1. Select **Status: NEW** → Table shows only NEW incidents
2. Select **Severity: MEDIUM** → Table filters further
3. Clear filters → All incidents shown

### Expected Result:
- Filters work correctly
- Table updates in real-time
- "View" button clickable

### Check Data Fields in Table:
| Column | Should Display |
|--------|----------------|
| CODE | INC-2025-0001 |
| TITLE | Your incident title |
| GROUP | Badge with color (e.g., "Vehicle") |
| DRIVER/VEHICLE | Driver name • Vehicle plate |
| SEVERITY | Badge (LOW/MEDIUM/HIGH/CRITICAL) |
| STATUS | Badge (NEW/VALIDATED/CLOSED) |
| ACTIONS | "View" link |

---

## Test 3: View Incident Details (1 minute)

### Steps:
1. Click **"View"** on any incident
2. Drawer opens from right side

### Should Display:
- **Header:** Incident code and title
- **Left Panel:**
  - Incident Type
  - Group (formatted, e.g., "Vehicle Issue")
  - Description
  - Location
- **Right Panel:**
  - Driver name
  - Vehicle plate
  - Status badge
  - Reported by username

### Test Actions (if permitted):
1. Click **"Validate Incident"** → Status changes to VALIDATED
2. Click **"Close as Small Issue"** → Status changes to CLOSED
3. Check **Timeline** section updates

---

## Test 4: Update Incident (1 minute)

### Steps:
1. From incident list, click **"View"** on incident
2. Drawer should have **"Edit"** button (if implemented)
3. OR navigate to: **http://localhost:4200/incidents/{id}/edit**

### Update Fields:
```
Title: [New Title] - Updated
Description: Updated description after testing
Severity: HIGH (change from MEDIUM)
```

### Expected Result:
- Form pre-populated with existing data
- Changes save successfully
- Redirects to detail view
- Updated fields visible

---

## Test 5: Data Model Verification (CRITICAL)

### Backend API Test (Use Postman or curl):

```bash
# Get incident by ID
curl -X GET "http://localhost:8080/api/incidents/1" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Expected JSON Response:
```json
{
  "success": true,
  "message": "Incident retrieved",
  "data": {
    "id": 1,
    "code": "INC-2025-0001",
    "title": "Test Incident",
    "description": "Testing integration",
    "incidentGroup": "VEHICLE",
    "incidentType": "Other",
    "severity": "MEDIUM",
    "incidentStatus": "NEW",
    
    // VERIFY THESE FIELDS ARE PRESENT:
    "locationText": "Test Location",       NEW
    "locationLat": null,                   NEW
    "locationLng": null,                   NEW
    "tripId": 123,                         NEW
    "tripReference": "TRIP-001",           NEW
    "reportedByUserId": 1,                 RENAMED
    "reportedByUsername": "admin",         OK
    "assignedToId": null,                  NEW
    "assignedToName": null,                NEW
    "photoCount": 0,                       NEW
    "photoUrls": [],                       OK
    "resolutionNotes": null,               NEW
    "resolvedAt": null,                    NEW
    "linkedToCase": false,                 NEW
    "caseId": null,                        OK
    "caseCode": null,                      OK
    "source": "SYSTEM",                    NEW
    "createdAt": "2025-01-XX...",         OK
    "updatedAt": null                      OK
  }
}
```

### ❌ If Fields Missing:
- Check backend compiled: `./mvnw clean compile`
- Check IncidentService.mapToDto() includes all fields
- Restart backend: `./mvnw spring-boot:run`

---

## Test 6: Pagination & Filtering (1 minute)

### Steps:
1. Create 25+ test incidents (or use existing data)
2. Navigate to incidents list
3. Should see pagination: **"Prev" and "Next" buttons**

### Test:
1. Click **"Next"** → Page 2 loads
2. Click **"Prev"** → Back to page 1
3. Apply filter **Status: NEW** → Only NEW incidents shown
4. Pagination adjusts to filtered results

### Expected Result:
- Pagination works
- Shows "X of Y incidents"
- Filters work with pagination

---

## 🎨 UI/UX Checklist

### Incident Form (`/incidents/new`)
- [ ] Breadcrumb navigation visible
- [ ] 2-column grid layout (looks professional)
- [ ] Form max-width: 1000px (centered)
- [ ] All labels clear and readable
- [ ] Validation errors show in red
- [ ] Submit button shows loading state
- [ ] Success message or redirect on submit

### Incident List (`/incidents`)
- [ ] Statistics cards at top (responsive)
- [ ] Filter section with dropdowns
- [ ] Search box (if implemented)
- [ ] Table responsive on mobile
- [ ] Badges colored correctly (severity, status)
- [ ] Pagination controls visible

### Incident Detail (Drawer)
- [ ] Drawer slides in from right
- [ ] Close button works (X or click outside)
- [ ] Information well-organized
- [ ] Timeline section shows events
- [ ] Action buttons visible (if user has permission)

---

## 🐛 Common Issues & Fixes

### Issue: "403 Forbidden"
**Fix:** User missing permissions. Add these to user role:
```sql
INSERT INTO user_permissions (user_id, permission_id)
SELECT 1, id FROM permissions 
WHERE name IN ('incident:create', 'incident:view', 'incident:list', 'incident:update');
```

### Issue: "Field 'locationText' not found"
**Fix:** Backend not recompiled. Run:
```bash
cd tms-backend
./mvnw clean package
./mvnw spring-boot:run
```

### Issue: "Cannot read property 'tripId' of undefined"
**Fix:** Frontend model not updated. Check `incident.model.ts` has new fields.

### Issue: Statistics cards show 0
**Fix:** Backend `/api/incidents/statistics` endpoint not implemented yet. Normal behavior.

---

## Success Criteria

Your Incidents feature is **PRODUCTION READY** when:

- All 6 tests pass
- No console errors
- Data model alignment verified (Test 5)
- UI looks professional (2-column form)
- Filters and pagination work
- Permissions enforced correctly

---

## 📊 Test Results Template

Copy this and fill in results:

```
INCIDENTS FEATURE TEST RESULTS
Date: ___________
Tester: ___________

/ ❌  Test 1: Create Incident
/ ❌  Test 2: View List
/ ❌  Test 3: View Details
/ ❌  Test 4: Update Incident
/ ❌  Test 5: Data Model Verification
/ ❌  Test 6: Pagination & Filtering

UI/UX:
/ ❌  Form layout professional
/ ❌  Responsive design works
/ ❌  No console errors

OVERALL: PASS / ❌ FAIL

Notes:
_________________________________
_________________________________
```

---

## 🎉 Next Steps After Passing Tests

1. **Deploy to Staging**
2. **Implement file upload endpoint** (optional)
3. **Implement statistics API** (optional)
4. **Add unit tests**
5. **User acceptance testing**

---

**Questions?** Check `INCIDENTS_PRODUCTION_READINESS_REPORT.md` for detailed analysis.
