import type { Routes } from '@angular/router';

export const TRAINING_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./list/training-list.component').then((m) => m.TrainingListComponent),
    data: { title: 'Training Records' },
  },
  {
    path: 'expiring',
    loadComponent: () =>
      import('./expiry/training-expiry.component').then((m) => m.TrainingExpiryComponent),
    data: { title: 'Expiring Training Records' },
  },
];
