import { Component, Input, Output, EventEmitter, ChangeDetectionStrategy } from '@angular/core';
import {
  BASE_IMPORTS,
  BUTTON_IMPORTS,
  LAYOUT_IMPORTS,
  LOADING_IMPORTS,
} from '../../../common-imports';

export type TrendDirection = 'up' | 'down' | 'neutral';
export type StatColor = 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'purple' | 'gray';

export interface TrendData {
  value: number;
  direction: TrendDirection;
  label?: string;
}

export interface StatCardConfig {
  label: string;
  value: number | string;
  icon?: string;
  trend?: TrendData;
  color?: StatColor;
  loading?: boolean;
  clickable?: boolean;
  unit?: string;
}

/**
 * StatCardComponent - Display KPI metrics with optional trend indicators
 *
 * Features:
 * - 7 color variants (primary, success, warning, danger, info, purple, gray)
 * - Trend indicators (up/down/neutral with percentage)
 * - Loading state overlay
 * - Clickable cards with hover effects
 * - Accessible (ARIA labels, keyboard support)
 *
 * @example
 * <app-stat-card
 *   [config]="{
 *     label: 'Total Drivers',
 *     value: 150,
 *     icon: 'local_shipping',
 *     color: 'primary',
 *     trend: { value: 12.5, direction: 'up', label: 'vs last month' },
 *     clickable: true
 *   }"
 *   (cardClick)="viewDrivers()">
 * </app-stat-card>
 */
@Component({
  selector: 'app-stat-card',
  standalone: true,
  imports: [...BASE_IMPORTS, ...BUTTON_IMPORTS, ...LAYOUT_IMPORTS, ...LOADING_IMPORTS],
  templateUrl: './stat-card.component.html',
  styleUrls: ['./stat-card.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class StatCardComponent {
  /** Card configuration */
  @Input() config: StatCardConfig = {
    label: '',
    value: 0,
    color: 'primary',
    loading: false,
    clickable: false,
  };

  /** Emitted when clickable card is clicked */
  @Output() cardClick = new EventEmitter<void>();

  /**
   * Handle card click
   */
  onClick(): void {
    if (this.config.clickable && !this.config.loading) {
      this.cardClick.emit();
    }
  }

  /**
   * Get card container CSS classes
   */
  get cardClasses(): string {
    const baseClasses = 'stat-card relative overflow-hidden rounded-lg border p-6 transition-all';
    const colorClasses = this.getColorClasses();
    const clickableClasses = this.config.clickable
      ? 'cursor-pointer hover:shadow-lg hover:-translate-y-1'
      : '';
    const loadingClasses = this.config.loading ? 'opacity-75' : '';

    return `${baseClasses} ${colorClasses} ${clickableClasses} ${loadingClasses}`;
  }

  /**
   * Get color-specific CSS classes
   */
  private getColorClasses(): string {
    const colorMap: Record<StatColor, string> = {
      primary: 'bg-blue-50 border-blue-200',
      success: 'bg-green-50 border-green-200',
      warning: 'bg-yellow-50 border-yellow-200',
      danger: 'bg-red-50 border-red-200',
      info: 'bg-cyan-50 border-cyan-200',
      purple: 'bg-purple-50 border-purple-200',
      gray: 'bg-gray-50 border-gray-200',
    };

    return colorMap[this.config.color || 'primary'];
  }

  /**
   * Get icon color CSS class
   */
  get iconColorClass(): string {
    const colorMap: Record<StatColor, string> = {
      primary: 'text-blue-600',
      success: 'text-green-600',
      warning: 'text-yellow-600',
      danger: 'text-red-600',
      info: 'text-cyan-600',
      purple: 'text-purple-600',
      gray: 'text-gray-600',
    };

    return colorMap[this.config.color || 'primary'];
  }

  /**
   * Get trend icon based on direction
   */
  get trendIcon(): string {
    if (!this.config.trend) return '';

    const iconMap: Record<TrendDirection, string> = {
      up: 'trending_up',
      down: 'trending_down',
      neutral: 'trending_flat',
    };

    return iconMap[this.config.trend.direction];
  }

  /**
   * Get trend color CSS class
   */
  get trendColorClass(): string {
    if (!this.config.trend) return '';

    const colorMap: Record<TrendDirection, string> = {
      up: 'text-green-600',
      down: 'text-red-600',
      neutral: 'text-gray-600',
    };

    return colorMap[this.config.trend.direction];
  }

  /**
   * Get ARIA label for accessibility
   */
  get ariaLabel(): string {
    const trend = this.config.trend
      ? ` ${this.config.trend.direction} ${this.config.trend.value}%`
      : '';
    return `${this.config.label}: ${this.config.value}${trend}`;
  }

  /**
   * Format value for display
   */
  get formattedValue(): string {
    if (typeof this.config.value === 'string') {
      return this.config.value;
    }

    // Format numbers with commas
    return this.config.value.toLocaleString();
  }
}
