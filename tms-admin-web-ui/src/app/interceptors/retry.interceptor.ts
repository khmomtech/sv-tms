import {
  HttpErrorResponse,
  HttpEvent,
  HttpHandler,
  HttpInterceptor,
  HttpRequest,
} from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, throwError, timer } from 'rxjs';
import { catchError, mergeMap, retry, retryWhen, scan } from 'rxjs/operators';

/**
 * HTTP Interceptor that implements intelligent retry logic with exponential backoff
 * for transient errors (5xx, network failures, timeouts).
 *
 * Production-grade features:
 * - Exponential backoff (1s, 2s, 4s)
 * - Maximum 3 retry attempts
 * - Only retries safe methods (GET, HEAD, OPTIONS) and 5xx errors
 * - Logs retry attempts for monitoring
 * - Request tracking with X-Request-ID
 */
@Injectable()
export class RetryInterceptor implements HttpInterceptor {
  private readonly MAX_RETRIES = 3;
  private readonly INITIAL_DELAY_MS = 1000;
  private readonly MAX_DELAY_MS = 10000;
  // Limit network-error retries separately to avoid long retry storms
  private readonly MAX_NETWORK_ERROR_RETRIES = 1;

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // Generate request ID if not present (for distributed tracing)
    const requestId = req.headers.get('X-Request-ID') || this.generateRequestId();
    const reqWithId = req.clone({
      setHeaders: { 'X-Request-ID': requestId },
    });

    return next.handle(reqWithId).pipe(
      retryWhen((errors) =>
        errors.pipe(
          // accumulator holds retryCount and optional lastDelay
          scan(
            (acc: { retryCount: number }, error: HttpErrorResponse) => {
              const retryCount = acc.retryCount || 0;

              // Don't retry if max attempts reached
              if (retryCount >= this.MAX_RETRIES) {
                console.error(
                  `[Retry] Max retries (${this.MAX_RETRIES}) reached for request ${requestId}`,
                  {
                    url: req.url,
                    method: req.method,
                    error: error.message,
                  },
                );
                throw error;
              }

              // Do not retry requests matching known paths or non-retriable conditions
              if (!this.shouldRetry(reqWithId, error)) {
                console.warn(`[Retry] Not retrying non-safe method or non-transient error`, {
                  requestId,
                  method: req.method,
                  status: error.status,
                });
                throw error;
              }

              // Special-case network errors (status === 0): keep them limited
              if (error.status === 0 && retryCount >= this.MAX_NETWORK_ERROR_RETRIES) {
                console.error(
                  `[Retry] Network error and max network retries reached for ${requestId}`,
                );
                throw error;
              }

              const nextRetryCount = retryCount + 1;

              // Compute delay: if server provided Retry-After header on 429, respect it.
              let delayMs = this.calculateBackoff(nextRetryCount);
              if (error.status === 429) {
                try {
                  const ra = error.headers?.get?.('retry-after');
                  if (ra) {
                    const seconds = parseInt(ra, 10);
                    if (!isNaN(seconds)) {
                      delayMs = Math.max(delayMs, seconds * 1000);
                    } else {
                      const date = Date.parse(ra);
                      if (!isNaN(date)) {
                        delayMs = Math.max(delayMs, Math.max(0, date - Date.now()));
                      }
                    }
                  }
                } catch (e) {
                  // ignore header parsing errors and fall back to backoff
                }
              }

              console.warn(
                `[Retry] Attempt ${nextRetryCount}/${this.MAX_RETRIES} for request ${requestId}`,
                {
                  url: req.url,
                  method: req.method,
                  status: error.status,
                  delayMs,
                  message: error.message,
                },
              );

              return { retryCount: nextRetryCount, delayMs };
            },
            { retryCount: 0 },
          ),
          mergeMap((acc) => timer((acc as any).delayMs || this.INITIAL_DELAY_MS)),
        ),
      ),
      catchError((error: HttpErrorResponse) => {
        // Final error logging with full context
        console.error(`[Retry] Request failed after all retries`, {
          requestId,
          url: req.url,
          method: req.method,
          status: error.status,
          statusText: error.statusText,
          message: error.message,
        });

        // Enhance error with request metadata for better debugging
        const enhancedError = new HttpErrorResponse({
          error: error.error,
          headers: error.headers,
          status: error.status,
          statusText: error.statusText,
          url: error.url || req.url,
        });

        (enhancedError as any).requestId = requestId;
        (enhancedError as any).retries = this.MAX_RETRIES;

        return throwError(() => enhancedError);
      }),
    );
  }

  /**
   * Determine if request should be retried based on method safety and error type
   */
  private shouldRetry(req: HttpRequest<any>, error: HttpErrorResponse): boolean {
    // Blacklist specific URL patterns that must not be retried because
    // they either cause harmful repeated side-effects or are known to
    // return consistent server errors that should be handled by UI.
    const noRetryPatterns: RegExp[] = [
      /\/api\/public\/counts/, // counts endpoints — avoid amplifying failures
      /\/api\/admin\/users\/driver-account/, // driver-account lookups
      /\/api\/loading-ops\/queue/, // queue endpoint can be hot-polled; avoid retry storms
    ];

    if (noRetryPatterns.some((p) => p.test(req.url))) return false;

    // Only retry safe methods (idempotent operations)
    const safeMethods = ['GET', 'HEAD', 'OPTIONS'];
    if (!safeMethods.includes(req.method.toUpperCase())) {
      return false;
    }

    // Retry transient errors
    const retriableStatuses = [
      0, // Network error / Connection refused
      408, // Request Timeout
      429, // Too Many Requests (rate limiting)
      500, // Internal Server Error
      502, // Bad Gateway
      503, // Service Unavailable
      504, // Gateway Timeout
    ];

    return retriableStatuses.includes(error.status);
  }

  /**
   * Calculate exponential backoff delay with jitter
   * Formula: min(MAX_DELAY, INITIAL_DELAY * 2^(attempt-1)) + random(0-1000ms)
   */
  private calculateBackoff(attempt: number): number {
    const exponentialDelay = this.INITIAL_DELAY_MS * Math.pow(2, attempt - 1);
    const jitter = Math.random() * 1000; // Add randomness to prevent thundering herd
    return Math.min(exponentialDelay + jitter, this.MAX_DELAY_MS);
  }

  /**
   * Generate unique request ID for tracing
   */
  private generateRequestId(): string {
    return `req-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
  }
}
