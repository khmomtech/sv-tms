import {
  Component,
  Input,
  Output,
  EventEmitter,
  ChangeDetectionStrategy,
  OnDestroy,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormControl } from '@angular/forms';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, takeUntil } from 'rxjs/operators';

export interface FilterChip {
  key: string;
  label: string;
  value: any;
  removable?: boolean;
}

/**
 * FilterBarComponent - Search and filter controls with debounced input
 *
 * Features:
 * - Debounced search input (300ms default)
 * - Filter chips display
 * - Clear all filters
 * - Customizable search placeholder
 * - Accessible (ARIA labels)
 * - Tailwind CSS styled
 *
 * @example
 * <app-filter-bar
 *   [searchPlaceholder]="'Search drivers...'"
 *   [filterChips]="activeFilters"
 *   [debounceTime]="300"
 *   (searchChange)="onSearch($event)"
 *   (filterRemove)="onFilterRemove($event)"
 *   (clearAll)="onClearFilters()">
 * </app-filter-bar>
 */
@Component({
  selector: 'app-filter-bar',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './filter-bar.component.html',
  styleUrls: ['./filter-bar.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FilterBarComponent implements OnDestroy {
  /** Search input placeholder */
  @Input() searchPlaceholder = 'Search...';

  /** Active filter chips */
  @Input() filterChips: FilterChip[] = [];

  /** Search debounce time in milliseconds */
  @Input() debounceTime = 300;

  /** Initial search value */
  @Input() set searchValue(value: string) {
    this.searchControl.setValue(value, { emitEvent: false });
  }

  /** Show clear button */
  @Input() showClear = true;

  /** Emitted when search value changes (debounced) */
  @Output() searchChange = new EventEmitter<string>();

  /** Emitted when filter chip is removed */
  @Output() filterRemove = new EventEmitter<FilterChip>();

  /** Emitted when clear all is clicked */
  @Output() clearAll = new EventEmitter<void>();

  /** Search form control */
  searchControl = new FormControl('');

  /** Destroy subject for cleanup */
  private destroy$ = new Subject<void>();

  constructor() {
    // Set up debounced search
    this.searchControl.valueChanges
      .pipe(debounceTime(this.debounceTime), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe((value) => {
        this.searchChange.emit(value || '');
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Handle chip removal
   */
  onRemoveChip(chip: FilterChip): void {
    if (chip.removable !== false) {
      this.filterRemove.emit(chip);
    }
  }

  /**
   * Handle clear all filters
   */
  onClearAll(): void {
    this.searchControl.setValue('', { emitEvent: true });
    this.clearAll.emit();
  }

  /**
   * Clear search input
   */
  clearSearch(): void {
    this.searchControl.setValue('', { emitEvent: true });
  }

  /**
   * Check if there are active filters
   */
  get hasFilters(): boolean {
    return this.filterChips.length > 0 || !!this.searchControl.value;
  }
}
