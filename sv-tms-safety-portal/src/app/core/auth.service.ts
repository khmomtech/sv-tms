import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class AuthService {
  user$ = new BehaviorSubject<any>(null);
  token: string | null = null;

  // Refresh control
  private refreshInProgress = false;
  private refreshPromise: Promise<boolean> | null = null;

  constructor(private api: ApiService) {
    // If a refresh token is present from a previous session, we keep it
    // in sessionStorage. We do not auto-refresh on load to avoid unexpected
    // network calls; refresh will be attempted on-demand when a request
    // receives 401.
  }

  login(username: string, password: string) {
    return this.api.post('/auth/login', { username, password }).toPromise().then((res: any) => {
      this.setToken(res.token);
      if (res.refreshToken) {
        sessionStorage.setItem('refreshToken', res.refreshToken);
      }
      this.user$.next(res.user);
      return res;
    });
  }

  setToken(token: string | null) {
    this.token = token;
  }

  private getRefreshToken(): string | null {
    return sessionStorage.getItem('refreshToken');
  }

  async refreshToken(): Promise<boolean> {
    if (this.refreshInProgress && this.refreshPromise) return this.refreshPromise;

    const rt = this.getRefreshToken();
    if (!rt) {
      this.logout();
      return false;
    }

    this.refreshInProgress = true;
    this.refreshPromise = this.api.post('/auth/refresh', { refreshToken: rt }).toPromise()
      .then((res: any) => {
        this.setToken(res.token);
        if (res.refreshToken) sessionStorage.setItem('refreshToken', res.refreshToken);
        if (res.user) this.user$.next(res.user);
        this.refreshInProgress = false;
        this.refreshPromise = null;
        return true;
      })
      .catch(() => {
        this.refreshInProgress = false;
        this.refreshPromise = null;
        this.logout();
        return false;
      });

    return this.refreshPromise;
  }

  logout() {
    this.token = null;
    sessionStorage.removeItem('refreshToken');
    this.user$.next(null);
  }

  isInRole(role: string) {
    const u = this.user$.value;
    return u && u.roles && u.roles.includes(role);
  }
}
