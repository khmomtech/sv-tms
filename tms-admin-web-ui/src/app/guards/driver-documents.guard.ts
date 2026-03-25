import { inject } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import type { CanActivateFn } from '@angular/router';
import { Router } from '@angular/router';

import { AuthService } from '../services/auth.service';

export const DriverDocumentsGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  const snackBar = inject(MatSnackBar);

  // Check if user is authenticated
  if (!authService.isAuthenticated()) {
    console.warn('🚫 Driver Documents Access Denied: User not authenticated');
    snackBar.open('Please login to access driver documents.', 'Close', {
      duration: 5000,
      panelClass: ['error-snackbar'],
    });
    router.navigate(['/login']);
    return false;
  }

  // Check for required permissions
  const hasDriverViewAll = authService.hasPermission('driver:view_all');
  const hasDriverManage = authService.hasPermission('driver:manage');
  const isAdmin = authService.isAdmin();
  const isSuperAdmin = authService.hasRole('SUPERADMIN');

  const hasAccess = hasDriverViewAll || hasDriverManage || isAdmin || isSuperAdmin;

  if (!hasAccess) {
    console.warn('🚫 Driver Documents Access Denied: Insufficient permissions');
    snackBar.open(
      'Access denied. You need DRIVER_VIEW_ALL or DRIVER_MANAGE permission to view driver documents.',
      'Close',
      {
        duration: 8000,
        panelClass: ['error-snackbar'],
      },
    );
    router.navigate(['/unauthorized']);
    return false;
  }

  console.log('Driver Documents Access Granted');
  return true;
};
