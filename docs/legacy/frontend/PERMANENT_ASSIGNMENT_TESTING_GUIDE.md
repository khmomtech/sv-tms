> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Permanent Truck-Driver Assignment - Complete Testing Guide

## 🎯 Overview

This guide covers complete testing of all CRUD operations for permanent truck-driver assignments, ensuring full integration with the backend.

**Status**: All compilation errors fixed  
**Date**: December 2, 2025  
**Components**: Assignment Form, Assignment List, Services Integration

---

## Pre-Testing Checklist

### Backend Requirements

- [ ] Backend server running on `http://localhost:8080`
- [ ] MySQL database accessible
- [ ] User authenticated with proper permissions:
  - `DRIVER_MANAGE` or `DRIVER_VIEW_ALL`
  - `VEHICLE_UPDATE` or `VEHICLE_MANAGE`

### Frontend Requirements

- [ ] Angular dev server running: `npm run start`
- [ ] No compilation errors (verified ✅)
- [ ] Browser console open for monitoring

---

## 📋 Test Cases

### **Test Group 1: Service Integration**

#### 1.1 Driver Service - Get Drivers (READ)

**Endpoint**: `GET /api/admin/drivers/alllists?page=0&size=1000`

**Test Steps**:

1. Open browser DevTools → Network tab
2. Navigate to `/fleet/assign-truck-driver`
3. Check network request for drivers

**Expected Results**:

```javascript
Request: GET /api/admin/drivers/alllists?page=0&size=1000
Response Status: 200 OK
Response Body: {
  "success": true,
  "data": {
    "content": [...],  // Array of drivers
    "totalElements": N,
    "totalPages": M
  }
}
Console Log: "[AssignTruckDriver] Loaded X drivers"
```

**Validation**:

- [ ] Drivers dropdown populated with data
- [ ] No NG0900 error in console
- [ ] Loading spinner disappears

---

#### 1.2 Vehicle Service - Get Vehicles (READ)

**Endpoint**: `GET /api/admin/vehicles/filter?page=0&size=1000`

**Test Steps**:

1. Open Network tab
2. Navigate to assignment page
3. Check vehicle API call

**Expected Results**:

```javascript
Request: GET /api/admin/vehicles/filter?page=0&size=1000
Response Status: 200 OK
Response Body: {
  "success": true,
  "data": {
    "content": [...],  // Array of vehicles
    "totalElements": N,
    "totalPages": M
  }
}
Console Log: "[AssignTruckDriver] Loaded X trucks"
```

**Validation**:

- [ ] Trucks dropdown populated
- [ ] Vehicle data displays correctly
- [ ] No errors in console

---

#### 1.3 Check Existing Driver Assignment (READ)

**Endpoint**: `GET /api/admin/assignments/permanent/{driverId}`

**Test Steps**:

1. Select a driver from dropdown
2. Wait 300ms (debounce delay)
3. Check network request

**Expected Results**:

```javascript
Request: GET /api/admin/assignments/permanent/{driverId}
Response (if exists): {
  "success": true,
  "data": {
    "id": 123,
    "driverId": X,
    "driverName": "John Doe",
    "vehicleId": Y,
    "truckPlate": "ABC-123",
    "active": true
  }
}
OR Response (if none): 404 Not Found
Console Log: "Driver assignment: {data}" or null
```

**Validation**:

- [ ] Warning badge shows if driver already assigned
- [ ] Current assignment details display
- [ ] 404 handled gracefully (no error message)

---

#### 1.4 Check Existing Truck Assignment (READ)

**Endpoint**: `GET /api/admin/assignments/permanent/truck/{vehicleId}`

**Test Steps**:

1. Select a truck from dropdown
2. Wait for debounce
3. Verify API call

**Expected Results**:

```javascript
Request: GET /api/admin/assignments/permanent/truck/{vehicleId}
Response structure same as driver assignment
Warning displays if truck already assigned
```

**Validation**:

- [ ] Shows current driver for selected truck
- [ ] Warning message appears
- [ ] No console errors

---

### **Test Group 2: Assignment CRUD Operations**

#### 2.1 Create New Assignment (CREATE)

**Endpoint**: `POST /api/admin/assignments/permanent`

**Test Steps**:

1. Select an unassigned driver
2. Select an unassigned truck
3. Enter optional reason
4. Click "Assign Truck to Driver"

**Expected Results**:

```javascript
Request: POST /api/admin/assignments/permanent
Request Body: {
  "driverId": X,
  "vehicleId": Y,
  "reason": "Initial assignment",
  "forceReassignment": false
}
Response Status: 200 OK
Response Body: {
  "success": true,
  "data": {
    "id": 123,
    "driverId": X,
    "driverName": "...",
    "vehicleId": Y,
    "truckPlate": "...",
    "assignedAt": "2025-12-02T...",
    "assignedBy": "admin",
    "active": true
  }
}
Success Message: "Successfully assigned ABC-123 to John Doe"
Form resets
Page scrolls to top
```

**Validation**:

- [ ] Assignment created in database
- [ ] Success message displays
- [ ] Form cleared after submission
- [ ] Can reassign immediately

---

#### 2.2 Reassignment with Warning (UPDATE)

**Endpoint**: `POST /api/admin/assignments/permanent`

**Test Steps**:

1. Select driver who already has assignment
2. Select different truck
3. Check for confirmation dialog
4. Confirm or cancel

**Expected Results**:

```javascript
Warning banner shows: "⚠️ Reassignment will occur"
Confirmation dialog displays details
If confirmed → old assignment revoked, new one created
If canceled → no changes
```

**Validation**:

- [ ] Warning appears before submission
- [ ] Confirmation dialog clear
- [ ] Old assignment properly revoked
- [ ] New assignment active

---

#### 2.3 Force Reassignment (UPDATE)

**Endpoint**: `POST /api/admin/assignments/permanent`

**Test Steps**:

1. Select assigned driver + assigned truck
2. Check "Force Reassignment" checkbox
3. Submit without confirmation dialog

**Expected Results**:

```javascript
Request Body: { ..., "forceReassignment": true }
No confirmation dialog
Both old assignments revoked
New assignment created
```

**Validation**:

- [ ] Force flag sent to backend
- [ ] Previous assignments cleared
- [ ] New assignment active

---

#### 2.4 Revoke Assignment (DELETE)

**Endpoint**: `DELETE /api/admin/assignments/permanent/{driverId}?reason=...`

**Test Steps**:

1. Select driver with active assignment
2. Click "Revoke Assignment" button
3. Enter optional reason
4. Confirm deletion

**Expected Results**:

```javascript
Request: DELETE /api/admin/assignments/permanent/{driverId}?reason=Manual+revocation
Response Status: 200 OK
Response Body: {
  "success": true,
  "message": "Assignment revoked"
}
Success Message: "Assignment revoked successfully for John Doe"
Driver selection cleared
Warning disappears
```

**Validation**:

- [ ] Assignment marked inactive in database
- [ ] Success message displays
- [ ] Form state updates
- [ ] Driver can be reassigned

---

### **Test Group 3: Assignment List Page**

#### 3.1 Load Assignment List (READ ALL)

**Endpoint**: `GET /api/admin/assignments/permanent/list` (may return 404)

**Navigate to**: `/fleet/truck-driver-assignments`

**Test Steps**:

1. Navigate to assignments list page
2. Check network for API call
3. Verify data loads

**Expected Results**:

```javascript
Attempts API call first
If 404 → Uses mock data (50 sample assignments)
If 200 → Displays real data from backend
Console: "Loaded X assignments from API" OR "⚠️ using mock data"
Table populates with assignments
```

**Validation**:

- [ ] Page loads without errors
- [ ] Assignment data displays in table
- [ ] Pagination works
- [ ] Filters available

---

#### 3.2 Filter Assignments

**No backend call - client-side filtering**

**Test Steps**:

1. Enter search query (driver name or plate)
2. Select driver from dropdown
3. Select truck from dropdown
4. Choose status (Active/Inactive)
5. Set date range

**Expected Results**:

```javascript
Filters apply immediately (300ms debounce)
Results update without API call
Pagination resets to page 1
Result count updates
```

**Validation**:

- [ ] Search filters by name and plate
- [ ] Driver filter works
- [ ] Truck filter works
- [ ] Status filter toggles active/inactive
- [ ] Date range filters correctly
- [ ] Multiple filters combine (AND logic)

---

#### 3.3 Sort Assignments

**No backend call - client-side sorting**

**Test Steps**:

1. Click column headers:
   - Driver Name
   - Truck Plate
   - Assigned At
   - Status

**Expected Results**:

```javascript
First click → Ascending order
Second click → Descending order
Sort icon updates (⬆️ / ⬇️)
Data reorders correctly
```

**Validation**:

- [ ] All columns sortable
- [ ] Sort direction toggles
- [ ] Icon indicates current sort

---

#### 3.4 Pagination

**No backend call - client-side pagination**

**Test Steps**:

1. Change page size (10, 25, 50, 100)
2. Click next/previous buttons
3. Click page numbers
4. Verify ellipsis for large page counts

**Expected Results**:

```javascript
Page size changes → resets to page 1
Navigation buttons work
Page numbers clickable
Ellipsis (...) shows for > 5 pages
Results summary accurate: "Showing 1 to 10 of 50"
```

**Validation**:

- [ ] Page size selector works
- [ ] Navigation responsive
- [ ] Correct items displayed per page
- [ ] Summary text accurate

---

#### 3.5 Revoke from List (DELETE)

**Endpoint**: `DELETE /api/admin/assignments/permanent/{driverId}`

**Test Steps**:

1. Click "Revoke" button on assignment row
2. Confirm dialog
3. Wait for API response

**Expected Results**:

```javascript
Request: DELETE /api/admin/assignments/permanent/{driverId}
Response Status: 200 OK
Success message appears
List refreshes automatically
Assignment removed or marked inactive
```

**Validation**:

- [ ] Confirmation dialog shows
- [ ] API call successful
- [ ] List updates
- [ ] Success message clear

---

#### 3.6 Export to CSV

**No backend call - client-side export**

**Test Steps**:

1. Apply filters (optional)
2. Click "Export to CSV" button
3. Check downloaded file

**Expected Results**:

```javascript
CSV file downloads
Filename: truck-driver-assignments-2025-12-02.csv
Headers: Driver Name, Truck Plate, Assigned At, ...
Data matches current filtered view
Dates formatted correctly
```

**Validation**:

- [ ] File downloads successfully
- [ ] Correct format (CSV)
- [ ] All visible data included
- [ ] No data corruption

---

### **Test Group 4: Error Handling**

#### 4.1 Network Errors

**Test Steps**:

1. Stop backend server
2. Try to load page or submit form

**Expected Results**:

```javascript
Error message: "Failed to load drivers. Please refresh the page."
Loading spinner stops
Form remains usable
No white screen or crash
```

**Validation**:

- [ ] User-friendly error messages
- [ ] No stack traces visible
- [ ] Graceful degradation
- [ ] Retry option available

---

#### 4.2 Authentication Errors (401/403)

**Test Steps**:

1. Clear auth token or use expired token
2. Attempt any operation

**Expected Results**:

```javascript
Error: "Unauthorized. Please log in again."
OR: "You don't have permission."
Hint message displays
No data exposure
```

**Validation**:

- [ ] Auth errors caught
- [ ] Clear message about re-login
- [ ] Redirects to login (if implemented)

---

#### 4.3 Validation Errors (400)

**Test Steps**:

1. Submit form without required fields
2. Or provide invalid data

**Expected Results**:

```javascript
Client-side validation first
Error: "Please fill in all required fields"
Invalid fields highlighted
No API call if validation fails
```

**Validation**:

- [ ] Required field validation
- [ ] Fields marked as touched
- [ ] Error messages clear

---

#### 4.4 Conflict Errors (409)

**Test Steps**:

1. Try to assign already-assigned driver
2. Without force reassignment flag

**Expected Results**:

```javascript
Error: Backend conflict message
Hint: "Try enabling Force Reassignment"
Form state preserved
User can adjust and retry
```

**Validation**:

- [ ] Conflict detected
- [ ] Helpful hint provided
- [ ] Form not cleared

---

## 🔍 Console Monitoring

### Success Logs to Look For:

```javascript
[AssignTruckDriver] Loaded X drivers
[AssignTruckDriver] Loaded X trucks
📋 Loaded X drivers for filter
🚛 Loaded X vehicles for filter
Loaded X assignments from API
[AssignTruckDriver] Success - Request ID: ...
```

### Warning Logs (Acceptable):

```javascript
⚠️ ⚠️ API endpoint not available (status: 404), using mock data
⚠️ [AssignTruckDriver] Unexpected response structure
```

### Error Logs (Investigate):

```javascript
❌ ❌ Failed to load drivers: ...
❌ ❌ Failed to load trucks: ...
❌ [AssignTruckDriver] Assignment failed: ...
```

---

## 📊 Performance Metrics

### Target Response Times:

- Load drivers: < 500ms
- Load vehicles: < 500ms
- Create assignment: < 1s
- Revoke assignment: < 1s
- Page load: < 2s

### Debounce Delays:

- Driver selection check: 300ms
- Truck selection check: 300ms
- Filter changes: 300ms

---

## 🐛 Known Issues & Workarounds

### 1. Assignment List Endpoint Not Implemented

**Issue**: Backend `/api/admin/assignments/permanent/list` returns 404

**Workaround**: Frontend automatically uses mock data (50 sample assignments)

**Impact**: Filters and pagination work, but data is not real

**Fix**: Backend team needs to implement the endpoint

---

### 2. ESLint Import Warnings

**Issue**: Import ordering warnings in TypeScript files

**Impact**: None - purely stylistic, code compiles and runs perfectly

**Fix**: Optional - can run `npm run lint:fix` to auto-fix

---

## Sign-Off Checklist

Before declaring "Production Ready", verify:

### Backend Integration

- [ ] All API endpoints respond correctly
- [ ] Authentication working
- [ ] Permissions enforced
- [ ] Error responses standardized

### Frontend Functionality

- [ ] All CRUD operations work
- [ ] Forms validate correctly
- [ ] Error messages clear
- [ ] Loading states display
- [ ] Success messages show

### User Experience

- [ ] No console errors
- [ ] Fast page loads
- [ ] Smooth interactions
- [ ] Responsive design works
- [ ] Accessibility tested

### Data Integrity

- [ ] Assignments persist
- [ ] Revocations recorded
- [ ] Audit trail complete
- [ ] No data loss

---

## 📞 Support

**Issues Found?**

1. Check browser console for errors
2. Verify backend is running
3. Check network tab for failed requests
4. Review this testing guide
5. Consult `ANGULAR_BACKEND_INTEGRATION_IMPROVEMENTS.md`

**Need Help?**

- Frontend Issues: Check Angular component code
- Backend Issues: Review controller endpoints
- Integration Issues: Verify API response structures

---

## 🎉 Testing Complete!

Once all test cases pass:

1. Document any issues found
2. Create tickets for backend endpoints needed
3. Deploy to staging environment
4. Conduct user acceptance testing
5. Monitor production logs

**Good luck with testing! 🚀**
