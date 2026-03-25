> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Banner Management Authentication Issue - Summary & Resolution

## 🔴 Current Issue

The `/banners` route at http://localhost:4200/banners is protected by `AdminGuard`, which requires the user to have either `ADMIN` or `SUPERADMIN` role. However, the login API is returning **empty roles array** despite the database having the correct relationships.

## 🔍 Root Cause Analysis

### Database State: CORRECT
```sql
-- User exists with correct password
SELECT * FROM users WHERE username = 'superadmin';
-- Result: id=56, enabled=1, all flags=1

-- User is assigned to SUPERADMIN role
SELECT * FROM user_roles WHERE user_id = 56;
-- Result: user_id=56, role_id=6 ✅

-- SUPERADMIN role exists
SELECT * FROM roles WHERE id = 6;
-- Result: id=6, name='SUPERADMIN' ✅

-- Banner permissions assigned to SUPERADMIN role
SELECT COUNT(*) FROM role_permissions WHERE role_id = 6;
-- Result: 100+ permissions including BANNER_* ✅
```

### API Response: ❌ INCORRECT
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"password"}' | jq '.data.user'
```

**Current Response:**
```json
{
  "username": "superadmin",
  "email": "superadmin@example.com",
  "roles": [],        ← ❌ Should contain ["SUPERADMIN"]
  "permissions": []   ← ❌ Should contain banner permissions
}
```

### Backend Logs Show:
```
INFO: User found: superadmin, roles count: 0, permissions count: 0
```

## 🐛 Technical Root Cause

**Hibernate/JPA is not loading the ManyToMany relationship** from `user_roles` join table despite:

1. `@ManyToMany(fetch = FetchType.EAGER)` annotation in `User.java`
2. `@EntityGraph` with `attributeNodes` for roles and permissions
3. Custom `@Query` with `LEFT JOIN FETCH u.roles`
4. Database foreign keys and relationships are correct

**Attempted Fixes:**
- Changed `FetchType` to `EAGER` Applied
- Added `@EntityGraph` with named attribute nodes Applied
- Created custom JPQL query with `JOIN FETCH` Applied
- Enabled SQL logging to debug queries Applied
- Restarted backend multiple times Done

**Suspected Issues:**
1. **Hibernate Session Boundary**: The User entity may be detached before roles are accessed
2. **Circular Reference**: Potential bidirectional mapping issue between User ↔ Role
3. **Transaction Scope**: Roles might be loaded outside the transaction boundary
4. **Query Caching**: Hibernate second-level cache might be stale

## 🛠️ Working Credentials

**Login URL**: http://localhost:4200  
**Username**: `superadmin`  
**Password**: `password`

**Note**: The password is **NOT** `super123` as mentioned in some documentation files. The working BCrypt hash is:
```
$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG
```

## 🎯 Recommended Solutions

### Solution 1: Force Role Loading in Service Layer (Immediate Fix)
Modify `AuthController.login()` to manually fetch roles after authentication:

```java
// In AuthController.java
User user = optionalUser.get();

// Force initialization of lazy collections
Hibernate.initialize(user.getRoles());
Hibernate.initialize(user.getPermissions());

// Or use explicit role fetching
Set<Role> roles = new HashSet<>(userRepository.findById(user.getId())
    .map(User::getRoles)
    .orElse(new HashSet<>()));
```

### Solution 2: Use DTO Mapping (Best Practice)
Create a `UserDetailsDto` and manually map the roles:

```java
UserDetailsDto userDto = UserDetailsDto.builder()
    .username(user.getUsername())
    .email(user.getEmail())
    .roles(roleRepository.findRolesByUserId(user.getId())
        .stream()
        .map(r -> r.getName().toString())
        .collect(Collectors.toList()))
    .permissions(userPermissionService.getEffectivePermissionNames(user.getId()))
    .build();
```

### Solution 3: Custom UserRepository Query (Recommended)
Already attempted but may need refinement:

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    @Query("SELECT u FROM User u " +
           "LEFT JOIN FETCH u.roles r " +
           "LEFT JOIN FETCH r.rolePermissions " +
           "WHERE u.username = :username")
    Optional<User> findByUsernameWithAllDetails(@Param("username") String username);
}
```

### Solution 4: Check Hibernate ddl-auto Setting
The `spring.jpa.hibernate.ddl-auto=update` might be recreating the schema on every restart. Change to:

```properties
spring.jpa.hibernate.ddl-auto=validate
```

## 📝 Files Modified During Troubleshooting

1. `/tms-backend/src/main/java/com/svtrucking/logistics/model/User.java`
   - Added `@NamedEntityGraph` for roles and permissions

2. `/tms-backend/src/main/java/com/svtrucking/logistics/repository/UserRepository.java`
   - Added `@EntityGraph` annotations
   - Added custom `findByUsernameWithRolesAndPermissions()` method

3. `/tms-backend/src/main/java/com/svtrucking/logistics/controller/AuthController.java`
   - Added debug logging for roles count

4. `/tms-backend/src/main/resources/application.properties`
   - Enabled SQL logging: `spring.jpa.show-sql=true`
   - Enabled Hibernate SQL debug logging

## 🚀 Immediate Workaround

While investigating the JPA issue, you can temporarily bypass the role check in the frontend:

### Option A: Temporarily Disable AdminGuard Check
In `admin.guard.ts`, temporarily allow all authenticated users:

```typescript
private checkAdminAccess(url: string): Observable<boolean> {
  return this.authService.isAuthenticated$.pipe(
    take(1),
    map((isAuthenticated) => {
      if (!isAuthenticated) {
        this.authService.setRedirectUrl(url);
        this.router.navigate(['/login']);
        return false;
      }
      
      // TEMPORARY: Allow all authenticated users
      console.warn('⚠️ TEMP: Bypassing admin role check');
      return true; // ← Temporary bypass
      
      // Original code (commented out):
      // const user = this.authService.getCurrentUser();
      // const hasAdminAccess = user?.roles?.some(role =>
      //   ['ADMIN', 'SUPERADMIN'].includes(role.toUpperCase())
      // );
      // return hasAdminAccess || false;
    }),
  );
}
```

### Option B: Hardcode Role in AuthService (Testing Only)
In `auth.service.ts`, modify the login response handler:

```typescript
tap((response) => {
  if (response?.token) {
    this.saveToken(response.token);
    
    // TEMPORARY: Force inject SUPERADMIN role for testing
    const user = response.user;
    if (user.username === 'superadmin' && (!user.roles || user.roles.length === 0)) {
      console.warn('⚠️ TEMP: Injecting SUPERADMIN role for testing');
      user.roles = ['SUPERADMIN'];
    }
    
    localStorage.setItem('user', JSON.stringify(user));
    this.isAuthenticatedSubject.next(true);
  }
}),
```

## Testing the Banner Management Page

Once you bypass the auth (temporary workaround above):

1. **Login**: http://localhost:4200
   - Username: `superadmin`
   - Password: `password`

2. **Access Banners**: http://localhost:4200/banners
   - Should now load the banner management page

3. **Test Features**:
   - View 3 existing banners
   - Create new banner
   - Edit banner
   - Toggle active/inactive
   - Delete banner
   - Check Flutter app carousel updates

## 🔧 Next Steps to Fix Properly

1. **Enable Hibernate SQL Logging** (Already done)
   - Check `/tmp/backend-sql-debug.log` for actual SQL queries
   - Verify if `user_roles` join table is being queried

2. **Add Transaction Boundary**
   - Ensure `@Transactional` is on the AuthController.login() method
   - Try `@Transactional(readOnly = false, propagation = Propagation.REQUIRED)`

3. **Check Hibernate Session**
   - Add `Hibernate.initialize(user.getRoles())` before returning response

4. **Test with Direct SQL Query**
   - Instead of relying on JPA, use `@Query` with native SQL:
   ```java
   @Query(value = "SELECT r.* FROM roles r " +
                  "JOIN user_roles ur ON r.id = ur.role_id " +
                  "WHERE ur.user_id = :userId", nativeQuery = true)
   Set<Role> findRolesByUserId(@Param("userId") Long userId);
   ```

5. **Review ddl-auto Setting**
   - Change from `update` to `validate` to prevent schema recreation

## 📊 System Status

- Database: Running (MySQL 8.x in Docker)
- Backend: Running on port 8080 (with issues loading roles)
- Frontend: Running on port 4200
- Flutter App: Running on iOS simulator
- ⚠️ Authentication: Working but returns empty roles/permissions
- ❌ Admin Panel Access: Blocked by AdminGuard (requires role)

## 📞 Support Information

**Database Connection:**
```bash
docker exec svtms-mysql mysql -udriver -pdriverpass svlogistics_tms_db
```

**Backend Logs:**
```bash
tail -f /tmp/backend-sql-debug.log
```

**Health Check:**
```bash
curl http://localhost:8080/actuator/health
```

**Test Login API:**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"password"}' | jq .
```

---

**Last Updated**: December 1, 2025  
**Status**: 🔴 Investigating JPA role loading issue  
**Workaround Available**: Yes (temporary bypass in AdminGuard)
