import type { Routes } from '@angular/router';
import { PERMISSIONS } from '../../shared/permissions';

export const SAFETY_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./list/safety-check-list.component').then((m) => m.SafetyCheckListComponent),
    data: {
      title: 'ត្រួតពិនិត្យសុវត្ថិភាព',
      requiredPermissions: [PERMISSIONS.DISPATCH_READ],
    },
  },
  {
    path: 'master/categories',
    loadComponent: () =>
      import('./master/category-list/safety-category-list.component').then(
        (m) => m.SafetyCategoryListComponent,
      ),
    data: {
      title: 'ប្រភេទសុវត្ថិភាព',
      requiredPermissions: [PERMISSIONS.ADMIN_READ],
    },
  },
  {
    path: 'master/items',
    loadComponent: () =>
      import('./master/item-list/safety-item-list.component').then(
        (m) => m.SafetyItemListComponent,
      ),
    data: {
      title: 'ធាតុត្រួតពិនិត្យសុវត្ថិភាព',
      requiredPermissions: [PERMISSIONS.ADMIN_READ],
    },
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./detail/safety-check-detail.component').then((m) => m.SafetyCheckDetailComponent),
    data: {
      title: 'លម្អិតត្រួតពិនិត្យសុវត្ថិភាព',
      requiredPermissions: [PERMISSIONS.DISPATCH_READ],
    },
  },
];
