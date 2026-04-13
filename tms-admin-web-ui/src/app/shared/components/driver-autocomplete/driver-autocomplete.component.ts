import { CommonModule } from '@angular/common';
import type { OnInit, OnChanges, OnDestroy, SimpleChanges, ElementRef } from '@angular/core';
import {
  Component,
  Input,
  Output,
  EventEmitter,
  ViewChild,
  HostListener,
  forwardRef,
  Inject,
  Optional,
} from '@angular/core';
import type { ControlValueAccessor } from '@angular/forms';
import { FormsModule, NG_VALUE_ACCESSOR } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged, takeUntil, switchMap, of } from 'rxjs';

export interface Driver {
  id: number;
  name?: string;
  firstName?: string;
  lastName?: string;
  phone?: string;
  assignedVehiclePlate?: string;
  currentVehiclePlate?: string;
  assignedVehicle?: {
    licensePlate?: string;
  } | null;
  status?: 'ONLINE' | 'BUSY' | 'OFFLINE' | string;
}

export interface DriverSearchService {
  searchDrivers(query: string): any;
}

@Component({
  selector: 'app-driver-autocomplete',
  standalone: true,
  templateUrl: './driver-autocomplete.component.html',
  imports: [CommonModule, FormsModule],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => DriverAutocompleteComponent),
      multi: true,
    },
  ],
})
export class DriverAutocompleteComponent
  implements OnInit, OnChanges, OnDestroy, ControlValueAccessor
{
  @Input() drivers: Driver[] = [];
  @Input() placeholder: string = 'Search driver by name or phone...';
  @Input() label: string = 'Select Driver';
  @Input() showLabel: boolean = true;
  @Input() required: boolean = false;
  @Input() disabled: boolean = false;
  @Input() showStatus: boolean = true;
  @Input() maxHeight: string = '15rem'; // 240px
  @Input() errorMessage: string = '';
  @Input() enableLiveSearch: boolean = false; // Enable API search
  @Input() minSearchLength: number = 2; // Minimum chars before search
  @Input() searchDebounceTime: number = 300; // Debounce in ms

  @Output() driverSelected = new EventEmitter<Driver>();
  @Output() driverCleared = new EventEmitter<void>();
  @Output() searchQuery = new EventEmitter<string>(); // Emit search query for API call

  @ViewChild('searchInput') searchInput!: ElementRef<HTMLInputElement>;

  // Component state
  filteredDrivers: Driver[] = [];
  searchText: string = '';
  showDropdown: boolean = false;
  selectedDriver: Driver | null = null;
  selectedDriverId: number | null = null;
  isTouched: boolean = false;
  isSearching: boolean = false; // Loading state for API search

  // RxJS subjects
  private searchSubject$ = new Subject<string>();
  private destroy$ = new Subject<void>();

  // ControlValueAccessor implementation
  private onChange: (value: number | null) => void = () => {};
  private onTouched: () => void = () => {};

  constructor() {}

  ngOnInit(): void {
    this.filteredDrivers = [...this.drivers];
    console.log('🚗 DriverAutocomplete initialized with', this.drivers.length, 'drivers');
    console.log('🔍 Live search enabled:', this.enableLiveSearch);

    // Setup live search with debounce
    if (this.enableLiveSearch) {
      this.searchSubject$
        .pipe(
          debounceTime(this.searchDebounceTime),
          distinctUntilChanged(),
          takeUntil(this.destroy$),
        )
        .subscribe((searchTerm) => {
          this.performLiveSearch(searchTerm);
        });
    }
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['drivers'] && !changes['drivers'].firstChange) {
      this.filteredDrivers = [...this.drivers];
      this.isSearching = false;
      if (this.enableLiveSearch && this.showDropdown) {
        this.showDropdown = true;
      }
      console.log('🔄 Drivers updated:', this.drivers.length, 'drivers');
      // Re-sync selected driver if ID matches
      if (this.selectedDriverId) {
        const driver = this.drivers.find((d) => d.id === this.selectedDriverId);
        if (driver) {
          this.selectedDriver = driver;
          this.searchText = this.getDriverDisplayName(driver);
        }
      }
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  // ControlValueAccessor methods
  writeValue(value: number | null): void {
    this.selectedDriverId = value;
    if (value) {
      const driver = this.drivers.find((d) => d.id === value);
      if (driver) {
        this.selectedDriver = driver;
        this.searchText = this.getDriverDisplayName(driver);
      }
    } else {
      this.selectedDriver = null;
      this.searchText = '';
    }
  }

  registerOnChange(fn: (value: number | null) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }

  // Filter drivers based on search text
  filterDrivers(): void {
    const search = this.searchText.toLowerCase().trim();

    if (this.enableLiveSearch) {
      // Use live API search
      if (search.length >= this.minSearchLength) {
        this.searchSubject$.next(search);
      } else if (search.length === 0) {
        // Show all drivers when search is cleared
        this.filteredDrivers = [...this.drivers];
        this.showDropdown = true;
      } else {
        // Less than min length, show empty
        this.filteredDrivers = [];
        this.showDropdown = true;
      }
    } else {
      // Use local filtering
      if (!search) {
        this.filteredDrivers = [...this.drivers];
      } else {
        this.filteredDrivers = this.drivers.filter((driver) => {
          const name = this.getDriverDisplayName(driver).toLowerCase();
          const phone = (driver.phone || '').toLowerCase();
          const firstName = (driver.firstName || '').toLowerCase();
          const lastName = (driver.lastName || '').toLowerCase();
          const plate = this.getDriverPlate(driver).toLowerCase();

          return (
            name.includes(search) ||
            phone.includes(search) ||
            plate.includes(search) ||
            firstName.includes(search) ||
            lastName.includes(search)
          );
        });
        console.log(
          `🔍 Filtered "${search}": ${this.filteredDrivers.length} of ${this.drivers.length} drivers found`,
        );
      }

      this.showDropdown = true;
    }
  }

  // Perform live API search
  private performLiveSearch(searchTerm: string): void {
    this.isSearching = true;
    console.log(`🌐 Live search API call: "${searchTerm}"`);

    // Emit search query for parent component to handle
    this.searchQuery.emit(searchTerm);
  }

  // Method for parent to update results after API call
  updateSearchResults(results: Driver[]): void {
    this.filteredDrivers = results;
    this.isSearching = false;
    this.showDropdown = true;
    console.log(`API search results: ${results.length} drivers found`);
  }

  // Select a driver from the dropdown
  selectDriver(driver: Driver): void {
    this.selectedDriver = driver;
    this.selectedDriverId = driver.id;
    this.searchText = this.getDriverDisplayName(driver);
    this.showDropdown = false;

    // Notify form control
    this.onChange(driver.id);
    this.markAsTouched();

    // Emit event
    this.driverSelected.emit(driver);
  }

  // Clear search input
  clearSearch(): void {
    this.searchText = '';
    this.filteredDrivers = [...this.drivers];
    this.showDropdown = true;

    // Focus back on input
    setTimeout(() => {
      if (this.searchInput && !this.disabled) {
        this.searchInput.nativeElement.focus();
      }
    }, 0);
  }

  // Clear the selected driver
  clearSelection(): void {
    this.selectedDriver = null;
    this.selectedDriverId = null;
    this.searchText = '';
    this.filteredDrivers = [...this.drivers];

    // Notify form control
    this.onChange(null);
    this.markAsTouched();

    // Emit event
    this.driverCleared.emit();

    // Focus on input
    setTimeout(() => {
      if (this.searchInput && !this.disabled) {
        this.searchInput.nativeElement.focus();
      }
    }, 0);
  }

  // Toggle dropdown visibility
  toggleDropdown(): void {
    if (this.disabled) return;

    this.showDropdown = !this.showDropdown;
    if (this.showDropdown) {
      this.filteredDrivers = [...this.drivers];
    }
  }

  // Mark as touched when user interacts
  markAsTouched(): void {
    if (!this.isTouched) {
      this.isTouched = true;
      this.onTouched();
    }
  }

  // Handle input focus
  onInputFocus(): void {
    if (!this.disabled) {
      this.showDropdown = true;
      this.markAsTouched();
    }
  }

  // Close dropdown when clicking outside
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    const clickedInside = target.closest('.driver-autocomplete-container');

    if (!clickedInside) {
      this.showDropdown = false;
    }
  }

  // Helper: Get driver display name
  getDriverDisplayName(driver: Driver): string {
    if (driver.name) {
      return driver.name;
    }
    if (driver.firstName || driver.lastName) {
      return `${driver.firstName || ''} ${driver.lastName || ''}`.trim();
    }
    return `Driver #${driver.id}`;
  }

  getDriverPlate(driver: Driver): string {
    return (
      driver.assignedVehiclePlate ||
      driver.currentVehiclePlate ||
      driver.assignedVehicle?.licensePlate ||
      ''
    ).trim();
  }

  // Helper: Get status badge class
  getStatusClass(status: string): string {
    switch (status?.toUpperCase()) {
      case 'ONLINE':
        return 'bg-green-100 text-green-800';
      case 'BUSY':
        return 'bg-yellow-100 text-yellow-800';
      case 'OFFLINE':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }

  // Helper: Check if driver is selected
  isSelected(driver: Driver): boolean {
    return this.selectedDriverId === driver.id;
  }
}
