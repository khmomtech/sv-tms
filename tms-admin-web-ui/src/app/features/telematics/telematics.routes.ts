import type { Routes } from '@angular/router';

import { PermissionGuard } from '../../guards/permission.guard';
import { PERMISSIONS } from '../../shared/permissions';

export const TELEMATICS_ROUTES: Routes = [
  // Default: redirect bare /live to /live/map
  { path: '', redirectTo: 'map', pathMatch: 'full' },

  // Live Map — real-time driver positions
  {
    path: 'map',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../live-map/live-map.component').then((m) => m.LiveMapComponent),
    data: {
      title: 'Live Map',
      permissions: [PERMISSIONS.TELEMATICS_LIVE_READ, PERMISSIONS.DRIVER_LIVE_READ],
    },
  },

  // Geofences
  {
    path: 'geofences',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../geofence-management/geofence-management.component').then(
        (m) => m.GeofenceManagementComponent,
      ),
    data: {
      title: 'Geofences',
      permissions: [PERMISSIONS.TELEMATICS_GEOFENCE_READ, PERMISSIONS.GEOFENCE_READ],
    },
  },

  // Telematics Console — admin debug view
  {
    path: 'console',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../telematics-console/telematics-console.component').then(
        (m) => m.TelematicsConsoleComponent,
      ),
    data: {
      title: 'Telematics Console',
      permissions: [PERMISSIONS.TELEMATICS_CONSOLE_READ, PERMISSIONS.ADMIN_READ],
    },
  },

  // Backward-compat redirects for old driver-monitoring/* URLs
  { path: 'live-location', redirectTo: 'map', pathMatch: 'full' },
  { path: 'debug-console', redirectTo: 'console', pathMatch: 'full' },
  { path: 'driver-map', redirectTo: 'map', pathMatch: 'full' },
  { path: 'google-map', redirectTo: 'map', pathMatch: 'full' },
];
