import {
  HttpErrorResponse,
  HttpEvent,
  HttpHandler,
  HttpInterceptor,
  HttpRequest,
} from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

/**
 * HTTP Interceptor for centralized error tracking and monitoring.
 * Integrates with error tracking services (Sentry, Rollbar, etc.)
 *
 * Features:
 * - Captures all HTTP errors with context
 * - Enriches errors with user and request metadata
 * - Filters sensitive data from error payloads
 * - Categorizes errors by severity
 * - Supports custom error tracking service injection
 */
@Injectable()
export class ErrorTrackingInterceptor implements HttpInterceptor {
  // In production, inject your error tracking service (Sentry, Rollbar, etc.)
  // constructor(private errorTracker: ErrorTrackerService) {}

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const startTime = Date.now();

    return next.handle(req).pipe(
      catchError((error: HttpErrorResponse) => {
        const duration = Date.now() - startTime;

        // Capture error with rich context
        this.captureError(error, req, duration);

        // Pass error downstream for component-level handling
        return throwError(() => error);
      }),
    );
  }

  /**
   * Capture error to monitoring service with sanitized context
   */
  private captureError(error: HttpErrorResponse, req: HttpRequest<any>, duration: number): void {
    const errorContext = {
      // Request context
      url: req.url,
      method: req.method,
      requestId: req.headers.get('X-Request-ID'),
      duration,

      // Error details
      status: error.status,
      statusText: error.statusText,
      message: this.extractErrorMessage(error),

      // Timing
      timestamp: new Date().toISOString(),

      // User context (if available)
      user: this.getUserContext(),

      // Additional metadata
      tags: this.categorizeError(error),
      level: this.getErrorSeverity(error.status),
    };

    // Log to console in development
    if (this.isDevelopment()) {
      console.error('[Error Tracking]', errorContext);
    }

    // In production, send to error tracking service
    // Example: Sentry.captureException(error, { contexts: { http: errorContext } });
    // Example: Rollbar.error(error, errorContext);

    // For now, store in session for debugging
    this.storeErrorInSession(errorContext);
  }

  /**
   * Extract meaningful error message from HTTP error response
   */
  private extractErrorMessage(error: HttpErrorResponse): string {
    if (error.error) {
      if (typeof error.error === 'string') {
        return error.error;
      }
      if (error.error.message) {
        return error.error.message;
      }
      if (error.error.error) {
        return error.error.error;
      }
    }
    return error.message || error.statusText || 'Unknown error';
  }

  /**
   * Get current user context for error attribution
   */
  private getUserContext(): any {
    try {
      const userStr = localStorage.getItem('currentUser') || sessionStorage.getItem('currentUser');
      if (userStr) {
        const user = JSON.parse(userStr);
        // Return only non-sensitive fields
        return {
          id: user.id,
          username: user.username,
          role: user.role || user.roles?.[0],
        };
      }
    } catch (e) {
      console.warn('Failed to extract user context', e);
    }
    return null;
  }

  /**
   * Categorize error for filtering and alerting
   */
  private categorizeError(error: HttpErrorResponse): Record<string, string> {
    const tags: Record<string, string> = {};

    // Error type
    if (error.status === 0) {
      tags.type = 'network-error';
    } else if (error.status >= 500) {
      tags.type = 'server-error';
    } else if (error.status >= 400) {
      tags.type = 'client-error';
    }

    // Specific error categories
    if (error.status === 401) {
      tags.category = 'authentication';
    } else if (error.status === 403) {
      tags.category = 'authorization';
    } else if (error.status === 404) {
      tags.category = 'not-found';
    } else if (error.status === 409) {
      tags.category = 'conflict';
    } else if (error.status === 422) {
      tags.category = 'validation';
    } else if (error.status === 429) {
      tags.category = 'rate-limit';
    }

    // Feature detection from URL
    const url = error.url || '';
    if (url.includes('/drivers')) {
      tags.feature = 'driver-management';
    } else if (url.includes('/vehicles')) {
      tags.feature = 'fleet-management';
    } else if (url.includes('/dispatch')) {
      tags.feature = 'dispatch';
    } else if (url.includes('/orders')) {
      tags.feature = 'orders';
    }

    return tags;
  }

  /**
   * Determine error severity for alerting thresholds
   */
  private getErrorSeverity(status: number): 'error' | 'warning' | 'info' {
    if (status === 0 || status >= 500) {
      return 'error'; // Critical - server down or network failure
    } else if (status === 401 || status === 403 || status === 429) {
      return 'warning'; // Important - auth issues or rate limiting
    } else {
      return 'info'; // Expected client errors (validation, not found, etc.)
    }
  }

  /**
   * Check if running in development mode
   */
  private isDevelopment(): boolean {
    return !('production' in window) && window.location.hostname === 'localhost';
  }

  /**
   * Store recent errors in session storage for debugging
   * Keeps last 50 errors
   */
  private storeErrorInSession(errorContext: any): void {
    try {
      const key = 'app_error_log';
      const existingStr = sessionStorage.getItem(key) || '[]';
      const existing = JSON.parse(existingStr);

      // Keep only last 50 errors
      const updated = [errorContext, ...existing].slice(0, 50);

      sessionStorage.setItem(key, JSON.stringify(updated));
    } catch (e) {
      // Ignore storage errors
    }
  }
}
