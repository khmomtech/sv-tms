> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Permission System Update - Complete Summary

## Overview
Comprehensive update to the permission system across frontend and backend to ensure all features have proper authorization controls.

## Changes Made

### 1. Frontend - Permissions Definition (`tms-frontend/src/app/shared/permissions.ts`)

**Added 160+ permissions organized by functional area:**

#### Core Modules
- **Dashboard**: `dashboard:read`
- **Customer**: read, list, create, update, delete
- **Vendor**: read, list, create, update, delete
- **Subcontractor**: read, admin:read
- **Item**: read, list, create, update, delete
- **Shipment**: read, list, create, update, delete, upload
- **Trip**: read, plan, monitor, pod

#### Fleet & Driver Management
- **Fleet**: read, management:read
- **Driver** (14 permissions): read, list, create, update, delete, manage, view_all, document:read, shift:read, account:read, performance:read, device:read, attendance:read, live:read
- **Vehicle**: read, create, update, delete
- **Trailer**: read, create, update, delete
- **Maintenance** (6 permissions): read, schedule:read, workorder:read, repair:read, part:read, record:read

#### Reports & Administration
- **Report**: read, dispatch:day, driver_performance
- **Administration**: read, user:read, role:read, permission:read
- **User**: read, create, update, delete
- **Role**: read, create, update, delete
- **Permission**: read, create, update, delete

#### Communication & Settings
- **Notification**: read, create, update, delete
- **Banner**: read, create, update, delete
- **Issue Management** (NEW): read, list, create, update, delete, assign, resolve
- **Settings** (16 permissions): read, create, update, delete, plus 12 category-specific read permissions

### 2. Backend - Database Migration (`V330__Add_comprehensive_permissions.sql`)

**Created comprehensive SQL migration that:**
- Inserts all 160+ permissions into the `permissions` table
- Uses `INSERT IGNORE` to prevent duplicates
- Automatically grants permissions to roles:
  - **ADMIN & SUPERADMIN**: All permissions
  - **MANAGER**: All read/list/view permissions
  - **DISPATCHER**: Specific operational permissions (dispatch, trips, drivers, orders)

**Migration Features:**
- Idempotent (safe to run multiple times)
- Preserves existing permissions
- Automatically assigns permissions to existing roles
- Includes backward compatibility for legacy permission names

### 3. Backend - Initialization Service (`PermissionInitializationService.java`)

**Created runtime permission initialization service:**
- Runs on application startup
- Ensures all required permissions exist in database
- Creates missing permissions automatically
- Logs initialization progress
- Provides fallback if migrations fail

**Features:**
- Uses `CommandLineRunner` for startup execution
- Transactional operation
- Detailed logging (created vs existing counts)
- Matches exact permission definitions from frontend

### 4. Sidebar Menu Integration

**Issue Management section added to sidebar:**
- All Issues
- Create Issue
- My Issues
- Open Issues
- Closed Issues

All menu items properly configured with permission checks.

## Permission Structure

### Naming Convention
```
resource:action[:subaction]
```

**Examples:**
- `customer:read` - View customers
- `driver:document:read` - View driver documents
- `setting:system.core:read` - View system core settings

### Resource Types
- Core: dashboard, customer, vendor, subcontractor, item
- Operations: shipment, trip, order, dispatch, pod
- Fleet: fleet, driver, vehicle, trailer, maintenance
- Admin: admin, user, role, permission
- Content: notification, banner, issue
- System: report, setting

### Action Types
- **Read Operations**: read, list, view, view_all
- **Write Operations**: create, update, delete
- **Special Operations**: upload, assign, manage, plan, monitor, resolve

## Role-Based Access Control (RBAC)

### Role Permission Assignments

**SUPERADMIN & ADMIN**
- All permissions (160+)

**MANAGER**
- All read/list/view permissions
- ❌ No create/update/delete permissions

**DISPATCHER**
- Dashboard, shipments, trips, dispatch
- Drivers (read, list, live tracking)
- Vehicles (read only)
- Customers (read, list)
- ❌ No administrative functions

**DRIVER**
- Basic user read permission only
- ❌ No management functions

## Database Schema

### Tables Affected
1. **permissions** - All permission definitions
2. **role_permissions** - Role-to-permission mappings
3. **user_permissions** - User-to-permission direct assignments (override)

### Indexes
- `permissions.name` - Unique index for fast permission lookup
- `role_permissions(role_id, permission_id)` - Composite primary key
- `user_permissions(user_id, permission_id)` - Composite primary key

## Security Implementation

### Backend Protection
All API endpoints protected with `@HasPermission` annotation:
```java
@GetMapping
@HasPermission("customer:read")
public ResponseEntity<List<Customer>> getAllCustomers() { ... }
```

### Frontend Guard
Menu items conditionally rendered based on permissions:
```typescript
{
  label: 'Create Issue',
  permission: 'issue:create'
}
```

### Permission Check Flow
1. User authenticates → JWT token generated
2. User roles loaded with permissions
3. Each request checked against required permission
4. Access granted only if user has permission (direct or via role)

## Testing Checklist

### Backend
- [ ] Run migration: `./mvnw flyway:migrate`
- [ ] Verify permissions in database: `SELECT COUNT(*) FROM permissions;` (should be 160+)
- [ ] Check role assignments: `SELECT COUNT(*) FROM role_permissions WHERE role_id = 1;`
- [ ] Test API endpoints with different roles
- [ ] Verify permission initialization logs on startup

### Frontend
- [ ] Login as ADMIN - verify all menu items visible
- [ ] Login as MANAGER - verify read-only access
- [ ] Login as DISPATCHER - verify limited operational access
- [ ] Login as DRIVER - verify minimal access
- [ ] Check Issue Management menu appears for authorized users

### Integration
- [ ] Create test user with specific permissions
- [ ] Verify frontend shows/hides features based on permissions
- [ ] Test API calls return 403 for unauthorized actions
- [ ] Verify permission checks work for nested resources

## Migration Path

### From Development to Production

1. **Backup Database**
   ```bash
   mysqldump -u root -p tms_db > backup_before_permissions.sql
   ```

2. **Run Migration**
   ```bash
   cd tms-backend
   ./mvnw flyway:migrate
   ```

3. **Verify Migration**
   ```sql
   SELECT COUNT(*) FROM permissions;
   SELECT * FROM permissions WHERE name LIKE 'issue:%';
   ```

4. **Restart Backend**
   ```bash
   ./mvnw spring-boot:run
   ```
   Check logs for: "Permission initialization complete"

5. **Test Frontend**
   - Clear browser cache
   - Login with different roles
   - Verify menu access

## Troubleshooting

### Issue: Permissions not showing in database
**Solution:** Check Flyway migration status:
```bash
./mvnw flyway:info
```

### Issue: Backend fails to start
**Solution:** Check for duplicate permission names in database:
```sql
SELECT name, COUNT(*) FROM permissions GROUP BY name HAVING COUNT(*) > 1;
```

### Issue: Menu items not visible
**Solution:** 
1. Check browser console for permission check errors
2. Verify user's role has required permissions
3. Check JWT token contains correct roles

### Issue: 403 Forbidden on API calls
**Solution:**
1. Verify permission exists in database
2. Check user has permission (direct or via role)
3. Review `@HasPermission` annotation on endpoint

## Files Modified/Created

### Frontend
- `tms-frontend/src/app/shared/permissions.ts` - Updated
- `tms-frontend/src/app/components/sidebar/sidebar.component.ts` - Updated

### Backend
- `tms-backend/src/main/resources/db/migration/V330__Add_comprehensive_permissions.sql` - Created
- `tms-backend/src/main/java/com/svtrucking/logistics/service/PermissionInitializationService.java` - Created

### Documentation
- `PERMISSION_SYSTEM_UPDATE.md` - This file

## Next Steps

1. **Review & Test** - Thoroughly test all role-based access scenarios
2. **Custom Roles** - Consider creating custom roles for specific departments
3. **Permission Audit** - Implement permission usage tracking
4. **Documentation** - Update user guides with permission requirements
5. **Monitoring** - Add metrics for permission denied events

## Maintenance

### Adding New Permissions
1. Add to `permissions.ts` frontend constant
2. Add to sidebar/component permission checks
3. Add to SQL migration or initialization service
4. Assign to appropriate roles
5. Add to backend `@HasPermission` annotations
6. Update documentation

### Removing Permissions
1. Remove from frontend
2. Remove role assignments from database
3. Remove permission from database
4. Remove from backend annotations
5. Update documentation

## Security Notes

- All permissions follow least-privilege principle
- Sensitive operations require explicit permissions
- No default "allow all" permissions
- Permission checks at both frontend and backend layers
- Audit trail for permission changes (via audit_trails table)

## Performance Considerations

- Permissions loaded once per session (cached in JWT)
- Database queries use indexed columns
- Frontend permission checks are synchronous
- Backend uses Spring Security's expression-based authorization
- Consider Redis caching for high-traffic scenarios

---

**Last Updated:** December 6, 2025  
**Version:** 1.0  
**Status:** Ready for Testing
