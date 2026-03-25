import type { Routes } from '@angular/router';
import { PermissionGuard } from '../../guards/permission.guard';
import { PERMISSIONS } from '../../shared/permissions';

export const SETTINGS_ROUTES: Routes = [
  {
    path: 'driver-app',
    loadComponent: () =>
      import('../../admin/settings/pages/driver-app-hub/driver-app-hub.component').then(
        (m) => m.DriverAppHubComponent,
      ),
    data: { title: 'Driver App Hub' },
  },
  {
    path: 'driver-app/version',
    loadComponent: () =>
      import('../../admin/settings/pages/app-version-management/app-version-management.component').then(
        (m) => m.AppVersionManagementComponent,
      ),
    data: { title: 'App Version Management' },
  },
  {
    path: 'app-management',
    loadComponent: () =>
      import('../../admin/settings/pages/app-management/app-management.component').then(
        (m) => m.AppManagementComponent,
      ),
    data: { title: 'Driver App Management' },
  },
  {
    path: 'dispatch-flow',
    canActivate: [PermissionGuard],
    data: {
      title: 'Dispatch Flow Policy',
      permissions: [PERMISSIONS.DISPATCH_FLOW_MANAGE],
    },
    loadComponent: () =>
      import('./pages/dispatch-flow-policy/dispatch-flow-policy.component').then(
        (m) => m.DispatchFlowPolicyComponent,
      ),
  },
  {
    path: 'group/:groupCode',
    loadComponent: () =>
      import('../../admin/settings/pages/settings-group/settings-group.component').then(
        (m) => m.SettingsGroupComponent,
      ),
    data: { title: 'Settings Group' },
  },
  {
    path: 'create',
    loadComponent: () =>
      import('../../admin/settings/pages/setting-create/setting-create.component').then(
        (m) => m.SettingCreateComponent,
      ),
    data: { title: 'Create Setting' },
  },
  {
    path: 'audit',
    loadComponent: () =>
      import('../../admin/settings/pages/audit-log/audit-log.component').then(
        (m) => m.AuditLogComponent,
      ),
    data: { title: 'Settings Audit Log' },
  },
  {
    path: 'import-export',
    loadComponent: () =>
      import('../../admin/settings/pages/import-export/import-export.component').then(
        (m) => m.ImportExportComponent,
      ),
    data: { title: 'Import/Export Settings' },
  },
  // Default redirect
  {
    path: '',
    redirectTo: 'driver-app',
    pathMatch: 'full',
  },
];
