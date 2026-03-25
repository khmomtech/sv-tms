> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Helper Utilities & Support Tools Guide

## 📋 Overview

Complete collection of helper utilities and support tools to complement the CRUD component library. These utilities provide production-ready solutions for common development tasks including form validation, date/array manipulation, storage, notifications, and user confirmations.

## 📁 File Structure

```
tms-frontend/src/app/shared/
├── utils/
│   ├── form-validators.ts      # Custom form validators
│   ├── date.utils.ts            # Date utilities
│   ├── array.utils.ts           # Array manipulation
│   └── index.ts                 # Barrel export
├── services/
│   ├── storage.service.ts       # LocalStorage/SessionStorage wrapper
│   ├── toast.service.ts         # Toast notifications
│   └── index.ts                 # Barrel export
├── components/
│   └── confirmation-dialog/     # Confirmation dialog component
│       ├── confirmation-dialog.component.ts
│       ├── confirmation-dialog.component.html
│       └── confirmation-dialog.component.css
└── styles/
    └── toast-styles.css         # Global toast styles
```

---

## 🛠️ Utilities Reference

### 1. Form Validators (`FormValidators`)

**Location:** `src/app/shared/utils/form-validators.ts`

Custom validators for Angular Reactive Forms with built-in error messages.

#### Available Validators

```typescript
import { FormValidators } from "@shared/utils";

// Phone number validation (international formats)
FormValidators.phone();

// URL validation
FormValidators.url();

// Email domain whitelist
FormValidators.emailDomain(["company.com", "example.org"]);

// Field matching (password confirmation)
FormValidators.matchField("password");

// Minimum age validation
FormValidators.minAge(18);

// File size validation (bytes)
FormValidators.fileSize(5 * 1024 * 1024); // 5MB

// File type validation
FormValidators.fileType(["pdf", "jpg", "png"]);

// Numeric range validation
FormValidators.range(1, 100);

// Alphanumeric only
FormValidators.alphanumeric();

// No whitespace
FormValidators.noWhitespace();
```

#### Usage Example

```typescript
import { FormBuilder, Validators } from "@angular/forms";
import { FormValidators } from "@shared/utils";

export class DriverFormComponent {
  constructor(private fb: FormBuilder) {}

  driverForm = this.fb.group({
    name: ["", [Validators.required, Validators.minLength(3)]],
    phone: ["", [Validators.required, FormValidators.phone()]],
    email: [
      "",
      [
        Validators.required,
        Validators.email,
        FormValidators.emailDomain(["company.com"]),
      ],
    ],
    age: ["", [Validators.required, FormValidators.range(18, 65)]],
    licenseFile: [
      "",
      [
        Validators.required,
        FormValidators.fileSize(5 * 1024 * 1024),
        FormValidators.fileType(["pdf", "jpg", "png"]),
      ],
    ],
  });

  getErrorMessage(fieldName: string): string {
    const control = this.driverForm.get(fieldName);
    return FormValidators.getErrorMessage(control?.errors, fieldName);
  }
}
```

---

### 2. Date Utilities (`DateUtils`)

**Location:** `src/app/shared/utils/date.utils.ts`

Comprehensive date formatting, comparison, and manipulation functions.

#### Available Methods

```typescript
import { DateUtils } from "@shared/utils";

// Formatting
DateUtils.format(date, "short"); // 1/1/24
DateUtils.format(date, "medium"); // Jan 1, 2024
DateUtils.format(date, "long"); // January 1, 2024
DateUtils.format(date, "time"); // 03:30 PM
DateUtils.format(date, "datetime"); // Jan 1, 2024 03:30 PM
DateUtils.format(date, "iso"); // 2024-01-01T15:30:00.000Z
DateUtils.format(date, "YYYY-MM-DD"); // 2024-01-01 (custom)

// Comparison
DateUtils.isInRange(date, startDate, endDate);
DateUtils.isToday(date);
DateUtils.isPast(date);
DateUtils.isFuture(date);
DateUtils.isWeekend(date);

// Manipulation
DateUtils.addDays(date, 7);
DateUtils.addMonths(date, 3);
DateUtils.startOfDay(date);
DateUtils.endOfDay(date);

// Calculation
DateUtils.getDaysDiff(date1, date2);
DateUtils.getAge(birthDate);
DateUtils.getRelativeTime(date); // "2 hours ago"
DateUtils.getDateRange(start, end); // Array of dates

// Parsing
DateUtils.parse(dateString);

// Display
DateUtils.getMonthName(0); // "January"
DateUtils.getDayName(date); // "Monday"
```

#### Usage Example

```typescript
import { DateUtils } from "@shared/utils";

export class DriverListComponent {
  // Table column with date formatting
  columns: TableColumn<Driver>[] = [
    {
      key: "createdAt",
      label: "Created",
      sortable: true,
      format: (value) => DateUtils.format(value, "medium"),
    },
    {
      key: "lastActive",
      label: "Last Active",
      format: (value) => DateUtils.getRelativeTime(value),
    },
  ];

  // Filter drivers by date range
  filterByLastWeek(): void {
    const today = new Date();
    const weekAgo = DateUtils.addDays(today, -7);
    this.filteredDrivers = this.drivers.filter((driver) =>
      DateUtils.isInRange(driver.lastActive, weekAgo, today),
    );
  }
}
```

---

### 3. Array Utilities (`ArrayUtils`)

**Location:** `src/app/shared/utils/array.utils.ts`

Array manipulation, sorting, filtering, and aggregation for client-side operations.

#### Available Methods

```typescript
import { ArrayUtils } from "@shared/utils";

// Sorting
ArrayUtils.sortBy(array, "name", "asc");
ArrayUtils.sortBy(array, "user.email", "desc"); // Nested properties

// Filtering
ArrayUtils.filterByQuery(array, "search term", ["name", "email"]);
ArrayUtils.findBy(array, "id", 123);
ArrayUtils.findAllBy(array, "status", "active");

// Grouping
ArrayUtils.groupBy(array, "status");
ArrayUtils.countBy(array, "status");

// Pagination
ArrayUtils.paginate(array, page, pageSize);
ArrayUtils.getPaginationInfo(totalItems, page, pageSize);

// Aggregation
ArrayUtils.sumBy(array, "amount");
ArrayUtils.averageBy(array, "rating");
ArrayUtils.minBy(array, "price");
ArrayUtils.maxBy(array, "price");

// Transformation
ArrayUtils.unique(array, "id");
ArrayUtils.chunk(array, 10);
ArrayUtils.flatten(nestedArray);
ArrayUtils.compact(arrayWithNulls);

// Set operations
ArrayUtils.difference(array1, array2);
ArrayUtils.intersection(array1, array2);
ArrayUtils.union(array1, array2);

// Other
ArrayUtils.shuffle(array);
ArrayUtils.take(array, 5);
ArrayUtils.drop(array, 5);
```

#### Usage Example

```typescript
import { ArrayUtils } from "@shared/utils";

export class DriverListComponent {
  drivers: Driver[] = [];

  // Client-side sorting
  onSort(event: SortEvent): void {
    this.drivers = ArrayUtils.sortBy(
      this.drivers,
      event.column,
      event.direction,
    );
  }

  // Client-side search
  onSearch(query: string): void {
    this.filteredDrivers = ArrayUtils.filterByQuery(this.drivers, query, [
      "name",
      "email",
      "phone",
      "vehicle.plateNumber",
    ]);
  }

  // Pagination
  getCurrentPage(): Driver[] {
    return ArrayUtils.paginate(this.drivers, this.currentPage, this.pageSize);
  }

  // Statistics
  getTotalEarnings(): number {
    return ArrayUtils.sumBy(this.drivers, "totalEarnings");
  }

  // Group by status
  getDriversByStatus(): Record<string, Driver[]> {
    return ArrayUtils.groupBy(this.drivers, "status");
  }
}
```

---

### 4. Storage Service (`StorageService`)

**Location:** `src/app/shared/services/storage.service.ts`

Type-safe wrapper for LocalStorage and SessionStorage with JSON serialization.

#### Available Methods

```typescript
import { StorageService } from "@shared/services";

// LocalStorage operations
storage.setLocal<T>(key, value);
storage.getLocal<T>(key);
storage.removeLocal(key);
storage.clearLocal();
storage.hasLocal(key);

// SessionStorage operations
storage.setSession<T>(key, value);
storage.getSession<T>(key);
storage.removeSession(key);
storage.clearSession();
storage.hasSession(key);

// With expiration
storage.setWithExpiry<T>(key, value, expiryDays, "local");
storage.getWithExpiry<T>(key, "local");

// Utilities
storage.getLocalKeys();
storage.getStorageSize("local");
storage.getStorageSizeMB("local");
storage.removeOlderThan(30, "local");
```

#### Usage Example

```typescript
import { StorageService } from "@shared/services";

export class DriverListComponent {
  constructor(private storage: StorageService) {
    this.loadUserPreferences();
  }

  // Save user preferences
  saveTableConfig(): void {
    this.storage.setLocal("driverTableConfig", {
      sortColumn: this.sortColumn,
      sortDirection: this.sortDirection,
      pageSize: this.pageSize,
      visibleColumns: this.visibleColumns,
    });
  }

  // Load user preferences
  loadUserPreferences(): void {
    const config = this.storage.getLocal<TableConfig>("driverTableConfig");
    if (config) {
      this.sortColumn = config.sortColumn;
      this.sortDirection = config.sortDirection;
      this.pageSize = config.pageSize;
      this.visibleColumns = config.visibleColumns;
    }
  }

  // Session-based filter state
  saveFilterState(): void {
    this.storage.setSession("driverFilters", this.activeFilters);
  }

  // Expirable cache
  cacheDriverStats(): void {
    this.storage.setWithExpiry("driverStats", this.stats, 1, "local"); // 1 day
  }
}
```

---

### 5. Toast Service (`ToastService`)

**Location:** `src/app/shared/services/toast.service.ts`

MatSnackBar wrapper with preset configurations for consistent notifications.

#### Available Methods

```typescript
import { ToastService } from '@shared/services';

// Basic toasts
toast.success(message, action?, config?)
toast.error(message, action?, config?)
toast.warning(message, action?, config?)
toast.info(message, action?, config?)
toast.loading(message?)

// Dismiss
toast.dismiss()
```

#### Usage Example

```typescript
import { ToastService } from "@shared/services";

export class DriverFormComponent {
  constructor(private toast: ToastService) {}

  createDriver(): void {
    this.driverService.create(this.form.value).subscribe({
      next: () => {
        this.toast.success("Driver created successfully");
        this.router.navigate(["/drivers"]);
      },
      error: (error) => {
        this.toast
          .error("Failed to create driver", "Retry")
          .onAction()
          .subscribe(() => this.createDriver());
      },
    });
  }

  deleteDriver(id: number): void {
    const loadingRef = this.toast.loading("Deleting driver...");

    this.driverService.delete(id).subscribe({
      next: () => {
        loadingRef.dismiss();
        this.toast.success("Driver deleted");
      },
      error: () => {
        loadingRef.dismiss();
        this.toast.error("Delete failed");
      },
    });
  }

  validateForm(): void {
    if (this.form.invalid) {
      this.toast.warning("Please fill all required fields");
    }
  }

  showInfo(): void {
    this.toast.info("Changes saved to draft", undefined, { duration: 5000 });
  }
}
```

#### Setup Toast Styles

Add to `src/styles.css`:

```css
@import "app/shared/styles/toast-styles.css";
```

---

### 6. Confirmation Dialog (`ConfirmationDialogComponent`)

**Location:** `src/app/shared/components/confirmation-dialog/`

Reusable confirmation dialog for delete/critical actions with danger variants.

#### Dialog Data Interface

```typescript
interface ConfirmationDialogData {
  title: string;
  message: string;
  confirmText?: string; // Default: "Confirm"
  cancelText?: string; // Default: "Cancel"
  variant?: "default" | "danger" | "warning";
  showIcon?: boolean; // Default: true
}
```

#### Usage Example

```typescript
import { MatDialog } from "@angular/material/dialog";
import { ConfirmationDialogComponent } from "@shared/components";

export class DriverListComponent {
  constructor(
    private dialog: MatDialog,
    private toast: ToastService,
  ) {}

  deleteDriver(driver: Driver): void {
    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      width: "450px",
      data: {
        title: "Delete Driver",
        message: `Are you sure you want to delete ${driver.fullName}? This action cannot be undone.`,
        confirmText: "Delete",
        cancelText: "Cancel",
        variant: "danger",
      },
    });

    dialogRef.afterClosed().subscribe((confirmed) => {
      if (confirmed) {
        this.driverService.delete(driver.id).subscribe({
          next: () => this.toast.success("Driver deleted"),
          error: () => this.toast.error("Delete failed"),
        });
      }
    });
  }

  deactivateDriver(driver: Driver): void {
    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: "Deactivate Driver",
        message: `Deactivate ${driver.fullName}? They won't be able to accept new jobs.`,
        confirmText: "Deactivate",
        variant: "warning",
      },
    });

    dialogRef.afterClosed().subscribe((confirmed) => {
      if (confirmed) {
        this.deactivate(driver.id);
      }
    });
  }

  clearFilters(): void {
    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: "Clear All Filters",
        message: "Reset all active filters to default values?",
        confirmText: "Clear",
        variant: "default",
      },
    });

    dialogRef.afterClosed().subscribe((confirmed) => {
      if (confirmed) {
        this.resetFilters();
      }
    });
  }
}
```

---

## 🎯 Complete Integration Example

### Full CRUD Page with All Utilities

```typescript
import { Component, OnInit, OnDestroy } from "@angular/core";
import { FormBuilder, Validators } from "@angular/forms";
import { MatDialog } from "@angular/material/dialog";
import { Subject, takeUntil } from "rxjs";

// Components
import {
  PageContainerComponent,
  DataTableComponent,
  FilterBarComponent,
  ConfirmationDialogComponent,
} from "@shared/components";

// Utils & Services
import { FormValidators, DateUtils, ArrayUtils } from "@shared/utils";
import { StorageService, ToastService } from "@shared/services";

@Component({
  selector: "app-drivers",
  standalone: true,
  imports: [PageContainerComponent, DataTableComponent, FilterBarComponent],
  template: `
    <app-page-container
      title="Drivers"
      [breadcrumbs]="breadcrumbs"
      [backLink]="'/dashboard'"
    >
      <!-- Stats -->
      <div stats class="grid grid-cols-4 gap-4">
        <app-stat-card
          *ngFor="let stat of stats"
          [config]="stat"
        ></app-stat-card>
      </div>

      <!-- Filters -->
      <app-filter-bar
        filters
        [searchPlaceholder]="'Search drivers...'"
        [chips]="filterChips"
        (searchChange)="onSearch($event)"
        (chipRemove)="onFilterRemove($event)"
      ></app-filter-bar>

      <!-- Table -->
      <app-data-table
        content
        [data]="displayedDrivers"
        [columns]="columns"
        [config]="tableConfig"
        (sort)="onSort($event)"
        (rowClick)="onRowClick($event)"
      ></app-data-table>
    </app-page-container>
  `,
})
export class DriversComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  drivers: Driver[] = [];
  displayedDrivers: Driver[] = [];

  breadcrumbs = [{ label: "Home", link: "/" }, { label: "Drivers" }];

  columns: TableColumn<Driver>[] = [
    {
      key: "name",
      label: "Name",
      sortable: true,
    },
    {
      key: "email",
      label: "Email",
      sortable: true,
    },
    {
      key: "phone",
      label: "Phone",
      format: (value) => this.formatPhone(value),
    },
    {
      key: "createdAt",
      label: "Created",
      sortable: true,
      format: (value) => DateUtils.format(value, "medium"),
    },
    {
      key: "lastActive",
      label: "Last Active",
      format: (value) => DateUtils.getRelativeTime(value),
    },
  ];

  tableConfig: TableConfig<Driver> = {
    trackByKey: "id",
    selectable: true,
    selectMode: "multiple",
  };

  stats = [
    { label: "Total Drivers", value: 0, color: "primary" as const },
    { label: "Active", value: 0, color: "success" as const },
    { label: "Inactive", value: 0, color: "gray" as const },
  ];

  filterChips: FilterChip[] = [];

  constructor(
    private fb: FormBuilder,
    private dialog: MatDialog,
    private storage: StorageService,
    private toast: ToastService,
    private driverService: DriverService,
  ) {
    this.loadUserPreferences();
  }

  ngOnInit(): void {
    this.loadDrivers();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadDrivers(): void {
    this.driverService
      .getAll()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (drivers) => {
          this.drivers = drivers;
          this.displayedDrivers = drivers;
          this.updateStats();
          this.applyStoredFilters();
        },
        error: () => this.toast.error("Failed to load drivers"),
      });
  }

  onSearch(query: string): void {
    this.displayedDrivers = ArrayUtils.filterByQuery(this.drivers, query, [
      "name",
      "email",
      "phone",
    ]);
    this.saveFilterState();
  }

  onSort(event: SortEvent): void {
    this.displayedDrivers = ArrayUtils.sortBy(
      this.displayedDrivers,
      event.column,
      event.direction,
    );
    this.saveSortState(event);
  }

  deleteDriver(driver: Driver): void {
    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: "Delete Driver",
        message: `Delete ${driver.fullName}? This cannot be undone.`,
        confirmText: "Delete",
        variant: "danger",
      },
    });

    dialogRef.afterClosed().subscribe((confirmed) => {
      if (confirmed) {
        this.performDelete(driver.id);
      }
    });
  }

  performDelete(id: number): void {
    const loading = this.toast.loading("Deleting driver...");

    this.driverService.delete(id).subscribe({
      next: () => {
        loading.dismiss();
        this.toast.success("Driver deleted");
        this.loadDrivers();
      },
      error: () => {
        loading.dismiss();
        this.toast.error("Delete failed");
      },
    });
  }

  updateStats(): void {
    const active = ArrayUtils.findAllBy(this.drivers, "status", "active");
    this.stats[0].value = this.drivers.length;
    this.stats[1].value = active.length;
    this.stats[2].value = this.drivers.length - active.length;
  }

  loadUserPreferences(): void {
    const prefs = this.storage.getLocal<TablePreferences>("driverTablePrefs");
    if (prefs) {
      this.tableConfig = { ...this.tableConfig, ...prefs };
    }
  }

  saveFilterState(): void {
    this.storage.setSession("driverFilters", {
      chips: this.filterChips,
      displayed: this.displayedDrivers.length,
    });
  }

  saveSortState(event: SortEvent): void {
    this.storage.setLocal("driverSort", event);
  }

  applyStoredFilters(): void {
    const stored = this.storage.getSession<any>("driverFilters");
    if (stored?.chips) {
      this.filterChips = stored.chips;
    }
  }

  formatPhone(phone: string): string {
    // Custom phone formatting logic
    return phone;
  }

  onRowClick(driver: Driver): void {
    this.router.navigate(["/drivers", driver.id]);
  }

  onFilterRemove(chip: FilterChip): void {
    this.filterChips = this.filterChips.filter((c) => c.key !== chip.key);
    this.applyFilters();
  }

  applyFilters(): void {
    // Apply filter logic based on filterChips
    this.saveFilterState();
  }
}
```

---

## 📝 Best Practices

### 1. **Import Organization**

```typescript
// Group imports by category
import { Component } from "@angular/core";
import { FormBuilder } from "@angular/forms";

import { PageContainerComponent } from "@shared/components";
import { FormValidators, DateUtils } from "@shared/utils";
import { ToastService } from "@shared/services";
```

### 2. **Type Safety**

```typescript
// Always use generic types with storage
const config = this.storage.getLocal<TableConfig>("tableConfig");

// Use type-safe array utilities
const sorted = ArrayUtils.sortBy<Driver>(drivers, "name", "asc");
```

### 3. **Error Handling**

```typescript
// Combine toast with error handling
this.service.create(data).subscribe({
  next: () => this.toast.success("Created"),
  error: (err) => {
    const message = FormValidators.getErrorMessage(err);
    this.toast.error(message);
  },
});
```

### 4. **Performance**

```typescript
// Cache expensive calculations
const stats = this.storage.getWithExpiry<Stats>("stats", "session");
if (!stats) {
  const calculated = this.calculateStats();
  this.storage.setWithExpiry("stats", calculated, 0.5, "session"); // 12 hours
}
```

### 5. **User Experience**

```typescript
// Always confirm destructive actions
deleteItem(id: number): void {
  this.dialog.open(ConfirmationDialogComponent, {
    data: {
      title: 'Delete Item',
      message: 'This cannot be undone.',
      variant: 'danger'
    }
  }).afterClosed().subscribe(confirmed => {
    if (confirmed) this.performDelete(id);
  });
}
```

---

## 🚀 Quick Reference

| Utility                       | Purpose               | Import               |
| ----------------------------- | --------------------- | -------------------- |
| `FormValidators`              | Form validation       | `@shared/utils`      |
| `DateUtils`                   | Date operations       | `@shared/utils`      |
| `ArrayUtils`                  | Array manipulation    | `@shared/utils`      |
| `StorageService`              | Local/session storage | `@shared/services`   |
| `ToastService`                | Notifications         | `@shared/services`   |
| `ConfirmationDialogComponent` | User confirmation     | `@shared/components` |

---

## What's Included

- **10 custom form validators** with error messages
- **25+ date utility functions** for formatting and manipulation
- **30+ array utility functions** for data operations
- **Type-safe storage service** with expiration support
- **Toast notification service** with 5 preset variants
- **Confirmation dialog component** with danger/warning modes
- **Global toast styles** ready to import
- **Barrel exports** for clean imports
- **Comprehensive JSDoc** documentation
- **Production-ready** error handling

Total: **~1,500 lines** of production code
