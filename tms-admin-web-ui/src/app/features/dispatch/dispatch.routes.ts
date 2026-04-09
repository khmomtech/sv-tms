import type { Routes } from '@angular/router';

import { PermissionGuard } from '../../guards/permission.guard';
import { PERMISSIONS } from '../../shared/permissions';

export const DISPATCH_ROUTES: Routes = [
  {
    path: '',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch-list/dispatch-list.component').then(
        (m) => m.DispatchListComponent,
      ),
    data: { title: 'Dispatch List', permissions: [PERMISSIONS.DISPATCH_LIST] },
  },
  {
    path: 'list',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch-list/dispatch-list.component').then(
        (m) => m.DispatchListComponent,
      ),
    data: { title: 'Dispatch List', permissions: [PERMISSIONS.DISPATCH_LIST] },
  },
  {
    path: 'create',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch/dispatch.component').then((m) => m.DispatchComponent),
    data: { title: 'Create Dispatch', permissions: [PERMISSIONS.DISPATCH_CREATE] },
  },
  {
    path: 'monitor',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch-monitor.component').then((m) => m.DispatchMonitorComponent),
    data: { title: 'Monitor Dispatches', permissions: [PERMISSIONS.DISPATCH_MONITOR] },
  },
  {
    path: 'queue-board',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/loading/queue-board.component').then((m) => m.QueueBoardComponent),
    data: { title: 'Queue Board', permissions: [PERMISSIONS.DISPATCH_READ] },
  },
  {
    path: 'loading-dashboard',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/loading/loading-dashboard.component').then(
        (m) => m.LoadingDashboardComponent,
      ),
    data: { title: 'Loading Dashboard', permissions: [PERMISSIONS.DISPATCH_READ] },
  },
  {
    path: 'loading-khb',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../admin/loading-khb.component').then((m) => m.LoadingKhbComponent),
    data: { title: 'G Team Loading - KHB', permissions: [PERMISSIONS.DISPATCH_READ] },
  },
  {
    path: 'pre-entry-safety',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../admin/pre-entry-safety-management.component').then(
        (m) => m.PreEntrySafetyManagementComponent,
      ),
    data: { title: 'Pre-Entry Safety Management', permissions: [PERMISSIONS.DISPATCH_MONITOR] },
  },
  {
    path: 'loading-session/:id',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/loading/loading-session-detail.component').then(
        (m) => m.LoadingSessionDetailComponent,
      ),
    data: { title: 'Loading Session', permissions: [PERMISSIONS.DISPATCH_READ] },
  },
  {
    path: 'loading-monitor',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/load-proof-admin.component').then((m) => m.LoadProofAdminComponent),
    data: { title: 'Proof of Delivery', permissions: [PERMISSIONS.POD_READ] },
  },
  {
    path: 'maps-view',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch-maps-view/dispatch-maps-view.component').then(
        (m) => m.DispatchMapsViewComponent,
      ),
    data: { title: 'Dispatch Maps', permissions: [PERMISSIONS.DISPATCH_READ] },
  },
  {
    path: 'planning',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch/dispatch-plan-track.component').then(
        (m) => m.DispatchPlanTrackComponent,
      ),
    data: { title: 'Dispatch Planning', permissions: [PERMISSIONS.DISPATCH_CREATE] },
  },
  {
    path: 'board-v2',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch/dispatch-board.component').then(
        (m) => m.DispatchBoardComponent,
      ),
    data: { title: 'Dispatch Board', permissions: [PERMISSIONS.DISPATCH_CREATE] },
  },
  {
    path: 'bulk-upload',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../pages/bulk-dispatch-upload/bulk-dispatch-upload.component').then(
        (m) => m.BulkDispatchUploadComponent,
      ),
    data: { title: 'Bulk Dispatch Upload', permissions: [PERMISSIONS.DISPATCH_CREATE] },
  },
  {
    path: 'approvals',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch-approvals/dispatch-approvals.component').then(
        (m) => m.DispatchApprovalsComponent,
      ),
    data: { title: 'Dispatch Approvals', permissions: [PERMISSIONS.DISPATCH_UPDATE] },
  },
  {
    path: 'closing',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch-closing/dispatch-closing.component').then(
        (m) => m.DispatchClosingComponent,
      ),
    data: { title: 'Dispatch Daily Closing', permissions: [PERMISSIONS.DISPATCH_UPDATE] },
  },
  {
    path: ':id',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../components/dispatch-detail/dispatch-detail.component').then(
        (m) => m.DispatchDetailComponent,
      ),
    data: { title: 'Dispatch Details', permissions: [PERMISSIONS.DISPATCH_READ] },
  },
];
