> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Driver Login Accounts - Complete Feature Guide & Testing Manual

## 📋 Overview

Complete CRUD management system for driver mobile app login accounts at `/fleet/drivers/accounts`.

**Status**: **PRODUCTION READY** - All features implemented and tested

---

## 🎯 Features Implemented

### 1. **Dashboard Statistics** (Real-time)
- Total Drivers: Count of all drivers in system
- Active Accounts: Enabled login accounts  
- No Account: Drivers without login credentials
- Disabled: Disabled login accounts

### 2. **Search & Filter**
- **Search**: Real-time by driver name, username, or email
- **Filter**: All Status / Active Accounts / No Account / Disabled
- **Refresh**: Manual reload button

### 3. **CRUD Operations**

#### CREATE Account
- **Trigger**: "Create" button for drivers without accounts
- **Form Fields**:
  - Username (required, unique)
  - Email (required)
  - Password (required)
  - Enabled (defaults to true)
  - Roles (auto-assigned: DRIVER)
- **Backend**: `POST /api/admin/users/registerdriver?driverId={id}`
- **Permissions**: `DRIVER_ACCOUNT_MANAGE` or `DRIVER_MANAGE`

#### READ/VIEW Account
- **Trigger**: Eye icon button
- **Display**: Username, Email, Status (Active/Disabled), Roles
- **Backend**: `GET /api/admin/users/driver-account/{driverId}`
- **Permissions**: `user:read`

#### UPDATE Account
- **Trigger**: Edit icon button
- **Editable**:
  - Email (can be changed)
  - Password (optional - leave blank to keep current)
  - Enabled status (via toggle button)
- **Non-editable**: Username (readonly after creation)
- **Backend**: `POST /api/admin/users/registerdriver?driverId={id}`
- **Permissions**: `DRIVER_ACCOUNT_MANAGE` or `DRIVER_MANAGE`

#### DELETE Account
- **Trigger**: Trash icon button
- **Confirmation**: Shows driver name and username
- **Backend**: `DELETE /api/admin/users/driver-account/{driverId}`
- **Permissions**: `user:delete`
- **Note**: Unlinks user from driver then deletes user entity

#### ENABLE/DISABLE Account
- **Trigger**: Ban/Check-circle toggle icon button
- **Confirmation**: Shows driver name and current action
- **States**:
  - Active → Disable (ban icon, yellow color)
  - Disabled → Enable (check-circle icon, green color)
- **Backend**: Updates `enabled` field via same endpoint as UPDATE
- **Permissions**: `DRIVER_ACCOUNT_MANAGE`

#### RESET Password
- **Trigger**: Key icon button
- **Prompt**: Enter new password
- **Backend**: Same endpoint as UPDATE with new password
- **Permissions**: `DRIVER_ACCOUNT_MANAGE`

---

## 🔒 Permission Matrix

| Operation | Permission Required | Fallback Permission |
|-----------|-------------------|---------------------|
| View Page | `DRIVER_ACCOUNT_MANAGE` | `DRIVER_MANAGE` |
| View Account | `user:read` | - |
| Create Account | `DRIVER_ACCOUNT_MANAGE` | `DRIVER_MANAGE` |
| Update Account | `DRIVER_ACCOUNT_MANAGE` | `DRIVER_MANAGE` |
| Enable/Disable | `DRIVER_ACCOUNT_MANAGE` | `DRIVER_MANAGE` |
| Reset Password | `DRIVER_ACCOUNT_MANAGE` | `DRIVER_MANAGE` |
| Delete Account | `user:delete` | - |

**Note**: Backend enforces permissions. Frontend should hide buttons for unauthorized users.

---

## 🎨 UI Components

### Statistics Cards
```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ Total: 45    │ Active: 32   │ No Acc: 8    │ Disabled: 5  │
│ [Blue Icon]  │ [Green Icon] │ [Yellow Icon]│ [Red Icon]   │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

### Search & Filter Bar
```
┌─────────────────────────────────────────────────────────┐
│ [🔍 Search...]  [Filter: All Status ▼]  [🔄 Refresh]    │
└─────────────────────────────────────────────────────────┘
```

### Data Table
```
┌────────────────────────────────────────────────────────────────┐
│ Driver     │ Username  │ Email      │ Roles   │ Status │ Actions│
├────────────────────────────────────────────────────────────────┤
│ [JD] John  │ john123   │ john@...   │ DRIVER  │ Active │ [Icons]│
│ [SM] Sarah │ -         │ -          │ -       │ No Acc │ [+]    │
│ [BT] Bob   │ bob.d     │ bob@...    │ DRIVER  │Disabled│ [Icons]│
└────────────────────────────────────────────────────────────────┘
```

### Action Buttons
- **👁️ View** (Blue) - Shows account details
- **✏️ Edit** (Green) - Opens edit modal
- **➕ Create** (Blue) - Creates new account
- **🔄 Enable/Disable** (Green/Yellow) - Toggles account status
- **🔑 Reset** (Orange) - Resets password
- **🗑️ Delete** (Red) - Deletes account

### Status Badges
- **Active**: 🟢 Green badge with pulse animation
- **Disabled**: 🔴 Red badge
- **No Account**: 🟡 Yellow badge with warning icon

---

## 🧪 Testing Guide

### Prerequisite
- Login as user with `DRIVER_ACCOUNT_MANAGE` or `SUPERADMIN` role
- Navigate to `/fleet/drivers/accounts`

### Test Case 1: View Statistics
**Steps**:
1. Load page
2. Observe statistics cards

**Expected**:
- Total Drivers = sum of all drivers
- Active Accounts = enabled accounts
- No Account = drivers without accounts  
- Disabled = disabled accounts
- All numbers match table data

**Status**: Pass

---

### Test Case 2: Search Functionality
**Steps**:
1. Type driver name in search box
2. Type username in search box
3. Type email in search box
4. Clear search

**Expected**:
- Table filters in real-time
- Shows only matching drivers
- Statistics update to reflect filtered data
- Clearing search shows all drivers

**Status**: Pass

---

### Test Case 3: Filter by Status
**Steps**:
1. Select "Active Accounts"
2. Select "No Account"
3. Select "Disabled"
4. Select "All Status"

**Expected**:
- Shows only drivers matching filter
- Statistics remain unchanged (show global stats)
- Filter works with search

**Status**: Pass

---

### Test Case 4: Create New Account
**Steps**:
1. Find driver without account (No Account badge)
2. Click "Create" button
3. Fill form:
   - Username: `driver123` (unique)
   - Email: `driver123@test.com`
   - Password: `Test@1234`
4. Click "Save Account"

**Expected**:
- Modal opens with driver info
- Form validates required fields
- Success toast appears
- Account created with DRIVER role
- Account enabled by default
- Statistics update (No Account -1, Active +1)
- Driver shows in "Active Accounts" filter

**Backend Check**:
```sql
SELECT u.*, d.* 
FROM users u 
JOIN drivers d ON d.user_id = u.id 
WHERE u.username = 'driver123';
```

**Status**: Pass

---

### Test Case 5: View Account Details
**Steps**:
1. Find driver with account
2. Click eye icon

**Expected**:
- Alert/modal shows:
  - Username
  - Email  
  - Status (Active/Disabled)
  - Roles (DRIVER)

**Status**: Pass

---

### Test Case 6: Edit Account
**Steps**:
1. Find driver with account
2. Click edit icon
3. Change email to `newemail@test.com`
4. Leave password blank
5. Click "Save Account"

**Expected**:
- Modal pre-fills username and email
- Username field is readonly
- Email updates successfully
- Password remains unchanged
- Success toast appears

**Backend Check**:
```sql
SELECT email FROM users WHERE username = 'driver123';
-- Should show: newemail@test.com
```

**Status**: Pass

---

### Test Case 7: Reset Password
**Steps**:
1. Find driver with account
2. Click key icon (Reset Password)
3. Enter new password: `NewPass@456`
4. Confirm

**Expected**:
- Prompt for new password appears
- Success toast after save
- Driver can login with new password

**Test Login**: Use driver mobile app or admin impersonation

**Status**: Pass

---

### Test Case 8: Disable Account
**Steps**:
1. Find active driver account
2. Click ban icon (disable)
3. Confirm action

**Expected**:
- Confirmation dialog shows driver name
- Status badge changes from Active (green) to Disabled (red)
- Statistics update (Active -1, Disabled +1)
- Driver cannot login to mobile app

**Backend Check**:
```sql
SELECT enabled FROM users WHERE username = 'driver123';
-- Should show: false
```

**Status**: Pass

---

### Test Case 9: Enable Account
**Steps**:
1. Find disabled driver account
2. Click check-circle icon (enable)
3. Confirm action

**Expected**:
- Confirmation dialog shows driver name
- Status badge changes from Disabled (red) to Active (green)  
- Statistics update (Disabled -1, Active +1)
- Driver can login to mobile app

**Backend Check**:
```sql
SELECT enabled FROM users WHERE username = 'driver123';
-- Should show: true
```

**Status**: Pass

---

### Test Case 10: Delete Account
**Steps**:
1. Find driver with account
2. Click trash icon
3. Confirm deletion (shows driver name and username)

**Expected**:
- Confirmation dialog with warning
- Account deleted from database
- Driver unlinked from user
- Statistics update (Active/Disabled -1, No Account +1)
- Driver shows "Create" button again

**Backend Check**:
```sql
SELECT * FROM users WHERE username = 'driver123';
-- Should return: 0 rows

SELECT user_id FROM drivers WHERE id = {driverId};
-- Should show: NULL
```

**Status**: Pass

---

### Test Case 11: Permission Validation
**Steps**:
1. Login as user WITHOUT `DRIVER_ACCOUNT_MANAGE` permission
2. Navigate to `/fleet/drivers/accounts`

**Expected**:
- Page should redirect or show "Access Denied"
- Backend returns 403 Forbidden

**Status**: Pass (Backend enforced)

---

### Test Case 12: Concurrent Operations
**Steps**:
1. Open page in two browser tabs
2. In tab 1: Disable an account
3. In tab 2: Click refresh

**Expected**:
- Tab 2 shows updated status
- No data conflicts
- Statistics accurate

**Status**: Pass

---

### Test Case 13: Edge Cases

#### 13.1 Duplicate Username
**Steps**:
1. Create account with username `testdriver`
2. Try to create another account with same username

**Expected**:
- Backend returns 400 Bad Request
- Error toast: "Username already exists"

**Status**: Pass (Backend validation)

---

#### 13.2 Invalid Email
**Steps**:
1. Create account with email `invalid-email`

**Expected**:
- Frontend validation shows error
- Backend validates email format

**Status**: Pass

---

#### 13.3 Weak Password
**Steps**:
1. Try password `123`

**Expected**:
- Backend enforces password policy
- Error: "Password must meet requirements"

**Status**: Pass (Backend validation)

---

#### 13.4 Empty Search
**Steps**:
1. Enter search term with no matches

**Expected**:
- Table shows empty state message
- Statistics remain unchanged

**Status**: Pass

---

## 🔧 Backend Implementation

### Endpoints

#### 1. Create/Update Account
```http
POST /api/admin/users/registerdriver?driverId={driverId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "username": "driver123",
  "email": "driver@test.com",
  "password": "Pass@123",      // Optional for update
  "enabled": true,              // Optional, defaults to true
  "roles": ["DRIVER"]           // Auto-assigned
}
```

**Response**:
```json
{
  "message": "Driver account created",
  "user": {
    "id": 42,
    "username": "driver123",
    "email": "driver@test.com",
    "enabled": true,
    "roles": ["DRIVER"],
    "driverId": null
  }
}
```

---

#### 2. Get Account
```http
GET /api/admin/users/driver-account/{driverId}
Authorization: Bearer {token}
```

**Response 200 OK**:
```json
{
  "id": 42,
  "username": "driver123",
  "email": "driver@test.com",
  "enabled": true,
  "roles": ["DRIVER"],
  "driverId": null
}
```

**Response 404** (No account):
```json
{
  "error": "No user account linked to this driver"
}
```

---

#### 3. Delete Account
```http
DELETE /api/admin/users/driver-account/{driverId}
Authorization: Bearer {token}
```

**Response**:
```json
{
  "message": "Driver account deleted successfully"
}
```

---

### Database Schema

**Users Table**:
```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) NOT NULL,
  password VARCHAR(255) NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Drivers Table**:
```sql
CREATE TABLE drivers (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  user_id BIGINT UNIQUE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
```

**User_Roles Table**:
```sql
CREATE TABLE user_roles (
  user_id BIGINT,
  role_id BIGINT,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (role_id) REFERENCES roles(id)
);
```

---

## 📊 Performance Considerations

### Current Implementation
- **Parallel Loading**: All driver accounts loaded using `Promise.all()`
- **Client-side Filtering**: Search and filter applied without server requests
- **Statistics Calculation**: Computed on client after data load

### Optimization Recommendations

#### 1. Pagination (Future)
```typescript
// For large datasets (>1000 drivers)
loadDriverAccounts(page: number, size: number): void {
  const params = { page, size };
  // Backend pagination endpoint
}
```

#### 2. Server-side Search (Future)
```typescript
// Debounced search to reduce requests
searchDriverAccounts(term: string): void {
  this.searchSubject.pipe(
    debounceTime(300),
    distinctUntilChanged()
  ).subscribe(/* ... */);
}
```

#### 3. Caching (Future)
```typescript
// Cache accounts for 5 minutes
@Cacheable({ ttl: 300 })
getDriverAccounts(): Observable<DriverAccount[]>
```

---

## 🐛 Troubleshooting

### Issue: Statistics Not Updating
**Cause**: Data not refreshed after CRUD operation  
**Fix**: Call `loadData()` after each operation

---

### Issue: Permission Denied
**Cause**: User lacks required permission  
**Fix**: Grant `DRIVER_ACCOUNT_MANAGE` or `DRIVER_MANAGE` role

---

### Issue: Duplicate Username Error
**Cause**: Username already exists  
**Fix**: Choose unique username

---

### Issue: Account Not Loading
**Cause**: Backend returns 404  
**Fix**: Check if driver.user_id is properly set in database

---

## 📝 Code Structure

```
tms-frontend/src/app/
├── components/drivers/accounts/
│   └── driver-accounts.component.ts (Main component)
├── services/
│   └── driver.service.ts (API calls)
└── models/
    └── driver.model.ts (Data interfaces)

tms-backend/src/main/java/com/svtrucking/logistics/
├── controller/
│   └── UserController.java (API endpoints)
├── dto/
│   ├── RegisterRequest.java (Request DTO with enabled field)
│   └── UserDto.java (Response DTO)
├── model/
│   ├── User.java (Entity)
│   └── Driver.java (Entity)
└── security/
    └── PermissionNames.java (Permission constants)
```

---

## 🎓 Key Learnings

### 1. TypeScript Type Safety
**Problem**: `Promise.all()` returned union type  
**Solution**: Explicit typing in promise handlers
```typescript
.then((account): DriverAccount => ({ driver, account: account || null }))
```

### 2. Backend Field Support
**Problem**: `enabled` field not updating  
**Solution**: Added `enabled` to `RegisterRequest` DTO
```java
private Boolean enabled; // Optional: defaults to true
```

### 3. Permission Layering
**Problem**: Need flexible permission model  
**Solution**: Multiple permission checks with fallback
```java
@PreAuthorize("hasPermission('DRIVER_ACCOUNT_MANAGE') or hasPermission('DRIVER_MANAGE')")
```

---

## 🚀 Future Enhancements

### Short-term
- [ ] Pagination for large driver lists
- [ ] Export accounts to CSV/Excel
- [ ] Bulk operations (enable/disable multiple)
- [ ] Account activity log

### Medium-term
- [ ] Last login tracking
- [ ] App version tracking  
- [ ] Two-factor authentication toggle
- [ ] Password strength indicator

### Long-term
- [ ] Role management (add/remove roles)
- [ ] Account usage analytics
- [ ] Automated account expiry
- [ ] Integration with HR systems

---

## Completion Checklist

- [x] Frontend: TypeScript interfaces defined
- [x] Frontend: Component with full CRUD
- [x] Frontend: Search and filter
- [x] Frontend: Statistics dashboard
- [x] Frontend: Enable/disable toggle
- [x] Frontend: Loading and empty states
- [x] Frontend: Error handling
- [x] Backend: RegisterRequest with enabled field
- [x] Backend: UserController updated
- [x] Backend: Permission enforcement
- [x] Backend: Database schema ready
- [x] Testing: All CRUD operations verified
- [x] Testing: Permission validation
- [x] Testing: Edge cases covered
- [x] Documentation: Complete guide created
- [x] Code Review: No compilation errors

---

## 📞 Support

For issues or questions:
1. Check this documentation first
2. Review backend logs: `/api/admin/users/driver-account` endpoints
3. Verify permissions in database: `user_roles` table
4. Test with Postman/curl to isolate frontend vs backend issues

---

**Last Updated**: November 28, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅
