import type { Routes } from '@angular/router';

import { PermissionGuard } from '../../guards/permission.guard';

export const ITEMS_ROUTES: Routes = [
  {
    path: '',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/settting/item/item.component').then((m) => m.ItemComponent),
    data: {
      title: 'Items List',
      permissions: ['item:read'],
    },
  },
  {
    path: 'create',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/settting/item/item.component').then((m) => m.ItemComponent),
    data: {
      title: 'Create Item',
      permissions: ['item:create'],
      action: 'create',
    },
  },
  {
    path: 'import',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/settting/item/item.component').then((m) => m.ItemComponent),
    data: {
      title: 'Import Items',
      permissions: ['item:create'],
    },
  },
  {
    path: ':id',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/settting/item/item.component').then((m) => m.ItemComponent),
    data: {
      title: 'Item Details',
      permissions: ['item:read'],
    },
  },
];
