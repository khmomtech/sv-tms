/**
 * CRUD Component Library - Barrel Exports
 *
 * Import all CRUD components from a single location:
 * import { PageContainerComponent, StatCardComponent, DataTableComponent } from '@shared/components/crud';
 */

// Components
export * from './page-container/page-container.component';
export * from './stat-card/stat-card.component';
export * from './data-table/data-table.component';
export * from './filter-bar/filter-bar.component';

// Re-export for convenience
import { PageContainerComponent } from './page-container/page-container.component';
import { StatCardComponent } from './stat-card/stat-card.component';
import { DataTableComponent } from './data-table/data-table.component';
import { FilterBarComponent } from './filter-bar/filter-bar.component';

/**
 * Array of all CRUD components for easy importing in standalone components
 *
 * @example
 * @Component({
 *   standalone: true,
 *   imports: [...BASE_IMPORTS, ...CRUD_COMPONENTS]
 * })
 */
export const CRUD_COMPONENTS = [
  PageContainerComponent,
  StatCardComponent,
  DataTableComponent,
  FilterBarComponent,
] as const;
