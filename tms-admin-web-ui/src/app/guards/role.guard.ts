import { Injectable } from '@angular/core';
import type {
  ActivatedRouteSnapshot,
  CanActivate,
  CanActivateChild,
  RouterStateSnapshot,
} from '@angular/router';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Router } from '@angular/router';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../services/auth.service';

@Injectable({
  providedIn: 'root',
})
export class RoleGuard implements CanActivate, CanActivateChild {
  constructor(
    private readonly router: Router,
    private readonly authService: AuthService,
  ) {}

  canActivate(route: ActivatedRouteSnapshot, _state: RouterStateSnapshot): boolean {
    return this.checkAccess(route);
  }

  canActivateChild(childRoute: ActivatedRouteSnapshot, _state: RouterStateSnapshot): boolean {
    return this.checkAccess(childRoute);
  }

  private checkAccess(route: ActivatedRouteSnapshot): boolean {
    if (!this.authService.isAuthenticated()) {
      this.authService.logout();
      return false;
    }

    const requiredRoles = (route.data?.['roles'] as string[] | undefined) ?? [];
    if (requiredRoles.length === 0) {
      return true;
    }

    const hasRequiredRole = requiredRoles.some((role) => this.authService.hasRole(role));
    if (!hasRequiredRole) {
      // Redirect to unauthorized page instead of dashboard for better UX
      this.router.navigate(['/unauthorized']);
      return false;
    }

    return true;
  }
}
