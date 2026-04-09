import { Component, Input, Output, EventEmitter, ChangeDetectionStrategy } from '@angular/core';
import { BASE_IMPORTS, NAV_IMPORTS, BUTTON_IMPORTS } from '../../../common-imports';

export interface Breadcrumb {
  label: string;
  link?: string;
  icon?: string;
}

/**
 * PageContainerComponent - Standardized CRUD page layout wrapper
 *
 * Provides consistent structure across all list/detail pages with:
 * - Breadcrumb navigation
 * - Page header with optional back button
 * - Stats section (KPI cards)
 * - Filters section
 * - Main content area
 * - Footer
 *
 * @example
 * <app-page-container
 *   title="Drivers"
 *   subtitle="Manage your driver accounts"
 *   [breadcrumbs]="[{label: 'Dashboard', link: '/'}, {label: 'Drivers'}]"
 *   [showBackButton]="false"
 *   [showStats]="true">
 *   <div stats>
 *     <app-stat-card [config]="{label: 'Total', value: 150}"></app-stat-card>
 *   </div>
 *   <div filters>
 *     <app-filter-bar></app-filter-bar>
 *   </div>
 *   <div content>
 *     <app-data-table></app-data-table>
 *   </div>
 * </app-page-container>
 */
@Component({
  selector: 'app-page-container',
  standalone: true,
  imports: [...BASE_IMPORTS, ...NAV_IMPORTS, ...BUTTON_IMPORTS],
  templateUrl: './page-container.component.html',
  styleUrls: ['./page-container.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PageContainerComponent {
  /** Page title displayed in header */
  @Input() title = '';

  /** Optional subtitle/description */
  @Input() subtitle = '';

  /** Breadcrumb navigation items */
  @Input() breadcrumbs: Breadcrumb[] = [];

  /** Show back navigation button */
  @Input() showBackButton = false;

  /** Show stats section */
  @Input() showStats = true;

  /** Show filters section */
  @Input() showFilters = true;

  /** Show footer section */
  @Input() showFooter = false;

  /** Custom CSS class for container */
  @Input() containerClass = '';

  /** Custom CSS class for header */
  @Input() headerClass = 'bg-white border-b border-gray-200';

  /** Custom CSS class for content area */
  @Input() contentClass = 'bg-gray-50';

  /** Custom CSS class for footer */
  @Input() footerClass = 'bg-white border-t border-gray-200';

  /** Emitted when back button is clicked */
  @Output() backClick = new EventEmitter<void>();

  /**
   * Handle back button click
   */
  onBackClick(): void {
    this.backClick.emit();
  }

  /**
   * Get breadcrumb CSS classes
   */
  get breadcrumbClasses(): string {
    return 'flex items-center text-sm text-gray-500 mb-4';
  }

  /**
   * Get header CSS classes
   */
  get headerClasses(): string {
    return `px-6 py-4 ${this.headerClass}`;
  }

  /**
   * Get content CSS classes
   */
  get contentClasses(): string {
    return `p-6 ${this.contentClass}`;
  }

  /**
   * Get footer CSS classes
   */
  get footerClasses(): string {
    return `px-6 py-4 ${this.footerClass}`;
  }
}
