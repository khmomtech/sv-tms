import { Injectable } from '@angular/core';
import type {
  ActivatedRouteSnapshot,
  CanActivate,
  CanActivateChild,
  RouterStateSnapshot,
} from '@angular/router';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Router } from '@angular/router';
import type { Observable } from 'rxjs';
import { map, take } from 'rxjs';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../services/auth.service';

@Injectable({
  providedIn: 'root',
})
export class AdminGuard implements CanActivate, CanActivateChild {
  constructor(
    private readonly router: Router,
    private readonly authService: AuthService,
  ) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<boolean> {
    return this.checkAdminAccess(state.url);
  }

  canActivateChild(
    childRoute: ActivatedRouteSnapshot,
    state: RouterStateSnapshot,
  ): Observable<boolean> {
    return this.checkAdminAccess(state.url);
  }

  private checkAdminAccess(url: string): Observable<boolean> {
    return this.authService.isAuthenticated$.pipe(
      take(1),
      map((isAuthenticated) => {
        if (!isAuthenticated) {
          this.authService.setRedirectUrl(url);
          this.router.navigate(['/login'], {
            queryParams: { returnUrl: url },
          });
          return false;
        }

        // Check if user has admin or superadmin role
        const user = this.authService.getCurrentUser();
        const hasAdminAccess = user?.roles?.some((role) =>
          ['ADMIN', 'SUPERADMIN'].includes(role.toUpperCase()),
        );

        if (hasAdminAccess) {
          return true;
        }

        // User is authenticated but not admin - redirect to dashboard
        console.warn('⛔ AdminGuard: User lacks ADMIN/SUPERADMIN role, redirecting to dashboard');
        this.router.navigate(['/dashboard']);
        return false;
      }),
    );
  }
}
