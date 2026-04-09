import type { Routes } from '@angular/router';

export const ADMIN_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('../../admin/admin/admin').then((m) => m.Admin),
    data: { title: 'Admin Dashboard' },
  },
  {
    path: 'employees',
    loadComponent: () =>
      import('../../admin/staff-management/staff-management').then(
        (m) => m.StaffManagementComponent,
      ),
    data: { title: 'Employees' },
  },
  {
    path: 'staff',
    redirectTo: 'employees',
    pathMatch: 'full',
  },
  {
    path: 'notifications',
    loadComponent: () =>
      import('../../components/in-app-notifications-admin/in-app-notifications-admin.component').then(
        (m) => m.InAppNotificationsAdminComponent,
      ),
    data: { title: 'Notifications' },
  },
  {
    path: 'notification-settings',
    loadComponent: () =>
      import('../../components/notification-settings/notification-settings.component').then(
        (m) => m.NotificationSettingsComponent,
      ),
    data: { title: 'Notification Settings' },
  },
  {
    path: 'tokens',
    loadComponent: () =>
      import('../../admin/token-admin/token-admin.component').then((m) => m.TokenAdminComponent),
    data: { title: 'Token Management' },
  },
  {
    path: 'roles',
    loadComponent: () =>
      import('../../admin/role-management/role-management').then((m) => m.RoleManagement),
    data: { title: 'Role Management' },
  },
  {
    path: 'permissions',
    loadComponent: () =>
      import('../../components/permissions/permissions.component').then(
        (m) => m.PermissionsComponent,
      ),
    data: { title: 'Permissions' },
  },
  {
    path: 'dynamic-permissions',
    loadComponent: () =>
      import('../../components/dynamic-permission-management/dynamic-permission-management.component').then(
        (m) => m.DynamicPermissionManagementComponent,
      ),
    data: { title: 'Dynamic Permissions' },
  },
  {
    path: 'system-initialization',
    loadComponent: () =>
      import('../../components/system-initialization/system-initialization.component').then(
        (m) => m.SystemInitializationComponent,
      ),
    data: { title: 'System Initialization' },
  },
  {
    path: 'audit-trails',
    loadComponent: () =>
      import('../../components/audit-trails/audit-trails.component').then(
        (m) => m.AuditTrailsComponent,
      ),
    data: { title: 'Audit Trails' },
  },
  {
    path: 'pre-entry-master/categories',
    loadComponent: () =>
      import('./pre-entry-category-list.component').then((m) => m.PreEntryCategoryListComponent),
    data: { title: 'Pre-entry Category' },
  },
  {
    path: 'pre-entry-master/items',
    loadComponent: () =>
      import('./pre-entry-item-list.component').then((m) => m.PreEntryItemListComponent),
    data: { title: 'Pre-entry Item' },
  },
  {
    path: 'items',
    data: { title: 'Items' },
    children: [
      {
        path: '',
        loadComponent: () =>
          import('../../components/settting/item/item.component').then((m) => m.ItemComponent),
      },
      {
        path: 'import',
        loadComponent: () =>
          import('../../components/settting/item/import/item-import.component').then(
            (m) => m.ItemImportComponent,
          ),
        data: { title: 'Import Items' },
      },
    ],
  },
  {
    path: 'uploads',
    data: { title: 'Uploads' },
    children: [
      {
        path: 'so',
        loadComponent: () =>
          import('../../components/so-upload/so-upload.component').then((m) => m.SoUploadComponent),
        data: { title: 'SO Upload' },
      },
      {
        path: 'khb',
        loadComponent: () =>
          import('../../components/khb-upload/khb-upload.component').then(
            (m) => m.KhbSoUploadComponent,
          ),
        data: { title: 'KHB Upload' },
      },
      {
        path: 'khb/trip-pre-plan',
        loadComponent: () =>
          import('../../components/khb-pre-trip-plan/khb-pre-trip-plan.component').then(
            (m) => m.TripPrePlanComponent,
          ),
        data: { title: 'Trip Pre-Plan' },
      },
    ],
  },
];
