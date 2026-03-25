import type { Routes } from '@angular/router';

import { PermissionGuard } from '../../guards/permission.guard';
import { PERMISSIONS } from '../../shared/permissions';

export const VENDORS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./vendor-list/vendor-list.component').then((m) => m.PartnerListComponent),
  },
  {
    path: 'create',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./vendor-list/vendor-list.component').then((m) => m.PartnerListComponent),
    data: {
      title: 'Create Vendor',
      permissions: [PERMISSIONS.VENDOR_CREATE],
      action: 'create',
    },
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./vendor-detail/vendor-detail.component').then((m) => m.PartnerDetailComponent),
  },
];
