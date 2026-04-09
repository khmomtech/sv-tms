/**
 * Date Utility Functions
 *
 * Helper functions for date formatting, comparison, and manipulation.
 * Used across CRUD components and data tables.
 *
 * @example
 * import { DateUtils } from '@shared/utils/date.utils';
 *
 * const formatted = DateUtils.format(new Date(), 'YYYY-MM-DD');
 * const isInRange = DateUtils.isInRange(date, startDate, endDate);
 */
export class DateUtils {
  /**
   * Format date to common patterns
   * @param date Date to format
   * @param format Format pattern: 'short', 'medium', 'long', 'time', 'datetime', 'iso', or custom
   */
  static format(
    date: Date | string | null | undefined,
    format: 'short' | 'medium' | 'long' | 'time' | 'datetime' | 'iso' | string = 'medium',
  ): string {
    if (!date) return '';

    const d = typeof date === 'string' ? new Date(date) : date;
    if (isNaN(d.getTime())) return '';

    switch (format) {
      case 'short':
        return d.toLocaleDateString('en-US', { month: 'numeric', day: 'numeric', year: '2-digit' });
      case 'medium':
        return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
      case 'long':
        return d.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
      case 'time':
        return d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
      case 'datetime':
        return `${this.format(d, 'medium')} ${this.format(d, 'time')}`;
      case 'iso':
        return d.toISOString();
      default:
        // Custom format: YYYY-MM-DD, DD/MM/YYYY, etc.
        return this.customFormat(d, format);
    }
  }

  /**
   * Custom date formatting
   */
  private static customFormat(date: Date, pattern: string): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');

    return pattern
      .replace('YYYY', String(year))
      .replace('YY', String(year).slice(-2))
      .replace('MM', month)
      .replace('DD', day)
      .replace('HH', hours)
      .replace('mm', minutes)
      .replace('ss', seconds);
  }

  /**
   * Check if date is within range (inclusive)
   */
  static isInRange(date: Date | string, startDate: Date | string, endDate: Date | string): boolean {
    const d = typeof date === 'string' ? new Date(date) : date;
    const start = typeof startDate === 'string' ? new Date(startDate) : startDate;
    const end = typeof endDate === 'string' ? new Date(endDate) : endDate;

    return d >= start && d <= end;
  }

  /**
   * Add days to a date
   */
  static addDays(date: Date | string, days: number): Date {
    const d = typeof date === 'string' ? new Date(date) : new Date(date);
    d.setDate(d.getDate() + days);
    return d;
  }

  /**
   * Add months to a date
   */
  static addMonths(date: Date | string, months: number): Date {
    const d = typeof date === 'string' ? new Date(date) : new Date(date);
    d.setMonth(d.getMonth() + months);
    return d;
  }

  /**
   * Get difference between two dates in days
   */
  static getDaysDiff(date1: Date | string, date2: Date | string): number {
    const d1 = typeof date1 === 'string' ? new Date(date1) : date1;
    const d2 = typeof date2 === 'string' ? new Date(date2) : date2;

    const diffTime = Math.abs(d2.getTime() - d1.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  /**
   * Check if date is weekend
   */
  static isWeekend(date: Date | string): boolean {
    const d = typeof date === 'string' ? new Date(date) : date;
    const day = d.getDay();
    return day === 0 || day === 6;
  }

  /**
   * Check if date is today
   */
  static isToday(date: Date | string): boolean {
    const d = typeof date === 'string' ? new Date(date) : date;
    const today = new Date();
    return d.toDateString() === today.toDateString();
  }

  /**
   * Check if date is in the past
   */
  static isPast(date: Date | string): boolean {
    const d = typeof date === 'string' ? new Date(date) : date;
    return d < new Date();
  }

  /**
   * Check if date is in the future
   */
  static isFuture(date: Date | string): boolean {
    const d = typeof date === 'string' ? new Date(date) : date;
    return d > new Date();
  }

  /**
   * Get start of day (00:00:00)
   */
  static startOfDay(date: Date | string): Date {
    const d = typeof date === 'string' ? new Date(date) : new Date(date);
    d.setHours(0, 0, 0, 0);
    return d;
  }

  /**
   * Get end of day (23:59:59)
   */
  static endOfDay(date: Date | string): Date {
    const d = typeof date === 'string' ? new Date(date) : new Date(date);
    d.setHours(23, 59, 59, 999);
    return d;
  }

  /**
   * Get relative time string (e.g., "2 hours ago", "in 3 days")
   */
  static getRelativeTime(date: Date | string): string {
    const d = typeof date === 'string' ? new Date(date) : date;
    const now = new Date();
    const diffMs = now.getTime() - d.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);
    const diffWeek = Math.floor(diffDay / 7);
    const diffMonth = Math.floor(diffDay / 30);
    const diffYear = Math.floor(diffDay / 365);

    if (diffSec < 60) return 'just now';
    if (diffMin === 1) return '1 minute ago';
    if (diffMin < 60) return `${diffMin} minutes ago`;
    if (diffHour === 1) return '1 hour ago';
    if (diffHour < 24) return `${diffHour} hours ago`;
    if (diffDay === 1) return 'yesterday';
    if (diffDay < 7) return `${diffDay} days ago`;
    if (diffWeek === 1) return '1 week ago';
    if (diffWeek < 4) return `${diffWeek} weeks ago`;
    if (diffMonth === 1) return '1 month ago';
    if (diffMonth < 12) return `${diffMonth} months ago`;
    if (diffYear === 1) return '1 year ago';
    return `${diffYear} years ago`;
  }

  /**
   * Parse string to date (supports common formats)
   */
  static parse(dateString: string): Date | null {
    if (!dateString) return null;

    const date = new Date(dateString);
    return isNaN(date.getTime()) ? null : date;
  }

  /**
   * Get age from date of birth
   */
  static getAge(birthDate: Date | string): number {
    const d = typeof birthDate === 'string' ? new Date(birthDate) : birthDate;
    const today = new Date();
    let age = today.getFullYear() - d.getFullYear();
    const monthDiff = today.getMonth() - d.getMonth();

    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < d.getDate())) {
      age--;
    }

    return age;
  }

  /**
   * Get array of dates between two dates
   */
  static getDateRange(startDate: Date | string, endDate: Date | string): Date[] {
    const start = typeof startDate === 'string' ? new Date(startDate) : new Date(startDate);
    const end = typeof endDate === 'string' ? new Date(endDate) : new Date(endDate);
    const dates: Date[] = [];

    const current = new Date(start);
    while (current <= end) {
      dates.push(new Date(current));
      current.setDate(current.getDate() + 1);
    }

    return dates;
  }

  /**
   * Get month name
   */
  static getMonthName(monthIndex: number, short = false): string {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const monthName = months[monthIndex];
    return short ? monthName.substring(0, 3) : monthName;
  }

  /**
   * Get day name
   */
  static getDayName(date: Date | string, short = false): string {
    const d = typeof date === 'string' ? new Date(date) : date;
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    const dayName = days[d.getDay()];
    return short ? dayName.substring(0, 3) : dayName;
  }
}
