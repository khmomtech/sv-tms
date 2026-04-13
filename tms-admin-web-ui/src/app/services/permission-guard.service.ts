import { Injectable, inject, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, Subscription, tap, map, catchError, of, filter } from 'rxjs';

import { PERMISSIONS } from '../shared/permissions';
import { AuthService } from './auth.service';
import { type User } from './auth.service';

interface EffectivePermissionsResponse {
  userId: number;
  permissions: string[];
  permissionMatrix: Record<string, string[]>;
}

@Injectable({
  providedIn: 'root',
})
export class PermissionGuardService implements OnDestroy {
  private authService = inject(AuthService);
  private http = inject(HttpClient);

  private readonly _effectivePermissions = new BehaviorSubject<Set<string>>(new Set());
  private readonly _authSub: Subscription;
  private _loadedForUsername: string | null = null;

  constructor() {
    // Auto-clear cached permissions whenever the user logs out.
    this._authSub = this.authService.isAuthenticated$
      .pipe(filter((authenticated) => !authenticated))
      .subscribe(() => this.clearEffectivePermissions());
  }

  ngOnDestroy(): void {
    this._authSub.unsubscribe();
  }

  /**
   * Load effective permissions for the current user from the server and cache them.
   * Call this once after a successful login.
   */
  loadEffectivePermissions(force = false): Observable<void> {
    const currentUser = this.authService.getCurrentUser();
    const username = currentUser?.username?.trim() ?? '';
    if (
      !force &&
      username &&
      this._loadedForUsername === username &&
      this._effectivePermissions.getValue().size > 0
    ) {
      return of(undefined);
    }

    return this.http
      .get<EffectivePermissionsResponse>('/api/admin/user-permissions/me/effective')
      .pipe(
        tap((response) => {
          const perms = new Set<string>(
            (response.permissions ?? []).map((p) => p.toLowerCase().trim()),
          );
          this._effectivePermissions.next(perms);
          this._loadedForUsername = username || null;
        }),
        map(() => undefined),
        catchError(() => {
          // Non-admin users (e.g. DRIVER) won't have access to this endpoint — ignore silently.
          return of(undefined);
        }),
      );
  }

  /** Clear cached permissions on logout. */
  clearEffectivePermissions(): void {
    this._effectivePermissions.next(new Set());
    this._loadedForUsername = null;
  }

  /**
   * Check if the current user has a specific permission.
   * Resolution order:
   *   1. SUPERADMIN role → always granted
   *   2. Server-loaded effective permissions set (populated via loadEffectivePermissions)
   *   3. Permissions embedded in the auth token / user object (fallback for non-admin roles)
   */
  hasPermission(permissionName: string): boolean {
    const normalizedPermission = permissionName?.toLowerCase().trim();
    if (!normalizedPermission) return false;

    const currentUser: User | null = this.authService.getCurrentUser();
    if (!currentUser) return false;

    // 1. SUPERADMIN always has full access
    const userRoles = (currentUser.roles ?? []).map((r) => r?.toUpperCase());
    if (userRoles.includes('SUPERADMIN')) return true;

    // 2. Server-loaded effective permissions (source of truth for admin users)
    const serverPerms = this._effectivePermissions.getValue();
    if (serverPerms.size > 0) {
      return serverPerms.has('all_functions') || serverPerms.has(normalizedPermission);
    }

    // 3. Fallback: permissions embedded directly in the user object from the auth token
    const tokenPerms = (currentUser.permissions ?? []).map((p) => p.toLowerCase());
    return tokenPerms.includes('all_functions') || tokenPerms.includes(normalizedPermission);
  }

  /** Returns true if the user has at least one of the provided permissions. */
  hasAnyPermission(requiredPermissions: string[] = []): boolean {
    if (!requiredPermissions.length) return true;
    return requiredPermissions.some((p) => this.hasPermission(p));
  }

  // ---------------------------------------------------------------------------
  //  Convenience helpers — delegates to hasPermission()
  // ---------------------------------------------------------------------------

  // Customer
  canReadCustomers = () => this.hasPermission(PERMISSIONS.CUSTOMER_READ);
  canCreateCustomers = () => this.hasPermission(PERMISSIONS.CUSTOMER_CREATE);
  canUpdateCustomers = () => this.hasPermission(PERMISSIONS.CUSTOMER_UPDATE);
  canDeleteCustomers = () => this.hasPermission(PERMISSIONS.CUSTOMER_DELETE);

  // Item
  canReadItems = () => this.hasPermission(PERMISSIONS.ITEM_READ);
  canCreateItems = () => this.hasPermission(PERMISSIONS.ITEM_CREATE);
  canUpdateItems = () => this.hasPermission(PERMISSIONS.ITEM_UPDATE);
  canDeleteItems = () => this.hasPermission(PERMISSIONS.ITEM_DELETE);

  // User
  canReadUsers = () => this.hasPermission(PERMISSIONS.USER_READ);
  canCreateUsers = () => this.hasPermission(PERMISSIONS.USER_CREATE);
  canUpdateUsers = () => this.hasPermission(PERMISSIONS.USER_UPDATE);
  canDeleteUsers = () => this.hasPermission(PERMISSIONS.USER_DELETE);

  // Role
  canReadRoles = () => this.hasPermission(PERMISSIONS.ROLE_READ);
  canCreateRoles = () => this.hasPermission(PERMISSIONS.ROLE_CREATE);
  canUpdateRoles = () => this.hasPermission(PERMISSIONS.ROLE_UPDATE);

  // Driver
  canReadDrivers = () => this.hasPermission(PERMISSIONS.DRIVER_READ);
  canCreateDrivers = () => this.hasPermission(PERMISSIONS.DRIVER_CREATE);
  canUpdateDrivers = () => this.hasPermission(PERMISSIONS.DRIVER_UPDATE);
  canManageDrivers = () => this.hasPermission(PERMISSIONS.DRIVER_MANAGE);

  // Vehicle
  canReadVehicles = () => this.hasPermission(PERMISSIONS.VEHICLE_READ);
  canCreateVehicles = () => this.hasPermission(PERMISSIONS.VEHICLE_CREATE);
  canUpdateVehicles = () => this.hasPermission(PERMISSIONS.VEHICLE_UPDATE);
  canDeleteVehicles = () => this.hasPermission(PERMISSIONS.VEHICLE_DELETE);

  // Order
  canReadOrders = () => this.hasPermission(PERMISSIONS.ORDER_READ);
  canCreateOrders = () => this.hasPermission(PERMISSIONS.ORDER_CREATE);
  canUpdateOrders = () => this.hasPermission(PERMISSIONS.ORDER_UPDATE);
  canAssignOrders = () => this.hasPermission(PERMISSIONS.ORDER_ASSIGN);

  // Notification
  canReadNotifications = () => this.hasPermission(PERMISSIONS.NOTIFICATION_READ);
}
