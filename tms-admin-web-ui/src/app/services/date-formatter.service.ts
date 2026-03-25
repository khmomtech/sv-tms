import { Injectable } from '@angular/core';

/**
 * Service for consistent date formatting across the application
 * Handles both display format (dd-MMM-yyyy) and API format (ISO)
 */
@Injectable({
  providedIn: 'root',
})
export class DateFormatterService {
  /**
   * Format date for display in UI (dd-MMM-yyyy format)
   * @param date - Date string or Date object
   * @returns Formatted string like "09-Jan-2026" or "-" if null
   */
  formatForDisplay(date: string | Date | null | undefined): string {
    if (!date) return '-';

    const dateObj = typeof date === 'string' ? new Date(date) : date;
    if (isNaN(dateObj.getTime())) return '-';

    return dateObj.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
    });
  }

  /**
   * Format date for API calls (ISO format: YYYY-MM-DD)
   * @param date - Date string or Date object
   * @returns ISO formatted string or empty string if null
   */
  formatForApi(date: string | Date | null | undefined): string {
    if (!date) return '';

    const dateObj = typeof date === 'string' ? new Date(date) : date;
    if (isNaN(dateObj.getTime())) return '';

    return dateObj.toISOString().split('T')[0];
  }

  /**
   * Format date for HTML date input (YYYY-MM-DD)
   * @param date - Date string or Date object
   * @returns ISO formatted string or empty string if null
   */
  formatForDateInput(date: string | Date | null | undefined): string {
    return this.formatForApi(date);
  }

  /**
   * Parse date from HTML date input (YYYY-MM-DD) to Date object
   * @param dateString - Date string from input
   * @returns Date object or null
   */
  parseFromDateInput(dateString: string | null): Date | null {
    if (!dateString) return null;

    const date = new Date(dateString + 'T00:00:00Z');
    return isNaN(date.getTime()) ? null : date;
  }

  /**
   * Get date range for current month
   * @returns Object with startDate and endDate
   */
  getCurrentMonthRange(): { startDate: string; endDate: string } {
    const today = new Date();
    const startDate = new Date(today.getFullYear(), today.getMonth(), 1);
    const endDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);

    return {
      startDate: this.formatForApi(startDate),
      endDate: this.formatForApi(endDate),
    };
  }

  /**
   * Get date range for last 30 days
   * @returns Object with startDate and endDate
   */
  getLast30DaysRange(): { startDate: string; endDate: string } {
    const endDate = new Date();
    const startDate = new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000);

    return {
      startDate: this.formatForApi(startDate),
      endDate: this.formatForApi(endDate),
    };
  }

  /**
   * Check if date is today
   */
  isToday(date: string | Date | null): boolean {
    if (!date) return false;

    const dateObj = typeof date === 'string' ? new Date(date) : date;
    const today = new Date();

    return (
      dateObj.getDate() === today.getDate() &&
      dateObj.getMonth() === today.getMonth() &&
      dateObj.getFullYear() === today.getFullYear()
    );
  }

  /**
   * Check if date is in the past
   */
  isPast(date: string | Date | null): boolean {
    if (!date) return false;

    const dateObj = typeof date === 'string' ? new Date(date) : date;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return dateObj < today;
  }

  /**
   * Check if date is in the future
   */
  isFuture(date: string | Date | null): boolean {
    if (!date) return false;

    const dateObj = typeof date === 'string' ? new Date(date) : date;
    const today = new Date();
    today.setHours(23, 59, 59, 999);

    return dateObj > today;
  }
}
