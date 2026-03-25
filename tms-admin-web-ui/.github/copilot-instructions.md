# TMS Frontend (Angular) - Copilot Instructions

## Project Overview

This is the **admin/dispatcher web panel** for SV-TMS. It manages transport orders, real-time driver tracking, fleet operations, and system administration.

**Stack:** Angular 19.2.x, TypeScript 5.8.x, Angular Material, RxJS 7.8.x, STOMP/WebSocket, Google Maps, Tailwind CSS, Chart.js, Playwright E2E.

## Essential Commands

```bash
# Development (proxies /api and /ws-sockjs to http://localhost:8080)
npm ci
npm start  # http://localhost:4200

# Production build
npm run build

# Tests
npm run test              # Unit tests (Karma/Jasmine, watch mode)
npm run test:ci           # Headless with coverage
npm run test:e2e          # Playwright E2E
npm run test:e2e:smoke    # Quick smoke tests

# Code quality (husky pre-commit runs these)
npm run lint
npm run lint:fix
npm run format
```

## Architecture Essentials

**Standalone components** with feature-based lazy loading. No NgModules except for imports.

```
src/app/
├── core/                      # Singleton services, guards, interceptors
│   ├── core.providers.ts      # Central provider config (HTTP, auth, error handling)
│   ├── services/              # Logger, error handler, performance monitoring
│   └── sentry.config.ts       # Sentry integration (production only)
├── services/                  # Business logic services (auth, dispatch, driver, etc.)
├── guards/                    # AuthGuard, RoleGuard, AdminGuard
├── interceptors/              # error-tracking.interceptor, retry.interceptor
├── features/                  # Lazy-loaded feature routes (drivers, fleet, dispatch, etc.)
├── shared/                    # Reusable UI components, pipes, directives
├── models/                    # TypeScript interfaces for API contracts
├── environments/              # environment.ts (dev), environment.prod.ts (prod)
├── app.config.ts              # Root config (provideRouter + coreProviders)
└── app.routes.ts              # Route definitions with lazy loading
```

**Path aliases** (defined in `tsconfig.json`):
```typescript
import { AuthService } from '@services/auth.service';
import { Driver } from '@models/driver.model';
import { environment } from '@env/environment';
import { DriverListComponent } from '@features/drivers/driver-list.component';
import { ButtonComponent } from '@shared/components/button.component';
```

**Key patterns:**
- Services are `providedIn: 'root'` (singletons).
- Components are standalone with explicit imports.
- Use RxJS BehaviorSubjects for shared state (no NgRx).
- HTTP interceptor (`AuthInterceptor`) auto-injects JWT tokens and handles 401 refresh.
- WebSocket service (`WebSocketService`) uses STOMP over SockJS for real-time updates.

## Backend API Integration

**CRITICAL:** Use **ONLY** `/api/admin/*` and `/api/auth/*` endpoints. This is the admin panel—never use `/api/customer/*` or `/api/driver/*`.

**Development proxy:** `proxy.conf.json` forwards `/api`, `/ws-sockjs`, `/uploads` to `http://localhost:8080`. Use relative URLs in service calls:

```typescript
// Correct (proxied in dev, env.baseUrl in prod)
this.http.get('/api/admin/drivers')

// Wrong - bypasses proxy in dev
this.http.get('http://localhost:8080/api/admin/drivers')
```

### Authentication & Token Management

**AuthService** handles JWT storage and refresh. **AuthInterceptor** (`src/app/services/auth.interceptor.ts`) auto-injects `Authorization: Bearer <token>` and refreshes expired tokens:

```typescript
// Login flow stores tokens in localStorage
POST /api/auth/login → { token, refreshToken, user }

// Interceptor detects expired tokens and calls:
POST /api/auth/refresh → new token

// On 401 after refresh fails → logout and redirect to /login
```

**Key methods:**
- `authService.login(username, password)` - Stores tokens
- `authService.refreshToken()` - Called automatically by interceptor
- `authService.logout()` - Clears tokens and redirects
- `authService.isAuthenticated$` - Observable for auth state
- `authService.hasPermission('resource:action')` - Permission checks

### Permission System: `all_functions` Wildcard

The backend may grant `all_functions` permission, which acts as a **superadmin wildcard** granting all permissions.

**Check in code:**
```typescript
// src/app/services/permission-guard.service.ts
hasPermission(permission: string): boolean {
  const userPerms = this.getUserPermissions();
  return userPerms.includes('all_functions') || userPerms.includes(permission);
}

// Usage in templates
<button *ngIf="authService.hasPermission('drivers:delete')">Delete</button>
```

**Dev testing:** Login as `admin`/`superadmin` to verify `all_functions` is present in the JWT payload or user object.

## WebSocket/Real-Time Updates

**WebSocketService** (`src/app/services/websocket.service.ts`) uses STOMP over SockJS for real-time driver locations, notifications, and status updates.

**Connection flow:**
```typescript
// Connect with JWT authentication
this.webSocketService.connectSTOMP();

// Subscribe to driver locations
this.webSocketService.subscribe('/topic/driver/locations')
  .subscribe((locationUpdate: DriverLocationUpdate) => {
    this.updateDriverMarker(locationUpdate);
  });

// Subscribe to user-specific notifications
this.webSocketService.subscribe('/user/queue/notifications')
  .subscribe((notification) => {
    this.showNotification(notification);
  });
```

**Auto-reconnect:** The service handles token expiration and reconnection with exponential backoff (max 5 attempts before logout).

**Key topics:**
- `/topic/driver/locations` - All driver location updates
- `/topic/driver/{driverId}/location` - Specific driver
- `/user/queue/notifications` - User-specific notifications
- `/topic/vehicle/status` - Vehicle status changes

## Google Maps Integration

**Angular Google Maps** (`@angular/google-maps`) is used for driver tracking and route visualization.

```typescript
// Basic map setup (src/app/live-driver-dashboard/)
<google-map
  [center]="mapCenter"
  [zoom]="mapZoom"
  [options]="mapOptions">
  
  @for (driver of drivers; track driver.id) {
    <map-marker
      [position]="{ lat: driver.latitude, lng: driver.longitude }"
      [options]="getDriverMarkerOptions(driver)"
      (mapClick)="selectDriver(driver)">
    </map-marker>
  }
</google-map>
```

**Custom markers:** Driver status (online/offline/busy) determines marker icon and color. See `src/app/live-driver-dashboard/` for complete implementation.

## State Management Pattern

**No NgRx.** Use RxJS BehaviorSubjects in services for shared state:

```typescript
// Example: DriverService
@Injectable({ providedIn: 'root' })
export class DriverService {
  private driversSubject = new BehaviorSubject<Driver[]>([]);
  public drivers$ = this.driversSubject.asObservable();
  
  loadDrivers(): void {
    this.http.get<Driver[]>('/api/admin/drivers').subscribe(
      drivers => this.driversSubject.next(drivers)
    );
  }
  
  updateDriver(id: number, data: Partial<Driver>): Observable<Driver> {
    return this.http.put<Driver>(`/api/admin/drivers/${id}`, data).pipe(
      tap(updated => {
        const current = this.driversSubject.value;
        const index = current.findIndex(d => d.id === id);
        if (index !== -1) {
          current[index] = updated;
          this.driversSubject.next([...current]);
        }
      })
    );
  }
}
```

**Component subscription:**
```typescript
export class DriverListComponent implements OnInit, OnDestroy {
  drivers$ = this.driverService.drivers$;
  private destroy$ = new Subject<void>();
  
  ngOnInit() {
    this.driverService.loadDrivers();
    
    // Auto-refresh from WebSocket
    this.webSocketService.subscribe('/topic/driver/status')
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => this.driverService.loadDrivers());
  }
  
  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```

## Testing Conventions

### Unit Tests (Karma/Jasmine)

**Service tests** use `HttpTestingController`:

```typescript
describe('DispatchService', () => {
  let service: DispatchService;
  let httpMock: HttpTestingController;
  
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [DispatchService]
    });
    service = TestBed.inject(DispatchService);
    httpMock = TestBed.inject(HttpTestingController);
  });
  
  it('should fetch dispatches', () => {
    const mockData = [{ id: 1, orderReference: 'ORD-001' }];
    
    service.getDispatches().subscribe(data => {
      expect(data).toEqual(mockData);
    });
    
    const req = httpMock.expectOne('/api/admin/dispatches');
    expect(req.request.method).toBe('GET');
    req.flush(mockData);
  });
  
  afterEach(() => httpMock.verify());
});
```

**Run tests:** `npm run test:ci` (headless with coverage, used in CI).

### E2E Tests (Playwright)

**Smoke tests** (`e2e/smoke-routes.spec.ts`) verify all routes load:
```typescript
test('admin can access drivers page', async ({ page }) => {
  await page.goto('/login');
  await page.fill('input[name="username"]', 'admin');
  await page.fill('input[name="password"]', 'password');
  await page.click('button[type="submit"]');
  
  await page.goto('/drivers');
  await expect(page).toHaveURL(/.*drivers/);
  await expect(page.locator('h1')).toContainText('Drivers');
});
```

**Page objects** (`e2e/page-objects/`) encapsulate selectors and actions. Prefer using them over inline selectors in tests.

**Run smoke tests quickly:** `npm run test:e2e:smoke`

## Project-Specific Conventions

### Route Guards & Permissions

**Guards stack in routes:**
```typescript
// app.routes.ts
{
  path: 'drivers',
  canActivate: [AuthGuard, PermissionGuard],
  data: { 
    requiredPermission: 'drivers:view',
    title: 'Driver Management' 
  },
  loadChildren: () => import('./features/drivers/driver.routes')
}
```

**Permission format:** `resource:action` (e.g., `drivers:create`, `dispatches:delete`).

**Check permissions in code:**
```typescript
if (this.authService.hasPermission('drivers:delete')) {
  // Show delete button
}
```

### Error Handling

**HTTP errors** are caught by `error-tracking.interceptor.ts` and sent to Sentry in production.

**User-facing errors** use `ngx-toastr`:
```typescript
import { ToastrService } from 'ngx-toastr';

this.dispatchService.createDispatch(data).subscribe({
  next: () => this.toastr.success('Dispatch created'),
  error: (err) => this.toastr.error(err.message || 'Failed to create dispatch')
});
```

### Linting & Formatting (Pre-commit Hook)

**Husky pre-commit** (`.husky/pre-commit`) runs `npm run lint` and `npm run format --check`. Commits fail if lint errors exist.

**Fix before committing:**
```bash
npm run lint:fix
npm run format
```

## Common Workflows

### Adding a New Feature Module

1. Create feature directory: `src/app/features/my-feature/`
2. Add route file: `my-feature.routes.ts` with route definitions
3. Add route to `app.routes.ts`:
   ```typescript
   {
     path: 'my-feature',
     loadChildren: () => import('./features/my-feature/my-feature.routes')
       .then(m => m.MY_FEATURE_ROUTES)
   }
   ```
4. Create standalone components with explicit imports
5. Create service in `src/app/services/my-feature.service.ts`
6. Add E2E smoke test in `e2e/smoke-routes.spec.ts`

### Adding a New Admin API Endpoint

1. Define TypeScript interface in `src/app/models/`
2. Add service method in appropriate service (e.g., `driver.service.ts`):
   ```typescript
   createDriver(data: CreateDriverRequest): Observable<Driver> {
     return this.http.post<Driver>('/api/admin/drivers', data);
   }
   ```
3. Add unit test for service method
4. Use in component via service
5. Add E2E test if it's a critical flow

### Debugging WebSocket Issues

**Check connection status:**
```typescript
// In component
this.webSocketService.connectionState$.subscribe(state => {
  console.log('WebSocket state:', state); // CONNECTED | CONNECTING | DISCONNECTED
});
```

**Verify backend WebSocket endpoint:**
- Dev: `ws://localhost:8080/ws-sockjs`
- Prod: `wss://svtms.svtrucking.biz/ws-sockjs`

**Common issues:**
- **401 on connect:** Token expired. Check `localStorage.getItem('access_token')`.
- **Reconnect loop:** Backend not accepting connection. Check backend logs.
- **No messages:** Wrong topic subscription. Verify topic names match backend.

## Troubleshooting

**CORS errors in dev:**
- Ensure `npm start` (not `ng serve` alone)
- Check `proxy.conf.json` target is `http://localhost:8080`
- Verify backend is running on port 8080

**Maps not loading:**
- Check Google Maps API key in `src/index.html`
- Verify API key has "Maps JavaScript API" enabled

**401 errors after login:**
- Check JWT token in localStorage (`access_token`)
- Verify interceptor is registered in `core.providers.ts`
- Check token expiration (decode JWT at jwt.io)

**Build fails:**
- Run `npm ci` (respects package-lock.json)
- Clear cache: `rm -rf node_modules .angular && npm ci`
- Check for TypeScript errors: `npx tsc --noEmit`

---

**Quick reference files:**
- Backend integration: `tms-backend/.github/copilot-instructions.md`
- Umbrella docs: `.github/copilot-instructions.md` (workspace root)
- API proxy config: `proxy.conf.json`
- Environment config: `src/app/environments/environment*.ts`
- Central providers: `src/app/core/core.providers.ts`

---

## Reusable Component Toolkit

### Philosophy

This project uses a **standardized component library** for all CRUD pages following **DRY (Don't Repeat Yourself)** and **SOLID principles**. All components are standalone with shared import constants to eliminate repetitive code.

### Shared Imports System

**Location:** `src/app/shared/common-imports.ts`

Centralized import constants eliminate repetitive imports across 40+ components:

```typescript
import { BASE_IMPORTS, FORM_IMPORTS, BUTTON_IMPORTS, TABLE_IMPORTS } from '@shared/common-imports';

@Component({
  standalone: true,
  imports: [...BASE_IMPORTS, ...FORM_IMPORTS, ...BUTTON_IMPORTS]
})
export class MyComponent {}
```

**Available constants:**
- `BASE_IMPORTS` - CommonModule (required for *ngIf, *ngFor, pipes)
- `FORM_IMPORTS` - FormsModule, ReactiveFormsModule, Material form fields
- `BUTTON_IMPORTS` - Material buttons, icons, tooltips
- `TABLE_IMPORTS` - Material table, paginator, sort
- `DIALOG_IMPORTS` - Material dialog, snackbar
- `LAYOUT_IMPORTS` - Material cards, toolbar, tabs
- `LOADING_IMPORTS` - Material spinners, progress bars
- `NAV_IMPORTS` - RouterModule
- `AUTOCOMPLETE_IMPORTS` - Material autocomplete, chips
- `MENU_IMPORTS` - Material menu
- `MATERIAL_IMPORTS` - All Material modules (use sparingly)

### CRUD Component Library

**Location:** `src/app/shared/components/crud/`

Production-ready components for standardized CRUD pages:

#### PageContainerComponent

Standardized page layout wrapper with breadcrumbs, header, stats, filters, content, footer sections.

```typescript
import { PageContainerComponent, Breadcrumb } from '@shared/components/crud';

<app-page-container
  title="Drivers"
  subtitle="Manage your driver accounts"
  [breadcrumbs]="[{label: 'Dashboard', link: '/'}, {label: 'Drivers'}]"
  [showBackButton]="false"
  [showStats]="true">
  
  <div headerActions>
    <button mat-raised-button color="primary">Add Driver</button>
  </div>
  
  <div stats>
    <app-stat-card [config]="{label: 'Total', value: 150, icon: 'people'}"></app-stat-card>
    <app-stat-card [config]="{label: 'Active', value: 120, color: 'success'}"></app-stat-card>
  </div>
  
  <div filters>
    <app-filter-bar (searchChange)="onSearch($event)"></app-filter-bar>
  </div>
  
  <div content>
    <app-data-table [config]="tableConfig"></app-data-table>
  </div>
</app-page-container>
```

**Key features:**
- Content projection with named slots (headerActions, stats, filters, content, footer)
- Customizable CSS classes for all sections
- OnPush change detection for performance
- Accessibility (ARIA labels, keyboard navigation)

#### StatCardComponent

KPI display cards with trend indicators and 7 color variants.

```typescript
import { StatCardComponent, StatCardConfig } from '@shared/components/crud';

// Basic usage
<app-stat-card [config]="{
  label: 'Total Drivers',
  value: 150,
  icon: 'local_shipping',
  color: 'primary'
}"></app-stat-card>

// With trend indicator
<app-stat-card 
  [config]="{
    label: 'Active Jobs',
    value: 45,
    icon: 'assignment',
    color: 'success',
    trend: { value: 12.5, direction: 'up', label: 'vs last month' },
    clickable: true
  }"
  (cardClick)="viewJobs()">
</app-stat-card>
```

**Color variants:** `primary` (blue), `success` (green), `warning` (yellow), `danger` (red), `info` (cyan), `purple`, `gray`

**Features:**
- Trend indicators (up/down/neutral with percentage)
- Loading state overlay
- Clickable cards with hover effects
- OnPush change detection

#### DataTableComponent

Advanced data table with generic typing, sorting, selection, custom templates.

```typescript
import { DataTableComponent, TableColumn, TableConfig } from '@shared/components/crud';

// Define columns with type safety
columns: TableColumn<Driver>[] = [
  { key: 'name', label: 'Name', sortable: true },
  { key: 'email', label: 'Email', type: 'text' },
  { key: 'status', label: 'Status', template: this.statusTemplate },
  { key: 'createdAt', label: 'Created', type: 'date', sortable: true }
];

// Configure table
tableConfig: TableConfig<Driver> = {
  columns: this.columns,
  data: this.drivers,
  loading: this.isLoading,
  selectable: true,
  stickyHeader: true,
  rowClickable: true,
  trackByKey: 'id'
};

// Template
<app-data-table
  [config]="tableConfig"
  [currentSort]="{ column: 'name', direction: 'asc' }"
  [selection]="selectedDrivers"
  (sort)="onSort($event)"
  (selectionChange)="onSelectionChange($event)"
  (rowClick)="onRowClick($event)">
</app-data-table>

// Custom cell template
<ng-template #statusTemplate let-row let-column="column">
  <span [class]="row.active ? 'text-green-600' : 'text-gray-400'">
    {{ row.active ? 'Active' : 'Inactive' }}
  </span>
</ng-template>
```

**Features:**
- Generic typing for type-safe data: `DataTableComponent<Driver>`
- Column sorting (single column)
- Row selection (single/multiple)
- Custom cell templates via `TemplateRef`
- Loading/empty states
- TrackBy for performance
- Accessible (ARIA labels, keyboard navigation)

#### FilterBarComponent

Search and filter controls with debounced input.

```typescript
import { FilterBarComponent, FilterChip } from '@shared/components/crud';

// Active filters as chips
activeFilters: FilterChip[] = [
  { key: 'status', label: 'Status', value: 'Active', removable: true },
  { key: 'type', label: 'Type', value: 'Full-time', removable: true }
];

<app-filter-bar
  searchPlaceholder="Search drivers..."
  [filterChips]="activeFilters"
  [debounceTime]="300"
  (searchChange)="onSearch($event)"
  (filterRemove)="onFilterRemove($event)"
  (clearAll)="onClearFilters()">
  
  <!-- Additional filter controls via content projection -->
  <button mat-button>Advanced Filters</button>
</app-filter-bar>
```

**Features:**
- Debounced search (300ms default, customizable)
- Filter chips with remove buttons
- Clear all filters button
- Content projection for custom filter controls
- OnDestroy cleanup with takeUntil pattern

### Best Practices

**Component Development:**
- Use `ChangeDetectionStrategy.OnPush` for performance
- Provide default values for `@Input()` properties
- Use `TrackByFunction` in `*ngFor` loops
- Implement `OnDestroy` with `takeUntil(destroy$)` for cleanup
- Prefer async pipe over manual subscriptions
- Provide ARIA labels for accessibility
- Support keyboard navigation (Enter/Space)
- Show loading/empty/error states

**Code Quality:**
- Follow Single Responsibility Principle
- Keep components under 300 lines
- Use interfaces for complex `@Input()` types
- Write JSDoc comments for public APIs
- Extract magic numbers to constants
- Use TypeScript strict mode (avoid `any`)

**Performance:**
- Lazy load feature modules via routes
- Use virtual scrolling for 100+ items (`@angular/cdk/scrolling`)
- Debounce search inputs (300ms)
- Cache API responses when appropriate
- Unsubscribe in `ngOnDestroy` (use `takeUntil`)

**Common Patterns:**

```typescript
// Loading state with finalize
isLoading = signal(false);

loadData() {
  this.isLoading.set(true);
  this.service.getData().pipe(
    finalize(() => this.isLoading.set(false))
  ).subscribe(data => this.data.set(data));
}

// Subscription cleanup
private destroy$ = new Subject<void>();

ngOnInit() {
  this.service.data$
    .pipe(takeUntil(this.destroy$))
    .subscribe(data => this.handleData(data));
}

ngOnDestroy() {
  this.destroy$.next();
  this.destroy$.complete();
}

// Form validation
form = this.fb.group({
  name: ['', [Validators.required, Validators.minLength(3)]],
  email: ['', [Validators.required, Validators.email]]
});

get nameError(): string {
  const control = this.form.get('name');
  if (control?.hasError('required')) return 'Name is required';
  if (control?.hasError('minlength')) return 'Min 3 characters';
  return '';
}
```

### Usage Example - Complete CRUD Page

```typescript
import { Component, OnInit, signal } from '@angular/core';
import { BASE_IMPORTS, FORM_IMPORTS, BUTTON_IMPORTS } from '@shared/common-imports';
import { 
  PageContainerComponent, 
  StatCardComponent, 
  DataTableComponent, 
  FilterBarComponent,
  TableColumn,
  FilterChip 
} from '@shared/components/crud';
import { DriverService } from '@services/driver.service';
import { Driver } from '@models/driver.model';

@Component({
  standalone: true,
  imports: [
    ...BASE_IMPORTS,
    ...FORM_IMPORTS,
    ...BUTTON_IMPORTS,
    PageContainerComponent,
    StatCardComponent,
    DataTableComponent,
    FilterBarComponent
  ]
})
export class DriversListComponent implements OnInit {
  drivers = signal<Driver[]>([]);
  isLoading = signal(false);
  totalCount = signal(0);
  activeCount = signal(0);
  
  columns: TableColumn<Driver>[] = [
    { key: 'name', label: 'Name', sortable: true },
    { key: 'email', label: 'Email', type: 'text' },
    { key: 'status', label: 'Status', sortable: true }
  ];
  
  constructor(private driverService: DriverService) {}
  
  ngOnInit() {
    this.loadDrivers();
  }
  
  loadDrivers() {
    this.isLoading.set(true);
    this.driverService.getAll().pipe(
      finalize(() => this.isLoading.set(false))
    ).subscribe(drivers => {
      this.drivers.set(drivers);
      this.totalCount.set(drivers.length);
      this.activeCount.set(drivers.filter(d => d.active).length);
    });
  }
}
```
