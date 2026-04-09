import type { Routes } from '@angular/router';

export const PARTNERS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./partner-list/partner-list.component').then((m) => m.PartnerListComponent),
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./partner-detail/partner-detail.component').then((m) => m.PartnerDetailComponent),
  },
];
