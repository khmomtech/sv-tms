import { InputPromptService } from '../../core/input-prompt.service';
/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit, OnDestroy } from '@angular/core';
import { Component, HostListener } from '@angular/core';
import { RouterModule } from '@angular/router';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { Subject, firstValueFrom } from 'rxjs';
import { finalize, takeUntil } from 'rxjs/operators';

import { PagedResponse } from '../../models/api-response-page.model';
import type { ApiResponse } from '../../models/api-response.model';
import type { DeviceRegisterDto } from '../../models/device-register.dto';
import type { Driver } from '../../models/driver.model';
import { SvSafeDatePipe } from '../../pipes/sv-safe-date.pipe';
import { AuthService } from '../../services/auth.service';
import { DeviceService } from '../../services/device.service';
import { DriverService } from '../../services/driver.service';
import { ConfirmService } from '../../services/confirm.service';

@Component({
  selector: 'app-device',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, SvSafeDatePipe, DatePipe],
  templateUrl: './device.component.html',
  styleUrls: ['./device.component.css'],
})
export class DeviceComponent implements OnInit, OnDestroy {
  devices: DeviceRegisterDto[] = [];
  filteredDevices: DeviceRegisterDto[] = [];
  selectedDevice?: DeviceRegisterDto;
  isLoading: boolean = false;
  errorMessage: string | null = null;

  drivers: Driver[] = [];
  // Filters (persisted)
  private readonly FILTER_STORAGE_KEY = 'svtms.devices.filters.v1';
  filters = {
    status: '',
    driverId: '',
    query: '',
  } as { status: string; driverId: string; query: string };

  // Pagination state (server-side)
  page = 0;
  size = 20;
  totalPages = 0;
  totalElements = 0;

  // expose Math to template for helper expressions (e.g. Math.min)
  readonly Math = Math;

  // Summary counts by status
  deviceSummary: Record<string, number> = {};

  deviceStatuses: string[] = ['PENDING', 'APPROVED', 'BLOCKED'];

  private destroy$ = new Subject<void>();
  private searchSubject$ = new Subject<string>();
  // selection state for bulk actions
  selectedIds: Set<number> = new Set<number>();
  isProcessingBulk = false;

  constructor(
    private deviceService: DeviceService,
    private driverService: DriverService,
    private authService: AuthService,
    private confirm: ConfirmService,
    private inputPrompt: InputPromptService,
  ) {}

  ngOnInit(): void {
    this.restoreFilters();
    this.loadDevices();
    this.loadDrivers();

    this.searchSubject$.pipe(takeUntil(this.destroy$)).subscribe(() => {
      this.page = 0; // reset to first page on search
      this.persistFilters();
      this.loadDevices();
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadDevices(): void {
    this.isLoading = true;
    this.errorMessage = null;
    this.deviceService
      .searchDevices(this.page, this.size, {
        status: this.filters.status,
        driverId: this.filters.driverId,
        q: this.filters.query,
      })
      .pipe(
        finalize(() => (this.isLoading = false)),
        takeUntil(this.destroy$),
      )
      .subscribe({
        next: (res: ApiResponse<DeviceRegisterDto[] | PagedResponse<DeviceRegisterDto>>) => {
          // extract page metadata if present
          const data = res.data as any;
          if (data?.totalPages !== undefined) this.totalPages = data.totalPages;
          if (data?.totalElements !== undefined) this.totalElements = data.totalElements;
          if (data?.number !== undefined) this.page = data.number;
          this.hydrateDevices(res);
        },
        error: (error: any) => {
          console.error('Error loading devices:', error);
          if (error?.status === 403) {
            this.errorMessage =
              'Access denied. You need DRIVER_MANAGE permission to view driver devices. Contact an administrator.';
          } else if (error?.status === 401) {
            this.errorMessage = 'Authentication required. Please log in again.';
          } else if (error?.error?.message) {
            this.errorMessage = error.error.message;
          } else if (error?.message) {
            this.errorMessage = error.message;
          } else {
            this.errorMessage =
              'Failed to load devices. Please check your connection and try again.';
          }
        },
      });
  }

  loadDrivers(): void {
    this.driverService
      .getAllDrivers()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (res: ApiResponse<PagedResponse<Driver>>) => {
          this.drivers = this.extractArray<Driver>(res);
        },
        error: (error: any) => console.error('Error loading drivers:', error),
      });
  }

  private hydrateDevices(
    res: ApiResponse<DeviceRegisterDto[] | PagedResponse<DeviceRegisterDto>>,
  ): void {
    const devices = this.extractArray<DeviceRegisterDto>(res);

    this.devices = devices.map((device) => ({
      ...device,
      showMenu: false,
    }));

    // compute summary counts
    this.deviceSummary = this.devices.reduce((acc: Record<string, number>, d) => {
      const key = (d.status || 'UNKNOWN').toUpperCase();
      acc[key] = (acc[key] || 0) + 1;
      return acc;
    }, {});

    // apply any active filters (local-only). Do NOT call `filterDevices()` here
    // because `filterDevices()` triggers a server-side load which would cause
    // an immediate duplicate request after hydration.
    this.filteredDevices = [...this.devices];
  }

  /**
   * Extracts an array payload from a variety of API response shapes:
   * - { data: [...] }
   * - { data: { content: [...] } }
   * - { content: [...] }
   * - directly an array
   * - nested { data: { data: [...] } } or similar
   */
  private extractArray<T>(input: any): T[] {
    const visited = new Set<any>();
    const stack: any[] = [input];

    while (stack.length) {
      const current = stack.pop();
      if (!current || visited.has(current)) continue;
      visited.add(current);

      if (Array.isArray(current)) {
        return current as T[];
      }

      if (typeof current === 'object') {
        const maybeContent = (current as any).content;
        const maybeData = (current as any).data;
        if (Array.isArray(maybeContent)) return maybeContent as T[];
        if (Array.isArray(maybeData)) return maybeData as T[];

        // Push nested objects to stack for further inspection
        if (maybeData) stack.push(maybeData);
        if (maybeContent) stack.push(maybeContent);
        // Common alternative keys
        if ((current as any).result) stack.push((current as any).result);
        if ((current as any).payload) stack.push((current as any).payload);
      }
    }

    return [];
  }

  filterDevices(): void {
    // With server-side pagination enabled, we call the server instead.
    this.page = 0;
    this.persistFilters();
    this.loadDevices();
  }

  resetFilters(): void {
    this.filters = { status: '', driverId: '', query: '' };
    this.persistFilters();
    this.page = 0;
    this.loadDevices();
  }

  prevPage(): void {
    if (this.page > 0) {
      this.page = Math.max(0, this.page - 1);
      this.loadDevices();
    }
  }

  nextPage(): void {
    if (this.totalPages > 0 && this.page < this.totalPages - 1) {
      this.page = Math.min(this.totalPages - 1, this.page + 1);
      this.loadDevices();
    }
  }

  onSearchChange(): void {
    clearTimeout((this as any).__searchDebounce);
    (this as any).__searchDebounce = setTimeout(
      () => this.searchSubject$.next(this.filters.query),
      250,
    );
  }

  private persistFilters(): void {
    try {
      localStorage.setItem(this.FILTER_STORAGE_KEY, JSON.stringify(this.filters));
    } catch (err) {
      console.warn('Failed to persist device filters', err);
    }
  }

  private restoreFilters(): void {
    try {
      const saved = localStorage.getItem(this.FILTER_STORAGE_KEY);
      if (!saved) return;
      this.filters = Object.assign(this.filters, JSON.parse(saved));
    } catch (err) {
      console.warn('Failed to restore device filters', err);
    }
  }

  viewDevice(device: DeviceRegisterDto): void {
    this.selectedDevice = device;
    this.closeAllMenus();
  }

  // Selection helpers for bulk actions
  isSelected(device: DeviceRegisterDto): boolean {
    return !!device.id && this.selectedIds.has(device.id);
  }

  /**
   * Returns true when all currently filtered devices are selected.
   * Extracted into a method because arrow functions are not allowed
   * inside Angular template bindings.
   */
  allFilteredSelected(): boolean {
    return (
      !!this.filteredDevices &&
      this.filteredDevices.length > 0 &&
      this.filteredDevices.every((d) => (d.id ? this.selectedIds.has(d.id) : false))
    );
  }

  toggleSelect(device: DeviceRegisterDto, checked: boolean): void {
    if (!device.id) return;
    if (checked) this.selectedIds.add(device.id);
    else this.selectedIds.delete(device.id);
  }

  toggleSelectAll(checked: boolean): void {
    if (checked) {
      this.filteredDevices.forEach((d) => {
        if (d.id) this.selectedIds.add(d.id);
      });
    } else {
      this.filteredDevices.forEach((d) => {
        if (d.id) this.selectedIds.delete(d.id);
      });
    }
  }

  clearSelection(): void {
    this.selectedIds.clear();
  }

  trackByDevice(index: number, device: DeviceRegisterDto): any {
    return device.id ?? device.deviceId ?? index;
  }

  async performBulkChangeStatus(status: string): Promise<void> {
    if (this.selectedIds.size === 0) return;
    if (
      !(await this.confirm.confirm(
        `Apply status '${status}' to ${this.selectedIds.size} selected device(s)?`,
      ))
    )
      return;
    this.isProcessingBulk = true;
    const ids = Array.from(this.selectedIds);
    try {
      // perform sequential updates to avoid overwhelming server; could be parallel if API supports
      for (const id of ids) {
        // find the device object for optimistic UI or fallback
        await firstValueFrom(this.deviceService.updateDeviceStatus(id, status));
      }
      this.clearSelection();
      this.loadDevices();
    } catch (err) {
      console.error('Bulk status update failed:', err);
      this.driverService.showToast('Bulk operation failed. See console for details.');
    } finally {
      this.isProcessingBulk = false;
    }
  }

  async performBulkDelete(): Promise<void> {
    if (this.selectedIds.size === 0) return;
    if (
      !(await this.confirm.confirm(
        `Delete ${this.selectedIds.size} selected device(s)? This cannot be undone.`,
      ))
    )
      return;
    this.isProcessingBulk = true;
    const ids = Array.from(this.selectedIds);
    try {
      for (const id of ids) {
        await firstValueFrom(this.deviceService.deleteDevice(id));
      }
      this.clearSelection();
      this.loadDevices();
    } catch (err) {
      console.error('Bulk delete failed:', err);
      this.driverService.showToast('Bulk delete failed. See console for details.');
    } finally {
      this.isProcessingBulk = false;
    }
  }

  async changeStatus(device: DeviceRegisterDto, status: string): Promise<void> {
    if (!(await this.confirm.confirm(`Are you sure you want to change the status to ${status}?`)))
      return;

    this.isLoading = true;
    this.deviceService.updateDeviceStatus(device.id!, status).subscribe({
      next: () => {
        this.loadDevices();
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error(`Error changing device status to ${status}:`, error);
        this.isLoading = false;
        const msg =
          error?.message ||
          'Failed to change device status. Please check your permissions or try again.';
        this.driverService.showToast(msg);
      },
    });
    this.closeAllMenus();
  }

  async deleteDevice(device: DeviceRegisterDto): Promise<void> {
    if (!(await this.confirm.confirm(`Are you sure you want to delete device ${device.deviceId}?`)))
      return;

    this.deviceService.deleteDevice(device.id!).subscribe({
      next: () => {
        this.selectedDevice = undefined;
        this.loadDevices();
      },
      error: (error: any) => console.error('Error deleting device:', error),
    });
    this.closeAllMenus();
  }

  async openCreateDevicePrompt(): Promise<void> {
    // Minimal prompt-based create flow for quick testing using InputPromptService
    const deviceId = await this.inputPrompt.prompt('Enter device ID (required)');
    if (!deviceId) return;
    const deviceName = (await this.inputPrompt.prompt('Enter device name (optional)')) || '';
    const driverIdStr =
      (await this.inputPrompt.prompt('Enter driver ID (optional, numeric)')) || '';
    const driverId = driverIdStr ? Number(driverIdStr) : undefined;

    const dto: Partial<DeviceRegisterDto> = {
      deviceId,
      deviceName,
      driverId,
    } as any;

    this.isLoading = true;
    this.deviceService.createDevice(dto as DeviceRegisterDto).subscribe({
      next: () => {
        this.driverService.showToast('Device created successfully.');
        this.loadDevices();
        this.isLoading = false;
      },
      error: (err: any) => {
        console.error('Error creating device:', err);
        this.driverService.showToast(err?.message || 'Failed to create device.');
        this.isLoading = false;
      },
    });
  }

  toggleMenu(device: DeviceRegisterDto): void {
    this.filteredDevices.forEach((d) => {
      if (d !== device) d.showMenu = false;
    });
    device.showMenu = !device.showMenu;
  }

  closeAllMenus(): void {
    this.filteredDevices.forEach((d) => (d.showMenu = false));
  }

  @HostListener('document:click', ['$event'])
  onClickOutside(event: MouseEvent): void {
    const clickedInside =
      (event.target as HTMLElement).closest('.dropdown-menu') ||
      (event.target as HTMLElement).closest('.dropdown-trigger');
    if (!clickedInside) {
      this.closeAllMenus();
    }
  }
}
