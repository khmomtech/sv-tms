import type { Routes } from '@angular/router';

export const COMPLIANCE_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./dashboard/compliance-dashboard.component').then(
        (m) => m.ComplianceDashboardComponent,
      ),
    data: { title: 'Document Compliance Dashboard' },
  },
];
