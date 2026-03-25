import {
  Component,
  Input,
  Output,
  EventEmitter,
  ChangeDetectionStrategy,
  TemplateRef,
} from '@angular/core';
import {
  BASE_IMPORTS,
  TABLE_IMPORTS,
  BUTTON_IMPORTS,
  LOADING_IMPORTS,
} from '../../../common-imports';

export type ColumnType = 'text' | 'number' | 'date' | 'boolean' | 'custom' | 'actions';

export interface TableColumn<T = any> {
  key: string;
  label: string;
  type?: ColumnType;
  sortable?: boolean;
  width?: string;
  align?: 'left' | 'center' | 'right';
  template?: TemplateRef<any>;
  formatter?: (value: any, row: T) => string;
}

export interface TableConfig<T = any> {
  columns: TableColumn<T>[];
  data: T[];
  loading?: boolean;
  selectable?: boolean;
  stickyHeader?: boolean;
  rowClickable?: boolean;
  trackByKey?: keyof T;
}

export interface SortEvent {
  column: string;
  direction: 'asc' | 'desc' | '';
}

export interface SelectionEvent<T = any> {
  selected: T[];
  isAllSelected: boolean;
}

/**
 * DataTableComponent - Advanced data table with sorting, selection, and custom templates
 *
 * Features:
 * - Generic typing for type-safe data
 * - Column sorting (single column)
 * - Row selection (single/multiple)
 * - Custom cell templates
 * - Sticky headers
 * - Loading/empty states
 * - Accessible (ARIA labels, keyboard navigation)
 * - TrackBy for performance
 *
 * @example
 * <app-data-table
 *   [config]="{
 *     columns: [
 *       { key: 'name', label: 'Name', sortable: true },
 *       { key: 'email', label: 'Email', type: 'text' },
 *       { key: 'status', label: 'Status', template: statusTemplate }
 *     ],
 *     data: drivers,
 *     loading: false,
 *     selectable: true
 *   }"
 *   (sort)="onSort($event)"
 *   (selectionChange)="onSelectionChange($event)"
 *   (rowClick)="onRowClick($event)">
 * </app-data-table>
 */
@Component({
  selector: 'app-data-table',
  standalone: true,
  imports: [...BASE_IMPORTS, ...TABLE_IMPORTS, ...BUTTON_IMPORTS, ...LOADING_IMPORTS],
  templateUrl: './data-table.component.html',
  styleUrls: ['./data-table.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DataTableComponent<T = any> {
  /** Table configuration */
  @Input() config: TableConfig<T> = {
    columns: [],
    data: [],
    loading: false,
    selectable: false,
    stickyHeader: true,
    rowClickable: false,
  };

  /** Current sort state */
  @Input() currentSort: SortEvent = { column: '', direction: '' };

  /** Currently selected rows */
  @Input() selection: T[] = [];

  /** Emitted when sort changes */
  @Output() sort = new EventEmitter<SortEvent>();

  /** Emitted when selection changes */
  @Output() selectionChange = new EventEmitter<SelectionEvent<T>>();

  /** Emitted when row is clicked */
  @Output() rowClick = new EventEmitter<T>();

  /**
   * Track by function for performance
   */
  trackByIndex(index: number): number {
    return index;
  }

  /**
   * Track by function using configured key
   */
  trackByKey = (index: number, item: T): any => {
    if (this.config.trackByKey) {
      return item[this.config.trackByKey];
    }
    return index;
  };

  /**
   * Handle column sort
   */
  onSort(column: TableColumn<T>): void {
    if (!column.sortable) return;

    let direction: 'asc' | 'desc' | '' = 'asc';

    if (this.currentSort.column === column.key) {
      if (this.currentSort.direction === 'asc') {
        direction = 'desc';
      } else if (this.currentSort.direction === 'desc') {
        direction = '';
      }
    }

    this.currentSort = { column: column.key, direction };
    this.sort.emit(this.currentSort);
  }

  /**
   * Check if all rows are selected
   */
  get isAllSelected(): boolean {
    return this.config.data.length > 0 && this.selection.length === this.config.data.length;
  }

  /**
   * Check if some (but not all) rows are selected
   */
  get isIndeterminate(): boolean {
    return this.selection.length > 0 && !this.isAllSelected;
  }

  /**
   * Toggle all rows selection
   */
  toggleAllRows(): void {
    if (this.isAllSelected) {
      this.selection = [];
    } else {
      this.selection = [...this.config.data];
    }

    this.selectionChange.emit({
      selected: this.selection,
      isAllSelected: this.isAllSelected,
    });
  }

  /**
   * Toggle single row selection
   */
  toggleRow(row: T): void {
    const index = this.selection.indexOf(row);

    if (index >= 0) {
      this.selection = this.selection.filter((item) => item !== row);
    } else {
      this.selection = [...this.selection, row];
    }

    this.selectionChange.emit({
      selected: this.selection,
      isAllSelected: this.isAllSelected,
    });
  }

  /**
   * Check if row is selected
   */
  isRowSelected(row: T): boolean {
    return this.selection.includes(row);
  }

  /**
   * Handle row click
   */
  onRowClick(row: T): void {
    if (this.config.rowClickable) {
      this.rowClick.emit(row);
    }
  }

  /**
   * Get cell value with optional formatter
   */
  getCellValue(column: TableColumn<T>, row: T): string {
    const value = (row as any)[column.key];

    if (column.formatter) {
      return column.formatter(value, row);
    }

    // Default formatting by type
    switch (column.type) {
      case 'date':
        return value instanceof Date ? value.toLocaleDateString() : value;
      case 'number':
        return typeof value === 'number' ? value.toLocaleString() : value;
      case 'boolean':
        return value ? 'Yes' : 'No';
      default:
        return value?.toString() || '';
    }
  }

  /**
   * Get sort icon for column
   */
  getSortIcon(column: TableColumn<T>): string {
    if (!column.sortable || this.currentSort.column !== column.key) {
      return 'unfold_more';
    }

    return this.currentSort.direction === 'asc' ? 'arrow_upward' : 'arrow_downward';
  }

  /**
   * Get column alignment class
   */
  getAlignClass(column: TableColumn<T>): string {
    const alignMap = {
      left: 'text-left',
      center: 'text-center',
      right: 'text-right',
    };

    return alignMap[column.align || 'left'];
  }
}
