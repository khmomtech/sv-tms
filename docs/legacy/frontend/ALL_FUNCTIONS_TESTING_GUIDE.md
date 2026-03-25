> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# ALL_FUNCTIONS Permission Testing Guide

## 🎯 Purpose

This guide provides comprehensive testing procedures to verify that the `all_functions` permission grants complete system access to SUPERADMIN users.

---

## 📋 Pre-Test Checklist

Before running tests, ensure:

- Backend is running on `localhost:8080`
- Frontend is running on `localhost:4200`
- Database is initialized with SUPERADMIN user
- SUPERADMIN has `all_functions` permission assigned
- Test dependencies are installed

---

## 🧪 Automated Tests

### Backend Integration Tests

**File:** `/tms-backend/src/test/java/com/svtrucking/logistics/security/AllFunctionsPermissionIntegrationTest.java`

**Run Command:**
```bash
cd tms-backend
./mvnw test -Dtest=AllFunctionsPermissionIntegrationTest
```

**Test Coverage:**
- SUPERADMIN can access all device endpoints
- SUPERADMIN can access all user management endpoints
- SUPERADMIN can access all driver endpoints
- SUPERADMIN can access all vehicle endpoints
- SUPERADMIN can access all dispatch endpoints
- SUPERADMIN can access all role/permission endpoints
- `all_functions` permission is returned in login response
- Regular ADMIN (without `all_functions`) gets 403 on restricted endpoints
- AuthorizationService grants access based on `all_functions`

**Expected Results:**
- All tests should pass (green checkmarks)
- No 403 Forbidden errors for SUPERADMIN
- Regular ADMIN should get 403 where appropriate

---

### Frontend E2E Tests

**File:** `/tms-frontend/e2e/all-functions-permission.spec.ts`

**Run Command:**
```bash
cd tms-frontend
npx playwright test e2e/all-functions-permission.spec.ts --headed
```

**Test Coverage:**
- SUPERADMIN can navigate to all major sections
- All API endpoints return 200 OK (not 403)
- All menu items are visible
- Create/Edit/Delete buttons are visible
- Permission guards allow access to all routes
- No 403 errors in network tab
- Comprehensive access matrix verification

**Expected Results:**
- All navigation tests pass
- No redirects to `/unauthorized`
- No 403 errors in browser console
- All feature categories accessible

---

## 🚀 Quick Test Execution

**One-Command Test Suite:**
```bash
cd /Users/sotheakh/Documents/develop/sv-tms
chmod +x test-all-functions-permission.sh
./test-all-functions-permission.sh
```

This script will:
1. Run backend integration tests
2. Run frontend E2E tests
3. Display comprehensive results
4. Provide manual verification checklist

---

## 🔍 Manual Testing Procedure

### Step 1: Login Verification

1. Navigate to `http://localhost:4200/login`
2. Login with SUPERADMIN credentials:
   - Username: `superadmin`
   - Password: `superadmin` (or your configured password)
3. Open browser DevTools → Application → Local Storage
4. Verify:
   - `user` contains `"roles": ["SUPERADMIN"]`
   - `permissions` contains `"all_functions"`

**Expected Result:**
```json
{
  "user": {
    "username": "superadmin",
    "roles": ["SUPERADMIN"],
    "permissions": ["all_functions", ...]
  }
}
```

---

### Step 2: Navigation Testing

Navigate to each section and verify NO permission errors:

| Section | URL | Expected Result |
|---------|-----|-----------------|
| Dashboard | `/dashboard` | Page loads |
| Fleet Drivers | `/fleet/drivers` | Page loads |
| Driver Devices | `/fleet/drivers/devices` | Page loads, no 403 |
| Driver Documents | `/fleet/drivers/documents` | Page loads |
| Fleet Vehicles | `/fleet/vehicles` | Page loads |
| Dispatch | `/dispatch` | Page loads |
| Orders | `/orders` | Page loads |
| Admin Users | `/admin/users` | Page loads |
| Admin Roles | `/admin/roles` | Page loads |
| Settings | `/settings` | Page loads |

**Failure Indicators:**
- ❌ Redirect to `/unauthorized`
- ❌ "Permission Denied" message
- ❌ 403 error in console

---

### Step 3: API Response Testing

Open browser DevTools → Network tab:

1. Navigate to `/fleet/drivers/devices`
2. Check the API call to `/api/driver/device/all`
3. Verify response:
   - Status: `200 OK` (NOT 403)
   - Response body: `{ "success": true, "data": [...] }`

**Test Multiple Endpoints:**

| Endpoint | Expected Status |
|----------|----------------|
| `GET /api/driver/device/all` | 200 OK |
| `GET /api/drivers` | 200 OK |
| `GET /api/vehicles` | 200 OK |
| `GET /api/admin/dispatches` | 200 OK |
| `GET /api/users` | 200 OK |
| `GET /api/roles` | 200 OK |
| `GET /api/permissions` | 200 OK |

---

### Step 4: UI Element Visibility

Verify SUPERADMIN sees all action buttons:

**Driver Management Page:**
- "Add Driver" button visible
- "Edit" button on each row
- "Delete" button on each row
- "View Details" button on each row

**Driver Devices Page:**
- "Approve" button on pending devices
- "Block" button on approved devices
- "Delete" button on each row

**Admin Section:**
- "Create User" button
- "Create Role" button
- "Assign Permissions" button

---

### Step 5: CRUD Operations Testing

**Create Operation:**
1. Navigate to `/fleet/drivers`
2. Click "Add Driver"
3. Fill in form
4. Submit
5. **Expected:** Success (not 403)

**Read Operation:**
1. Navigate to `/fleet/drivers/devices`
2. View device list
3. **Expected:** Data loads (not permission error)

**Update Operation:**
1. Navigate to `/fleet/drivers/devices`
2. Click "Approve" on a pending device
3. **Expected:** Device approved (not 403)

**Delete Operation:**
1. Navigate to `/fleet/drivers/devices`
2. Click "Delete" on a device
3. **Expected:** Device deleted (not 403)

---

### Step 6: Console Error Check

Open browser DevTools → Console:

**Should NOT see:**
- ❌ `403 Forbidden`
- ❌ `Permission denied`
- ❌ `Unauthorized`
- ❌ `Access denied`

**Should see:**
- Normal API success logs
- No security-related errors

---

## 🐛 Troubleshooting

### Issue: Backend tests fail with 403 errors

**Solution:**
1. Check if SUPERADMIN user has `all_functions` permission:
   ```sql
   SELECT u.username, p.name 
   FROM users u
   JOIN user_roles ur ON u.id = ur.user_id
   JOIN roles r ON ur.role_id = r.id
   JOIN role_permissions rp ON r.id = rp.role_id
   JOIN permissions p ON rp.permission_id = p.id
   WHERE u.username = 'superadmin';
   ```
2. Verify `PermissionEnsurer` ran on startup (check logs)
3. Restart backend to ensure latest code is running

---

### Issue: Frontend tests fail with navigation errors

**Solution:**
1. Ensure backend is running: `curl http://localhost:8080/actuator/health`
2. Ensure frontend is running: `curl http://localhost:4200`
3. Clear browser cache and localStorage
4. Re-login as SUPERADMIN

---

### Issue: "all_functions not found in permissions"

**Solution:**
1. Check database for permission:
   ```sql
   SELECT * FROM permissions WHERE name = 'all_functions';
   ```
2. If missing, run:
   ```sql
   INSERT INTO permissions (name, description, resource_type, action_type)
   VALUES ('all_functions', 'Wildcard permission for superadmin', 'Global', '*');
   ```
3. Assign to SUPERADMIN role:
   ```sql
   INSERT INTO role_permissions (role_id, permission_id)
   SELECT r.id, p.id 
   FROM roles r, permissions p
   WHERE r.name = 'SUPERADMIN' AND p.name = 'all_functions';
   ```

---

### Issue: Regular ADMIN has same access as SUPERADMIN

**Problem:** `all_functions` might be assigned to wrong roles

**Solution:**
1. Check role permissions:
   ```sql
   SELECT r.name, p.name 
   FROM roles r
   JOIN role_permissions rp ON r.id = rp.role_id
   JOIN permissions p ON rp.permission_id = p.id
   WHERE p.name = 'all_functions';
   ```
2. Only SUPERADMIN should have `all_functions`
3. Remove from other roles if found

---

## 📊 Success Criteria

All tests pass when:

**Backend:**
- All integration tests pass (green)
- SUPERADMIN gets 200 OK on all endpoints
- Regular ADMIN gets 403 on restricted endpoints
- `all_functions` in login response for SUPERADMIN

**Frontend:**
- All navigation tests pass
- No 403 errors in browser console
- All routes accessible
- All UI elements visible
- CRUD operations successful

**Manual:**
- Can navigate to all sections
- Can perform all operations
- No permission errors anywhere
- `all_functions` visible in localStorage

---

## 📝 Test Report Template

```markdown
# ALL_FUNCTIONS Permission Test Report

**Date:** 2025-11-28
**Tester:** [Your Name]
**Environment:** Local Development

## Backend Integration Tests
- Device endpoints: PASS
- User endpoints: PASS
- Driver endpoints: PASS
- Vehicle endpoints: PASS
- Dispatch endpoints: PASS
- Role/Permission endpoints: PASS
- Login response verification: PASS
- Regular ADMIN comparison: PASS

## Frontend E2E Tests
- Navigation tests: PASS
- API response tests: PASS
- UI visibility tests: PASS
- Permission guard tests: PASS
- CRUD operations: PASS
- No 403 errors: PASS

## Manual Verification
- Login with SUPERADMIN: PASS
- localStorage verification: PASS
- All sections accessible: PASS
- No console errors: PASS
- All operations successful: PASS

## Overall Result: PASS

**Notes:**
- All tests passed successfully
- SUPERADMIN has complete system access
- `all_functions` permission working as expected
```

---

## 🔗 Related Documentation

- [ALL_FUNCTIONS_PERMISSION_AUDIT.md](./ALL_FUNCTIONS_PERMISSION_AUDIT.md) - Complete system audit
- [AuthorizationService.java](./tms-backend/src/main/java/com/svtrucking/logistics/security/AuthorizationService.java) - Backend authorization logic
- [PermissionGuardService.ts](./tms-frontend/src/app/services/permission-guard.service.ts) - Frontend permission logic

---

**Last Updated:** November 28, 2025  
**Status:** Ready for Testing
