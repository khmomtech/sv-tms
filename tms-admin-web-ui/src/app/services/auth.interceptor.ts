import type {
  HttpEvent,
  HttpInterceptor,
  HttpHandler,
  HttpRequest,
  HttpErrorResponse,
} from '@angular/common/http';
import { Injectable, Injector } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError, from } from 'rxjs';
import { catchError, switchMap } from 'rxjs/operators';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private readonly injector: Injector) {}

  // Lazily resolve AuthService to avoid DI circular reference with HTTP_INTERCEPTORS
  private get authService(): AuthService {
    return this.injector.get(AuthService);
  }

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.authService.getToken();

    // Skip auth URLs
    if (req.url.includes('/auth/login') || req.url.includes('/auth/refresh')) {
      return next.handle(req);
    }

    // If token exists but is expired, try to refresh first
    if (token && this.authService.isTokenExpired(token)) {
      console.warn('[AuthInterceptor] Token expired. Attempting refresh...');

      return from(this.authService.refreshToken()).pipe(
        switchMap((newToken) => {
          if (newToken) {
            const newReq = this.addAuthHeader(req, newToken);
            return next.handle(newReq);
          } else {
            // Check if this is a background request that shouldn't trigger logout
            const isBackgroundRequest = this.isBackgroundRequest(req);
            if (!isBackgroundRequest) {
              console.warn('[AuthInterceptor] Token refresh failed, logging out user');
              this.authService.logout();
            }
            return throwError(() => new Error('Token refresh failed'));
          }
        }),
        catchError((err) => {
          const isBackgroundRequest = this.isBackgroundRequest(req);
          if (!isBackgroundRequest) {
            console.error('[AuthInterceptor] Refresh error, logging out user:', err);
            this.authService.logout();
          }
          return throwError(() => err);
        }),
      );
    }

    // Token exists and is valid → add Authorization header, and mark as not retried
    const baseReq = token ? this.addAuthHeader(req, token) : req;
    const authReq = baseReq.clone({
      setHeaders: {
        'X-Retried': baseReq.headers.get('X-Retried') ?? 'false',
      },
    });

    return next.handle(authReq).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401) {
          const body: any = error.error;
          const code = body && typeof body === 'object' ? body.error : undefined;
          const alreadyRetried = authReq.headers.get('X-Retried') === 'true';

          if (code === 'TOKEN_EXPIRED' && !alreadyRetried) {
            console.warn('[AuthInterceptor] TOKEN_EXPIRED. Refreshing and retrying once...');
            return from(this.authService.refreshToken()).pipe(
              switchMap((newToken) => {
                if (newToken) {
                  const retryReq = this.addAuthHeader(
                    authReq.clone({ setHeaders: { 'X-Retried': 'true' } }),
                    newToken,
                  );
                  return next.handle(retryReq);
                } else {
                  const isBackgroundRequest = this.isBackgroundRequest(authReq);
                  if (!isBackgroundRequest) {
                    this.authService.logout();
                  }
                  return throwError(() => error);
                }
              }),
              catchError((err) => {
                const isBackgroundRequest = this.isBackgroundRequest(authReq);
                if (!isBackgroundRequest) {
                  this.authService.logout();
                }
                return throwError(() => err);
              }),
            );
          }

          // For other 401 cases or already retried:
          // Only force-logout if there is no token at all (truly unauthenticated).
          // If a valid token exists but the backend rejected the request due to
          // insufficient permissions (should be 403 but returned 401), propagate
          // the error so the component can handle it without disrupting the session.
          if (!token) {
            const isBackgroundRequest = this.isBackgroundRequest(authReq);
            if (!isBackgroundRequest) {
              this.authService.logout();
            }
          }
          return throwError(() => error);
        }

        return throwError(() => error);
      }),
    );
  }

  private addAuthHeader(req: HttpRequest<any>, token: string): HttpRequest<any> {
    return req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`,
      },
    });
  }

  private isBackgroundRequest(req: HttpRequest<any>): boolean {
    const backgroundPatterns = [
      '/count',
      '/notifications',
      '/admin/notifications',
      '/health',
      '/actuator',
      'polling=true',
    ];

    return backgroundPatterns.some(
      (pattern) => req.url.includes(pattern) || req.params.get('polling') === 'true',
    );
  }
}
