> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Authorization System Improvement Plan

## Current Issues

1. **Role Mismatch**: User `sotheakh` has `DRIVER` role but admin endpoints require `ADMIN` role
2. **Overly Restrictive**: Device listing endpoints blocked for legitimate admin users
3. **No Role-Based UI**: Frontend doesn't adapt to user roles

## Recommended Solutions

### Option A: Update User Role (Quick Fix)
```sql
-- Add ADMIN role to sotheakh user for testing
INSERT INTO user_roles (user_id, role_id) 
SELECT u.id, r.id 
FROM users u, roles r 
WHERE u.username = 'sotheakh' AND r.name = 'ADMIN'
AND NOT EXISTS (
    SELECT 1 FROM user_roles ur 
    WHERE ur.user_id = u.id AND ur.role_id = r.id
);
```

### Option B: Flexible Authorization (Recommended)
Update controller methods with more flexible role requirements:

```java
// Allow both ADMIN and DRIVER roles to view devices (read-only for drivers)
@PreAuthorize("hasRole('ADMIN') or hasRole('DRIVER')")
@GetMapping("/all")
public ApiResponse<List<DeviceRegisterDto>> getAllDevices() { ... }

// Only ADMIN can modify device status
@PreAuthorize("hasRole('ADMIN')")
@PutMapping("/{id}/status") 
public ApiResponse<Void> updateDeviceStatus(...) { ... }

// Drivers can only see their own devices
@PreAuthorize("hasRole('DRIVER')")
@GetMapping("/my-devices")
public ApiResponse<List<DeviceRegisterDto>> getMyDevices(Authentication auth) {
    // Filter by current user's devices only
}
```

### Option C: Role-Based Endpoints
Create separate endpoints for different user types:

```java
// Admin endpoints (full access)
@PreAuthorize("hasRole('ADMIN')")
@GetMapping("/admin/devices")
public ResponseEntity<List<DeviceRegisterDto>> getDevicesForAdmin() { ... }

// Driver endpoints (limited access) 
@PreAuthorize("hasRole('DRIVER')")
@GetMapping("/driver/my-devices") 
public ResponseEntity<List<DeviceRegisterDto>> getMyDevices(Authentication auth) { ... }
```

## Frontend Role Integration

### Angular Role Guard
```typescript
// Create role-based route guards
@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(): boolean {
    const user = this.authService.getCurrentUser();
    return user && user.roles.includes('ADMIN');
  }
}

@Injectable() 
export class DriverGuard implements CanActivate {
  canActivate(): boolean {
    const user = this.authService.getCurrentUser();
    return user && (user.roles.includes('DRIVER') || user.roles.includes('ADMIN'));
  }
}
```

### Role-Based UI Components
```typescript
// Show/hide UI elements based on roles
@Component({
  template: `
    <div *ngIf="hasRole('ADMIN')">
      <button (click)="approveDevice()">Approve</button>
      <button (click)="rejectDevice()">Reject</button>
    </div>
    <div *ngIf="hasRole('DRIVER')">
      <span>Status: {{device.status}}</span>
    </div>
  `
})
export class DeviceItemComponent {
  hasRole(role: string): boolean {
    return this.authService.hasRole(role);
  }
}
```