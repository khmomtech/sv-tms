> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Angular Development Guide - TMS Frontend

**Version:** 1.0  
**Last Updated:** December 7, 2025  
**Team:** TMS Development Team

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Decision: Standalone Components](#architecture-decision-standalone-components)
3. [Project Structure](#project-structure)
4. [Development Standards](#development-standards)
5. [When to Create Modules vs Standalone Components](#when-to-create-modules-vs-standalone-components)
6. [Component Development Guide](#component-development-guide)
7. [Service Development Guide](#service-development-guide)
8. [Routing Strategy](#routing-strategy)
9. [State Management](#state-management)
10. [Code Examples](#code-examples)
11. [Best Practices Checklist](#best-practices-checklist)

---

## 🎯 Project Overview

**Technology Stack:**

- **Framework:** Angular 19.2.x
- **Language:** TypeScript 5.8.x
- **Styling:** Tailwind CSS 4.x + Angular Material 19.2.x
- **State Management:** RxJS 7.8.x (BehaviorSubject pattern)
- **Architecture:** Standalone Components (Modern Angular)

**Project Type:** Transport Management System (TMS) - Dispatcher/Admin Web Interface

---

## 🏗️ Architecture Decision: Standalone Components

### Why We Use Standalone Components

**Our project uses the modern standalone component architecture (Angular 14+).** This means:

- ❌ **NO NgModules** for feature components
- **Direct imports** in component metadata
- **Simplified dependency management**
- **Better tree-shaking** and smaller bundles
- **Easier testing** (no module setup required)

### When to Use NgModules (Rare Cases)

Use `NgModule` **ONLY** for:

1. **Root application module** (`app.config.ts` for providers)
2. **Third-party library integration** (if library requires it)
3. **Legacy code migration** (temporary, during transition)

---

## 📁 Project Structure

```
tms-frontend/
├── src/
│   ├── app/
│   │   ├── core/                    # Singleton services, guards, interceptors
│   │   │   ├── auth/
│   │   │   │   ├── guards/
│   │   │   │   ├── interceptors/
│   │   │   │   └── services/
│   │   │   ├── services/           # Core business services
│   │   │   └── models/             # Core interfaces/types
│   │   │
│   │   ├── shared/                  # Reusable components, utilities, services
│   │   │   ├── components/         # Shared UI components
│   │   │   │   ├── crud/           # CRUD component library
│   │   │   │   └── confirmation-dialog/
│   │   │   ├── utils/              # Utility functions
│   │   │   │   ├── form-validators.ts
│   │   │   │   ├── date.utils.ts
│   │   │   │   └── array.utils.ts
│   │   │   ├── services/           # Shared services
│   │   │   │   ├── storage.service.ts
│   │   │   │   └── toast.service.ts
│   │   │   ├── directives/         # Shared directives
│   │   │   ├── pipes/              # Shared pipes
│   │   │   ├── common-imports.ts   # Shared import constants
│   │   │   └── styles/             # Shared styles
│   │   │
│   │   ├── features/                # Feature modules (business domains)
│   │   │   ├── drivers/
│   │   │   │   ├── components/
│   │   │   │   │   ├── driver-list/
│   │   │   │   │   ├── driver-form/
│   │   │   │   │   └── driver-detail/
│   │   │   │   ├── services/
│   │   │   │   │   └── driver.service.ts
│   │   │   │   ├── models/
│   │   │   │   │   └── driver.model.ts
│   │   │   │   └── drivers.routes.ts
│   │   │   │
│   │   │   ├── cases/              # Job/Case management
│   │   │   ├── vehicles/           # Fleet management
│   │   │   ├── customers/          # Customer management
│   │   │   ├── documents/          # Document management
│   │   │   └── dashboard/          # Dashboard/Analytics
│   │   │
│   │   ├── layouts/                 # Layout components
│   │   │   ├── main-layout/
│   │   │   ├── auth-layout/
│   │   │   └── error-layout/
│   │   │
│   │   ├── app.component.ts        # Root component
│   │   ├── app.config.ts           # App configuration
│   │   └── app.routes.ts           # Root routing
│   │
│   ├── assets/                      # Static assets
│   ├── environments/                # Environment configs
│   └── styles.css                   # Global styles
│
├── .github/
│   └── copilot-instructions.md     # AI coding guidelines
├── REUSABLE_COMPONENTS_QUICK_START.md
├── HELPER_UTILITIES_GUIDE.md
└── ANGULAR_DEVELOPMENT_GUIDE.md    # This file
```

---

## 📐 Development Standards

### File Naming Conventions

| Type                | Pattern                       | Example                    |
| ------------------- | ----------------------------- | -------------------------- |
| **Component**       | `feature-name.component.ts`   | `driver-list.component.ts` |
| **Service**         | `feature-name.service.ts`     | `driver.service.ts`        |
| **Model/Interface** | `feature-name.model.ts`       | `driver.model.ts`          |
| **Guard**           | `feature-name.guard.ts`       | `auth.guard.ts`            |
| **Interceptor**     | `feature-name.interceptor.ts` | `jwt.interceptor.ts`       |
| **Pipe**            | `feature-name.pipe.ts`        | `phone-format.pipe.ts`     |
| **Directive**       | `feature-name.directive.ts`   | `auto-focus.directive.ts`  |
| **Routes**          | `feature-name.routes.ts`      | `drivers.routes.ts`        |

### Code Organization

```typescript
// 1. Angular imports
import { Component, OnInit, OnDestroy } from "@angular/core";
import { FormBuilder, Validators } from "@angular/forms";

// 2. Third-party imports
import { Subject, takeUntil } from "rxjs";

// 3. Shared imports (grouped by category)
import { PageContainerComponent, DataTableComponent } from "@shared/components";
import { FormValidators, DateUtils, ArrayUtils } from "@shared/utils";
import { ToastService, StorageService } from "@shared/services";
import { BASE_IMPORTS, FORM_IMPORTS } from "@shared/common-imports";

// 4. Feature imports
import { DriverService } from "../services/driver.service";
import { Driver } from "../models/driver.model";

// 5. Component decorator and class
@Component({
  /* ... */
})
export class DriverListComponent implements OnInit, OnDestroy {
  /* ... */
}
```

---

## �� When to Create Modules vs Standalone Components

### 🎯 Decision Matrix

| Scenario                      | Use                            | Example                  |
| ----------------------------- | ------------------------------ | ------------------------ |
| **New feature component**     | Standalone Component           | Driver list, Case detail |
| **Shared UI component**       | Standalone Component           | Button, Card, Table      |
| **Utility service**           | Injectable Service             | Toast, Storage, HTTP     |
| **Route configuration**       | Routes file                    | `drivers.routes.ts`      |
| **Third-party library setup** | ⚠️ NgModule (only if required) | Material imports         |
| **Root app config**           | App Config                     | `app.config.ts`          |

### ❌ DO NOT Create NgModules For:

- Feature components (use standalone instead)
- Shared components (use standalone instead)
- Lazy-loaded features (use routes instead)
- Component libraries (use barrel exports instead)

### DO Create Standalone Components For:

- **Every new component** in the project
- **Pages/Views** in features
- **Reusable UI components**
- **Layout components**

---

## 🧩 Component Development Guide

### Standard Standalone Component Template

```typescript
import {
  Component,
  OnInit,
  OnDestroy,
  ChangeDetectionStrategy,
} from "@angular/core";
import { CommonModule } from "@angular/common";
import { Subject, takeUntil } from "rxjs";

// Shared imports
import {
  BASE_IMPORTS,
  FORM_IMPORTS,
  TABLE_IMPORTS,
} from "@shared/common-imports";
import { PageContainerComponent } from "@shared/components";
import { ToastService } from "@shared/services";

// Feature imports
import { Driver } from "../models/driver.model";
import { DriverService } from "../services/driver.service";

@Component({
  selector: "app-driver-list",
  standalone: true,
  imports: [...BASE_IMPORTS, ...TABLE_IMPORTS, PageContainerComponent],
  templateUrl: "./driver-list.component.html",
  styleUrl: "./driver-list.component.css",
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DriverListComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  drivers: Driver[] = [];
  loading = false;

  constructor(
    private driverService: DriverService,
    private toast: ToastService,
  ) {}

  ngOnInit(): void {
    this.loadDrivers();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadDrivers(): void {
    this.loading = true;
    this.driverService
      .getAll()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (drivers) => {
          this.drivers = drivers;
          this.loading = false;
        },
        error: (err) => {
          this.toast.error("Failed to load drivers");
          this.loading = false;
        },
      });
  }
}
```

### Component Creation Steps

**Step 1: Generate Component**

```bash
cd src/app/features/drivers/components
ng generate component driver-list --standalone --skip-tests
```

**Step 2: Update Imports**

```typescript
// Add to component imports
imports: [
  ...BASE_IMPORTS, // Common Angular imports
  ...FORM_IMPORTS, // Form-related imports
  ...TABLE_IMPORTS, // Table-related imports
  PageContainerComponent, // Custom shared components
];
```

**Step 3: Implement Interfaces**

```typescript
export class DriverListComponent implements OnInit, OnDestroy {
  // Always implement OnDestroy for subscription cleanup
}
```

**Step 4: Add Cleanup Logic**

```typescript
private destroy$ = new Subject<void>();

ngOnDestroy(): void {
  this.destroy$.next();
  this.destroy$.complete();
}

// Use in subscriptions
.pipe(takeUntil(this.destroy$))
```

---

## 🔧 Service Development Guide

### Standard Service Template

```typescript
import { Injectable } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Observable, BehaviorSubject } from "rxjs";
import { map, tap } from "rxjs/operators";

import { environment } from "@env/environment";
import {
  Driver,
  CreateDriverDto,
  UpdateDriverDto,
} from "../models/driver.model";

@Injectable({
  providedIn: "root", // Singleton service
})
export class DriverService {
  private readonly apiUrl = `${environment.apiUrl}/drivers`;

  // State management (optional)
  private driversSubject = new BehaviorSubject<Driver[]>([]);
  public drivers$ = this.driversSubject.asObservable();

  constructor(private http: HttpClient) {}

  /**
   * Get all drivers with optional filters
   */
  getAll(filters?: { status?: string; search?: string }): Observable<Driver[]> {
    let params = new HttpParams();

    if (filters?.status) {
      params = params.set("status", filters.status);
    }
    if (filters?.search) {
      params = params.set("search", filters.search);
    }

    return this.http
      .get<Driver[]>(this.apiUrl, { params })
      .pipe(tap((drivers) => this.driversSubject.next(drivers)));
  }

  /**
   * Get driver by ID
   */
  getById(id: number): Observable<Driver> {
    return this.http.get<Driver>(`${this.apiUrl}/${id}`);
  }

  /**
   * Create new driver
   */
  create(dto: CreateDriverDto): Observable<Driver> {
    return this.http.post<Driver>(this.apiUrl, dto).pipe(
      tap((driver) => {
        const current = this.driversSubject.value;
        this.driversSubject.next([...current, driver]);
      }),
    );
  }

  /**
   * Update existing driver
   */
  update(id: number, dto: UpdateDriverDto): Observable<Driver> {
    return this.http.put<Driver>(`${this.apiUrl}/${id}`, dto).pipe(
      tap((updated) => {
        const current = this.driversSubject.value;
        const index = current.findIndex((d) => d.id === id);
        if (index !== -1) {
          current[index] = updated;
          this.driversSubject.next([...current]);
        }
      }),
    );
  }

  /**
   * Delete driver
   */
  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`).pipe(
      tap(() => {
        const current = this.driversSubject.value;
        this.driversSubject.next(current.filter((d) => d.id !== id));
      }),
    );
  }
}
```

### Service Placement Rules

| Service Type                 | Location                       | Provided In |
| ---------------------------- | ------------------------------ | ----------- |
| **Feature-specific service** | `features/[feature]/services/` | `'root'`    |
| **Shared service**           | `shared/services/`             | `'root'`    |
| **Core singleton service**   | `core/services/`               | `'root'`    |
| **Auth-related service**     | `core/auth/services/`          | `'root'`    |

---

## 🛣️ Routing Strategy

### Feature Routes File

**File:** `src/app/features/drivers/drivers.routes.ts`

```typescript
import { Routes } from "@angular/router";
import { AuthGuard } from "@core/auth/guards/auth.guard";

export const DRIVERS_ROUTES: Routes = [
  {
    path: "",
    canActivate: [AuthGuard],
    children: [
      {
        path: "",
        loadComponent: () =>
          import("./components/driver-list/driver-list.component").then(
            (m) => m.DriverListComponent,
          ),
        title: "Drivers",
      },
      {
        path: "create",
        loadComponent: () =>
          import("./components/driver-form/driver-form.component").then(
            (m) => m.DriverFormComponent,
          ),
        title: "Create Driver",
      },
      {
        path: ":id",
        loadComponent: () =>
          import("./components/driver-detail/driver-detail.component").then(
            (m) => m.DriverDetailComponent,
          ),
        title: "Driver Details",
      },
      {
        path: ":id/edit",
        loadComponent: () =>
          import("./components/driver-form/driver-form.component").then(
            (m) => m.DriverFormComponent,
          ),
        title: "Edit Driver",
      },
    ],
  },
];
```

### Root Routes Configuration

**File:** `src/app/app.routes.ts`

```typescript
import { Routes } from "@angular/router";
import { AuthGuard } from "@core/auth/guards/auth.guard";

export const routes: Routes = [
  // Public routes
  {
    path: "login",
    loadComponent: () =>
      import("./features/auth/login/login.component").then(
        (m) => m.LoginComponent,
      ),
    title: "Login",
  },

  // Protected routes with layout
  {
    path: "",
    canActivate: [AuthGuard],
    loadComponent: () =>
      import("./layouts/main-layout/main-layout.component").then(
        (m) => m.MainLayoutComponent,
      ),
    children: [
      {
        path: "",
        redirectTo: "dashboard",
        pathMatch: "full",
      },
      {
        path: "dashboard",
        loadComponent: () =>
          import("./features/dashboard/dashboard.component").then(
            (m) => m.DashboardComponent,
          ),
        title: "Dashboard",
      },
      {
        path: "drivers",
        loadChildren: () =>
          import("./features/drivers/drivers.routes").then(
            (m) => m.DRIVERS_ROUTES,
          ),
      },
      {
        path: "cases",
        loadChildren: () =>
          import("./features/cases/cases.routes").then((m) => m.CASES_ROUTES),
      },
      {
        path: "vehicles",
        loadChildren: () =>
          import("./features/vehicles/vehicles.routes").then(
            (m) => m.VEHICLES_ROUTES,
          ),
      },
    ],
  },

  // Error routes
  {
    path: "**",
    loadComponent: () =>
      import("./features/error/not-found/not-found.component").then(
        (m) => m.NotFoundComponent,
      ),
    title: "404 - Not Found",
  },
];
```

---

## 💾 State Management

### BehaviorSubject Pattern (Recommended)

```typescript
import { Injectable } from "@angular/core";
import { BehaviorSubject, Observable } from "rxjs";

export interface AppState {
  user: User | null;
  isLoading: boolean;
  sidebarOpen: boolean;
}

@Injectable({
  providedIn: "root",
})
export class StateService {
  private state: AppState = {
    user: null,
    isLoading: false,
    sidebarOpen: true,
  };

  private stateSubject = new BehaviorSubject<AppState>(this.state);
  public state$ = this.stateSubject.asObservable();

  // User state
  setUser(user: User | null): void {
    this.state = { ...this.state, user };
    this.stateSubject.next(this.state);
  }

  // Loading state
  setLoading(isLoading: boolean): void {
    this.state = { ...this.state, isLoading };
    this.stateSubject.next(this.state);
  }

  // Sidebar state
  toggleSidebar(): void {
    this.state = { ...this.state, sidebarOpen: !this.state.sidebarOpen };
    this.stateSubject.next(this.state);
  }

  // Selectors
  get currentUser(): User | null {
    return this.state.user;
  }

  get isAuthenticated(): boolean {
    return this.state.user !== null;
  }
}
```

### Component Usage

```typescript
export class HeaderComponent {
  user$ = this.stateService.state$.pipe(map((state) => state.user));

  constructor(private stateService: StateService) {}

  toggleSidebar(): void {
    this.stateService.toggleSidebar();
  }
}
```

---

## 📝 Code Examples

### Example 1: Complete CRUD Feature

**Directory Structure:**

```
features/drivers/
├── components/
│   ├── driver-list/
│   │   ├── driver-list.component.ts
│   │   ├── driver-list.component.html
│   │   └── driver-list.component.css
│   ├── driver-form/
│   │   ├── driver-form.component.ts
│   │   ├── driver-form.component.html
│   │   └── driver-form.component.css
│   └── driver-detail/
│       ├── driver-detail.component.ts
│       ├── driver-detail.component.html
│       └── driver-detail.component.css
├── services/
│   └── driver.service.ts
├── models/
│   └── driver.model.ts
└── drivers.routes.ts
```

**Model:** `driver.model.ts`

```typescript
export interface Driver {
  id: number;
  name: string;
  email: string;
  phone: string;
  licenseNumber: string;
  status: "active" | "inactive" | "suspended";
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateDriverDto {
  name: string;
  email: string;
  phone: string;
  licenseNumber: string;
}

export interface UpdateDriverDto extends Partial<CreateDriverDto> {
  status?: "active" | "inactive" | "suspended";
}
```

**List Component:** `driver-list.component.ts`

```typescript
import {
  Component,
  OnInit,
  OnDestroy,
  ChangeDetectionStrategy,
} from "@angular/core";
import { Router } from "@angular/router";
import { Subject, takeUntil } from "rxjs";

import { BASE_IMPORTS, TABLE_IMPORTS } from "@shared/common-imports";
import {
  PageContainerComponent,
  DataTableComponent,
  FilterBarComponent,
  ConfirmationDialogComponent,
  TableColumn,
  TableConfig,
} from "@shared/components";
import { DateUtils, ArrayUtils } from "@shared/utils";
import { ToastService } from "@shared/services";

import { Driver } from "../../models/driver.model";
import { DriverService } from "../../services/driver.service";
import { MatDialog } from "@angular/material/dialog";

@Component({
  selector: "app-driver-list",
  standalone: true,
  imports: [
    ...BASE_IMPORTS,
    ...TABLE_IMPORTS,
    PageContainerComponent,
    DataTableComponent,
    FilterBarComponent,
  ],
  templateUrl: "./driver-list.component.html",
  styleUrl: "./driver-list.component.css",
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DriverListComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  drivers: Driver[] = [];
  displayedDrivers: Driver[] = [];
  loading = false;

  columns: TableColumn<Driver>[] = [
    { key: "name", label: "Name", sortable: true },
    { key: "email", label: "Email", sortable: true },
    { key: "phone", label: "Phone" },
    { key: "licenseNumber", label: "License" },
    {
      key: "status",
      label: "Status",
      format: (value) => value.toUpperCase(),
    },
    {
      key: "createdAt",
      label: "Created",
      sortable: true,
      format: (value) => DateUtils.format(value, "medium"),
    },
  ];

  tableConfig: TableConfig<Driver> = {
    trackByKey: "id",
    selectable: false,
  };

  breadcrumbs = [{ label: "Home", link: "/" }, { label: "Drivers" }];

  constructor(
    private driverService: DriverService,
    private toast: ToastService,
    private dialog: MatDialog,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.loadDrivers();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadDrivers(): void {
    this.loading = true;
    this.driverService
      .getAll()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (drivers) => {
          this.drivers = drivers;
          this.displayedDrivers = drivers;
          this.loading = false;
        },
        error: () => {
          this.toast.error("Failed to load drivers");
          this.loading = false;
        },
      });
  }

  onSearch(query: string): void {
    this.displayedDrivers = ArrayUtils.filterByQuery(this.drivers, query, [
      "name",
      "email",
      "phone",
      "licenseNumber",
    ]);
  }

  onRowClick(driver: Driver): void {
    this.router.navigate(["/drivers", driver.id]);
  }

  deleteDriver(driver: Driver): void {
    const dialogRef = this.dialog.open(ConfirmationDialogComponent, {
      data: {
        title: "Delete Driver",
        message: `Are you sure you want to delete ${driver.fullName}?`,
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

  private performDelete(id: number): void {
    this.driverService.delete(id).subscribe({
      next: () => {
        this.toast.success("Driver deleted");
        this.loadDrivers();
      },
      error: () => this.toast.error("Delete failed"),
    });
  }
}
```

**Form Component:** `driver-form.component.ts`

```typescript
import { Component, OnInit } from "@angular/core";
import { FormBuilder, Validators } from "@angular/forms";
import { ActivatedRoute, Router } from "@angular/router";

import { BASE_IMPORTS, FORM_IMPORTS } from "@shared/common-imports";
import { PageContainerComponent } from "@shared/components";
import { FormValidators } from "@shared/utils";
import { ToastService } from "@shared/services";

import { DriverService } from "../../services/driver.service";
import { CreateDriverDto } from "../../models/driver.model";

@Component({
  selector: "app-driver-form",
  standalone: true,
  imports: [...BASE_IMPORTS, ...FORM_IMPORTS, PageContainerComponent],
  templateUrl: "./driver-form.component.html",
  styleUrl: "./driver-form.component.css",
})
export class DriverFormComponent implements OnInit {
  isEditMode = false;
  driverId?: number;
  loading = false;

  driverForm = this.fb.group({
    name: ["", [Validators.required, Validators.minLength(3)]],
    email: ["", [Validators.required, Validators.email]],
    phone: ["", [Validators.required, FormValidators.phone()]],
    licenseNumber: ["", [Validators.required]],
  });

  constructor(
    private fb: FormBuilder,
    private driverService: DriverService,
    private toast: ToastService,
    private route: ActivatedRoute,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.driverId = Number(this.route.snapshot.paramMap.get("id"));
    if (this.driverId) {
      this.isEditMode = true;
      this.loadDriver();
    }
  }

  loadDriver(): void {
    if (!this.driverId) return;

    this.loading = true;
    this.driverService.getById(this.driverId).subscribe({
      next: (driver) => {
        this.driverForm.patchValue(driver);
        this.loading = false;
      },
      error: () => {
        this.toast.error("Failed to load driver");
        this.loading = false;
      },
    });
  }

  onSubmit(): void {
    if (this.driverForm.invalid) {
      this.driverForm.markAllAsTouched();
      return;
    }

    const dto: CreateDriverDto = this.driverForm.value as CreateDriverDto;

    if (this.isEditMode && this.driverId) {
      this.updateDriver(dto);
    } else {
      this.createDriver(dto);
    }
  }

  private createDriver(dto: CreateDriverDto): void {
    this.loading = true;
    this.driverService.create(dto).subscribe({
      next: () => {
        this.toast.success("Driver created");
        this.router.navigate(["/drivers"]);
      },
      error: () => {
        this.toast.error("Failed to create driver");
        this.loading = false;
      },
    });
  }

  private updateDriver(dto: CreateDriverDto): void {
    if (!this.driverId) return;

    this.loading = true;
    this.driverService.update(this.driverId, dto).subscribe({
      next: () => {
        this.toast.success("Driver updated");
        this.router.navigate(["/drivers"]);
      },
      error: () => {
        this.toast.error("Failed to update driver");
        this.loading = false;
      },
    });
  }

  getErrorMessage(fieldName: string): string {
    const control = this.driverForm.get(fieldName);
    return FormValidators.getErrorMessage(control?.errors, fieldName);
  }
}
```

---

## Best Practices Checklist

### Component Development

- [ ] Use standalone components (no NgModules)
- [ ] Import shared constants from `common-imports.ts`
- [ ] Implement `OnDestroy` for cleanup
- [ ] Use `takeUntil(destroy$)` for subscriptions
- [ ] Use `ChangeDetectionStrategy.OnPush`
- [ ] Add proper TypeScript typing
- [ ] Write meaningful JSDoc comments

### Service Development

- [ ] Use `providedIn: 'root'` for singletons
- [ ] Add JSDoc for public methods
- [ ] Handle errors properly
- [ ] Use `BehaviorSubject` for state management
- [ ] Type HTTP responses properly
- [ ] Cache data when appropriate

### Routing

- [ ] Use lazy loading (`loadComponent`)
- [ ] Add route guards for protected routes
- [ ] Set page titles
- [ ] Group related routes in feature files
- [ ] Use route parameters for dynamic content

### Code Quality

- [ ] Follow naming conventions
- [ ] Keep functions small and focused
- [ ] Use utility functions (DateUtils, ArrayUtils)
- [ ] Add error handling
- [ ] Use toast notifications for user feedback
- [ ] Confirm destructive actions

### Testing

- [ ] Write unit tests for services
- [ ] Test component logic
- [ ] Mock HTTP calls
- [ ] Test error scenarios

---

## 🚀 Quick Start Commands

### Create New Feature

```bash
# 1. Create feature directory structure
mkdir -p src/app/features/[feature-name]/{components,services,models}

# 2. Create route file
touch src/app/features/[feature-name]/[feature-name].routes.ts

# 3. Generate components
cd src/app/features/[feature-name]/components
ng g c [component-name] --standalone --skip-tests

# 4. Generate service
cd ../services
ng g s [service-name] --skip-tests
```

### Create Shared Component

```bash
cd src/app/shared/components
ng g c [component-name] --standalone --skip-tests
```

### Create Shared Service

```bash
cd src/app/shared/services
ng g s [service-name] --skip-tests
```

---

## 📚 Additional Resources

### Internal Documentation

- [Reusable Components Guide](./REUSABLE_COMPONENTS_QUICK_START.md)
- [Helper Utilities Guide](./HELPER_UTILITIES_GUIDE.md)
- [Copilot Instructions](./.github/copilot-instructions.md)

### External Resources

- [Angular Official Docs](https://angular.io/docs)
- [Angular Material](https://material.angular.io/)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [RxJS Documentation](https://rxjs.dev/)

---

## 🤝 Team Collaboration

### Code Review Checklist

- [ ] Code follows project structure
- [ ] Uses standalone components (not NgModules)
- [ ] Proper error handling
- [ ] Subscriptions cleaned up
- [ ] Types properly defined
- [ ] User feedback implemented (toast notifications)
- [ ] Follows naming conventions
- [ ] Comments added for complex logic

### Git Workflow

```bash
# Create feature branch
git checkout -b feat/feature-name

# Make changes and commit
git add .
git commit -m "feat: add driver management feature"

# Push and create PR
git push origin feat/feature-name
```

### Commit Message Convention

- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `style:` Code style changes
- `docs:` Documentation updates
- `test:` Test updates
- `chore:` Build/config updates

---

## 📞 Support

For questions or issues:

1. Check this documentation
2. Review existing code examples
3. Ask team lead
4. Create GitHub issue

**Document Version:** 1.0  
**Maintained By:** TMS Development Team  
**Last Review:** December 7, 2025
