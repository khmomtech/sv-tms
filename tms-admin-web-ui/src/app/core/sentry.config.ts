import * as Sentry from '@sentry/angular';
import type { ErrorHandler } from '@angular/core';

import { environment } from '../environments/environment';

/**
 * Initialize Sentry error monitoring
 * Call this before bootstrapping the Angular application
 */
export function initSentry(): void {
  if (!environment.production) {
    console.log('[Sentry] Skipping initialization in development mode');
    return;
  }

  Sentry.init({
    dsn: environment.sentryDsn || '',
    environment: environment.production ? 'production' : 'development',

    // Performance Monitoring
    integrations: [
      Sentry.browserTracingIntegration(),
      Sentry.replayIntegration({
        maskAllText: true,
        blockAllMedia: true,
      }),
    ],

    // Performance trace sampling
    tracesSampleRate: 0.1, // 10% of transactions

    // Session replay sampling
    replaysSessionSampleRate: 0.1, // 10% of sessions
    replaysOnErrorSampleRate: 1.0, // 100% of sessions with errors

    // Release tracking
    release: environment.version || '0.0.0',

    // Ignore common errors
    ignoreErrors: [
      'Non-Error promise rejection captured',
      'ResizeObserver loop limit exceeded',
      'Navigation cancelled',
      /ChunkLoadError/,
      /Loading chunk .* failed/,
    ],

    // Filter sensitive data
    beforeSend(event, hint) {
      // Don't send events if Sentry DSN is not configured
      if (!environment.sentryDsn) {
        return null;
      }

      // Remove sensitive query parameters
      if (event.request?.url) {
        const url = new URL(event.request.url);
        const sensitiveParams = ['token', 'access_token', 'password', 'api_key'];
        sensitiveParams.forEach((param) => url.searchParams.delete(param));
        event.request.url = url.toString();
      }

      return event;
    },
  });
}

/**
 * Sentry Error Handler for Angular
 * Integrates with Angular's error handling mechanism
 */
export function createSentryErrorHandler(): ErrorHandler {
  return Sentry.createErrorHandler({
    showDialog: false, // Don't show Sentry dialog to users
    logErrors: !environment.production, // Log errors in dev mode
  });
}
