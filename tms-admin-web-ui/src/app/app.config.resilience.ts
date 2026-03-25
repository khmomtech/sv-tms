import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { HTTP_INTERCEPTORS, provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { provideRouter } from '@angular/router';
import { provideAnimations } from '@angular/platform-browser/animations';

import { routes } from './app.routes';
import { RetryInterceptor } from './interceptors/retry.interceptor';
import { ErrorTrackingInterceptor } from './interceptors/error-tracking.interceptor';
import { AuthInterceptor } from './services/auth.interceptor';

/**
 * Enhanced application configuration with production-grade resilience features.
 *
 * Interceptor Order (important!):
 * 1. AuthInterceptor - Adds auth headers first
 * 2. RetryInterceptor - Handles retries with exponential backoff
 * 3. ErrorTrackingInterceptor - Tracks errors for monitoring
 *
 * This order ensures:
 * - Auth is always included in retried requests
 * - Errors are tracked even after retry attempts
 * - Request IDs propagate through the entire chain
 */
export const appConfigWithResilience: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideAnimations(),
    provideHttpClient(withInterceptorsFromDi()),

    // HTTP Interceptors in execution order
    {
      provide: HTTP_INTERCEPTORS,
      useClass: AuthInterceptor,
      multi: true,
    },
    {
      provide: HTTP_INTERCEPTORS,
      useClass: RetryInterceptor,
      multi: true,
    },
    {
      provide: HTTP_INTERCEPTORS,
      useClass: ErrorTrackingInterceptor,
      multi: true,
    },
  ],
};
