// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpHeaders, HttpBackend } from '@angular/common/http';
import { Injectable } from '@angular/core';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Router } from '@angular/router';
import type { Observable } from 'rxjs';
import { of, tap, catchError, map, firstValueFrom, BehaviorSubject } from 'rxjs';

import { environment } from '../environments/environment';

export interface User {
  username: string;
  email: string;
  roles: string[];
  permissions?: string[];
}

interface AuthResponse {
  token: string;
  refreshToken?: string;
  user: User;
}

interface RefreshResponse {
  accessToken?: string;
  token?: string;
  refreshToken?: string;
  data?: {
    accessToken?: string;
    token?: string;
    refreshToken?: string;
  };
}

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private readonly apiUrl = `${environment.baseUrl}/api/auth`;
  /** Raw client bypassing interceptors for login/refresh to avoid DI cycles */
  private readonly httpRaw: HttpClient;
  private redirectUrl: string = '/dashboard';
  private isAuthenticatedSubject = new BehaviorSubject<boolean>(this.checkInitialAuthState());
  private tokenRefreshedSubject = new BehaviorSubject<string | null>(null);
  private refreshTokenTimeout?: ReturnType<typeof setTimeout>;
  private isRefreshing = false;
  private refreshPromise: Promise<string | null> | null = null;

  constructor(
    private readonly http: HttpClient,
    httpBackend: HttpBackend,
    private readonly router: Router,
  ) {
    this.httpRaw = new HttpClient(httpBackend);
    // Start auto-refresh mechanism
    this.startRefreshTokenTimer();
  }

  /** Observable for authentication state */
  get isAuthenticated$(): Observable<boolean> {
    return this.isAuthenticatedSubject.asObservable();
  }

  /** Observable for token refresh events - emits new token when refreshed */
  get tokenRefreshed$(): Observable<string | null> {
    return this.tokenRefreshedSubject.asObservable();
  }

  /** Check initial authentication state */
  private checkInitialAuthState(): boolean {
    const token = this.getToken();
    return !!token && !this.isTokenExpired(token);
  }

  /** Set redirect URL for post-login navigation */
  setRedirectUrl(url: string): void {
    this.redirectUrl = url;
  }

  /** Get redirect URL */
  getRedirectUrl(): string {
    return this.redirectUrl;
  }

  /** 🔐 Login */
  login(username: string, password: string): Observable<AuthResponse> {
    return this.http.post<any>(`${this.apiUrl}/login`, { username, password }).pipe(
      // Normalize backend ApiResponse wrapper { success,message,data } to AuthResponse
      map((resp) => {
        if (resp && resp.data) return resp.data as AuthResponse;
        return resp as AuthResponse;
      }),
      tap((response) => {
        if (response?.token) {
          this.saveToken(response.token);
          // save permissions if provided by backend (response.user may include permissions)
          try {
            const perms = (response as any)?.user?.permissions;
            const roles = (response as any)?.user?.roles || [];
            // Superadmin convenience: ensure all_functions is present client-side
            const enhancedPerms = roles.includes('SUPERADMIN')
              ? Array.from(new Set([...(Array.isArray(perms) ? perms : []), 'all_functions']))
              : perms;
            this.savePermissions(enhancedPerms);
          } catch (err) {
            console.warn('[AuthService] Could not extract permissions from login response');
          }
          if (response.refreshToken) {
            this.saveRefreshToken(response.refreshToken);
          }
          localStorage.setItem('user', JSON.stringify(response.user));
          this.isAuthenticatedSubject.next(true);

          // Start auto-refresh timer after successful login
          this.startRefreshTokenTimer();
        } else {
          console.error("Login failed: 'token' is missing in response");
        }
      }),
    );
  }

  /**  Refresh token */
  async refreshToken(): Promise<string | null> {
    // Prevent concurrent refresh attempts
    if (this.isRefreshing && this.refreshPromise) {
      console.log('[AuthService] Refresh already in progress, waiting...');
      return this.refreshPromise;
    }

    const refreshToken = this.getRefreshToken();
    if (!refreshToken) {
      console.warn('[AuthService] No refresh token available');
      return null;
    }

    // Check if refresh token is expired
    if (this.isTokenExpired(refreshToken)) {
      console.warn('[AuthService] Refresh token is expired');
      this.logout();
      return null;
    }

    this.isRefreshing = true;

    this.refreshPromise = (async () => {
      try {
        const res = await firstValueFrom(
          this.httpRaw
            .post<RefreshResponse>(
              `${this.apiUrl}/refresh`,
              {},
              {
                headers: new HttpHeaders({
                  Authorization: `Bearer ${refreshToken}`,
                }),
              },
            )
            .pipe(
              map((res) => {
                const payload = res?.data ?? res;
                const nextAccessToken = payload?.accessToken ?? payload?.token;
                if (nextAccessToken) {
                  this.saveToken(nextAccessToken);
                  if (payload?.refreshToken) this.saveRefreshToken(payload.refreshToken);

                  // Update auth state
                  this.isAuthenticatedSubject.next(true);

                  // Restart the auto-refresh timer with the new token
                  this.startRefreshTokenTimer();

                  console.log('[AuthService] Token refresh successful');
                  return nextAccessToken;
                }
                console.warn('[AuthService] No access token in refresh response');
                return null;
              }),
              catchError((err) => {
                console.error('[AuthService] Token refresh failed:', err);
                // If refresh fails due to 401/403, logout user
                if (err.status === 401 || err.status === 403) {
                  console.warn('[AuthService] Refresh token invalid, logging out');
                  this.logout();
                }
                return of(null);
              }),
            ),
        );
        return res ?? null;
      } catch (err) {
        console.error('[AuthService] Unexpected error during refresh:', err);
        return null;
      } finally {
        this.isRefreshing = false;
        this.refreshPromise = null;
      }
    })();

    return this.refreshPromise;
  }

  /** 💾 Save token */
  saveToken(token: string): void {
    localStorage.setItem('token', token);
    // Notify subscribers that token has been refreshed
    this.tokenRefreshedSubject.next(token);
  }

  /** 🔐 Save permissions (array of permission names) */
  savePermissions(permissions: string[] | undefined): void {
    try {
      if (!permissions) {
        localStorage.removeItem('permissions');
      } else {
        localStorage.setItem('permissions', JSON.stringify(permissions));
      }
    } catch (err) {
      console.error('[AuthService] Failed to save permissions', err);
    }
  }

  saveRefreshToken(refreshToken: string): void {
    localStorage.setItem('refresh_token', refreshToken);
  }

  /**  Get tokens */
  getToken(): string | null {
    return localStorage.getItem('token');
  }

  getRefreshToken(): string | null {
    return localStorage.getItem('refresh_token');
  }

  /** 👤 User Info */
  getUser(): User | null {
    try {
      const userStr = localStorage.getItem('user');
      return userStr ? JSON.parse(userStr) : null;
    } catch (error) {
      console.error('Error parsing user data:', error);
      return null;
    }
  }

  /**
   * Extract companyId from the JWT token payload claims.
   * Falls back to 1 if the claim is not present or the token cannot be decoded.
   */
  getCompanyId(): number {
    try {
      const token = this.getToken();
      if (!token) return 1;
      const parts = token.split('.');
      if (parts.length !== 3) return 1;
      const payload = JSON.parse(atob(parts[1]));
      return payload.companyId ?? payload.company_id ?? payload.partnerCompanyId ?? 1;
    } catch {
      return 1;
    }
  }

  /** 👮 Permission helpers */
  getPermissions(): string[] {
    try {
      const p = localStorage.getItem('permissions');
      if (!p) return [];
      const parsed = JSON.parse(p);
      return Array.isArray(parsed) ? parsed : [];
    } catch (err) {
      console.error('[AuthService] Error parsing permissions from storage', err);
      return [];
    }
  }

  hasPermission(permissionName: string): boolean {
    if (!permissionName) return false;
    // Superadmin/Admin bypass (role-based) to prevent empty menu when permission payload is missing
    if (this.hasRole('SUPERADMIN')) {
      return true;
    }

    const perms = this.getPermissions().map((p) => String(p).toLowerCase());
    if (perms.length === 0 && this.hasRole('ADMIN')) {
      return true;
    }
    const target = permissionName.toLowerCase();
    // wildcard
    if (perms.includes('all_functions')) return true;
    return perms.includes(target);
  }

  hasAnyPermission(permissionNames: string[]): boolean {
    if (!Array.isArray(permissionNames) || permissionNames.length === 0) {
      return false;
    }
    return permissionNames.some((permission) => this.hasPermission(permission));
  }

  hasAllPermissions(permissionNames: string[]): boolean {
    if (!Array.isArray(permissionNames) || permissionNames.length === 0) {
      return false;
    }
    return permissionNames.every((permission) => this.hasPermission(permission));
  }

  /** 👮 Role Checks */
  hasRole(requiredRole: string): boolean {
    const user = this.getUser();
    if (!user?.roles || !Array.isArray(user.roles)) {
      return false;
    }
    const normalizedRoles = user.roles.map((role) => this.normalizeRole(role));
    const targetRole = this.normalizeRole(requiredRole);

    // Superadmin has all roles
    if (normalizedRoles.includes('SUPERADMIN')) {
      return true;
    }

    return normalizedRoles.includes(targetRole);
  }

  private normalizeRole(role: string): string {
    return String(role)
      .trim()
      .toUpperCase()
      .replace(/^ROLE_/, '');
  }

  isAdmin(): boolean {
    // SUPERADMIN should also be considered as admin
    return this.hasRole('ADMIN') || this.hasRole('SUPERADMIN');
  }

  isSuperAdmin(): boolean {
    return this.hasRole('SUPERADMIN');
  }

  isDispatcherOrDriver(): boolean {
    return this.hasRole('MANAGER') || this.hasRole('DRIVER');
  }

  /** 🔐 Auth Validity */
  isAuthenticated(): boolean {
    const token = this.getToken();
    return !!token && !this.isTokenExpired(token);
  }

  isTokenExpired(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      const expiry = payload.exp * 1000;
      return Date.now() > expiry;
    } catch (err) {
      return true;
    }
  }

  /**
   * Get the expiry timestamp (in milliseconds) from a JWT token
   */
  private getTokenExpiryTime(token: string): number | null {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      return payload.exp * 1000; // Convert to milliseconds
    } catch (err) {
      console.error('[AuthService] Error parsing token expiry:', err);
      return null;
    }
  }

  /**
   * Start auto-refresh timer
   * Automatically refreshes the token before it expires (2 minutes before expiry)
   */
  private startRefreshTokenTimer(): void {
    // Clear any existing timeout
    this.stopRefreshTokenTimer();

    const token = this.getToken();
    if (!token) {
      console.log('[AuthService] No token found, skipping auto-refresh timer');
      return;
    }

    if (this.isTokenExpired(token)) {
      console.warn('[AuthService] Token is already expired, cannot schedule refresh');
      return;
    }

    const expiryTime = this.getTokenExpiryTime(token);
    if (!expiryTime) {
      console.warn('[AuthService] Could not parse token expiry, skipping auto-refresh timer');
      return;
    }

    // Calculate time until refresh (refresh 2 minutes before expiry)
    const now = Date.now();
    const timeUntilExpiry = expiryTime - now;
    const refreshBuffer = 2 * 60 * 1000; // 2 minutes in milliseconds
    const timeUntilRefresh = Math.max(0, timeUntilExpiry - refreshBuffer);

    // If token expires too soon (less than 1 minute), refresh immediately
    if (timeUntilRefresh < 60000) {
      console.log('[AuthService] Token expires soon, refreshing immediately');
      this.refreshToken();
      return;
    }

    console.log(
      `[AuthService] Token expires at ${new Date(expiryTime).toISOString()}, ` +
        `auto-refresh scheduled in ${Math.round(timeUntilRefresh / 1000)}s`,
    );

    // Schedule the refresh
    this.refreshTokenTimeout = setTimeout(async () => {
      console.log('[AuthService] Auto-refreshing token...');
      try {
        const success = await this.refreshToken();
        if (success) {
          console.log('[AuthService] Auto-refresh successful');
        } else {
          console.warn('[AuthService] Auto-refresh failed, user may need to re-login');
          // Don't logout automatically, let the user continue with current session
          // The interceptor will handle expired tokens on next request
        }
      } catch (err) {
        console.error('[AuthService] Auto-refresh error:', err);
      }
    }, timeUntilRefresh);
  }

  /**
   * Stop the auto-refresh timer
   */
  private stopRefreshTokenTimer(): void {
    if (this.refreshTokenTimeout) {
      clearTimeout(this.refreshTokenTimeout);
      this.refreshTokenTimeout = undefined;
    }
  }

  /** 🚪 Logout */
  logout(): void {
    // Stop auto-refresh timer
    this.stopRefreshTokenTimer();

    localStorage.removeItem('token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('user');
    localStorage.removeItem('permissions');
    this.isAuthenticatedSubject.next(false);
    this.router.navigate(['/login']);
  }

  /** 🧹 Force clear all cached session data */
  forceClearSession(): void {
    console.log('🧹 Force clearing all cached session data...');
    localStorage.clear();
    sessionStorage.clear();
    this.router.navigate(['/login']);
  }

  getCurrentUser(): User | null {
    return this.getUser();
  }
}
