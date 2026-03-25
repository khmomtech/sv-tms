import { inject, Injectable } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

/**
 * Simple guard usable as `canActivate: [authGuard]` in route definitions.
 * If not authenticated, navigates to `/login`.
 */
export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const user = auth.user$.value;
  if (user) return true;
  router.navigate(['/login']);
  return false;
};
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  if (!auth.user$.value) {
    router.navigate(['/']);
    return false;
  }
  return true;
};
