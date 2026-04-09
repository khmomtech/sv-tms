import { inject } from '@angular/core';
import type { CanActivateFn } from '@angular/router';
import { Router } from '@angular/router';

import { PermissionGuardService } from '../services/permission-guard.service';

export const PermissionGuard: CanActivateFn = (route, state) => {
  const permissionService = inject(PermissionGuardService);
  const router = inject(Router);

  const requiredPermissions = route.data['permissions'] as string[];

  // Check if user has at least one of the required permissions
  const hasPermission = permissionService.hasAnyPermission(requiredPermissions);

  if (!hasPermission) {
    router.navigate(['/unauthorized']);
    return false;
  }

  return true;
};
