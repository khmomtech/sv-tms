/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Injectable } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { type Observable, from, throwError } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';

import { environment } from '../environments/environment';
// Removed all OpenAPI generated imports (generated folder deleted)

import { AuthService } from './auth.service';

/**
 * Service for managing driver issues in the admin/dispatcher UI.
 * Wraps the generated API client with error handling and user feedback.
 */
@Injectable({
  providedIn: 'root',
})
export class DriverIssueService {
  // Removed OpenAPI API client

  constructor(
    private readonly authService: AuthService,
    private readonly snackBar: MatSnackBar,
  ) {}

  // ===== Helper Methods =====

  private showToast(message: string, action = 'Close', duration = 3000): void {
    this.snackBar.open(message, action, {
      duration,
      horizontalPosition: 'right',
      verticalPosition: 'top',
    });
  }

  private handleError(operation: string) {
    return (error: any): Observable<never> => {
      console.error(`❌ ${operation} failed:`, error);
      const message = error?.error?.message || error?.message || `${operation} failed`;
      this.showToast(message, 'Close', 4000);
      return throwError(() => error);
    };
  }

  // ===== Issue Management Operations =====

  /**
   * Get paginated list of issues for a specific driver with optional filters.
   * @param driverId - The driver ID
   * @param page - Page number (0-indexed)
   * @param size - Page size
   * @param status - Optional status filter (OPEN, IN_PROGRESS, RESOLVED, CLOSED)
   * @param type - Optional type/title filter
   * @param fromDate - Optional start date filter
   * @param toDate - Optional end date filter
   */
  getIssuesByDriver(
    driverId: number,
    page: number = 0,
    size: number = 10,
    status?: string,
    type?: string,
    fromDate?: Date,
    toDate?: Date,
  ): any {
    // TODO: Implement API call
    return null;
  }

  /**
   * Get issues for the current authenticated driver (used by driver app backend integration).
   * Admin UI typically uses getIssuesByDriver with explicit driverId.
   */
  getCurrentDriverIssues(
    page: number = 0,
    size: number = 10,
    status?: string,
    type?: string,
    fromDate?: Date,
    toDate?: Date,
  ): any {
    // TODO: Implement API call
    return null;
  }

  /**
   * Get detailed information about a specific issue.
   */
  getIssueById(id: number): any {
    // TODO: Implement API call
    return null;
  }

  /**
   * Admin/Dispatcher: Create a new issue on behalf of a driver.
   * Note: Drivers use the mobile app to submit issues. This is for admin manual entry.
   */
  submitIssue(payload: any, images?: Array<Blob>): any {
    // TODO: Implement API call
    return null;
  }

  /**
   * Update issue title and description.
   */
  updateIssue(id: number, update: any): any {
    // TODO: Implement API call
    return null;
  }

  /**
   * Update issue status with workflow validation.
   * Valid transitions: OPEN → IN_PROGRESS → RESOLVED → CLOSED
   */
  updateStatus(id: number, status: string): any {
    // TODO: Implement API call
    return null;
  }

  /**
   * Delete an issue (admin only, typically used for test data cleanup).
   */
  deleteIssue(id: number): any {
    // TODO: Implement API call
    return null;
  }

  // ===== Status Workflow Helpers =====

  /**
   * Validate if a status transition is allowed.
   * Workflow: OPEN → IN_PROGRESS → RESOLVED → CLOSED
   */
  isValidStatusTransition(currentStatus: string, newStatus: string): boolean {
    const workflow: Record<string, string[]> = {
      OPEN: ['IN_PROGRESS', 'RESOLVED', 'CLOSED'],
      IN_PROGRESS: ['RESOLVED', 'CLOSED', 'OPEN'], // Allow back to OPEN for reopening
      RESOLVED: ['CLOSED', 'OPEN'], // Allow reopening if needed
      CLOSED: ['OPEN'], // Allow reopening closed issues
    };

    return workflow[currentStatus]?.includes(newStatus) || false;
  }

  /**
   * Get available status transitions for current status.
   */
  getAvailableStatuses(currentStatus: string): string[] {
    const workflow: Record<string, string[]> = {
      OPEN: ['IN_PROGRESS', 'RESOLVED', 'CLOSED'],
      IN_PROGRESS: ['RESOLVED', 'CLOSED'],
      RESOLVED: ['CLOSED', 'OPEN'],
      CLOSED: ['OPEN'],
    };

    return workflow[currentStatus] || [];
  }

  /**
   * Get status badge color for UI display.
   */
  getStatusColor(status: string): string {
    const colors: Record<string, string> = {
      OPEN: 'bg-red-100 text-red-800',
      IN_PROGRESS: 'bg-yellow-100 text-yellow-800',
      RESOLVED: 'bg-green-100 text-green-800',
      CLOSED: 'bg-gray-100 text-gray-800',
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  }

  /**
   * Get severity badge color for UI display.
   */
  getSeverityColor(severity: string): string {
    const colors: Record<string, string> = {
      LOW: 'bg-blue-100 text-blue-800',
      MEDIUM: 'bg-yellow-100 text-yellow-800',
      HIGH: 'bg-orange-100 text-orange-800',
      CRITICAL: 'bg-red-100 text-red-800',
    };
    return colors[severity] || 'bg-gray-100 text-gray-800';
  }

  /**
   * Format issue type for display (convert title to readable format).
   */
  formatIssueType(title: string): string {
    // Common issue types from mobile app
    const typeMap: Record<string, string> = {
      'Mechanical Issue': '🔧 Mechanical',
      Accident: '🚨 Accident',
      'Flat Tire': '🛞 Flat Tire',
      'Engine Problem': '⚙️ Engine',
      'Brake Issue': '🛑 Brakes',
      'Electrical Problem': '⚡ Electrical',
      'Fuel Issue': '⛽ Fuel',
      'Customer Complaint': '😤 Complaint',
      'Traffic Delay': '🚦 Traffic',
      Other: '📝 Other',
    };
    return typeMap[title] || title;
  }
}
