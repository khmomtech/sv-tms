import { Component, Inject, ChangeDetectionStrategy } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { BASE_IMPORTS, BUTTON_IMPORTS, DIALOG_IMPORTS } from '../../common-imports';

/**
 * Confirmation Dialog Configuration
 */
export interface ConfirmationDialogData {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  variant?: 'default' | 'danger' | 'warning';
  showIcon?: boolean;
}

/**
 * Confirmation Dialog Component
 *
 * Reusable confirmation dialog for delete/critical actions.
 * Supports danger and warning variants with custom styling.
 *
 * @example
 * // Inject MatDialog in component
 * constructor(private dialog: MatDialog) {}
 *
 * // Open confirmation dialog
 * const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
 *   data: {
 *     title: 'Delete Driver',
 *     message: 'Are you sure you want to delete this driver? This action cannot be undone.',
 *     confirmText: 'Delete',
 *     cancelText: 'Cancel',
 *     variant: 'danger'
 *   }
 * });
 *
 * // Handle confirmation
 * dialogRef.afterClosed().subscribe(confirmed => {
 *   if (confirmed) {
 *     this.deleteDriver(id);
 *   }
 * });
 */
@Component({
  selector: 'app-confirmation-dialog',
  standalone: true,
  imports: [...BASE_IMPORTS, ...BUTTON_IMPORTS, ...DIALOG_IMPORTS],
  templateUrl: './confirmation-dialog.component.html',
  styleUrl: './confirmation-dialog.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConfirmationDialogComponent {
  constructor(
    public dialogRef: MatDialogRef<ConfirmationDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: ConfirmationDialogData,
  ) {
    // Set defaults
    this.data.confirmText = this.data.confirmText || 'Confirm';
    this.data.cancelText = this.data.cancelText || 'Cancel';
    this.data.variant = this.data.variant || 'default';
    this.data.showIcon = this.data.showIcon !== false; // Default true
  }

  /**
   * Get icon based on variant
   */
  get icon(): string {
    switch (this.data.variant) {
      case 'danger':
        return 'error_outline';
      case 'warning':
        return 'warning';
      default:
        return 'help_outline';
    }
  }

  /**
   * Get icon color based on variant
   */
  get iconColor(): string {
    switch (this.data.variant) {
      case 'danger':
        return 'text-red-600';
      case 'warning':
        return 'text-orange-600';
      default:
        return 'text-blue-600';
    }
  }

  /**
   * Get confirm button color based on variant
   */
  get confirmColor(): 'primary' | 'warn' {
    return this.data.variant === 'danger' ? 'warn' : 'primary';
  }

  /**
   * Handle cancel action
   */
  onCancel(): void {
    this.dialogRef.close(false);
  }

  /**
   * Handle confirm action
   */
  onConfirm(): void {
    this.dialogRef.close(true);
  }
}
