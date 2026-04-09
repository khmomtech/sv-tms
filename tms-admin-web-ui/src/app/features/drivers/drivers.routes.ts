import type { Routes } from '@angular/router';

export const DRIVERS_ROUTES: Routes = [
  {
    path: '',
    pathMatch: 'full',
    redirectTo: 'list',
  },
  {
    path: 'overview',
    loadComponent: () =>
      import('./driver-overview/driver-overview.component').then((m) => m.DriverOverviewComponent),
    data: { title: 'Overview & Monitoring' },
  },
  {
    path: 'list',
    loadComponent: () =>
      import('./driver-list/driver-list.component').then((m) => m.DriverListComponent),
    data: { title: 'Driver List' },
  },
  {
    path: 'documents',
    loadComponent: () =>
      import('../../components/drivers/documents/driver-documents.component').then(
        (m) => m.DriverDocumentsComponent,
      ),
    data: { title: 'Documents & Licenses' },
  },
  {
    path: 'shifts',
    loadComponent: () =>
      import('./driver-shifts/driver-shifts.component').then((m) => m.DriverShiftsComponent),
    data: { title: 'Shifts & Hours' },
  },
  {
    path: 'accounts',
    loadComponent: () =>
      import('./driver-app-accounts/driver-app-accounts.component').then(
        (m) => m.DriverAppAccountsComponent,
      ),
    data: { title: 'Driver App Accounts' },
  },
  {
    path: 'performance',
    loadComponent: () =>
      import('./driver-performance/driver-performance.component').then(
        (m) => m.DriverPerformanceComponent,
      ),
    data: { title: 'Performance & Incidents' },
  },
  {
    path: 'devices',
    loadComponent: () =>
      import('./driver-app-devices/driver-app-devices.component').then(
        (m) => m.DriverAppDevicesComponent,
      ),
    data: { title: 'Driver App Devices' },
  },
  {
    path: 'attendance',
    loadComponent: () =>
      import('./attendance/driver-attendance.component').then((m) => m.DriverAttendanceComponent),
    data: { title: 'Driver Attendance' },
  },
  {
    path: 'issues',
    loadComponent: () =>
      import('./driver-issues/driver-issue-list.component').then((m) => m.DriverIssueListComponent),
    data: { title: 'Driver Issues' },
  },
  {
    path: 'issues/:id',
    loadComponent: () =>
      import('./driver-issues/driver-issue-detail.component').then(
        (m) => m.DriverIssueDetailComponent,
      ),
    data: { title: 'Issue Detail' },
  },
  {
    path: 'communication/messages',
    loadComponent: () =>
      import('./driver-messages/driver-messages.component').then((m) => m.DriverMessagesComponent),
    data: { title: 'Driver Messages' },
  },
  {
    path: 'add',
    loadComponent: () => import('./create-driver.component').then((m) => m.CreateDriverComponent),
    data: { title: 'Create Driver' },
  },
  {
    path: 'location-history',
    pathMatch: 'full',
    redirectTo: 'list',
  },
  {
    path: ':id/location-history',
    loadComponent: () =>
      import('../../components/drivers/location/driver-location-history.component').then(
        (m) => m.DriverLocationHistoryComponent,
      ),
    data: { title: 'Driver Location History' },
  },
  {
    path: ':id',
    loadComponent: () =>
      import('../../components/drivers/driver-detail/driver-detail.component').then(
        (m) => m.DriverDetailComponent,
      ),
    data: { title: 'Driver Detail' },
  },
];
