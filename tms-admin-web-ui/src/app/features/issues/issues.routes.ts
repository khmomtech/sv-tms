import type { Routes } from '@angular/router';
import { PERMISSIONS } from '../../shared/permissions';

export const ISSUES_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./list/issue-list.component').then((m) => m.IssueListComponent),
    data: {
      title: 'Issues',
      requiredPermissions: [PERMISSIONS.ISSUE_LIST],
    },
  },
  {
    path: 'create',
    loadComponent: () =>
      import('./create/issue-create.component').then((m) => m.IssueCreateComponent),
    data: {
      title: 'Create Issue',
      requiredPermissions: [PERMISSIONS.ISSUE_CREATE],
    },
  },
  {
    path: 'my',
    loadComponent: () => import('./list/issue-list.component').then((m) => m.IssueListComponent),
    data: {
      title: 'My Issues',
      requiredPermissions: [PERMISSIONS.ISSUE_LIST],
    },
  },
  {
    path: 'open',
    loadComponent: () => import('./list/issue-list.component').then((m) => m.IssueListComponent),
    data: {
      title: 'Open Issues',
      requiredPermissions: [PERMISSIONS.ISSUE_LIST],
    },
  },
  {
    path: 'closed',
    loadComponent: () => import('./list/issue-list.component').then((m) => m.IssueListComponent),
    data: {
      title: 'Closed Issues',
      requiredPermissions: [PERMISSIONS.ISSUE_LIST],
    },
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./detail/issue-detail.component').then((m) => m.IssueDetailComponent),
    data: {
      title: 'Issue Detail',
      requiredPermissions: [PERMISSIONS.ISSUE_READ],
    },
  },
];
