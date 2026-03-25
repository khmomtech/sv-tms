import type { Routes } from '@angular/router';

import { PermissionGuard } from '../../guards/permission.guard';

export const CUSTOMERS_ROUTES: Routes = [
  {
    path: '',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/customer/customer.component').then((m) => m.CustomerComponent),
    data: {
      title: 'Customers',
      permissions: ['customer:read'],
    },
  },
  {
    path: 'create',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/customer/customer.component').then((m) => m.CustomerComponent),
    data: {
      title: 'Create Customer',
      permissions: ['customer:create'],
      action: 'create',
    },
  },
  {
    path: ':id',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/customer-view/customer-view.component').then(
        (m) => m.CustomerViewComponent,
      ),
    data: {
      title: 'Customer Details',
      permissions: ['customer:read'],
    },
  },
];
