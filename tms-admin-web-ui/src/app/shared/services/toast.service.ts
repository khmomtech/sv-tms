import { Injectable } from '@angular/core';
import { MatSnackBar, MatSnackBarConfig } from '@angular/material/snack-bar';

/**
 * Toast Notification Service
 *
 * Wrapper around MatSnackBar with preset configurations for common notification types.
 * Provides consistent styling and behavior for success, error, warning, and info messages.
 *
 * @example
 * // Inject in component
 * constructor(private toast: ToastService) {}
 *
 * // Show success message
 * this.toast.success('Driver created successfully');
 *
 * // Show error with action
 * this.toast.error('Failed to save', 'Retry').onAction().subscribe(() => {
 *   this.retryOperation();
 * });
 *
 * // Custom duration
 * this.toast.info('Processing...', { duration: 5000 });
 */
@Injectable({
  providedIn: 'root',
})
export class ToastService {
  private readonly defaultDuration = 3000;
  private readonly defaultHorizontalPosition: 'start' | 'center' | 'end' | 'left' | 'right' = 'end';
  private readonly defaultVerticalPosition: 'top' | 'bottom' = 'bottom';

  constructor(private snackBar: MatSnackBar) {}

  /**
   * Show success message (green)
   */
  success(message: string, action?: string, config?: Partial<MatSnackBarConfig>) {
    return this.show(message, action, {
      ...config,
      panelClass: ['toast-success'],
      duration: config?.duration ?? this.defaultDuration,
    });
  }

  /**
   * Show error message (red)
   */
  error(message: string, action?: string, config?: Partial<MatSnackBarConfig>) {
    return this.show(message, action, {
      ...config,
      panelClass: ['toast-error'],
      duration: config?.duration ?? 5000, // Longer duration for errors
    });
  }

  /**
   * Show warning message (orange)
   */
  warning(message: string, action?: string, config?: Partial<MatSnackBarConfig>) {
    return this.show(message, action, {
      ...config,
      panelClass: ['toast-warning'],
      duration: config?.duration ?? 4000,
    });
  }

  /**
   * Show info message (blue)
   */
  info(message: string, action?: string, config?: Partial<MatSnackBarConfig>) {
    return this.show(message, action, {
      ...config,
      panelClass: ['toast-info'],
      duration: config?.duration ?? this.defaultDuration,
    });
  }

  /**
   * Show loading message (no auto-dismiss)
   */
  loading(message: string = 'Loading...') {
    return this.show(message, undefined, {
      panelClass: ['toast-loading'],
      duration: 0, // Don't auto-dismiss
    });
  }

  /**
   * Dismiss all active toasts
   */
  dismiss(): void {
    this.snackBar.dismiss();
  }

  /**
   * Generic show method with full configuration
   */
  private show(message: string, action?: string, config?: Partial<MatSnackBarConfig>) {
    const defaultConfig: MatSnackBarConfig = {
      duration: this.defaultDuration,
      horizontalPosition: this.defaultHorizontalPosition,
      verticalPosition: this.defaultVerticalPosition,
      ...config,
    };

    return this.snackBar.open(message, action, defaultConfig);
  }
}
