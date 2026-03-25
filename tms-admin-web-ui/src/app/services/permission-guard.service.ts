import { Injectable, inject } from '@angular/core';

import { PERMISSIONS } from '../shared/permissions';

import { AuthService } from './auth.service';
import { type User } from './auth.service';

const ROLES_PERMISSIONS: { [key: string]: string[] } = {
  SUPERADMIN: ['all_functions'], // SUPERADMIN has all permissions
  ADMIN: [
    PERMISSIONS.CUSTOMER_READ,
    PERMISSIONS.CUSTOMER_CREATE,
    PERMISSIONS.CUSTOMER_UPDATE,
    PERMISSIONS.CUSTOMER_DELETE,
    PERMISSIONS.ITEM_READ,
    PERMISSIONS.ITEM_CREATE,
    PERMISSIONS.ITEM_UPDATE,
    PERMISSIONS.ITEM_DELETE,
    PERMISSIONS.USER_READ,
    PERMISSIONS.USER_CREATE,
    PERMISSIONS.USER_UPDATE,
    PERMISSIONS.USER_DELETE,
    PERMISSIONS.ROLE_READ,
    PERMISSIONS.ROLE_CREATE,
    PERMISSIONS.ROLE_UPDATE,
    PERMISSIONS.DRIVER_READ,
    PERMISSIONS.DRIVER_VIEW_ALL,
    PERMISSIONS.DRIVER_CREATE,
    PERMISSIONS.DRIVER_UPDATE,
    PERMISSIONS.DRIVER_MANAGE,
    PERMISSIONS.DRIVER_DOCUMENTS_READ,
    PERMISSIONS.DRIVER_DOCUMENTS_UPLOAD,
    PERMISSIONS.DRIVER_SCHEDULE_READ,
    PERMISSIONS.DRIVER_SCHEDULE_UPDATE,
    PERMISSIONS.DRIVER_ACCOUNT_MANAGE,
    PERMISSIONS.VEHICLE_READ,
    PERMISSIONS.VEHICLE_CREATE,
    PERMISSIONS.VEHICLE_UPDATE,
    PERMISSIONS.VEHICLE_DELETE,
    PERMISSIONS.ORDER_READ,
    PERMISSIONS.ORDER_CREATE,
    PERMISSIONS.ORDER_UPDATE,
    PERMISSIONS.ORDER_ASSIGN,
    PERMISSIONS.DISPATCH_READ,
    PERMISSIONS.DISPATCH_CREATE,
    PERMISSIONS.DISPATCH_UPDATE,
    PERMISSIONS.DISPATCH_MONITOR,
    PERMISSIONS.POD_READ,
    PERMISSIONS.TELEMATICS_LIVE_READ,
    PERMISSIONS.DRIVER_LIVE_READ,
    PERMISSIONS.TELEMATICS_GEOFENCE_READ,
    PERMISSIONS.GEOFENCE_READ,
    PERMISSIONS.GEOFENCE_CREATE,
    PERMISSIONS.GEOFENCE_UPDATE,
    PERMISSIONS.GEOFENCE_DELETE,
    PERMISSIONS.TELEMATICS_CONSOLE_READ,
    PERMISSIONS.ADMIN_READ,
  ],
  MANAGER: [
    PERMISSIONS.CUSTOMER_READ,
    PERMISSIONS.ITEM_READ,
    PERMISSIONS.ITEM_CREATE,
    PERMISSIONS.ITEM_UPDATE,
    PERMISSIONS.USER_READ,
    PERMISSIONS.DRIVER_READ,
    PERMISSIONS.DRIVER_VIEW_ALL,
    PERMISSIONS.DRIVER_DOCUMENTS_READ,
    PERMISSIONS.DRIVER_SCHEDULE_READ,
    PERMISSIONS.DRIVER_SCHEDULE_UPDATE,
    PERMISSIONS.DRIVER_ACCOUNT_MANAGE,
    PERMISSIONS.VEHICLE_READ,
    PERMISSIONS.ORDER_READ,
    PERMISSIONS.ORDER_CREATE,
    PERMISSIONS.ORDER_UPDATE,
    PERMISSIONS.ORDER_ASSIGN,
    PERMISSIONS.DISPATCH_READ,
    PERMISSIONS.DISPATCH_MONITOR,
    PERMISSIONS.POD_READ,
    PERMISSIONS.REPORT_DRIVER_PERFORMANCE,
    PERMISSIONS.TELEMATICS_LIVE_READ,
    PERMISSIONS.DRIVER_LIVE_READ,
    PERMISSIONS.TELEMATICS_GEOFENCE_READ,
    PERMISSIONS.GEOFENCE_READ,
    PERMISSIONS.GEOFENCE_CREATE,
    PERMISSIONS.GEOFENCE_UPDATE,
  ],
  USER: [PERMISSIONS.ITEM_READ, PERMISSIONS.USER_READ, PERMISSIONS.NOTIFICATION_READ],
};

@Injectable({
  providedIn: 'root',
})
export class PermissionGuardService {
  private authService = inject(AuthService);

  constructor() {}

  /**
   * Check if the current user has a specific permission.
   * This is the core logic that checks against roles and direct permissions.
   */
  hasPermission(permissionName: string): boolean {
    const normalizedPermission = permissionName?.toLowerCase().trim();
    if (!normalizedPermission) return false;

    const currentUser: User | null = this.authService.getCurrentUser();
    if (!currentUser) {
      return false;
    }

    // 1. SUPERADMIN has all permissions (check with exact case and uppercase)
    const userRoles = (currentUser.roles || []).map((r) => r?.toUpperCase());
    if (userRoles.includes('SUPERADMIN')) {
      return true;
    }

    // 2. Check for permissions directly assigned to the user
    //    This covers both the login response permissions and anything stored in localStorage.
    if (this.authService.hasPermission(normalizedPermission)) {
      return true;
    }

    // 3. Check for permissions attached to the user object (if backend included them)
    const userPerms = (currentUser.permissions ?? []).map((p) => p.toLowerCase());
    if (userPerms.includes('all_functions') || userPerms.includes(normalizedPermission)) {
      return true;
    }

    // 4. Check for permissions granted by the user's roles (normalized, deduped)
    const rolePerms = new Set<string>();
    (currentUser.roles || []).forEach((role) => {
      const perms = ROLES_PERMISSIONS[role?.toUpperCase()];
      perms?.forEach((p) => rolePerms.add(p.toLowerCase()));
    });

    return rolePerms.has('all_functions') || rolePerms.has(normalizedPermission);
  }

  /** Check if the user has any of the provided permissions */
  hasAnyPermission(requiredPermissions: string[] = []): boolean {
    if (!requiredPermissions.length) return true;
    return requiredPermissions.some((p) => this.hasPermission(p));
  }

  // --- Customer Permissions ---
  canReadCustomers(): boolean {
    return this.hasPermission(PERMISSIONS.CUSTOMER_READ);
  }
  canCreateCustomers(): boolean {
    return this.hasPermission(PERMISSIONS.CUSTOMER_CREATE);
  }
  canUpdateCustomers(): boolean {
    return this.hasPermission(PERMISSIONS.CUSTOMER_UPDATE);
  }
  canDeleteCustomers(): boolean {
    return this.hasPermission(PERMISSIONS.CUSTOMER_DELETE);
  }

  // --- Item Permissions ---
  canReadItems(): boolean {
    return this.hasPermission(PERMISSIONS.ITEM_READ);
  }
  canCreateItems(): boolean {
    return this.hasPermission(PERMISSIONS.ITEM_CREATE);
  }
  canUpdateItems(): boolean {
    return this.hasPermission(PERMISSIONS.ITEM_UPDATE);
  }
  canDeleteItems(): boolean {
    return this.hasPermission(PERMISSIONS.ITEM_DELETE);
  }

  // --- User Permissions ---
  canReadUsers(): boolean {
    return this.hasPermission(PERMISSIONS.USER_READ);
  }
  canCreateUsers(): boolean {
    return this.hasPermission(PERMISSIONS.USER_CREATE);
  }
  canUpdateUsers(): boolean {
    return this.hasPermission(PERMISSIONS.USER_UPDATE);
  }
  canDeleteUsers(): boolean {
    return this.hasPermission(PERMISSIONS.USER_DELETE);
  }

  // --- Role Permissions ---
  canReadRoles(): boolean {
    return this.hasPermission(PERMISSIONS.ROLE_READ);
  }
  canCreateRoles(): boolean {
    return this.hasPermission(PERMISSIONS.ROLE_CREATE);
  }
  canUpdateRoles(): boolean {
    return this.hasPermission(PERMISSIONS.ROLE_UPDATE);
  }

  // --- Driver Permissions ---
  canReadDrivers(): boolean {
    return this.hasPermission(PERMISSIONS.DRIVER_READ);
  }
  canCreateDrivers(): boolean {
    return this.hasPermission(PERMISSIONS.DRIVER_CREATE);
  }
  canUpdateDrivers(): boolean {
    return this.hasPermission(PERMISSIONS.DRIVER_UPDATE);
  }
  canManageDrivers(): boolean {
    return this.hasPermission(PERMISSIONS.DRIVER_MANAGE);
  }

  // --- Vehicle Permissions ---
  canReadVehicles(): boolean {
    return this.hasPermission(PERMISSIONS.VEHICLE_READ);
  }
  canCreateVehicles(): boolean {
    return this.hasPermission(PERMISSIONS.VEHICLE_CREATE);
  }
  canUpdateVehicles(): boolean {
    return this.hasPermission(PERMISSIONS.VEHICLE_UPDATE);
  }
  canDeleteVehicles(): boolean {
    return this.hasPermission(PERMISSIONS.VEHICLE_DELETE);
  }

  // --- Order Permissions ---
  canReadOrders(): boolean {
    return this.hasPermission(PERMISSIONS.ORDER_READ);
  }
  canCreateOrders(): boolean {
    return this.hasPermission(PERMISSIONS.ORDER_CREATE);
  }
  canUpdateOrders(): boolean {
    return this.hasPermission(PERMISSIONS.ORDER_UPDATE);
  }
  canAssignOrders(): boolean {
    return this.hasPermission(PERMISSIONS.ORDER_ASSIGN);
  }

  // --- Notification Permissions ---
  canReadNotifications(): boolean {
    return this.hasPermission(PERMISSIONS.NOTIFICATION_READ);
  }
}
