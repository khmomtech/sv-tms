import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { firstValueFrom, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { FormsModule } from '@angular/forms';
import { AssignDriverModalComponent } from '../../../assign-driver-modal/assign-driver-modal.component';
import { NotificationService } from '@services/notification.service';
import {
  VehicleDriverService,
  type AssignmentResponse,
  type BulkAssignmentUploadResponse,
} from '@services/vehicle-driver.service';

@Component({
  selector: 'app-vehicle-assignment-list',
  standalone: true,
  imports: [CommonModule, HttpClientModule, FormsModule, AssignDriverModalComponent],
  templateUrl: './vehicle-assignment-list.html',
  styleUrl: './vehicle-assignment-list.css',
})
export class VehicleAssignmentListComponent {
  private notification = inject(NotificationService);
  private vehicleDriverService = inject(VehicleDriverService);
  private searchInput$ = new Subject<string>();
  loading = false;
  error?: string;

  searchTerm = '';
  debouncedSearchTerm = '';
  statusFilter: 'all' | 'assigned' | 'unassigned' | 'temporary' | 'permanentOnly' = 'all';
  sortBy: 'vehicle' | 'permanentDriver' | 'currentDriver' = 'vehicle';
  sortDirection: 'asc' | 'desc' = 'asc';
  page = 1;
  pageSize = 20;
  filteredTotal = 0;
  displayRows: Array<{
    vehicleId: number;
    vehicleCode?: string;
    permanentDriver?: { id: number; name: string } | null;
    temporaryDriver?: {
      id: number;
      name: string;
      expiresAt?: string;
      remainingMinutes?: number;
    } | null;
    effectiveDriver?: { id: number; name: string } | null;
  }> = [];

  // Assignment modal state
  showAssignModal = false;
  selectedVehicleId?: number;
  selectedVehicleCode?: string;
  currentDriverId?: number | null;
  bulkUploadInProgress = false;
  bulkUploadSummary?: BulkAssignmentUploadResponse;

  rows: Array<{
    vehicleId: number;
    vehicleCode?: string;
    permanentDriver?: { id: number; name: string } | null;
    temporaryDriver?: {
      id: number;
      name: string;
      expiresAt?: string;
      remainingMinutes?: number;
    } | null;
    effectiveDriver?: { id: number; name: string } | null;
  }> = [];

  constructor(private http: HttpClient) {
    this.searchInput$.pipe(debounceTime(300), distinctUntilChanged()).subscribe((value) => {
      this.debouncedSearchTerm = value;
      this.page = 1;
      this.applyFiltersAndSorting();
    });
    this.load();
  }

  private normalizeArray<T>(value: unknown): T[] {
    if (Array.isArray(value)) {
      return value as T[];
    }
    if (value && typeof value === 'object' && Array.isArray((value as any).content)) {
      return (value as any).content as T[];
    }
    return [];
  }

  async load(): Promise<void> {
    this.loading = true;
    this.error = undefined;
    try {
      // Load all vehicles, not just those with drivers
      const response: any = await firstValueFrom(this.http.get<any>('/api/admin/vehicles/all'));
      const vehicles: any[] = this.normalizeArray<any>(response?.data);

      // Get active permanent assignments from current API
      const assignmentsResponse = await firstValueFrom(
        this.vehicleDriverService.getAssignments({ active: true }),
      );
      const assignments: AssignmentResponse[] = this.normalizeArray<AssignmentResponse>(
        assignmentsResponse?.data,
      );

      // Create a map of vehicle assignments
      const assignmentMap = new Map<number, AssignmentResponse>();
      assignments.forEach((a) => {
        if (a?.vehicleId != null) {
          assignmentMap.set(a.vehicleId, a);
        }
      });

      // Map all vehicles with their assignments
      this.rows = vehicles.map((v: any) => {
        const assignment = assignmentMap.get(v.id);
        const driverName =
          assignment?.driverName ||
          [assignment?.driverFirstName, assignment?.driverLastName].filter(Boolean).join(' ');
        return {
          vehicleId: v.id,
          vehicleCode: v.licensePlate || v.code || v.plateNumber,
          permanentDriver:
            assignment && assignment.driverId
              ? { id: assignment.driverId, name: driverName || `Driver #${assignment.driverId}` }
              : null,
          temporaryDriver: null,
          effectiveDriver:
            assignment && assignment.driverId
              ? { id: assignment.driverId, name: driverName || `Driver #${assignment.driverId}` }
              : null,
        };
      });
      this.applyFiltersAndSorting();
    } catch (e: any) {
      // Provide user-friendly errors; include requestId if server returns one
      const msg = e?.error?.message || e?.message;
      const reqId = e?.error?.requestId;
      this.error =
        (msg ? msg : 'Failed to load vehicle assignments') +
        (reqId ? ` (Request ID: ${reqId})` : '');
    } finally {
      this.loading = false;
    }
  }

  refresh(): void {
    this.page = 1;
    this.load();
  }

  downloadCsvTemplate(): void {
    this.vehicleDriverService.downloadBatchTemplate().subscribe({
      next: (blob) => {
        const fileName = 'vehicle-driver-bulk-template.csv';
        const url = window.URL.createObjectURL(blob);
        const anchor = document.createElement('a');
        anchor.href = url;
        anchor.download = fileName;
        anchor.click();
        window.URL.revokeObjectURL(url);
      },
      error: (e: any) => {
        const msg = e?.message || 'Failed to download CSV template';
        this.notification.simulateNotification('Error', msg);
      },
    });
  }

  openBulkUploadPicker(fileInput: HTMLInputElement): void {
    if (this.bulkUploadInProgress) return;
    fileInput.click();
  }

  onBulkCsvSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input?.files?.[0];
    if (!file) return;

    if (!file.name.toLowerCase().endsWith('.csv')) {
      this.notification.simulateNotification('Error', 'Please select a CSV file.');
      input.value = '';
      return;
    }

    this.bulkUploadInProgress = true;
    this.bulkUploadSummary = undefined;

    this.vehicleDriverService.uploadBatchCsv(file).subscribe({
      next: async (res) => {
        this.bulkUploadSummary = res?.data;
        const summary = this.bulkUploadSummary;
        if (summary) {
          const message =
            summary.failedCount > 0
              ? `Bulk upload done: ${summary.successCount} success, ${summary.failedCount} failed.`
              : `Bulk upload done: ${summary.successCount} success.`;
          this.notification.simulateNotification(
            summary.failedCount > 0 ? 'Warning' : 'Success',
            message,
          );
        } else {
          this.notification.simulateNotification('Success', 'Bulk upload completed.');
        }
        await this.load();
      },
      error: (e: any) => {
        const msg = e?.message || e?.error?.message || 'Bulk CSV upload failed.';
        this.notification.simulateNotification('Error', msg);
        this.bulkUploadInProgress = false;
        input.value = '';
      },
      complete: () => {
        this.bulkUploadInProgress = false;
        input.value = '';
      },
    });
  }

  get bulkFailedPreview(): string[] {
    const results = this.bulkUploadSummary?.results ?? [];
    return results
      .filter((r) => !r.success)
      .slice(0, 5)
      .map((r) => `${r.requestId || 'row'}: ${r.message}`);
  }

  onSearchChange(): void {
    this.searchInput$.next(this.searchTerm);
  }

  onFilterChange(): void {
    this.page = 1;
    this.applyFiltersAndSorting();
  }

  onPageSizeChange(): void {
    this.page = 1;
    this.applyFiltersAndSorting();
  }

  onSort(column: 'vehicle' | 'permanentDriver' | 'currentDriver'): void {
    if (this.sortBy === column) {
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortBy = column;
      this.sortDirection = 'asc';
    }
    this.page = 1;
    this.applyFiltersAndSorting();
  }

  getSortIcon(column: 'vehicle' | 'permanentDriver' | 'currentDriver'): string {
    if (this.sortBy !== column) return 'unfold_more';
    return this.sortDirection === 'asc' ? 'arrow_upward' : 'arrow_downward';
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.debouncedSearchTerm = '';
    this.statusFilter = 'all';
    this.sortBy = 'vehicle';
    this.sortDirection = 'asc';
    this.page = 1;
    this.applyFiltersAndSorting();
  }

  nextPage(): void {
    if (this.page * this.pageSize < this.filteredTotal) {
      this.page++;
      this.applyFiltersAndSorting();
    }
  }

  prevPage(): void {
    if (this.page > 1) {
      this.page--;
      this.applyFiltersAndSorting();
    }
  }

  get assignedCount(): number {
    return this.rows.filter((r) => r.effectiveDriver).length;
  }

  get temporaryCount(): number {
    return this.rows.filter((r) => r.temporaryDriver).length;
  }

  get unassignedCount(): number {
    return this.rows.filter((r) => !r.effectiveDriver).length;
  }

  get statusFilterLabel(): string {
    const labels: Record<string, string> = {
      all: 'All Assignments',
      assigned: 'Assigned Only',
      unassigned: 'Unassigned Only',
      temporary: 'Temporary Only',
      permanentOnly: 'Permanent Only',
    };
    return labels[this.statusFilter] ?? 'All Assignments';
  }

  get hasNoData(): boolean {
    return !this.loading && !this.error && this.rows.length === 0;
  }

  get hasNoMatches(): boolean {
    return !this.loading && !this.error && this.rows.length > 0 && this.filteredTotal === 0;
  }

  get pageCount(): number {
    return Math.max(1, Math.ceil(this.filteredTotal / this.pageSize));
  }

  get showingFrom(): number {
    if (this.filteredTotal === 0) return 0;
    return (this.page - 1) * this.pageSize + 1;
  }

  get showingTo(): number {
    if (this.filteredTotal === 0) return 0;
    return Math.min(this.page * this.pageSize, this.filteredTotal);
  }

  clearSearchBadge(): void {
    this.searchTerm = '';
    this.debouncedSearchTerm = '';
    this.page = 1;
    this.applyFiltersAndSorting();
  }

  clearStatusBadge(): void {
    this.statusFilter = 'all';
    this.page = 1;
    this.applyFiltersAndSorting();
  }

  trackByVehicleId(_index: number, row: { vehicleId: number }): number {
    return row.vehicleId;
  }

  private normalizeText(value?: string | null): string {
    return (value ?? '').toLowerCase().trim().replace(/\s+/g, ' ');
  }

  private rowHasSearchMatch(
    row: {
      vehicleId: number;
      vehicleCode?: string;
      permanentDriver?: { id: number; name: string } | null;
      temporaryDriver?: { id: number; name: string } | null;
      effectiveDriver?: { id: number; name: string } | null;
    },
    query: string,
  ): boolean {
    if (!query) return true;
    const fields = [
      row.vehicleCode || `${row.vehicleId}`,
      row.permanentDriver?.name,
      row.temporaryDriver?.name,
      row.effectiveDriver?.name,
    ];
    return fields.some((field) => this.normalizeText(field).includes(query));
  }

  private getSortValue(
    row: {
      vehicleCode?: string;
      permanentDriver?: { name: string } | null;
      effectiveDriver?: { name: string } | null;
    },
    column: 'vehicle' | 'permanentDriver' | 'currentDriver',
  ): string {
    if (column === 'vehicle') return this.normalizeText(row.vehicleCode);
    if (column === 'permanentDriver') return this.normalizeText(row.permanentDriver?.name);
    return this.normalizeText(row.effectiveDriver?.name);
  }

  private applyFiltersAndSorting(): void {
    const query = this.normalizeText(this.debouncedSearchTerm);
    let data = [...this.rows];

    data = data.filter((row) => this.rowHasSearchMatch(row, query));

    if (this.statusFilter === 'assigned') {
      data = data.filter((r) => !!r.effectiveDriver);
    } else if (this.statusFilter === 'unassigned') {
      data = data.filter((r) => !r.effectiveDriver);
    } else if (this.statusFilter === 'temporary') {
      data = data.filter((r) => !!r.temporaryDriver);
    } else if (this.statusFilter === 'permanentOnly') {
      data = data.filter((r) => !!r.permanentDriver && !r.temporaryDriver);
    }

    data.sort((a, b) => {
      const left = this.getSortValue(a, this.sortBy);
      const right = this.getSortValue(b, this.sortBy);
      const comparison = left.localeCompare(right, undefined, {
        numeric: true,
        sensitivity: 'base',
      });
      return this.sortDirection === 'asc' ? comparison : -comparison;
    });

    this.filteredTotal = data.length;
    const maxPage = Math.max(1, Math.ceil(this.filteredTotal / this.pageSize));
    if (this.page > maxPage) {
      this.page = maxPage;
    }

    const start = (this.page - 1) * this.pageSize;
    this.displayRows = data.slice(start, start + this.pageSize);
  }

  openAssignModal(vehicle: any): void {
    this.selectedVehicleId = vehicle.vehicleId;
    this.selectedVehicleCode = vehicle.vehicleCode;
    this.currentDriverId = vehicle.effectiveDriver?.id || vehicle.permanentDriver?.id || null;
    this.showAssignModal = true;
  }

  closeAssignModal(): void {
    this.showAssignModal = false;
    this.selectedVehicleId = undefined;
    this.selectedVehicleCode = undefined;
    this.currentDriverId = null;
  }

  async handleAssignDriver(driverId: number): Promise<void> {
    await this.handleAssignDriverWithOptions({ driverId, forceReassignment: false });
  }

  async handleAssignDriverWithOptions(payload: {
    driverId: number;
    forceReassignment?: boolean;
  }): Promise<void> {
    if (!this.selectedVehicleId) return;
    const driverId = payload.driverId;
    const vehicleId = this.selectedVehicleId;
    const currentDriverId = this.currentDriverId ?? null;
    const isReassignment = currentDriverId != null && currentDriverId !== driverId;
    const forceReassignment = !!payload.forceReassignment;

    if (currentDriverId != null && currentDriverId === driverId) {
      this.notification.simulateNotification(
        'Info',
        `Driver is already assigned to vehicle ${this.selectedVehicleCode || '#' + vehicleId}.`,
      );
      this.closeAssignModal();
      return;
    }

    this.loading = true;
    try {
      await this.assignDriver(driverId, vehicleId, isReassignment, forceReassignment);

      this.closeAssignModal();
      this.notification.simulateNotification('Success', 'Driver assigned successfully');
      await this.load(); // Reload the list
    } catch (e: any) {
      const msg = e?.error?.message || e?.message || 'Failed to assign driver';
      this.notification.simulateNotification('Error', msg);
    } finally {
      this.loading = false;
    }
  }

  private async assignDriver(
    driverId: number,
    vehicleId: number,
    isReassignment: boolean,
    forceReassignment: boolean,
  ): Promise<void> {
    const baseReason = isReassignment
      ? 'Reassigned from Vehicle Assignments page'
      : 'Assigned from Vehicle Assignments page';
    const shouldForce = forceReassignment || isReassignment;

    try {
      await firstValueFrom(
        this.vehicleDriverService.assignTruckToDriver({
          driverId,
          vehicleId,
          reason: baseReason,
          forceReassignment: shouldForce,
        }),
      );
    } catch (error: any) {
      if (!shouldForce && this.shouldRetryWithForce(error)) {
        await firstValueFrom(
          this.vehicleDriverService.assignTruckToDriver({
            driverId,
            vehicleId,
            reason: `${baseReason} (force reassignment)`,
            forceReassignment: true,
          }),
        );
        return;
      }
      throw error;
    }
  }

  private shouldRetryWithForce(error: any): boolean {
    const message = this.normalizeText(error?.message || error?.error?.message || '');
    if (!message) return false;
    return (
      message.includes('must be online') ||
      message.includes('is not employed') ||
      message.includes('is not available') ||
      message.includes('license class')
    );
  }
}
