import type { Routes } from '@angular/router';
import { PermissionGuard } from '../../guards/permission.guard';
import { PERMISSIONS } from '../../shared/permissions';

export const INCIDENT_ROUTES: Routes = [
  {
    path: '',
    redirectTo: 'list',
    pathMatch: 'full',
  },
  {
    path: 'list',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./components/incident-components/incident-list.component').then(
        (m) => m.IncidentListComponent,
      ),
    data: {
      title: 'Incidents',
      breadcrumb: 'Incidents',
      permissions: [PERMISSIONS.INCIDENT_LIST, PERMISSIONS.ADMIN_READ],
    },
  },
  {
    path: 'tasks',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./components/incident-components/incident-tasks.component').then(
        (m) => m.IncidentTasksComponent,
      ),
    data: {
      title: 'Incident Tasks',
      breadcrumb: 'Tasks',
      permissions: [PERMISSIONS.TASK_READ, PERMISSIONS.ADMIN_READ],
    },
  },
  {
    path: 'create',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./components/incident-components/incident-form.component').then(
        (m) => m.IncidentFormComponent,
      ),
    data: {
      title: 'Create Incident',
      breadcrumb: 'Create',
      permissions: [PERMISSIONS.INCIDENT_CREATE],
    },
  },
  {
    path: ':id/edit',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./components/incident-components/incident-form.component').then(
        (m) => m.IncidentFormComponent,
      ),
    data: {
      title: 'Edit Incident',
      breadcrumb: 'Edit',
      permissions: [PERMISSIONS.INCIDENT_UPDATE],
    },
  },
  {
    path: ':id',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./components/incident-components/incident-detail.component').then(
        (m) => m.IncidentDetailComponent,
      ),
    data: {
      title: 'Incident Details',
      breadcrumb: 'Details',
      permissions: [PERMISSIONS.INCIDENT_LIST, PERMISSIONS.ADMIN_READ],
    },
  },
];

export const CASE_ROUTES: Routes = [
  {
    path: '',
    redirectTo: 'list',
    pathMatch: 'full',
  },
  {
    path: 'list',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./components/case-components/case-list.component').then((m) => m.CaseListComponent),
    data: {
      title: 'Cases',
      breadcrumb: 'Cases',
      permissions: [PERMISSIONS.CASE_LIST, PERMISSIONS.ADMIN_READ],
    },
  },
  {
    path: 'create',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./components/case-components/case-form.component').then((m) => m.CaseFormComponent),
    data: {
      title: 'Create Case',
      breadcrumb: 'Create',
      permissions: [PERMISSIONS.CASE_CREATE],
    },
  },
  {
    path: ':id/edit',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./components/case-components/case-form.component').then((m) => m.CaseFormComponent),
    data: {
      title: 'Edit Case',
      breadcrumb: 'Edit',
      permissions: [PERMISSIONS.CASE_UPDATE],
    },
  },
  {
    path: ':id',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('./components/case-components/case-detail.component').then(
        (m) => m.CaseDetailComponent,
      ),
    data: {
      title: 'Case Details',
      breadcrumb: 'Details',
      permissions: [PERMISSIONS.CASE_LIST, PERMISSIONS.ADMIN_READ],
    },
  },
];
