# User / Role / Permission Guide

SV-TMS uses Role-Based Access Control (RBAC). Users hold Roles; Roles hold Permissions.
No direct user→permission link exists — everything goes through roles.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Data Model](#2-data-model)
3. [Role Types](#3-role-types)
4. [Permission Format](#4-permission-format)
5. [Authorization Flow](#5-authorization-flow)
6. [Backend API Reference](#6-backend-api-reference)
7. [Frontend Services & Guards](#7-frontend-services--guards)
8. [Admin UI Screens](#8-admin-ui-screens)
9. [Startup Seeding](#9-startup-seeding)
10. [Common Tasks](#10-common-tasks)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                  Angular Admin UI                │
│  LoginComponent → loadEffectivePermissions()     │
│  PermissionGuardService (BehaviorSubject cache)  │
│  PermissionGuard / RoleGuard (route protection)  │
└────────────────────┬────────────────────────────┘
                     │ Bearer JWT  /api/admin/*
                     ▼
┌─────────────────────────────────────────────────┐
│               API Gateway :8086                  │
│  /api/admin/**  →  core-api:8080                 │
│  /api/auth/**   →  auth-api:8083                 │
└────────────────────┬────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────┐
│              tms-core-api :8080                  │
│  @PreAuthorize("@authorizationService            │
│      .hasPermission('resource:action')")         │
│                                                  │
│  AuthorizationService                            │
│    1. SUPERADMIN role  → grant all               │
│    2. all_functions    → grant all (non-explicit)│
│    3. effective perms  → role → permissions      │
└────────────────────┬────────────────────────────┘
                     ▼
              MySQL: users, roles, permissions
                     user_roles, role_permissions
```

---

## 2. Data Model

### Tables

| Table | Purpose |
|-------|---------|
| `users` | Login accounts — username, password (bcrypt), email, enabled |
| `roles` | Role definitions — name (RoleType enum), description |
| `permissions` | Permission atoms — name (`resource:action`), resourceType, actionType |
| `user_roles` | Many-to-many join: user_id ↔ role_id |
| `role_permissions` | Many-to-many join: role_id ↔ permission_id |

### Entity relationships

```
User ──(ManyToMany)──▶ Role ──(ManyToMany)──▶ Permission
         user_roles              role_permissions
         (EAGER)                 (LAZY)
```

`User.roles` is loaded `EAGER`. `Role.permissions` is loaded `LAZY` — use the named graph
`Role.withPermissions` when you need them in a single query.

### Key source files

| File | Path |
|------|------|
| `User.java` | `tms-backend-shared/.../model/User.java` |
| `Role.java` | `tms-backend-shared/.../model/Role.java` |
| `Permission.java` | `tms-backend-shared/.../model/Permission.java` |
| `RoleType.java` | `tms-backend-shared/.../enums/RoleType.java` |
| `UserDto.java` | `tms-core-api/.../dto/UserDto.java` |

---

## 3. Role Types

Defined in `RoleType` enum. Never hardcode role strings — use the enum.

| Role | Intended users | Notes |
|------|---------------|-------|
| `SUPERADMIN` | Platform owner | Bypasses all permission checks — cannot be restricted |
| `ADMIN` | Internal operations staff | Broad access seeded at startup |
| `MANAGER` | Department / area managers | Order + dispatch read/write, no user management |
| `TECHNICIAN` | Workshop mechanics | Vehicle maintenance scope |
| `DRIVER` | Mobile app users | Driver App API only — no admin UI access |
| `CUSTOMER` | Customer portal users | `/api/customer/{customerId}/*` scope only |
| `PARTNER_ADMIN` | Partner company administrators | Partner-scoped data |
| `USER` | Basic authenticated users | Minimal read access |
| `SAFETY` | Factory gate / pre-load safety | Safety API scope |
| `LOADING` | Warehouse operators | Loading operations scope |
| `DISPATCH_MONITOR` | Control tower, read-only | Dispatch read + monitor only |

> **Rule:** SUPERADMIN always grants full access server-side — even without any role-permission row
> in the database.

---

## 4. Permission Format

All permission names follow `resource:action` format. The only exception is `all_functions`.

```
user:read          user:create        user:update        user:delete
role:read          role:create        role:update        role:delete
permission:read    permission:create  permission:update  permission:delete
driver:read        driver:create      driver:update      driver:manage
vehicle:read       vehicle:create     vehicle:update     vehicle:delete
order:read         order:create       order:update       order:assign
dispatch:read      dispatch:create    dispatch:update    dispatch:monitor
customer:read      customer:create    customer:update    customer:delete
pod:read
audit:read         audit:create
settings:read      settings:update
all_functions      (wildcard — grants everything except explicit-only perms)
```

### Explicit-only permissions (not granted by `all_functions`)

These must be assigned **directly to a role**. They cannot be granted via wildcard:

- `dispatch:flow:manage`
- `dispatch:status:override`
- `dispatch:status:manual:update`

> **Why:** These are high-risk operations (overriding automated state machines) that must be
> consciously assigned — never inherited implicitly.

### Adding a new permission

1. Add the constant to `PermissionNames.java` (shared) and `PermissionType.java` (core).
2. Seed it in `PermissionInitializationService.java` so it is created on next startup.
3. Add it to `PERMISSIONS` in `tms-admin-web-ui/src/app/shared/permissions.ts`.
4. Use it in `@PreAuthorize` on the backend endpoint.
5. Use it in route `data: { permissions: ['resource:action'] }` on the Angular route.

---

## 5. Authorization Flow

### Backend (every protected endpoint)

```java
@GetMapping
@PreAuthorize("@authorizationService.hasPermission('user:read')")
public ResponseEntity<List<UserDto>> getAllUsers() { ... }
```

`AuthorizationService.hasPermission(name)` resolution order:

```
1. Is the authenticated user ROLE_SUPERADMIN?  → GRANT
2. Does the user have permission 'all_functions'?
     → GRANT (unless permission is explicit-only)
3. Does the user's effective permission set contain 'name'?
     → effective = union of all permissions from all roles
     → GRANT / DENY
```

### Frontend (route guards)

```typescript
// admin.routes.ts
{
  path: 'users',
  component: UserManagement,
  canActivate: [PermissionGuard],
  data: { permissions: ['user:read'] }
}
```

`PermissionGuard` calls `permissionGuardService.hasAnyPermission(requiredPermissions)`.

`PermissionGuardService.hasPermission(name)` resolution order:

```
1. Is the user SUPERADMIN?              → true
2. Is 'name' in server-loaded set?      → true / false  (populated on login)
3. Is 'name' in token/user object?      → true / false  (fallback)
```

### Permission cache lifecycle

```
login()
  └─▶ loadEffectivePermissions()
        └─▶ GET /api/admin/user-permissions/me/effective
        └─▶ BehaviorSubject<Set<string>> populated

isAuthenticated$ → false  (logout / token expiry)
  └─▶ BehaviorSubject cleared automatically
```

---

## 6. Backend API Reference

All endpoints are under `tms-core-api` (port 8080) and accessible via the gateway at port 8086.
All require a valid Bearer JWT.

### Users — `/api/admin/users`

| Method | Path | Permission | Description |
|--------|------|-----------|-------------|
| `GET` | `/api/admin/users` | `user:read` | List all users (returns `UserDto[]`) |
| `POST` | `/api/admin/users` | `user:create` | Create user |
| `PUT` | `/api/admin/users/{id}` | `user:update` | Update user (username, email, password, roles) |
| `PATCH` | `/api/admin/users/{id}/status?enabled=true\|false` | `user:update` | Enable / disable account |
| `DELETE` | `/api/admin/users/{id}` | `user:delete` | Delete user |
| `POST` | `/api/admin/users/registerdriver` | `driver:manage` | Create driver login account |

**Create / update request body:**
```json
{
  "username": "john.doe",
  "email": "john@example.com",
  "password": "secret123",
  "roles": ["ADMIN", "MANAGER"],
  "enabled": true
}
```
On `PUT`, omit or send `""` for `password` to keep the existing hash.

**UserDto response shape:**
```json
{
  "id": 42,
  "username": "john.doe",
  "email": "john@example.com",
  "enabled": true,
  "roles": ["ADMIN"]
}
```

---

### Roles — `/api/admin/roles`

| Method | Path | Permission | Description |
|--------|------|-----------|-------------|
| `GET` | `/api/admin/roles` | `role:read` | List all roles |
| `GET` | `/api/admin/roles/{id}` | `role:read` | Get role by ID |
| `POST` | `/api/admin/roles` | `role:create` | Create role |
| `PUT` | `/api/admin/roles/{id}` | `role:update` | Update role |
| `DELETE` | `/api/admin/roles/{id}` | `role:delete` | Delete role |
| `POST` | `/api/admin/roles/{roleId}/permissions/{permissionId}` | `role:update` | Add permission to role |
| `DELETE` | `/api/admin/roles/{roleId}/permissions/{permissionId}` | `role:update` | Remove permission from role |
| `GET` | `/api/admin/roles/{roleId}/permissions` | `role:read` | List role's permissions |

---

### Permissions — `/api/admin/permissions`

| Method | Path | Permission | Description |
|--------|------|-----------|-------------|
| `GET` | `/api/admin/permissions` | `permission:read` | List all permissions |
| `POST` | `/api/admin/permissions` | `permission:create` | Create permission |
| `PUT` | `/api/admin/permissions/{id}` | `permission:update` | Update permission |
| `DELETE` | `/api/admin/permissions/{id}` | `permission:delete` | Delete permission |

**Create body:**
```json
{
  "name": "report:export",
  "resourceType": "report",
  "actionType": "export",
  "description": "Export reports to CSV/PDF"
}
```

---

### Effective Permissions — `/api/admin/user-permissions`

| Method | Path | Permission | Description |
|--------|------|-----------|-------------|
| `GET` | `/api/admin/user-permissions/me/effective` | authenticated | Current user's effective permissions |
| `GET` | `/api/admin/user-permissions/user/{id}/effective` | `user:read` | Any user's effective permissions |
| `GET` | `/api/admin/user-permissions/user/{id}/has-permission?permissionName=X` | `user:read` | Boolean check |
| `GET` | `/api/admin/user-permissions/users-with-permission?permissionName=X` | `user:read` | Users who have permission X |

**Effective permissions response:**
```json
{
  "userId": 42,
  "permissions": ["user:read", "user:create", "driver:read"],
  "permissionMatrix": {
    "driver": ["read"],
    "user": ["create", "read"]
  }
}
```

> **Deprecated (410 Gone):** `POST /assign`, `POST /assign-by-name`, `DELETE /remove`,
> `GET /user/{id}` — direct user-permission assignment was removed in V29.
> Use role-permission endpoints instead.

---

## 7. Frontend Services & Guards

### `PermissionGuardService`

The single source of truth for permission checks in the UI.

```typescript
// Inject
private perm = inject(PermissionGuardService);

// Check single permission
this.perm.hasPermission('user:read')          // boolean

// Check any of a list
this.perm.hasAnyPermission(['user:read', 'admin:read'])  // boolean

// Convenience helpers
this.perm.canReadUsers()
this.perm.canCreateDrivers()
this.perm.canDeleteVehicles()
// ... etc.
```

**Cache management** (handled automatically):

```typescript
// After login — called by LoginComponent automatically
permGuard.loadEffectivePermissions().subscribe()

// On logout — triggered automatically by isAuthenticated$ subscription
// No manual call needed
```

### `UserService`

```typescript
getAllUsers(): Observable<UserDto[]>
createUser(req: RegisterRequest): Observable<any>
updateUser(id, req): Observable<any>
toggleStatus(id, enabled): Observable<{ message, user: UserDto }>
deleteUser(id): Observable<any>
```

### `RoleService`

```typescript
getAllRoles(): Observable<Role[]>
createRole(role): Observable<Role>
updateRole(role): Observable<Role>
deleteRole(id): Observable<void>
addPermissionToRole(roleId, permissionId): Observable<Role>
removePermissionFromRole(roleId, permissionId): Observable<Role>
getRolePermissions(roleId): Observable<Permission[]>
```

### `PermissionService`

```typescript
getAllPermissions(): Observable<Permission[]>
createPermission(p): Observable<Permission>
updatePermission(p): Observable<Permission>
deletePermission(id): Observable<void>
```

### Route Guards

**`PermissionGuard`** — protects routes by permission name:
```typescript
{
  path: 'users',
  canActivate: [PermissionGuard],
  data: { permissions: ['user:read'] }
}
```

**`RoleGuard`** — protects routes by role:
```typescript
{
  path: 'admin',
  canActivate: [RoleGuard],
  data: { roles: ['ADMIN', 'SUPERADMIN'] }
}
```

### `hasPermission` Pipe

Use in templates to conditionally show UI elements:
```html
<button *ngIf="'user:create' | hasPermission">Create User</button>
```

---

## 8. Admin UI Screens

All screens require `ADMIN` or `SUPERADMIN` role (enforced by `AdminGuard`).

### User Management — `/admin/users`

| Feature | Notes |
|---------|-------|
| **Search** | Live filter by username, email, or role name |
| **Status badge** | Green = Active, Gray = Disabled — click to toggle |
| **Role badges** | Color-coded: SUPERADMIN=red, ADMIN=blue, MANAGER=purple |
| **Create** | Dialog with username, email, password, roles |
| **Edit** | Same dialog; password field optional (leave blank to keep) |
| **Delete** | Confirmation dialog required |

### Role Management — `/admin/roles`

| Feature | Notes |
|---------|-------|
| **Stats cards** | Total roles, active roles, total permissions, system roles count |
| **Search + filter** | Filter by name, description, or permission name |
| **Sort** | By name, description, or permission count |
| **Bulk delete** | Checkbox select + bulk delete |
| **Duplicate role** | Creates a copy with `(Copy)` suffix |
| **Permission assignment** | Managed through the role edit dialog |

### Permission Management — `/admin/permissions`

| Feature | Notes |
|---------|-------|
| **Search** | Filter by name, description, resource, or action |
| **Resource filter** | Dropdown populated from live data |
| **Action type badges** | delete=red, create=green, update=orange, read=gray |
| **Create** | Name validated as `resource:action` pattern |
| **Edit** | Name is read-only (changing it would break role assignments) |
| **Delete** | `all_functions` delete button is disabled |

---

## 9. Startup Seeding

Two `CommandLineRunner` beans run on every `core-api` startup. Both are **idempotent**.

### `PermissionEnsurer` (priority: low)

File: `tms-core-api/.../config/PermissionEnsurer.java`

- Seeds `all_functions` permission if it does not exist.
- Seeds basic banner/dashboard permissions.
- Assigns core permissions to `ADMIN` and `SUPERADMIN` roles.
- Skipped when Spring profile is `test`.
- Controlled by env var `APP_SEEDALLFUNCTIONS=true` (set in `docker-compose.local-dev.yml`).

### `PermissionInitializationService` (priority: high)

File: `tms-core-api/.../service/PermissionInitializationService.java`

- Seeds the full application permission catalogue (200+ entries).
- Controlled by property `permissions.init.enabled` (default: `true`).
- Safe to run repeatedly — uses `findByName()` before inserting.

> **Never delete a seeded permission manually from the DB.** Remove it from the seeder first,
> then run a migration to clean up role_permissions rows before dropping the permission.

---

## 10. Common Tasks

### Grant a permission to a role

```bash
# 1. Find the role ID
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8086/api/admin/roles | jq '.[] | {id, name}'

# 2. Find the permission ID
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8086/api/admin/permissions | jq '.[] | select(.name=="report:export") | .id'

# 3. Assign
curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8086/api/admin/roles/3/permissions/47"
```

### Create a new permission + assign to ADMIN role

```bash
# Create
curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"report:export","resourceType":"report","actionType":"export","description":"Export reports"}' \
  http://localhost:8086/api/admin/permissions

# Assign (use IDs from above commands)
curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8086/api/admin/roles/{adminRoleId}/permissions/{newPermId}"
```

### Disable a user account

```bash
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8086/api/admin/users/42/status?enabled=false"
```

### Check a user's effective permissions

```bash
# Current user
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8086/api/admin/user-permissions/me/effective | jq '.permissionMatrix'

# Any user (requires user:read)
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8086/api/admin/user-permissions/user/42/effective | jq '.permissions'
```

### Add a permission check to a new Angular route

```typescript
// In admin.routes.ts
{
  path: 'reports',
  loadComponent: () => import('./reports/reports.component'),
  canActivate: [PermissionGuard],
  data: { permissions: ['report:export'] }
}
```

### Add a `@PreAuthorize` to a new endpoint

```java
@GetMapping("/export")
@PreAuthorize("@authorizationService.hasPermission('report:export')")
public ResponseEntity<byte[]> exportReport() { ... }
```

---

## 11. Troubleshooting

### User gets 403 on an endpoint they should have access to

1. Check their effective permissions:
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" \
     http://localhost:8086/api/admin/user-permissions/me/effective | jq '.permissions'
   ```
2. Check the endpoint's `@PreAuthorize` annotation in the controller.
3. If the permission name is correct but still denied, check whether it is an **explicit-only** permission (`dispatch:flow:manage`, `dispatch:status:override`, `dispatch:status:manual:update`) — those must be directly assigned to a role, not inherited via `all_functions`.

### Frontend guard shows page as unauthorized but user has the role

The server-loaded permission cache may not have loaded yet, or the user's role does not have the permission assigned in the DB (the old hardcoded fallback no longer exists).

1. Open the browser console and check if `loadEffectivePermissions()` fired after login.
2. Verify the role has the permission via:
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" \
     http://localhost:8086/api/admin/roles/{roleId}/permissions | jq '.[].name'
   ```
3. If missing, assign it via the Permission Management UI or the API.

### `all_functions` permission not working for a dispatch permission

Expected. `dispatch:flow:manage`, `dispatch:status:override`, and `dispatch:status:manual:update` are **explicit-only** and intentionally excluded from the `all_functions` wildcard. Assign them directly to the required role.

### Deprecated endpoint returns 500 instead of 410

The service JAR predates V29 and has not been rebuilt. Run:
```bash
docker compose -f docker-compose.local-dev.yml build core-api
docker compose -f docker-compose.local-dev.yml up -d core-api
```

### Permission cache stale after role change in DB

The frontend cache is only refreshed on login. To force a refresh without logout:
```typescript
// Inject and call manually (e.g. from a dev/debug button)
this.permissionGuardService.loadEffectivePermissions().subscribe()
```
For production, instruct the user to log out and back in after a role change.

### `systemRolesCount` shows 0 in Role Management

This was a bug (checked `r.name === 'Admin'` instead of `'ADMIN'`). Fixed in the current build — rebuild the Angular app if you're on an older bundle:
```bash
cd tms-admin-web-ui && npm start
```
