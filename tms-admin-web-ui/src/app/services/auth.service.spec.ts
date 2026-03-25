import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';

import { environment } from '../../environments/environment';

import { AuthService } from './auth.service';

describe('AuthService', () => {
  let service: AuthService;
  let httpMock: HttpTestingController;
  let routerSpy: jasmine.SpyObj<Router>;

  beforeEach(() => {
    const routerMock = jasmine.createSpyObj('Router', ['navigate']);

    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [AuthService, { provide: Router, useValue: routerMock }],
    });

    service = TestBed.inject(AuthService);
    httpMock = TestBed.inject(HttpTestingController);
    routerSpy = TestBed.inject(Router) as jasmine.SpyObj<Router>;

    // Clear localStorage before each test
    localStorage.clear();
  });

  afterEach(() => {
    httpMock.verify();
    localStorage.clear();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('login', () => {
    it('should login successfully and store token', () => {
      const mockResponse = {
        token: 'mock-jwt-token',
        refreshToken: 'mock-refresh-token',
        user: { username: 'testuser', email: 'test@example.com', roles: ['USER'] },
      };

      service.login('testuser', 'password').subscribe((response) => {
        expect(response).toEqual(mockResponse);
      });

      const req = httpMock.expectOne(`${environment.baseUrl}/api/auth/login`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ username: 'testuser', password: 'password' });
      req.flush(mockResponse);

      expect(localStorage.getItem('token')).toBe('mock-jwt-token');
      expect(localStorage.getItem('refresh_token')).toBe('mock-refresh-token');
      expect(JSON.parse(localStorage.getItem('user')!)).toEqual(mockResponse.user);
    });
  });

  describe('isAuthenticated', () => {
    it('should return true for valid token', () => {
      const validToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjIwMDAwMDAwMDB9.signature';
      localStorage.setItem('token', validToken);

      expect(service.isAuthenticated()).toBeTruthy();
    });

    it('should return false for expired token', () => {
      const expiredToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjJ9.signature';
      localStorage.setItem('token', expiredToken);

      expect(service.isAuthenticated()).toBeFalsy();
    });

    it('should return false when no token', () => {
      expect(service.isAuthenticated()).toBeFalsy();
    });
  });

  describe('logout', () => {
    it('should clear storage and navigate to login', () => {
      localStorage.setItem('token', 'token');
      localStorage.setItem('refresh_token', 'refresh');
      localStorage.setItem('user', JSON.stringify({ username: 'test' }));

      service.logout();

      expect(localStorage.getItem('token')).toBeNull();
      expect(localStorage.getItem('refresh_token')).toBeNull();
      expect(localStorage.getItem('user')).toBeNull();
      expect(routerSpy.navigate).toHaveBeenCalledWith(['/login']);
    });
  });

  describe('hasRole', () => {
    it('should return true for user with role', () => {
      localStorage.setItem('user', JSON.stringify({ username: 'test', roles: ['ADMIN', 'USER'] }));

      expect(service.hasRole('ADMIN')).toBeTruthy();
      expect(service.hasRole('USER')).toBeTruthy();
      expect(service.hasRole('MANAGER')).toBeFalsy();
    });
  });

  describe('permissions', () => {
    it('should return true when user has direct permission', () => {
      localStorage.setItem('user', JSON.stringify({ username: 'test', roles: ['USER'] }));
      localStorage.setItem('permissions', JSON.stringify(['geofence:read', 'driver:live:read']));

      expect(service.hasPermission('geofence:read')).toBeTrue();
      expect(service.hasPermission('geofence:create')).toBeFalse();
    });

    it('should be case-insensitive for permission checks', () => {
      localStorage.setItem('user', JSON.stringify({ username: 'test', roles: ['USER'] }));
      localStorage.setItem('permissions', JSON.stringify(['GEOFENCE:READ']));

      expect(service.hasPermission('geofence:read')).toBeTrue();
      expect(service.hasPermission('Geofence:Read')).toBeTrue();
    });

    it('should allow all permissions for SUPERADMIN role', () => {
      localStorage.setItem('user', JSON.stringify({ username: 'super', roles: ['SUPERADMIN'] }));
      localStorage.setItem('permissions', JSON.stringify([]));

      expect(service.hasPermission('anything:any')).toBeTrue();
      expect(service.hasPermission('geofence:delete')).toBeTrue();
    });

    it('should allow all permissions when all_functions is present', () => {
      localStorage.setItem('user', JSON.stringify({ username: 'test', roles: ['USER'] }));
      localStorage.setItem('permissions', JSON.stringify(['all_functions']));

      expect(service.hasPermission('geofence:read')).toBeTrue();
      expect(service.hasPermission('random:permission')).toBeTrue();
    });

    it('hasAnyPermission should return true when at least one permission matches', () => {
      localStorage.setItem('user', JSON.stringify({ username: 'test', roles: ['USER'] }));
      localStorage.setItem('permissions', JSON.stringify(['geofence:read']));

      expect(service.hasAnyPermission(['geofence:create', 'geofence:read'])).toBeTrue();
      expect(service.hasAnyPermission(['geofence:create', 'geofence:update'])).toBeFalse();
    });

    it('hasAnyPermission should return false for empty input', () => {
      localStorage.setItem('user', JSON.stringify({ username: 'test', roles: ['USER'] }));
      localStorage.setItem('permissions', JSON.stringify(['geofence:read']));

      expect(service.hasAnyPermission([])).toBeFalse();
    });

    it('hasAllPermissions should return true only when all permissions match', () => {
      localStorage.setItem('user', JSON.stringify({ username: 'test', roles: ['USER'] }));
      localStorage.setItem('permissions', JSON.stringify(['geofence:read', 'geofence:update']));

      expect(service.hasAllPermissions(['geofence:read', 'geofence:update'])).toBeTrue();
      expect(service.hasAllPermissions(['geofence:read', 'geofence:delete'])).toBeFalse();
    });

    it('hasAllPermissions should return false for empty input', () => {
      localStorage.setItem('user', JSON.stringify({ username: 'test', roles: ['USER'] }));
      localStorage.setItem('permissions', JSON.stringify(['geofence:read']));

      expect(service.hasAllPermissions([])).toBeFalse();
    });
  });
});
