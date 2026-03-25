# Trip/Dispatch Management Testing Guide

## Quick Start Testing

### Prerequisites
- Backend running on `http://localhost:8080`
- Frontend running on `http://localhost:4200`
- Test user with dispatch permissions (admin/admin123)

### Test Scenarios

## 1. Trip List View (5 minutes)

**URL**: `http://localhost:4200/dispatch`

- [ ] Page loads without errors
- [ ] Trip list table displays with columns: Route Code, Driver, Vehicle, Status, Departure, Arrival
- [ ] Search by route code works
- [ ] Filter by status works
- [ ] Pagination works
- [ ] **NEW**: Click "View Location" button → navigates to driver tracking page
- [ ] **NEW**: Click "View Timeline" button → navigates to dispatch detail page

**Expected**: All features work, no console errors

---

## 2. Trip Planning & Tracking (10 minutes)

**URL**: `http://localhost:4200/dispatch/planning`

- [ ] Page loads with map view
- [ ] Trip list displays on left/right panel
- [ ] **NEW**: Click "View" button on dispatch → opens detail in new tab
- [ ] **NEW**: Click "Edit" button on dispatch → opens trip modal with data
- [ ] **NEW**: Click "Delete" button on dispatch:
  - Shows confirmation dialog
  - Deletes trip if confirmed
  - Refreshes list after deletion
- [ ] **NEW**: Click "Assign Driver" button → opens driver assignment modal
- [ ] **NEW**: Click "Manage Orders" button → navigates to related order
- [ ] **NEW**: Click "Generate Report" button → navigates to detail page
- [ ] **NEW**: Click "Mark as Complete" button:
  - Updates status to COMPLETED
  - Refreshes list
  - Shows success message

**Expected**: All buttons work, proper navigation, confirmations shown

---

## 3. Transport Order Management (5 minutes)

**URL**: `http://localhost:4200/dispatch/planning` (in related orders section)

- [ ] Related orders display for selected dispatch
- [ ] **NEW**: Click "View" button on order → navigates to order detail
- [ ] **NEW**: Click "Edit" button on order → navigates to order edit page
- [ ] **NEW**: Click "Delete" button on order:
  - Shows confirmation dialog
  - Deletes order if confirmed
  - Refreshes orders list
  - Shows error if order has dependent dispatches

**Expected**: All order operations work correctly

---

## 4. Trip Monitoring (5 minutes)

**URL**: `http://localhost:4200/dispatch/monitor`

- [ ] Page loads with trip status overview
- [ ] Real-time updates display (if available)
- [ ] Filter by status works
- [ ] Click on trip → shows details
- [ ] Status badges display correctly (color-coded)

**Expected**: Monitoring dashboard functional

---

## 5. Proof of Delivery (3 minutes)

**URL**: `http://localhost:4200/dispatch/loading-monitor`

- [ ] Page loads without errors
- [ ] POD documents display
- [ ] Signatures/photos visible
- [ ] Delivery status shown

**Expected**: POD viewing works

---

## 6. Trip Detail Page (7 minutes)

**URL**: `http://localhost:4200/dispatch/:id` (replace :id with actual trip ID)

- [ ] Page loads with complete trip information
- [ ] Driver and vehicle details display
- [ ] Route information shown
- [ ] Timeline/status history visible
- [ ] Related orders listed
- [ ] **VERIFY**: Export/PDF button works
- [ ] **VERIFY**: All data matches backend

**Expected**: Complete trip information displayed

---

## 7. Trip Maps View (3 minutes)

**URL**: `http://localhost:4200/dispatch/maps-view`

- [ ] Google Maps loads
- [ ] Trip routes displayed on map
- [ ] Driver locations shown (if available)
- [ ] Map controls work (zoom, pan)

**Expected**: Map view functional

---

## 8. Driver Location Tracking (5 minutes)

**From trip list**, click "View Location" button:

- [ ] Navigates to `/driver-monitoring/live-location`
- [ ] Driver ID passed as parameter
- [ ] Driver's current GPS location shown on map
- [ ] Location updates in real-time (if tracking active)

**Expected**: Live driver tracking works

---

## 9. Delete Operations (10 minutes)

### Test Delete Dispatch

1. Go to trip planning page
2. Select a test dispatch (not in use)
3. Click "Delete" button
4. **Verify**:
   - [ ] Confirmation dialog appears: "Are you sure you want to delete this dispatch?"
   - [ ] Click Cancel → nothing happens
   - [ ] Click OK → dispatch deleted
   - [ ] List refreshes automatically
   - [ ] Toast/alert message appears
   - [ ] Backend API called: `DELETE /api/dispatches/:id`

### Test Delete Order

1. Go to trip planning page
2. Select dispatch with orders
3. Expand related orders
4. Click "Delete" on an order
5. **Verify**:
   - [ ] Confirmation dialog appears
   - [ ] Click Cancel → nothing happens
   - [ ] Click OK → order deleted
   - [ ] Orders list refreshes
   - [ ] Error shown if order has active dispatches

**Expected**: Confirmation required, proper API calls, error handling

---

## 10. Status Update Workflow (5 minutes)

1. Go to trip planning page
2. Find a dispatch in PENDING or IN_TRANSIT status
3. Click "Mark as Complete" button
4. **Verify**:
   - [ ] Status updates to COMPLETED
   - [ ] List refreshes with new status
   - [ ] Status badge changes color
   - [ ] Backend API called: `PATCH /api/dispatches/:id/status`
   - [ ] Success message displayed

**Expected**: Status update works correctly

---

## 11. Navigation Flow (5 minutes)

Test complete navigation flow:

1. `/dispatch` (list)
2. Click trip → `/dispatch/:id` (detail)
3. Click "Back" → `/dispatch` (list)
4. Click "Plan Trip" → `/dispatch/planning`
5. Click "Monitor" → `/dispatch/monitor`
6. Click "POD" → `/dispatch/loading-monitor`
7. Click "Maps" → `/dispatch/maps-view`

**Verify at each step**:
- [ ] URL changes correctly
- [ ] Page content loads
- [ ] No console errors
- [ ] Browser back button works
- [ ] Session persists (no re-login)

**Expected**: Smooth navigation, no errors

---

## 12. Error Handling (10 minutes)

### Test Network Errors

1. Stop backend server
2. Try delete operation
3. **Verify**:
   - [ ] Error message displayed
   - [ ] No silent failures
   - [ ] UI doesn't break

### Test Invalid Data

1. Try to delete non-existent dispatch
2. **Verify**:
   - [ ] 404 error handled gracefully
   - [ ] User-friendly message shown

### Test Permission Errors

1. Login as user without TRIP_PLAN permission
2. Try to access `/dispatch/planning`
3. **Verify**:
   - [ ] Access denied or redirected
   - [ ] Permission check working

**Expected**: All errors handled gracefully

---

## API Endpoints to Verify

Use browser DevTools Network tab to verify these calls:

| Action | Method | Endpoint | Expected |
|--------|--------|----------|----------|
| View Location | - | `/driver-monitoring/live-location?driverId=X` | Page navigates |
| View Timeline | - | `/dispatch/:id` | Page navigates |
| View Dispatch | - | `window.open('/dispatch/:id')` | New tab opens |
| Edit Dispatch | - | Opens modal | Modal with data |
| Delete Dispatch | DELETE | `/api/dispatches/:id` | 204 No Content |
| Delete Order | DELETE | `/api/transport-orders/:id` | 204 No Content |
| Mark Complete | PATCH | `/api/dispatches/:id/status` | 200 OK |

---

## Checklist Summary

After testing all scenarios above, verify:

- [ ] All 11 newly implemented functions work
- [ ] No console errors on any trip pages
- [ ] All confirmations appear for destructive actions
- [ ] All API calls succeed (check Network tab)
- [ ] All navigation works correctly
- [ ] Error messages display properly
- [ ] Lists refresh after operations
- [ ] Session persists across pages
- [ ] Browser back button works
- [ ] No visual glitches or broken UI

---

## Common Issues & Solutions

### Issue: "View Location" doesn't work
- **Check**: Driver ID is being passed correctly
- **Check**: Driver monitoring route exists
- **Check**: User has DRIVER_READ permission

### Issue: Delete doesn't refresh list
- **Check**: `loadDispatches()` is called after deletion
- **Check**: API returns success (204/200)
- **Check**: Console for errors

### Issue: "Mark as Complete" fails
- **Check**: Dispatch status allows completion
- **Check**: Backend validates status transitions
- **Check**: User has TRIP_UPDATE permission

### Issue: Modal doesn't open
- **Check**: `openTripModal` method exists
- **Check**: Trip modal component is imported
- **Check**: Console for errors

---

## Test Data Setup

For thorough testing, ensure you have:

- At least 5 dispatches in different statuses:
  - 1-2 in PENDING
  - 2-3 in IN_TRANSIT
  - 1-2 in COMPLETED
- Each dispatch with:
  - Assigned driver
  - Assigned vehicle
  - Route code
  - Related transport order(s)
- At least 1 driver with active GPS tracking

---

## Testing Timeline

| Test Suite | Estimated Time |
|------------|---------------|
| Trip List | 5 min |
| Trip Planning | 10 min |
| Order Management | 5 min |
| Trip Monitoring | 5 min |
| POD | 3 min |
| Detail Page | 7 min |
| Maps View | 3 min |
| Driver Tracking | 5 min |
| Delete Operations | 10 min |
| Status Updates | 5 min |
| Navigation | 5 min |
| Error Handling | 10 min |
| **Total** | **73 minutes** |

---

## Success Criteria

**Ready for Production** if:
- All test scenarios pass
- No critical bugs found
- All features work as documented
- Error handling is robust
- Performance is acceptable (< 3s load times)
- No console errors on any page

⚠️ **Needs Work** if:
- Any test scenario fails
- Critical bugs found (data loss, crashes)
- Errors not handled gracefully
- Performance issues (> 5s load times)

---

## Reporting Issues

If you find bugs during testing, report with:

1. **Title**: Brief description (e.g., "Delete dispatch doesn't refresh list")
2. **Steps to Reproduce**: Numbered list of exact steps
3. **Expected Result**: What should happen
4. **Actual Result**: What actually happens
5. **Console Errors**: Any errors from browser console
6. **Network Tab**: API call details if relevant
7. **Screenshot**: If UI is involved

---

## Post-Testing

After successful testing:

1. Document any discovered edge cases
2. Update user documentation if needed
3. Create Jira tickets for any "nice-to-have" improvements
4. Update this guide with any new scenarios
5. Mark features as "Tested ✅" in project board

---

**Happy Testing!** 🚀

For questions or issues, contact the development team.
