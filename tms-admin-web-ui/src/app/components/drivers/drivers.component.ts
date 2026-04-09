/* eslint-disable @typescript-eslint/consistent-type-imports */
import { ScrollingModule } from '@angular/cdk/scrolling';
import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy } from '@angular/core';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component } from '@angular/core';
import { FormsModule, FormControl, ReactiveFormsModule } from '@angular/forms';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSliderModule } from '@angular/material/slider';
import { Router, ActivatedRoute } from '@angular/router';
import type { Observable } from 'rxjs';
import { forkJoin, Subject, from } from 'rxjs';
import {
  map,
  startWith,
  debounceTime,
  distinctUntilChanged,
  takeUntil,
  mergeMap,
  toArray,
} from 'rxjs/operators';

import type { Driver, DriverCreateDto, VehicleTypeEnum } from '../../models/driver.model';
import { mapToDriverCreateDto } from '../../models/driver.model';
import type { Vehicle } from '../../models/vehicle.model';
import { AdminNotificationService } from '../../services/admin-notification.service';
import { ConfirmService } from '../../services/confirm.service';
import { InputPromptService } from '../../core/input-prompt.service';
import { DriverFormValidators } from '../../services/driver-form-validators';
import { DriverService } from '../../services/driver.service';
import type { DriverFilter } from '../../services/driver.service';
import { PermissionGuardService } from '../../services/permission-guard.service';
import { PERMISSIONS } from '../../shared/permissions';

type ActivityFilter = 'all' | 'active' | 'inactive';
type AccountFilter = 'any' | 'with' | 'without';

interface FilterState {
  query: string;
  activity: ActivityFilter;
  driverStatuses: string[];
  vehicleType: VehicleTypeEnum | '';
  zone: string;
  account: AccountFilter;
  minRating?: number;
  maxRating?: number;
  licensePlate?: string;
}

interface SavedFilter {
  id: string;
  name: string;
  filters: FilterState;
}

interface DriverSummary {
  total: number;
  active: number;
  inactive: number;
  withAccount: number;
  withoutAccount: number;
}

const DRIVER_STATUS_OPTIONS = [
  { value: 'ON_TRIP', label: 'On Trip' },
  { value: 'BUSY', label: 'Busy' },
  { value: 'IDLE', label: 'Idle' },
  { value: 'OFFLINE', label: 'Offline' },
];

const VEHICLE_TYPE_OPTIONS: { value: VehicleTypeEnum; label: string }[] = [
  { value: 'TRUCK', label: 'Truck' },
  { value: 'VAN', label: 'Van' },
  { value: 'BIKE', label: 'Bike' },
];

@Component({
  selector: 'app-drivers',
  standalone: true,
  templateUrl: './drivers.component.html',
  styleUrls: ['./drivers.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatAutocompleteModule,
    MatIconModule,
    MatButtonModule,
    MatProgressSpinnerModule,
    MatSliderModule,
    ScrollingModule,
  ],
})
export class DriversComponent implements OnInit, OnDestroy {
  private readonly FILTER_STORAGE_KEY = 'svtms.drivers.filters.v1';
  private readonly PRESET_STORAGE_KEY = 'svtms.drivers.filter-presets.v1';

  // Data
  private allDrivers: Driver[] = [];
  drivers: Driver[] = [];
  vehicles: Vehicle[] = [];

  // Filters
  filters: FilterState = {
    query: '',
    activity: 'all',
    driverStatuses: [],
    vehicleType: '',
    zone: '',
    account: 'any',
    licensePlate: '',
  };
  savedFilters: SavedFilter[] = [];
  selectedPresetId = '';

  zones: string[] = [];
  summary: DriverSummary = {
    total: 0,
    active: 0,
    inactive: 0,
    withAccount: 0,
    withoutAccount: 0,
  };

  driverStatusOptions = DRIVER_STATUS_OPTIONS;
  vehicleTypeOptions = VEHICLE_TYPE_OPTIONS;

  // Pagination
  currentPage = 0;
  pageSize = 10;
  totalPages = 0;
  jumpToPageInput = '';

  isLoadingDrivers = false;
  isSaving = false;
  errorMessage = '';

  // Vehicle autocomplete state
  vehicleCtrl = new FormControl<string | Vehicle>('');
  filteredVehicles$!: Observable<Vehicle[]>;
  selectedVehicle?: Vehicle;
  selectedVehicleId: number | null = null;

  // Modal state
  isModalOpen = false;
  isCreateAccountModalOpen = false;
  isEditing = false;
  dropdownOpen: number | null = null;
  formErrors: Record<string, string> = {};

  selectedDriver: Driver = this.getDefaultDriver();
  newAccount: any = this.getDefaultAccount();

  // Selection & bulk actions
  selectedIds: number[] = [];
  bulkMode = false;

  // Messaging
  showMessageModal = false;
  messageContent = '';
  selectedTitle = '';

  // Debug logs
  debugLogs: string[] = [];

  // Cleanup
  private destroy$ = new Subject<void>();
  private searchSubject$ = new Subject<string>();

  // Math reference for template
  Math = Math;
  Object = Object;

  // Permission getters for template
  get canManageDrivers(): boolean {
    return this.permissionService.hasPermission(PERMISSIONS.DRIVER_MANAGE);
  }

  get canViewDrivers(): boolean {
    return (
      this.permissionService.hasPermission(PERMISSIONS.DRIVER_VIEW_ALL) ||
      this.permissionService.hasPermission(PERMISSIONS.DRIVER_READ)
    );
  }

  get canCreateDrivers(): boolean {
    return this.permissionService.hasPermission(PERMISSIONS.DRIVER_CREATE);
  }

  get canManageDriverAccounts(): boolean {
    return this.permissionService.hasPermission(PERMISSIONS.DRIVER_ACCOUNT_MANAGE);
  }

  constructor(
    private readonly driverService: DriverService,
    private readonly router: Router,
    private readonly route: ActivatedRoute,
    private readonly adminNotificationService: AdminNotificationService,
    private readonly permissionService: PermissionGuardService,
    private readonly confirm: ConfirmService,
    private readonly cdr: ChangeDetectorRef,
    private readonly inputPrompt: InputPromptService,
  ) {}

  ngOnInit(): void {
    this.restoreSavedFilters();
    this.restoreLastFilters();
    this.loadDrivers();
    this.loadVehicles();

    // Check if route data indicates we should open create modal
    const action = this.route.snapshot.data['action'];
    const currentUrl = this.router.url || '';
    const isAddPath = /\/add($|\/|\?)/.test(currentUrl);
    // Do not auto-open modal when URL already points to the dedicated create page
    if (action === 'create' && !isAddPath) {
      setTimeout(() => this.openDriverModal(), 100);
    }

    // Setup debounced search
    this.searchSubject$
      .pipe(debounceTime(300), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe(() => {
        this.currentPage = 0;
        this.persistFilters();
        this.loadDrivers();
      });

    this.filteredVehicles$ = this.vehicleCtrl.valueChanges.pipe(
      startWith(''),
      map((value) => {
        const query = (
          typeof value === 'string' ? value : (this.vehiclePlate(value as Vehicle) ?? '')
        )
          .trim()
          .toLowerCase();

        if (!query) return this.vehicles;
        return this.vehicles.filter((v) =>
          [
            this.vehiclePlate(v),
            this.vehicleModel(v),
            this.vehicleTypeLabel(v),
            this.vehicleStatus(v),
          ]
            .join(' ')
            .toLowerCase()
            .includes(query),
        );
      }),
    );
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private restoreLastFilters(): void {
    try {
      const saved = localStorage.getItem(this.FILTER_STORAGE_KEY);
      if (!saved) return;
      const parsed = JSON.parse(saved) as Partial<FilterState>;
      this.filters = {
        ...this.filters,
        ...parsed,
        driverStatuses: Array.isArray(parsed.driverStatuses) ? parsed.driverStatuses : [],
      };
    } catch (error) {
      console.warn('[DriversComponent] Failed to restore filters', error);
    }
  }

  private restoreSavedFilters(): void {
    try {
      const saved = localStorage.getItem(this.PRESET_STORAGE_KEY);
      if (!saved) return;
      const parsed = JSON.parse(saved) as SavedFilter[];
      this.savedFilters = Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      console.warn('[DriversComponent] Failed to restore presets', error);
    }
  }

  private persistFilters(): void {
    localStorage.setItem(this.FILTER_STORAGE_KEY, JSON.stringify(this.filters));
  }

  private persistSavedFilters(): void {
    localStorage.setItem(this.PRESET_STORAGE_KEY, JSON.stringify(this.savedFilters));
  }

  private buildServiceFilters(): DriverFilter {
    const payload: DriverFilter = {};
    const query = this.filters.query.trim();
    if (query) payload.query = query;

    if (this.filters.activity === 'active') payload.isActive = true;
    if (this.filters.activity === 'inactive') payload.isActive = false;

    if (this.filters.vehicleType) payload.vehicleType = this.filters.vehicleType;
    if (this.filters.zone) payload.zone = this.filters.zone;

    if (this.filters.driverStatuses.length === 1) {
      payload.status = this.filters.driverStatuses[0];
    } else if (this.filters.driverStatuses.length === 0) {
      payload.status = undefined;
    }

    if (this.filters.minRating !== undefined) payload.minRating = this.filters.minRating;
    if (this.filters.maxRating !== undefined) payload.maxRating = this.filters.maxRating;

    return payload;
  }

  private applyLocalFilters(list: Driver[]): Driver[] {
    let output = [...list];

    if (this.filters.driverStatuses.length > 0) {
      const statuses = new Set(this.filters.driverStatuses);
      output = output.filter((driver) => {
        const normalized = (driver.status || '').toUpperCase().replace(/[\s-]+/g, '_');
        return statuses.has(normalized);
      });
    }

    if (this.filters.vehicleType) {
      output = output.filter((driver) => driver.vehicleType === this.filters.vehicleType);
    }

    if (this.filters.zone) {
      output = output.filter((driver) => driver.zone === this.filters.zone);
    }

    if (this.filters.account === 'with') {
      output = output.filter((driver) => !!driver.user?.id);
    } else if (this.filters.account === 'without') {
      output = output.filter((driver) => !driver.user?.id);
    }

    return output;
  }

  private computeSummary(list: Driver[]): DriverSummary {
    const active = list.filter((driver) => driver.isActive).length;
    const withAccount = list.filter((driver) => !!driver.user?.id).length;

    return {
      total: list.length,
      active,
      inactive: list.length - active,
      withAccount,
      withoutAccount: list.length - withAccount,
    };
  }

  private updateZones(list: Driver[]): void {
    this.zones = Array.from(
      new Set(list.map((driver) => driver.zone).filter((zone): zone is string => !!zone?.trim())),
    ).sort((a, b) => a.localeCompare(b));
  }

  loadDrivers(): void {
    this.isLoadingDrivers = true;
    this.errorMessage = '';
    this.cdr.detectChanges();

    this.driverService
      .getAdvancedDrivers(this.currentPage, this.pageSize, this.buildServiceFilters())
      .subscribe({
        next: (response: any) => {
          const page = response?.data;
          this.allDrivers = page?.content ?? [];
          this.totalPages = page?.totalPages ?? 1;
          this.summary = this.computeSummary(this.allDrivers);
          this.updateZones(this.allDrivers);
          this.drivers = this.applyLocalFilters(this.allDrivers);
          this.reconcileSelection();
          this.cdr.detectChanges();
        },
        error: (error: any) => {
          console.error('Error loading drivers:', error);
          this.errorMessage = 'Failed to load drivers. Please try again.';
          this.cdr.detectChanges();
        },
        complete: () => {
          this.isLoadingDrivers = false;
          this.cdr.detectChanges();
        },
      });
  }

  loadVehicles(): void {
    this.driverService.getAllVehicles().subscribe({
      next: (res: any) => {
        this.vehicles = res?.data ?? [];
        // trigger autocomplete refresh
        this.vehicleCtrl.setValue(this.vehicleCtrl.value ?? '');
        this.cdr.detectChanges();
      },
      error: (err: any) => console.error('Error loading vehicles:', err),
    });
  }

  onSearchChange(): void {
    this.searchSubject$.next(this.filters.query);
  }

  setActivityFilter(activity: ActivityFilter): void {
    this.filters.activity = activity;
    this.persistFilters();
    this.currentPage = 0;
    this.loadDrivers();
  }

  toggleStatusFilter(value: string): void {
    const set = new Set(this.filters.driverStatuses);
    if (set.has(value)) set.delete(value);
    else set.add(value);
    this.filters.driverStatuses = Array.from(set);
    this.persistFilters();
    this.loadDrivers();
  }

  applyFilters(): void {
    this.currentPage = 0;
    this.persistFilters();
    this.loadDrivers();
  }

  clearFilters(): void {
    this.filters = {
      query: '',
      activity: 'all',
      driverStatuses: [],
      vehicleType: '',
      zone: '',
      account: 'any',
      minRating: undefined,
      maxRating: undefined,
    };
    this.selectedPresetId = '';
    this.persistFilters();
    this.currentPage = 0;
    this.loadDrivers();
  }

  async saveCurrentFilters(): Promise<void> {
    const name = await this.inputPrompt.prompt('Name this driver filter preset:');
    if (!name || !name.trim()) return;
    const preset: SavedFilter = {
      id: `${Date.now()}`,
      name: name.trim(),
      filters: JSON.parse(JSON.stringify(this.filters)),
    };
    this.savedFilters = [...this.savedFilters, preset];
    this.selectedPresetId = preset.id;
    this.persistSavedFilters();
  }

  onPresetChange(): void {
    if (!this.selectedPresetId) return;
    const preset = this.savedFilters.find((p) => p.id === this.selectedPresetId);
    if (!preset) return;
    this.filters = JSON.parse(JSON.stringify(preset.filters));
    this.persistFilters();
    this.currentPage = 0;
    this.loadDrivers();
  }

  async deleteCurrentPreset(): Promise<void> {
    if (!this.selectedPresetId) return;
    const preset = this.savedFilters.find((p) => p.id === this.selectedPresetId);
    if (!preset) return;
    const ok = await this.confirm.confirm(`Delete saved filter "${preset.name}"?`);
    if (!ok) return;
    this.savedFilters = this.savedFilters.filter((p) => p.id !== preset.id);
    this.selectedPresetId = '';
    this.persistSavedFilters();
  }

  private reconcileSelection(): void {
    const currentIds = new Set(this.drivers.map((driver) => driver.id));
    this.selectedIds = this.selectedIds.filter((id) => currentIds.has(id));
  }

  toggleDriverSelection(id: number): void {
    if (this.selectedIds.includes(id)) {
      this.selectedIds = this.selectedIds.filter((value) => value !== id);
    } else {
      this.selectedIds = [...this.selectedIds, id];
    }
  }

  isDriverSelected(id: number): boolean {
    return this.selectedIds.includes(id);
  }

  toggleSelectAllOnPage(event: Event): void {
    const checked = (event.target as HTMLInputElement).checked;
    if (checked) {
      this.selectedIds = this.drivers.map((driver) => driver.id);
    } else {
      this.selectedIds = [];
    }
  }

  selectionSummary(): string {
    if (!this.selectedIds.length) return 'No drivers selected';
    return `${this.selectedIds.length} selected`;
  }

  clearSelection(): void {
    this.selectedIds = [];
  }

  trackByDriver = (_: number, driver: Driver) => driver.id;

  // ─── Vehicle helpers ────────────────────────────────────────────────────────

  vehiclePlate(vehicle: Vehicle): string {
    const ref: any = vehicle;
    return (
      ref.plate ??
      ref.plateNumber ??
      ref.licensePlate ??
      ref.registrationNumber ??
      ref.registrationPlate ??
      ref.vehiclePlate ??
      ''
    );
  }

  vehicleModel(vehicle: Vehicle): string {
    const ref: any = vehicle;
    return ref.model ?? ref.vehicleModel ?? ref.modelName ?? '';
  }

  vehicleTypeLabel(vehicle: Vehicle): string {
    const ref: any = vehicle;
    return ref.type ?? ref.vehicleType ?? '';
  }

  vehicleStatus(vehicle: Vehicle): string {
    const ref: any = vehicle;
    return ref.status ?? ref.vehicleStatus ?? '';
  }

  displayVehicle = (value?: Vehicle | string): string => {
    if (typeof value === 'string') return value;
    if (!value) return '';
    const plate = this.vehiclePlate(value);
    const model = this.vehicleModel(value);
    return `${plate}${model ? ` • ${model}` : ''}`.trim();
  };

  trackVehicle = (_: number, vehicle: Vehicle) => vehicle.id;

  onVehicleSelected(vehicle: Vehicle): void {
    this.selectedVehicle = vehicle;
    this.selectedVehicleId = vehicle?.id ?? null;
  }

  // ─── CRUD Actions ───────────────────────────────────────────────────────────

  private getDefaultDriver(): Driver {
    return {
      id: 0,
      name: '',
      firstName: '',
      lastName: '',
      licenseNumber: '',
      phone: '',
      rating: 5,
      isActive: true,
      logs: [],
      updatedFromSocket: false,
      selected: false,
      countryCode: 'KH', // Default to Cambodia for new drivers
    } as Driver;
  }

  private getDefaultAccount() {
    return {
      email: '',
      username: '',
      password: '',
      roles: ['DRIVER'],
    };
  }

  /**
   * Validate driver form before submission
   * Uses advanced DriverFormValidators for multi-country support
   */
  validateDriverForm(): boolean {
    this.formErrors = {};

    // First name validation
    const firstNameResult = DriverFormValidators.validateFirstName(
      this.selectedDriver.firstName || '',
    );
    if (!firstNameResult.isValid) {
      this.formErrors['firstName'] = firstNameResult.message || 'Invalid first name';
    }

    // Last name validation
    const lastNameResult = DriverFormValidators.validateLastName(
      this.selectedDriver.lastName || '',
    );
    if (!lastNameResult.isValid) {
      this.formErrors['lastName'] = lastNameResult.message || 'Invalid last name';
    }

    // Phone validation - get country code or default to Cambodia
    const countryCode = (this.selectedDriver as any).countryCode || 'KH';
    const phoneResult = DriverFormValidators.validatePhone(
      this.selectedDriver.phone || '',
      countryCode,
    );
    if (!phoneResult.isValid) {
      this.formErrors['phone'] = phoneResult.message || 'Invalid phone number';
    }

    // National ID validation - ONLY required when editing existing driver
    if (this.isEditing && this.selectedDriver.licenseNumber) {
      const nationalIdResult = DriverFormValidators.validateNationalId(
        this.selectedDriver.licenseNumber || '',
        countryCode,
      );
      if (!nationalIdResult.isValid) {
        this.formErrors['licenseNumber'] = nationalIdResult.message || 'Invalid National ID';
      }
    }

    // Rating validation
    if (this.selectedDriver.rating) {
      const ratingResult = DriverFormValidators.validateRating(this.selectedDriver.rating);
      if (!ratingResult.isValid) {
        this.formErrors['rating'] = ratingResult.message || 'Rating must be between 1 and 5';
      }
    }

    return Object.keys(this.formErrors).length === 0;
  }

  /**
   * Check if a form field has an error
   */
  hasFieldError(field: string): boolean {
    return !!this.formErrors[field];
  }

  /**
   * Get error message for a form field
   */
  getFieldError(field: string): string {
    return this.formErrors[field] || '';
  }

  /**
   * Validate a single field in real-time
   */
  validateSingleField(field: string): void {
    const countryCode = (this.selectedDriver as any).countryCode || 'US';

    switch (field) {
      case 'firstName':
        const firstNameResult = DriverFormValidators.validateFirstName(
          this.selectedDriver.firstName || '',
        );
        if (!firstNameResult.isValid) {
          this.formErrors['firstName'] = firstNameResult.message || 'Invalid first name';
        } else {
          delete this.formErrors['firstName'];
        }
        break;

      case 'lastName':
        const lastNameResult = DriverFormValidators.validateLastName(
          this.selectedDriver.lastName || '',
        );
        if (!lastNameResult.isValid) {
          this.formErrors['lastName'] = lastNameResult.message || 'Invalid last name';
        } else {
          delete this.formErrors['lastName'];
        }
        break;

      case 'phone':
        const phoneResult = DriverFormValidators.validatePhone(
          this.selectedDriver.phone || '',
          countryCode,
        );
        if (!phoneResult.isValid) {
          this.formErrors['phone'] = phoneResult.message || 'Invalid phone number';
        } else {
          delete this.formErrors['phone'];
        }
        break;

      case 'licenseNumber':
        const nationalIdResult = DriverFormValidators.validateNationalId(
          this.selectedDriver.licenseNumber || '',
          countryCode,
        );
        if (!nationalIdResult.isValid) {
          this.formErrors['licenseNumber'] = nationalIdResult.message || 'Invalid National ID';
        } else {
          delete this.formErrors['licenseNumber'];
        }
        break;

      case 'rating':
        const ratingResult = DriverFormValidators.validateRating(this.selectedDriver.rating || 0);
        if (!ratingResult.isValid) {
          this.formErrors['rating'] = ratingResult.message || 'Rating must be between 1 and 5';
        } else {
          delete this.formErrors['rating'];
        }
        break;

      case 'email':
        const emailResult = DriverFormValidators.validateEmail(
          (this.selectedDriver as any).email || '',
        );
        if (!emailResult.isValid) {
          this.formErrors['email'] = emailResult.message || 'Invalid email address';
        } else {
          delete this.formErrors['email'];
        }
        break;
    }
  }

  openDriverModal(driver?: Driver): void {
    // If no driver provided, navigate to dedicated create page instead of opening modal
    if (!driver) {
      // navigate to absolute create-driver page to avoid relative path append
      this.router.navigate(['/drivers', 'add']);
      return;
    }

    this.isEditing = !!driver;
    this.selectedDriver = driver ? { ...driver } : this.getDefaultDriver();
    this.dropdownOpen = null;
    this.isModalOpen = true;
    // accessibility: focus the first input in the modal after it opens
    setTimeout(() => {
      const el = document.getElementById('driver-modal-first-input') as HTMLElement | null;
      if (el) el.focus();
    }, 50);
  }

  closeModal(): void {
    this.isModalOpen = false;
    this.selectedDriver = this.getDefaultDriver();
    this.selectedVehicleId = null;
    this.vehicleCtrl.setValue('');
    this.selectedVehicle = undefined;
    this.formErrors = {};
  }

  addDriver(): void {
    // Check permissions first
    if (!this.canManageDrivers) {
      this.driverService.showToast(
        'You do not have permission to create drivers. Contact your administrator.',
        'Close',
        5000,
      );
      return;
    }

    // Prevent duplicate submits
    if (this.isSaving) return;
    // Validate form
    if (!this.validateDriverForm()) {
      return;
    }

    this.isSaving = true;
    const payload: DriverCreateDto = mapToDriverCreateDto(this.selectedDriver as any);
    this.driverService.addDriver(payload).subscribe({
      next: () => {
        this.loadDrivers();
        this.closeModal();
      },
      error: (err: any) => {
        console.error('Error adding driver:', err);
        if (err.status === 403) {
          this.driverService.showToast(
            'Permission denied: You cannot create drivers. Contact your administrator.',
            'Close',
            5000,
          );
        } else {
          this.driverService.showToast('Failed to add driver. Please try again.');
        }
      },
      complete: () => {
        this.isSaving = false;
      },
    });
  }

  updateDriver(): void {
    // Check permissions first
    if (!this.canManageDrivers) {
      this.driverService.showToast(
        'You do not have permission to update drivers. Contact your administrator.',
        'Close',
        5000,
      );
      return;
    }

    // Prevent duplicate submits
    if (this.isSaving) return;
    // Validate form
    if (!this.validateDriverForm()) {
      return;
    }

    this.isSaving = true;
    const payload = this.cleanPayload(this.selectedDriver);
    this.driverService.updateDriver(this.selectedDriver.id, payload).subscribe({
      next: () => {
        this.loadDrivers();
        this.closeModal();
      },
      error: (err: any) => {
        console.error('Error updating driver:', err);
        if (err.status === 403) {
          this.driverService.showToast(
            'Permission denied: You cannot update drivers. Contact your administrator.',
            'Close',
            5000,
          );
        } else {
          this.driverService.showToast('Failed to update driver. Please try again.');
        }
      },
      complete: () => {
        this.isSaving = false;
      },
    });
  }

  /**
   * Validate driver form inputs
   */

  async deleteDriver(id: number): Promise<void> {
    // Check permissions first
    if (!this.canManageDrivers) {
      this.driverService.showToast(
        'You do not have permission to delete drivers. Contact your administrator.',
        'Close',
        5000,
      );
      return;
    }

    const ok = await this.confirm.confirm('Delete this driver?');
    if (!ok) return;
    this.driverService.deleteDriver(id).subscribe({
      next: () => {
        this.dropdownOpen = null;
        this.loadDrivers();
      },
      error: (err: any) => {
        console.error('Error deleting driver:', err);
        if (err.status === 403) {
          this.driverService.showToast(
            'Permission denied: You cannot delete drivers. Contact your administrator.',
            'Close',
            5000,
          );
        } else {
          this.driverService.showToast('Failed to delete driver. Please try again.');
        }
      },
    });
  }

  viewDriver(driver: Driver): void {
    if (driver?.id) {
      this.router.navigate(['/drivers', driver.id]);
    } else {
      this.driverService.showToast('Selected driver has no ID');
    }
    this.dropdownOpen = null;
  }

  assignVehicle(driverId: number): void {
    // Check permissions first
    if (!this.canManageDrivers) {
      this.driverService.showToast(
        'You do not have permission to assign vehicles. Contact your administrator.',
        'Close',
        5000,
      );
      return;
    }

    if (!this.selectedVehicleId && this.selectedVehicle?.id) {
      this.selectedVehicleId = this.selectedVehicle.id;
    }
    if (!this.selectedVehicleId) {
      this.driverService.showToast('Please select a vehicle to assign.');
      return;
    }

    this.driverService.assignDriverToVehicle(driverId, this.selectedVehicleId).subscribe({
      next: () => {
        this.loadDrivers();
        this.selectedVehicleId = null;
      },
      error: (err: any) => {
        console.error('Assignment failed:', err);
        if (err.status === 403) {
          this.driverService.showToast(
            'Permission denied: You cannot assign vehicles. Contact your administrator.',
            'Close',
            5000,
          );
        } else {
          this.driverService.showToast('Failed to assign vehicle. Please try again.');
        }
      },
    });

    this.dropdownOpen = null;
  }

  openCreateAccountModal(driver: Driver): void {
    this.selectedDriver = driver;
    this.newAccount = this.getDefaultAccount();
    this.isCreateAccountModalOpen = true;
    this.dropdownOpen = null;
  }

  closeCreateAccountModal(): void {
    this.isCreateAccountModalOpen = false;
  }

  createDriverAccount(): void {
    if (!this.selectedDriver?.id) {
      this.driverService.showToast('No driver selected!');
      return;
    }

    if (!Array.isArray(this.newAccount.roles) || !this.newAccount.roles.length) {
      this.newAccount.roles = ['DRIVER'];
    }

    this.driverService.addDriverAccount(this.newAccount, this.selectedDriver.id).subscribe({
      next: () => {
        this.driverService.showToast('Driver account created successfully!');
        this.closeCreateAccountModal();
      },
      error: (err: any) => {
        console.error('Error creating account:', err);
        this.driverService.showToast(
          `Failed to create account: ${err.error?.error || 'Unknown error'}`,
        );
      },
    });
  }

  private cleanPayload(driver: Driver): any {
    const cleaned: any = {};
    Object.keys(driver).forEach((key) => {
      const value = (driver as any)[key];
      if (value !== null && value !== undefined) cleaned[key] = value;
    });

    if (!cleaned.name && (cleaned.firstName || cleaned.lastName)) {
      cleaned.name = `${cleaned.firstName || ''} ${cleaned.lastName || ''}`.trim();
    }

    return cleaned;
  }

  // ─── Messaging ──────────────────────────────────────────────────────────────

  sendMessage(driver: Driver): void {
    this.bulkMode = false;
    this.selectedDriver = driver;
    this.selectedTitle = '';
    this.messageContent = '';
    this.showMessageModal = true;
  }

  sendMessageToSelected(): void {
    if (!this.selectedIds.length) return;
    this.bulkMode = true;
    this.selectedDriver = this.drivers.find((d) => d.id === this.selectedIds[0])!;
    this.selectedTitle = '';
    this.messageContent = '';
    this.showMessageModal = true;
  }

  closeMessageModal(): void {
    this.showMessageModal = false;
    this.messageContent = '';
    this.selectedTitle = '';
    this.bulkMode = false;
  }

  submitMessage(): void {
    const title = this.selectedTitle.trim();
    const body = this.messageContent.trim();
    if (!title) {
      this.driverService.showToast('Please select a message title.');
      return;
    }
    if (!body) {
      this.driverService.showToast('Please enter a message.');
      return;
    }

    const recipients = this.bulkMode
      ? this.selectedIds
      : this.selectedDriver?.id
        ? [this.selectedDriver.id]
        : [];

    if (!recipients.length) {
      this.driverService.showToast('No driver selected.');
      return;
    }
    // Send notifications with limited concurrency to avoid overloading backend
    from(recipients)
      .pipe(
        mergeMap(
          (driverId) =>
            this.adminNotificationService.sendNotificationToDriver({
              driverId,
              title,
              message: body,
              type: 'admin',
              severity: 'info',
              sender: 'ADMIN_UI',
            }),
          6,
        ),
        toArray(),
        takeUntil(this.destroy$),
      )
      .subscribe({
        next: (results: any[]) => {
          this.logDebug(
            `Message sent to ${recipients.length} driver${recipients.length > 1 ? 's' : ''}`,
          );
          this.driverService.showToast('Message dispatched.');
          this.closeMessageModal();
        },
        error: (err: any) => {
          console.error('Error sending message:', err);
          this.driverService.showToast('Failed to send message. Please try again.');
        },
      });
  }

  // ─── UI Helpers ─────────────────────────────────────────────────────────────

  toggleDropdown(id: number): void {
    this.dropdownOpen = this.dropdownOpen === id ? null : id;
  }

  goToPreviousPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.loadDrivers();
    }
  }

  goToNextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.loadDrivers();
    }
  }

  jumpToPage(pageNumber: number): void {
    const page = parseInt(String(pageNumber), 10);
    if (!isNaN(page) && page > 0 && page <= this.totalPages) {
      this.currentPage = page - 1;
      this.jumpToPageInput = '';
      this.loadDrivers();
    } else {
      this.driverService.showToast(`Please enter a page number between 1 and ${this.totalPages}`);
    }
  }

  logDebug(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    this.debugLogs.unshift(`[${timestamp}] ${message}`);
    if (this.debugLogs.length > 10) this.debugLogs.pop();
  }

  // ─── Quick Filter Helpers ───────────────────────────────────────────────────

  /**
   * Apply a quick filter preset (e.g., "Active Drivers", "Needs Account", "No Vehicle")
   */
  applyQuickFilter(
    preset: 'active' | 'inactive' | 'with-account' | 'without-account' | 'on-trip',
  ): void {
    this.currentPage = 0;
    this.selectedPresetId = '';

    switch (preset) {
      case 'active':
        this.filters = {
          ...this.filters,
          activity: 'active',
          driverStatuses: [],
        };
        break;
      case 'inactive':
        this.filters = {
          ...this.filters,
          activity: 'inactive',
          driverStatuses: [],
        };
        break;
      case 'with-account':
        this.filters = {
          ...this.filters,
          activity: 'all',
          account: 'with',
          driverStatuses: [],
        };
        break;
      case 'without-account':
        this.filters = {
          ...this.filters,
          activity: 'all',
          account: 'without',
          driverStatuses: [],
        };
        break;
      case 'on-trip':
        this.filters = {
          ...this.filters,
          activity: 'all',
          driverStatuses: ['ON_TRIP'],
        };
        break;
    }

    this.persistFilters();
    this.loadDrivers();
  }

  /**
   * Count how many filters are currently active
   */
  getActiveFilterCount(): number {
    let count = 0;
    if (this.filters.query.trim()) count++;
    if (this.filters.activity !== 'all') count++;
    if (this.filters.driverStatuses.length > 0) count++;
    if (this.filters.vehicleType) count++;
    if (this.filters.zone) count++;
    if (this.filters.account !== 'any') count++;
    if (this.filters.minRating !== undefined || this.filters.maxRating !== undefined) count++;
    return count;
  }

  /**
   * Get filter summary for display
   */
  getFilterSummary(): string {
    const parts: string[] = [];
    if (this.filters.query.trim()) parts.push(`Search: "${this.filters.query}"`);
    if (this.filters.activity !== 'all') parts.push(this.filters.activity);
    if (this.filters.driverStatuses.length > 0)
      parts.push(`Status: ${this.filters.driverStatuses.join(', ')}`);
    if (this.filters.vehicleType) parts.push(`Type: ${this.filters.vehicleType}`);
    if (this.filters.zone) parts.push(`Zone: ${this.filters.zone}`);
    if (this.filters.account !== 'any') parts.push(`Account: ${this.filters.account}`);
    if (this.filters.minRating !== undefined || this.filters.maxRating !== undefined) {
      const min = this.filters.minRating ?? 1;
      const max = this.filters.maxRating ?? 5;
      parts.push(`Rating: ${min} - ${max}★`);
    }
    return parts.join(' • ') || 'No filters applied';
  }

  /**
   * Get driver status badge color
   */
  getStatusBadgeClass(status?: string): string {
    const normalized = (status || '').toUpperCase();
    switch (normalized) {
      case 'ON_TRIP':
        return 'bg-blue-100 text-blue-800';
      case 'BUSY':
        return 'bg-yellow-100 text-yellow-800';
      case 'IDLE':
        return 'bg-green-100 text-green-800';
      case 'OFFLINE':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }

  /**
   * Format driver status for display
   */
  formatStatus(status?: string): string {
    if (!status) return '—';
    return status
      .toLowerCase()
      .split('_')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }

  /**
   * Check if driver has all required documents
   */
  hasRequiredDocuments(driver: Driver): boolean {
    // This is a placeholder; adjust based on your actual document requirements
    return !!(driver as any).documentsVerified;
  }

  /**
   * Get rating display (stars or number)
   */
  getRatingDisplay(rating?: number): string {
    if (!rating || rating < 1) return 'N/A';
    return `${rating.toFixed(1)}★`;
  }

  /**
   * Handle keyboard shortcuts in driver list
   */
  handleKeyboardShortcuts(event: KeyboardEvent): void {
    // Escape: close modal
    if (
      event.key === 'Escape' &&
      (this.isModalOpen || this.isCreateAccountModalOpen || this.showMessageModal)
    ) {
      this.closeModal();
      this.closeCreateAccountModal();
      this.closeMessageModal();
    }

    // Ctrl+N: New driver
    if ((event.ctrlKey || event.metaKey) && event.key === 'n') {
      event.preventDefault();
      if (!this.isModalOpen) {
        this.openDriverModal();
      }
    }

    // Ctrl+F: Focus search
    if ((event.ctrlKey || event.metaKey) && event.key === 'f') {
      event.preventDefault();
      const searchInput = document.querySelector(
        'input[placeholder*="Search"]',
      ) as HTMLInputElement;
      if (searchInput) {
        searchInput.focus();
      }
    }
  }

  /**
   * Export drivers to Excel
   */
  async exportToExcel(): Promise<void> {
    try {
      const ExcelJS = await import('exceljs');
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet('Drivers');

      // Define columns
      worksheet.columns = [
        { header: 'ID', key: 'id', width: 10 },
        { header: 'Full Name', key: 'fullName', width: 25 },
        { header: 'Phone', key: 'phone', width: 15 },
        { header: 'License Number', key: 'licenseNumber', width: 20 },
        { header: 'Zone', key: 'zone', width: 15 },
        { header: 'Vehicle Type', key: 'vehicleType', width: 15 },
        { header: 'Status', key: 'status', width: 15 },
        { header: 'Active', key: 'isActive', width: 10 },
        { header: 'Account', key: 'username', width: 20 },
        { header: 'Device Token', key: 'deviceToken', width: 30 },
        { header: 'Rating', key: 'rating', width: 10 },
      ];

      // Style header row
      worksheet.getRow(1).font = { bold: true };
      worksheet.getRow(1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF2563EB' },
      };
      worksheet.getRow(1).font = { color: { argb: 'FFFFFFFF' }, bold: true };

      // Add data
      this.allDrivers.forEach((driver) => {
        worksheet.addRow({
          id: driver.id,
          fullName: driver.fullName || driver.name || `${driver.firstName} ${driver.lastName}`,
          phone: driver.phone,
          licenseNumber: driver.licenseNumber || 'N/A',
          zone: driver.zone || 'N/A',
          vehicleType: driver.vehicleType || 'N/A',
          status: this.formatStatus(driver.status),
          isActive: driver.isActive ? 'Yes' : 'No',
          username: driver.user?.username || 'N/A',
          deviceToken: driver.deviceToken || 'N/A',
          rating: driver.rating || 'N/A',
        });
      });

      // Generate buffer and download
      const buffer = await workbook.xlsx.writeBuffer();
      const blob = new Blob([buffer], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `drivers_${new Date().toISOString().split('T')[0]}.xlsx`;
      link.click();
      window.URL.revokeObjectURL(url);

      this.driverService.showToast('Drivers exported successfully!');
    } catch (error) {
      console.error('Export error:', error);
      this.driverService.showToast('❌ Failed to export drivers');
    }
  }

  /**
   * Export drivers to PDF
   */
  exportToPDF(): void {
    // Placeholder for PDF export functionality
    this.driverService.showToast('PDF export coming soon! Use Excel export for now.');
  }

  /**
   * Import drivers from file
   */
  importDrivers(): void {
    // Placeholder for import functionality
    this.driverService.showToast('Import functionality coming soon!');
  }

  /**
   * Format last seen time in human-readable format
   */
  formatLastSeen(lastActiveAt: string | Date): string {
    const now = new Date();
    const lastSeen = new Date(lastActiveAt);
    const diffMs = now.getTime() - lastSeen.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;

    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h ago`;

    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 7) return `${diffDays}d ago`;

    return lastSeen.toLocaleDateString();
  }
}
