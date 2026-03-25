/* eslint-disable @typescript-eslint/consistent-type-imports */
import { ScrollingModule } from '@angular/cdk/scrolling';
import { CommonModule } from '@angular/common';
import type { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, ChangeDetectorRef, OnInit } from '@angular/core';
import { ElementRef } from '@angular/core';
import { Component, HostListener, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { ConfirmService } from '@services/confirm.service';

import { VehicleType, VehicleStatus } from '../../models/enums/vehicle.enums';
import type { Vehicle } from '../../models/vehicle.model';
import { VehicleService } from '../../services/vehicle.service';
import { NotificationService } from '../../services/notification.service';

@Component({
  selector: 'app-vehicle',
  standalone: true,
  templateUrl: './vehicle.component.html',
  styleUrls: ['./vehicle.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, FormsModule, ScrollingModule],
})
export class VehicleComponent implements OnInit {
  private confirm = inject(ConfirmService);

  private readonly FILTER_STORAGE_KEY = 'svtms.vehicles.filters.v1';

  vehicles: Vehicle[] = [];
  filteredList: Vehicle[] = [];

  selectedVehicle: Vehicle = this.getEmptyVehicle();
  isModalOpen = false;
  isEditing = false;

  dropdownOpen: number | null = null;
  modalErrorMessage = '';
  listErrorMessage = '';
  isLoading = false;
  private lastFilterKey = '';

  // Filters
  filters: VehicleFilterState = {
    search: '',
    status: '',
    assigned: '',
  };
  private filterDebounceTimer: ReturnType<typeof setTimeout> | null = null;

  // Pagination
  currentPage = 0;
  totalPages = 1;
  totalElements = 0;
  pageSize = 15;

  // Enums
  VehicleStatus = VehicleStatus;
  private readonly vehicleStatusValues = Object.values(VehicleStatus) as VehicleStatus[];
  vehicleStatuses = this.vehicleStatusValues;
  vehicleTypes = Object.values(VehicleType);

  // Expose Math for template
  Math = Math;

  constructor(
    private readonly vehicleService: VehicleService,
    private router: Router,
    private readonly route: ActivatedRoute,
    private readonly elRef: ElementRef,
    private readonly cdr: ChangeDetectorRef,
    private readonly notification: NotificationService,
  ) {}

  ngOnInit(): void {
    this.restoreFilters();
    this.fetchVehiclesWithFilters();

    // Check if route data indicates we should open create modal
    const action = this.route.snapshot.data['action'];
    if (action === 'create') {
      setTimeout(() => this.openVehicleModal(), 100);
    }
  }

  fetchVehiclesWithFilters(force = false): void {
    const filterKey = JSON.stringify({
      page: this.currentPage,
      size: this.pageSize,
      filters: this.filters,
    });
    if (!force && !this.isLoading && this.lastFilterKey === filterKey) {
      return;
    }
    this.lastFilterKey = filterKey;
    this.isLoading = true;
    this.listErrorMessage = '';
    const filters = {
      search: this.filters.search || undefined,
      status: this.filters.status || undefined,
      assigned:
        this.filters.assigned === 'assigned'
          ? 'true'
          : this.filters.assigned === 'unassigned'
            ? 'false'
            : undefined,
    };

    this.vehicleService.getVehicles(this.currentPage, this.pageSize, filters).subscribe(
      (response: any) => {
        if (response.success && response.data) {
          const incoming = response.data.content || [];
          this.vehicles = incoming.map((v: Vehicle) => this.normalizeVehicle(v));
          this.totalPages = response.data.totalPages || 1;
          this.totalElements = response.data.totalElements ?? this.vehicles.length;
          this.filteredList = this.vehicles;
          // OnPush: async updates need to mark view dirty.
          this.cdr.markForCheck();
        } else {
          this.setListError('Failed to load vehicles.');
        }
        this.isLoading = false;
        this.cdr.markForCheck();
      },
      (error) => {
        this.handleListError(error, 'Error loading vehicles.');
        this.isLoading = false;
        this.cdr.markForCheck();
      },
    );
  }

  filterVehicles(): void {
    this.currentPage = 0;
    this.persistFilters();
    this.fetchVehiclesWithFilters(true);
  }

  onSearchInput(): void {
    this.scheduleFilterApply();
  }

  onFilterChange(): void {
    this.scheduleFilterApply();
  }

  retryFetch(): void {
    this.fetchVehiclesWithFilters(true);
  }

  private scheduleFilterApply(): void {
    if (this.filterDebounceTimer) {
      clearTimeout(this.filterDebounceTimer);
    }
    this.filterDebounceTimer = setTimeout(() => {
      this.filterVehicles();
      this.filterDebounceTimer = null;
    }, 300);
  }

  clearFilters(): void {
    this.filters = {
      search: '',
      status: '',
      assigned: '',
    };
    this.persistFilters();
    this.currentPage = 0;
    this.fetchVehiclesWithFilters();
  }

  openVehicleModal(vehicle?: Vehicle): void {
    this.isEditing = !!vehicle;
    this.selectedVehicle = vehicle ? { ...vehicle } : this.getEmptyVehicle();
    this.isModalOpen = true;
    this.modalErrorMessage = '';
  }

  viewVehicle(id: number): void {
    this.router.navigate(['/fleet/vehicles', id]);
  }

  navigateToSetup(): void {
    this.router.navigate(['/fleet/vehicles/setup']);
  }

  trackByVehicleId(index: number, vehicle: Vehicle): number {
    return vehicle?.id ?? index;
  }

  closeModal(): void {
    this.isModalOpen = false;
    this.selectedVehicle = this.getEmptyVehicle();
    this.modalErrorMessage = '';
    this.cdr.markForCheck();
  }

  saveVehicle(): void {
    if (!this.selectedVehicle) return;

    // Validate status transition for existing vehicles
    if (this.isEditing) {
      const originalVehicle = this.vehicles.find((v) => v.id === this.selectedVehicle.id);
      if (
        originalVehicle &&
        originalVehicle.status !== this.selectedVehicle.status &&
        !this.canTransitionTo(originalVehicle.status, this.selectedVehicle.status)
      ) {
        this.modalErrorMessage = `Invalid status transition: Cannot change from ${this.getStatusLabel(
          originalVehicle.status,
        )} to ${this.getStatusLabel(this.selectedVehicle.status)}. Please check the status lifecycle rules.`;
        this.cdr.detectChanges();
        return;
      }
    }

    this.modalErrorMessage = '';

    const saveObs = this.isEditing
      ? this.vehicleService.updateVehicle(this.selectedVehicle)
      : this.vehicleService.addVehicle(this.selectedVehicle);

    (saveObs as import('rxjs').Observable<Vehicle>).subscribe(
      (vehicle) => {
        if (!this.isEditing && vehicle?.id) {
          // Show success notification, then redirect
          this.notification.success('Vehicle created successfully!');
          this.closeModal();
          setTimeout(() => {
            this.router.navigate(['/fleet/vehicles', vehicle.id]);
          }, 800); // allow user to see the alert
        } else {
          this.notification.success('Vehicle updated successfully!');
          this.fetchVehiclesWithFilters();
          this.closeModal();
        }
      },
      (error: any) => this.handleModalError(error, 'Error saving vehicle.'),
    );
  }

  private setModalError(message: string): void {
    this.modalErrorMessage = message;
    this.cdr.markForCheck();
  }

  private handleModalError(error: any, fallbackMessage: string): void {
    if (error?.error?.message) {
      this.setModalError(error.error.message);
    } else if (typeof error.error === 'string') {
      this.setModalError(error.error);
    } else {
      const statusMessages: { [code: number]: string } = {
        400: 'Bad request. Please review input fields.',
        401: 'Unauthorized access.',
        403: 'Forbidden. You lack permission.',
        404: 'Vehicle not found.',
        500: 'Internal server error.',
      };
      this.setModalError(statusMessages[error.status] || fallbackMessage);
    }
  }

  async deleteVehicle(vehicleId: number): Promise<void> {
    if (!(await this.confirm.confirm('Are you sure you want to delete this vehicle?'))) {
      return;
    }
    this.vehicleService.deleteVehicle(vehicleId).subscribe(
      () => {
        this.dropdownOpen = null;
        this.fetchVehiclesWithFilters();
        this.cdr.markForCheck();
      },
      (error) => this.handleListError(error, 'Error deleting vehicle.'),
    );
  }

  toggleDropdown(vehicleId: number | undefined): void {
    this.dropdownOpen = vehicleId === this.dropdownOpen ? null : (vehicleId ?? null);
  }

  prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.persistFilters();
      this.fetchVehiclesWithFilters();
    }
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.persistFilters();
      this.fetchVehiclesWithFilters();
    }
  }

  goToFirstPage(): void {
    if (this.currentPage !== 0) {
      this.currentPage = 0;
      this.persistFilters();
      this.fetchVehiclesWithFilters();
    }
  }

  goToLastPage(): void {
    const lastPage = this.totalPages - 1;
    if (this.currentPage !== lastPage) {
      this.currentPage = lastPage;
      this.persistFilters();
      this.fetchVehiclesWithFilters();
    }
  }

  onPageSizeChange(): void {
    this.currentPage = 0; // Reset to first page when changing page size
    this.persistFilters();
    this.fetchVehiclesWithFilters();
  }

  /**
   * Get allowed status transitions for the current vehicle status
   * Implements the vehicle status lifecycle workflow
   */
  getAvailableStatusTransitions(currentStatus: VehicleStatus): VehicleStatus[] {
    const transitions: Record<VehicleStatus, VehicleStatus[]> = {
      [VehicleStatus.ACTIVE]: [
        VehicleStatus.IN_USE,
        VehicleStatus.MAINTENANCE,
        VehicleStatus.UNDER_REPAIR,
        VehicleStatus.SAFETY_HOLD,
        VehicleStatus.IN_ISSUE,
        VehicleStatus.OUT_OF_SERVICE,
        VehicleStatus.RETIRED,
      ],
      [VehicleStatus.UNDER_REPAIR]: [
        VehicleStatus.ACTIVE,
        VehicleStatus.AVAILABLE,
        VehicleStatus.MAINTENANCE,
        VehicleStatus.OUT_OF_SERVICE,
        VehicleStatus.RETIRED,
      ],
      [VehicleStatus.SAFETY_HOLD]: [
        VehicleStatus.ACTIVE,
        VehicleStatus.AVAILABLE,
        VehicleStatus.IN_ISSUE,
        VehicleStatus.MAINTENANCE,
        VehicleStatus.OUT_OF_SERVICE,
        VehicleStatus.RETIRED,
      ],
      [VehicleStatus.RETIRED]: [],
      [VehicleStatus.AVAILABLE]: [
        VehicleStatus.ACTIVE,
        VehicleStatus.IN_USE,
        VehicleStatus.MAINTENANCE,
        VehicleStatus.UNDER_REPAIR,
        VehicleStatus.SAFETY_HOLD,
        VehicleStatus.IN_ISSUE,
        VehicleStatus.OUT_OF_SERVICE,
        VehicleStatus.RETIRED,
      ],
      [VehicleStatus.IN_USE]: [
        VehicleStatus.AVAILABLE,
        VehicleStatus.ACTIVE,
        VehicleStatus.MAINTENANCE,
        VehicleStatus.UNDER_REPAIR,
        VehicleStatus.SAFETY_HOLD,
        VehicleStatus.IN_ISSUE,
        VehicleStatus.OUT_OF_SERVICE,
        VehicleStatus.RETIRED,
      ],
      [VehicleStatus.MAINTENANCE]: [
        VehicleStatus.AVAILABLE,
        VehicleStatus.ACTIVE,
        VehicleStatus.UNDER_REPAIR,
        VehicleStatus.SAFETY_HOLD,
        VehicleStatus.IN_ISSUE,
        VehicleStatus.OUT_OF_SERVICE,
        VehicleStatus.RETIRED,
      ],
      [VehicleStatus.IN_ISSUE]: [
        VehicleStatus.AVAILABLE,
        VehicleStatus.ACTIVE,
        VehicleStatus.SAFETY_HOLD,
        VehicleStatus.MAINTENANCE,
        VehicleStatus.OUT_OF_SERVICE,
        VehicleStatus.RETIRED,
      ],
      [VehicleStatus.OUT_OF_SERVICE]: [], // Terminal state - no transitions out
    };
    return transitions[currentStatus] || [];
  }

  /**
   * Check if a status transition is valid according to lifecycle rules
   */
  canTransitionTo(
    from: VehicleStatus | string | undefined,
    to: VehicleStatus | string | undefined,
  ): boolean {
    const normalizedTo = this.normalizeStatus(to);
    if (!normalizedTo) return false;
    const normalizedFrom = this.normalizeStatus(from);
    if (!normalizedFrom) return true; // New vehicle can have any status
    if (normalizedFrom === normalizedTo) return true; // No change is always allowed
    return this.getAvailableStatusTransitions(normalizedFrom).includes(normalizedTo);
  }

  /**
   * Get human-readable label for status with context
   */
  getStatusLabel(status: VehicleStatus | string | undefined): string {
    const labels: Record<VehicleStatus, string> = {
      [VehicleStatus.ACTIVE]: 'Active',
      [VehicleStatus.UNDER_REPAIR]: 'Under Repair',
      [VehicleStatus.SAFETY_HOLD]: 'Safety Hold',
      [VehicleStatus.RETIRED]: 'Retired',
      [VehicleStatus.AVAILABLE]: 'Available',
      [VehicleStatus.IN_USE]: 'In Use',
      [VehicleStatus.MAINTENANCE]: 'Maintenance',
      [VehicleStatus.IN_ISSUE]: 'In Issue',
      [VehicleStatus.OUT_OF_SERVICE]: 'Out of Service',
    };
    const normalized = this.normalizeStatus(status);
    if (normalized) {
      return labels[normalized] || normalized;
    }
    return typeof status === 'string' ? status : '';
  }

  /**
   * Get status description
   */
  getStatusDescription(status: VehicleStatus | string | undefined): string {
    const descriptions: Record<VehicleStatus, string> = {
      [VehicleStatus.ACTIVE]: 'Ready for assignment',
      [VehicleStatus.UNDER_REPAIR]: 'Work order in progress',
      [VehicleStatus.SAFETY_HOLD]: 'Critical safety issue - dispatch blocked',
      [VehicleStatus.RETIRED]: 'Removed from fleet',
      [VehicleStatus.AVAILABLE]: 'Ready for assignment',
      [VehicleStatus.IN_USE]: 'Currently on dispatch',
      [VehicleStatus.MAINTENANCE]: 'Under repair/service',
      [VehicleStatus.IN_ISSUE]: 'Police/Legal hold',
      [VehicleStatus.OUT_OF_SERVICE]: 'Decommissioned/Removed from fleet',
    };
    const normalized = this.normalizeStatus(status);
    return normalized ? descriptions[normalized] || '' : '';
  }

  /**
   * Get filtered status options based on current status (for editing)
   */
  getFilteredStatusOptions(): VehicleStatus[] {
    if (!this.isEditing || !this.selectedVehicle.status) {
      // New vehicle - show all statuses
      return this.vehicleStatuses;
    }
    const currentStatus = this.normalizeStatus(this.selectedVehicle.status);
    if (!currentStatus) {
      return this.vehicleStatuses;
    }
    const allowed = this.getAvailableStatusTransitions(currentStatus);
    // Remove duplicates and maintain order
    return Array.from(new Set([currentStatus, ...allowed]));
  }

  /**
   * Check if status option should be disabled
   */
  isStatusDisabled(status: VehicleStatus): boolean {
    if (!this.isEditing || !this.selectedVehicle.status) return false;
    return !this.canTransitionTo(this.selectedVehicle.status, status);
  }

  /**
   * Get status transition warning message
   */
  getStatusTransitionWarning(newStatus: VehicleStatus | string | undefined): string {
    const oldStatus = this.selectedVehicle.status;
    const normalizedOld = this.normalizeStatus(oldStatus);
    const normalizedNew = this.normalizeStatus(newStatus);
    if (!normalizedOld || !normalizedNew || normalizedOld === normalizedNew) return '';

    const warnings: Record<string, string> = {
      [`${VehicleStatus.IN_USE}-${VehicleStatus.AVAILABLE}`]:
        '⚠️ Ensure dispatch is completed before marking as available',
      [`${VehicleStatus.IN_USE}-${VehicleStatus.MAINTENANCE}`]:
        '⚠️ Issue reported during dispatch - maintenance required',
      [`${VehicleStatus.IN_USE}-${VehicleStatus.IN_ISSUE}`]:
        '⚠️ Accident/incident occurred - legal hold required',
      [`${VehicleStatus.MAINTENANCE}-${VehicleStatus.AVAILABLE}`]:
        '✓ Repairs completed - vehicle ready for use',
      [`${VehicleStatus.IN_ISSUE}-${VehicleStatus.AVAILABLE}`]:
        '✓ Legal matter resolved - vehicle cleared',
      [`${VehicleStatus.AVAILABLE}-${VehicleStatus.MAINTENANCE}`]:
        'ℹ️ Scheduling maintenance/service',
      [`${VehicleStatus.AVAILABLE}-${VehicleStatus.IN_ISSUE}`]:
        '⚠️ Legal/police hold - document the reason',
    };

    return warnings[`${normalizedOld}-${normalizedNew}`] || '';
  }

  /**
   * Get status badge color classes
   */
  getStatusBadgeClasses(status: VehicleStatus | string | undefined): string {
    const classes: Record<VehicleStatus, string> = {
      [VehicleStatus.ACTIVE]: 'bg-emerald-100 text-emerald-700',
      [VehicleStatus.UNDER_REPAIR]: 'bg-orange-100 text-orange-700',
      [VehicleStatus.SAFETY_HOLD]: 'bg-red-100 text-red-700',
      [VehicleStatus.RETIRED]: 'bg-gray-100 text-gray-700',
      [VehicleStatus.AVAILABLE]: 'bg-emerald-100 text-emerald-700',
      [VehicleStatus.IN_USE]: 'bg-blue-100 text-blue-700',
      [VehicleStatus.MAINTENANCE]: 'bg-orange-100 text-orange-700',
      [VehicleStatus.IN_ISSUE]: 'bg-red-100 text-red-700',
      [VehicleStatus.OUT_OF_SERVICE]: 'bg-gray-100 text-gray-700',
    };
    const normalized = this.normalizeStatus(status);
    return normalized
      ? classes[normalized] || 'bg-gray-100 text-gray-700'
      : 'bg-gray-100 text-gray-700';
  }

  /**
   * Get status dot color classes
   */
  getStatusDotClasses(status: VehicleStatus | string | undefined): string {
    const classes: Record<VehicleStatus, string> = {
      [VehicleStatus.ACTIVE]: 'bg-green-500',
      [VehicleStatus.UNDER_REPAIR]: 'bg-yellow-500',
      [VehicleStatus.SAFETY_HOLD]: 'bg-red-500',
      [VehicleStatus.RETIRED]: 'bg-gray-500',
      [VehicleStatus.AVAILABLE]: 'bg-green-500',
      [VehicleStatus.IN_USE]: 'bg-blue-500',
      [VehicleStatus.MAINTENANCE]: 'bg-yellow-500',
      [VehicleStatus.IN_ISSUE]: 'bg-red-500',
      [VehicleStatus.OUT_OF_SERVICE]: 'bg-gray-500',
    };
    const normalized = this.normalizeStatus(status);
    return normalized ? classes[normalized] || 'bg-gray-500' : 'bg-gray-500';
  }

  private normalizeStatus(status?: VehicleStatus | string): VehicleStatus | undefined {
    if (!status) return undefined;
    const candidate = status as VehicleStatus;
    return this.vehicleStatusValues.includes(candidate) ? candidate : undefined;
  }

  @HostListener('document:click', ['$event'])
  onClickOutside(event: Event): void {
    const clickedInside = this.elRef.nativeElement.contains(event.target);
    if (!clickedInside) {
      this.dropdownOpen = null;
    }
  }

  private getEmptyVehicle(): Vehicle {
    return {
      licensePlate: '',
      manufacturer: '',
      model: '',
      type: VehicleType.TRUCK,
      status: VehicleStatus.ACTIVE,
      mileage: 0,
      fuelConsumption: 0,
      lastInspectionDate: undefined,
      lastServiceDate: undefined,
      nextServiceDue: undefined,
      maxWeight: 0,
      maxVolume: 0,
      qtyPalletsCapacity: 0,
      truckSize: undefined,
      assignedZoneId: undefined,
      assignedZoneName: '',
      assignedZone: '',
      gpsDeviceId: '',
      yearMade: new Date().getFullYear(),
      year: new Date().getFullYear(),
      availableRoutes: '',
      unavailableRoutes: '',
      remarks: '',
      parentVehicleId: undefined,
      assignedVehicleId: undefined,
      assignedDriver: undefined,
    };
  }

  private normalizeVehicle(vehicle: Vehicle): Vehicle {
    return {
      ...vehicle,
      yearMade: vehicle.yearMade ?? vehicle.year,
      qtyPalletsCapacity: vehicle.qtyPalletsCapacity ?? vehicle.palletCapacity,
      parentVehicleId: vehicle.parentVehicleId ?? vehicle.assignedVehicleId,
      assignedZoneName: vehicle.assignedZoneName ?? vehicle.assignedZone,
    };
  }

  get totalVehicles(): number {
    return this.vehicles.length;
  }

  get activeVehicles(): number {
    return this.vehicles.filter((v) =>
      [VehicleStatus.ACTIVE, VehicleStatus.AVAILABLE, VehicleStatus.IN_USE].includes(
        this.normalizeStatus(v.status) ?? VehicleStatus.ACTIVE,
      ),
    ).length;
  }

  get maintenanceVehicles(): number {
    return this.vehicles.filter((v) =>
      [VehicleStatus.MAINTENANCE, VehicleStatus.UNDER_REPAIR, VehicleStatus.SAFETY_HOLD].includes(
        this.normalizeStatus(v.status) ?? VehicleStatus.MAINTENANCE,
      ),
    ).length;
  }

  get unassignedVehicles(): number {
    return this.vehicles.filter((v) => !v.assignedDriver).length;
  }

  formatFuel(value?: number): string {
    if (value === null || value === undefined || Number.isNaN(value)) return '—';
    return `${value} L/100km`;
  }

  formatMileage(value?: number): string {
    if (value === null || value === undefined || Number.isNaN(value)) return '—';
    return `${value} km`;
  }

  formatWeight(value?: number): string {
    if (value === null || value === undefined || Number.isNaN(value)) return '—';
    return `${value} kg`;
  }

  formatVolume(value?: number): string {
    if (value === null || value === undefined || Number.isNaN(value)) return '—';
    return `${value} m³`;
  }

  formatZone(vehicle: Vehicle): string {
    if (vehicle.assignedZoneName) return vehicle.assignedZoneName;
    if (vehicle.assignedZone) return vehicle.assignedZone;
    if (vehicle.assignedZoneId !== undefined && vehicle.assignedZoneId !== null) {
      return `Zone #${vehicle.assignedZoneId}`;
    }
    return '—';
  }

  private handleError(error: HttpErrorResponse, fallbackMessage: string): void {
    // For modal context, use modalErrorMessage
    if (error?.error?.message) {
      this.modalErrorMessage = error.error.message;
    } else if (typeof error.error === 'string') {
      this.modalErrorMessage = error.error;
    } else {
      const statusMessages: { [code: number]: string } = {
        400: 'Bad request. Please review input fields.',
        401: 'Unauthorized access.',
        403: 'Forbidden. You lack permission.',
        404: 'Vehicle not found.',
        500: 'Internal server error.',
      };
      this.modalErrorMessage = statusMessages[error.status] || fallbackMessage;
    }
    this.cdr.markForCheck();
  }

  private handleListError(error: HttpErrorResponse, fallbackMessage: string): void {
    console.error('Vehicle List Error:', error);
    if (error?.error?.message) {
      this.setListError(error.error.message);
    } else if (typeof error.error === 'string') {
      this.setListError(error.error);
    } else {
      const statusMessages: { [code: number]: string } = {
        400: 'Bad request. Please review input filters.',
        401: 'Unauthorized access.',
        403: 'Forbidden. You lack permission.',
        404: 'Vehicle list not found.',
        500: 'Internal server error.',
      };
      this.setListError(statusMessages[error.status] || fallbackMessage);
    }
  }

  private setListError(message: string): void {
    this.listErrorMessage = message;
    this.filteredList = [];
    this.totalElements = 0;
    this.totalPages = 1;
    // OnPush: ensure errors/state changes render immediately.
    this.cdr.markForCheck();
  }

  private restoreFilters(): void {
    try {
      const raw = localStorage.getItem(this.FILTER_STORAGE_KEY);
      if (!raw) return;
      const parsed = JSON.parse(raw) as VehicleFilterState;
      this.filters = { ...this.filters, ...parsed };
    } catch (error) {
      console.warn('[VehicleComponent] Failed to restore filters', error);
    }
  }

  private persistFilters(): void {
    localStorage.setItem(this.FILTER_STORAGE_KEY, JSON.stringify(this.filters));
  }
}

interface VehicleFilterState {
  search: string;
  status: string;
  assigned: string;
}
