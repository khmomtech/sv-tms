import { HttpErrorResponse } from '@angular/common/http';
import type { ErrorHandler } from '@angular/core';
import { Injectable, inject } from '@angular/core';
import { Router } from '@angular/router';
import * as Sentry from '@sentry/angular';
import { ToastrService } from 'ngx-toastr';

import { environment } from '../../environments/environment';
import { LoggerService } from './logger.service';

export interface ErrorContext {
  component?: string;
  action?: string;
  userId?: string;
  timestamp?: Date;
  [key: string]: any;
}

export interface ErrorResponse {
  userMessage: string;
  technicalMessage: string;
  statusCode?: number;
  canRetry: boolean;
  shouldLogout?: boolean;
}

/**
 * Centralized error handling service
 * Processes all application errors with user-friendly messages
 */
@Injectable({
  providedIn: 'root',
})
export class ErrorHandlerService implements ErrorHandler {
  private readonly toastr = inject(ToastrService);
  private readonly router = inject(Router);
  private readonly logger = inject(LoggerService);

  /**
   * Handle all uncaught errors
   */
  handleError(error: Error | HttpErrorResponse, context?: ErrorContext): void {
    const errorResponse = this.processError(error, context);

    // Log to structured logger
    this.logger.error('Unhandled error occurred', {
      error,
      context,
      errorResponse,
    });

    // Send to Sentry in production
    if (environment.production && environment.sentryDsn) {
      this.reportToSentry(error, context);
    }

    // Show user-friendly message
    this.showErrorToUser(errorResponse);

    // Handle special cases
    if (errorResponse.shouldLogout) {
      this.handleAuthError();
    }

    // In development, also log to console
    if (!environment.production) {
      console.error('Error details:', error);
      if (context) {
        console.log('Error context:', context);
      }
    }
  }

  /**
   * Process error and return user-friendly response
   */
  processError(error: Error | HttpErrorResponse, context?: ErrorContext): ErrorResponse {
    if (error instanceof HttpErrorResponse) {
      return this.handleHttpError(error, context);
    }

    return this.handleClientError(error, context);
  }

  /**
   * Handle HTTP errors
   */
  private handleHttpError(error: HttpErrorResponse, context?: ErrorContext): ErrorResponse {
    const statusCode = error.status;

    switch (statusCode) {
      case 0:
        return {
          userMessage: 'Unable to connect to the server. Please check your internet connection.',
          technicalMessage: 'Network error - no response from server',
          statusCode: 0,
          canRetry: true,
        };

      case 400:
        return {
          userMessage:
            this.extractErrorMessage(error) || 'Invalid request. Please check your input.',
          technicalMessage: error.message,
          statusCode: 400,
          canRetry: false,
        };

      case 401:
        return {
          userMessage: 'Your session has expired. Please log in again.',
          technicalMessage: 'Unauthorized - token expired or invalid',
          statusCode: 401,
          canRetry: false,
          shouldLogout: true,
        };

      case 403:
        return {
          userMessage: "You don't have permission to perform this action.",
          technicalMessage: 'Forbidden - insufficient permissions',
          statusCode: 403,
          canRetry: false,
        };

      case 404:
        return {
          userMessage: 'The requested resource was not found.',
          technicalMessage: `Resource not found: ${error.url}`,
          statusCode: 404,
          canRetry: false,
        };

      case 409:
        return {
          userMessage:
            this.extractErrorMessage(error) || 'This operation conflicts with existing data.',
          technicalMessage: 'Conflict error',
          statusCode: 409,
          canRetry: false,
        };

      case 422:
        return {
          userMessage:
            this.extractErrorMessage(error) || 'Validation failed. Please check your input.',
          technicalMessage: 'Validation error',
          statusCode: 422,
          canRetry: false,
        };

      case 429:
        return {
          userMessage: 'Too many requests. Please wait a moment and try again.',
          technicalMessage: 'Rate limit exceeded',
          statusCode: 429,
          canRetry: true,
        };

      case 500:
        return {
          userMessage: 'An internal server error occurred. Our team has been notified.',
          technicalMessage: error.message,
          statusCode: 500,
          canRetry: true,
        };

      case 503:
        return {
          userMessage: 'The service is temporarily unavailable. Please try again later.',
          technicalMessage: 'Service unavailable',
          statusCode: 503,
          canRetry: true,
        };

      default:
        return {
          userMessage: 'An unexpected error occurred. Please try again.',
          technicalMessage: error.message,
          statusCode,
          canRetry: true,
        };
    }
  }

  /**
   * Handle client-side errors
   */
  private handleClientError(error: Error, context?: ErrorContext): ErrorResponse {
    // Check for specific error types
    if (error.name === 'ChunkLoadError' || error.message.includes('Loading chunk')) {
      return {
        userMessage: 'A new version is available. Please refresh the page.',
        technicalMessage: 'Chunk load error - likely new deployment',
        canRetry: false,
      };
    }

    if (error.message?.includes('timeout')) {
      return {
        userMessage: 'The request took too long. Please try again.',
        technicalMessage: 'Request timeout',
        canRetry: true,
      };
    }

    return {
      userMessage: 'An unexpected error occurred. Please try again.',
      technicalMessage: error.message || 'Unknown client error',
      canRetry: true,
    };
  }

  /**
   * Extract error message from HTTP response
   */
  private extractErrorMessage(error: HttpErrorResponse): string | null {
    if (error.error) {
      // Try common API response formats
      if (typeof error.error === 'string') {
        return error.error;
      }
      if (error.error.message) {
        return error.error.message;
      }
      if (error.error.error) {
        return error.error.error;
      }
      if (error.error.errors && Array.isArray(error.error.errors)) {
        return error.error.errors.join(', ');
      }
    }
    return null;
  }

  /**
   * Show error to user via toastr
   */
  private showErrorToUser(errorResponse: ErrorResponse): void {
    const options = {
      timeOut: errorResponse.canRetry ? 5000 : 7000,
      closeButton: true,
      progressBar: true,
    };

    this.toastr.error(errorResponse.userMessage, 'Error', options);
  }

  /**
   * Report error to Sentry
   */
  private reportToSentry(error: Error | HttpErrorResponse, context?: ErrorContext): void {
    Sentry.captureException(error, {
      contexts: {
        errorContext: context || {},
      },
      tags: {
        errorType: error instanceof HttpErrorResponse ? 'http' : 'client',
        statusCode: error instanceof HttpErrorResponse ? error.status.toString() : 'n/a',
      },
    });
  }

  /**
   * Handle authentication errors
   */
  private handleAuthError(): void {
    localStorage.clear();
    sessionStorage.clear();
    this.router.navigate(['/login'], {
      queryParams: { sessionExpired: 'true' },
    });
  }

  /**
   * Create retry-able error handler
   * Returns a function that can be used in RxJS catchError
   */
  createRetryHandler<T>(
    defaultValue: T,
    maxRetries: number = 3,
    context?: ErrorContext,
  ): (error: any) => T {
    let retryCount = 0;

    return (error: any): T => {
      retryCount++;

      const errorResponse = this.processError(error, context);

      if (errorResponse.canRetry && retryCount < maxRetries) {
        this.logger.warn(`Retrying operation (${retryCount}/${maxRetries})`, { error, context });
        throw error; // Re-throw to trigger retry
      }

      this.handleError(error, context);
      return defaultValue;
    };
  }
}
