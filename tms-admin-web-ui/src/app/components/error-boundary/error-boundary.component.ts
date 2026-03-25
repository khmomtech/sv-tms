import {
  Component,
  Input,
  OnDestroy,
  OnInit,
  HostListener,
  EventEmitter,
  Output,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject } from 'rxjs';

@Component({
  selector: 'app-error-boundary',
  standalone: true,
  imports: [CommonModule],
  template: `
    <ng-container *ngIf="!hasError">
      <ng-content></ng-content>
    </ng-container>
    <div
      *ngIf="hasError"
      class="error-boundary"
      style="border:1px solid #f44336;padding:1.5rem;margin:1rem 0;background:#fff3f3;color:#b71c1c;"
    >
      <h2>{{ errorTitle || 'Something went wrong' }}</h2>
      <p>{{ errorMessage }}</p>
      <div><strong>Error ID:</strong> {{ errorId }}</div>
      <div><strong>Component:</strong> {{ componentName }}</div>
      <div><strong>Occurred at:</strong> {{ errorTime || getFormattedTimestamp() }}</div>
      <button data-test="retry-button" (click)="retry()">Retry</button>
      <button data-test="reload-button" (click)="reload()">Reload</button>
      <button data-test="toggle-details" (click)="toggleTechnicalDetails()">
        {{ showTechnicalDetails ? 'Hide' : 'Show' }} Technical Details
      </button>
      <div
        *ngIf="showTechnicalDetails"
        class="technical-details"
        style="margin-top:1rem;white-space:pre-wrap;background:#f5f5f5;padding:1rem;"
      >
        <div><strong>Stack Trace:</strong></div>
        <div>{{ errorDetails }}</div>
      </div>
    </div>
  `,
  styles: [
    `
      .error-boundary h2 {
        color: #b71c1c;
      }
      .error-boundary button {
        margin-right: 0.5rem;
      }
      .technical-details {
        font-size: 0.95em;
      }
    `,
  ],
})
export class ErrorBoundaryComponent implements OnInit, OnDestroy {
  /**
   * Properties required by the spec
   */
  error: Error | null = null;
  errorCount = 0;
  retryCount = 0;
  errorTimestamp: Date = new Date();
  showTechnicalDetails = false;
  @Output() retryAttempt = new EventEmitter<void>();
  @Input() errorTitle = 'Something went wrong';
  @Input() errorMessage =
    'We encountered an unexpected error. Please try again or reload the page.';
  @Input() showDetails = true;
  @Input() componentName = 'Unknown Component';

  hasError = false;
  errorDetails = '';
  errorId = '';
  errorTime = '';
  private destroy$ = new Subject<void>();

  ngOnInit(): void {
    this.errorId = this.generateErrorId();
    this.errorTimestamp = new Date();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Global error handler for window errors
   */
  @HostListener('window:error', ['$event'])
  handleError(event: ErrorEvent | Error | any): void {
    if (event instanceof ErrorEvent) {
      this.captureError(event.error || new Error(event.message));
      event.preventDefault();
    } else {
      this.captureError(event);
    }
  }

  /**
   * Retry by clearing error state
   */
  retry(): void {
    this.hasError = false;
    this.error = null;
    this.errorDetails = '';
    this.errorId = this.generateErrorId();
    this.errorTimestamp = new Date();
    this.showTechnicalDetails = false;
    this.retryCount++;
    this.retryAttempt.emit();
    console.log('[Error Boundary] Retrying...');
  }

  /**
   * Toggle technical details display
   */
  toggleTechnicalDetails(): void {
    this.showTechnicalDetails = !this.showTechnicalDetails;
  }

  /**
   * Get formatted error timestamp
   */
  getFormattedTimestamp(): string {
    return this.errorTimestamp.toLocaleTimeString();
  }

  /**
   * Reload entire page
   */
  reload(): void {
    this.reloadPage();
  }

  protected reloadPage(): void {
    window.location.reload();
  }

  /**
   * Capture and process error
   */
  private captureError(error: any): void {
    this.hasError = true;
    this.error = error instanceof Error ? error : null;
    this.errorDetails = this.formatError(error);
    this.errorId = this.generateErrorId();
    this.errorTimestamp = new Date();
    this.errorTime = this.errorTimestamp.toLocaleString();
    this.errorCount++;
    // Log to console for debugging
    console.error('[Error Boundary] Caught error:', {
      errorId: this.errorId,
      component: this.componentName,
      error: error,
      timestamp: this.errorTime,
    });
    // In production, send to error tracking service
    // Example: Sentry.captureException(error, { tags: { errorId: this.errorId } });
  }

  /**
   * Format error for display
   */
  private formatError(error: any): string {
    if (error instanceof Error) {
      return `${error.name}: ${error.message}\n\nStack Trace:\n${error.stack || 'No stack trace available'}`;
    }

    if (typeof error === 'object') {
      try {
        return JSON.stringify(error, null, 2);
      } catch {
        return String(error);
      }
    }

    return String(error);
  }

  /**
   * Generate unique error ID for tracking
   */
  private generateErrorId(): string {
    return `ERR-${Date.now()}-${Math.random().toString(36).substring(2, 9).toUpperCase()}`;
  }
}
