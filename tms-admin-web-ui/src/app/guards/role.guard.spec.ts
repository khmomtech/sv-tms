import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';

import { AuthService } from '../services/auth.service';

import { RoleGuard } from './role.guard';

describe('RoleGuard', () => {
  let guard: RoleGuard;
  let authServiceSpy: jasmine.SpyObj<AuthService>;
  let routerSpy: jasmine.SpyObj<Router>;

  beforeEach(() => {
    const authSpy = jasmine.createSpyObj('AuthService', ['isAuthenticated', 'hasRole', 'logout']);
    const routerMock = jasmine.createSpyObj('Router', ['navigate']);

    // Mock logout to navigate to login
    authSpy.logout.and.callFake(() => {
      routerMock.navigate(['/login']);
    });

    TestBed.configureTestingModule({
      providers: [
        RoleGuard,
        { provide: AuthService, useValue: authSpy },
        { provide: Router, useValue: routerMock },
      ],
    });

    guard = TestBed.inject(RoleGuard);
    authServiceSpy = TestBed.inject(AuthService) as jasmine.SpyObj<AuthService>;
    routerSpy = TestBed.inject(Router) as jasmine.SpyObj<Router>;
  });

  it('should be created', () => {
    expect(guard).toBeTruthy();
  });

  describe('canActivate', () => {
    it('should allow access when authenticated and no roles required', () => {
      authServiceSpy.isAuthenticated.and.returnValue(true);

      const route = { data: {} };
      const state = { url: '/dashboard' };

      const result = guard.canActivate(route as any, state as any);

      expect(result).toBeTruthy();
      expect(authServiceSpy.isAuthenticated).toHaveBeenCalled();
    });

    it('should allow access when authenticated and user has required role', () => {
      authServiceSpy.isAuthenticated.and.returnValue(true);
      authServiceSpy.hasRole.and.returnValue(true);

      const route = { data: { roles: ['ADMIN'] } };
      const state = { url: '/admin' };

      const result = guard.canActivate(route as any, state as any);

      expect(result).toBeTruthy();
      expect(authServiceSpy.hasRole).toHaveBeenCalledWith('ADMIN');
    });

    it('should deny access and redirect when user lacks required role', () => {
      authServiceSpy.isAuthenticated.and.returnValue(true);
      authServiceSpy.hasRole.and.returnValue(false);

      const route = { data: { roles: ['ADMIN'] } };
      const state = { url: '/admin' };

      const result = guard.canActivate(route as any, state as any);

      expect(result).toBeFalsy();
      expect(routerSpy.navigate).toHaveBeenCalledWith(['/unauthorized']);
    });

    it('should deny access and logout when not authenticated', () => {
      authServiceSpy.isAuthenticated.and.returnValue(false);

      const route = { data: {} };
      const state = { url: '/dashboard' };

      const result = guard.canActivate(route as any, state as any);

      expect(result).toBeFalsy();
      expect(routerSpy.navigate).toHaveBeenCalledWith(['/login']);
    });
  });

  describe('canActivateChild', () => {
    it('should delegate to checkAccess', () => {
      const spy = spyOn<any>(guard, 'checkAccess').and.returnValue(true);

      const childRoute = { data: { roles: ['USER'] } } as any;
      const state = { url: '/child' } as any;

      const result = guard.canActivateChild(childRoute, state);

      expect(spy).toHaveBeenCalledWith(childRoute);
      expect(result).toBeTruthy();
    });
  });
});
