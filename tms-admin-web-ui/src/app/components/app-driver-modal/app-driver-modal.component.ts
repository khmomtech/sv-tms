import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';

import type { ApiResponse } from '../../models/api-response.model';
import type { Driver } from '../../models/driver.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DriverService } from '../../services/driver.service';

@Component({
  selector: 'app-driver-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div
      *ngIf="visible"
      class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50"
    >
      <div class="bg-white rounded-lg p-6 w-full max-w-2xl shadow-lg">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-semibold">Select Driver</h3>
          <button (click)="close.emit()" class="text-gray-500 hover:text-red-600 text-lg">
            &times;
          </button>
        </div>

        <input
          [(ngModel)]="searchTerm"
          (input)="onSearchInput()"
          placeholder="Search drivers by name or phone..."
          class="w-full p-2 border rounded mb-4"
        />

        <div class="grid grid-cols-2 gap-4 mb-4">
          <div>
            <label>Status</label>
            <select
              [(ngModel)]="filterStatus"
              (ngModelChange)="applyFilters()"
              class="w-full p-2 border rounded"
            >
              <option value="">All</option>
              <option value="ONLINE">ONLINE</option>
              <option value="OFFLINE">OFFLINE</option>
              <option value="on-trip">On Trip</option>
              <option value="busy">Busy</option>
              <option value="idle">Idle</option>
            </select>
          </div>
          <div>
            <label>Vehicle Type</label>
            <select
              [(ngModel)]="filterType"
              (ngModelChange)="applyFilters()"
              class="w-full p-2 border rounded"
            >
              <option value="">All</option>
              <option value="truck">Truck</option>
              <option value="van">Van</option>
              <option value="bike">Bike</option>
            </select>
          </div>
          <div>
            <label>Zone</label>
            <input
              [(ngModel)]="filterZone"
              (ngModelChange)="applyFilters()"
              class="w-full p-2 border rounded"
              placeholder="Enter zone..."
            />
          </div>
          <div>
            <label>Partner</label>
            <select
              [(ngModel)]="filterPartner"
              (ngModelChange)="applyFilters()"
              class="w-full p-2 border rounded"
            >
              <option value="">All</option>
              <option value="partner">Partner</option>
              <option value="internal">Internal</option>
            </select>
          </div>
        </div>

        <div class="max-h-60 overflow-y-auto border rounded">
          <div *ngIf="loading" class="p-4 text-sm text-gray-500">Loading drivers...</div>
          <div *ngIf="!loading && errorMsg" class="p-4 text-sm text-red-600">{{ errorMsg }}</div>
          <div
            *ngIf="!loading && !errorMsg && filteredDrivers.length === 0"
            class="p-4 text-sm text-gray-500"
          >
            No drivers found.
          </div>
          <ul *ngIf="!loading && !errorMsg && filteredDrivers.length > 0" class="list-none m-0 p-0">
            <li
              *ngFor="let driver of filteredDriversList()"
              class="cursor-pointer px-4 py-2 border-b hover:bg-gray-100"
              (click)="chooseDriver(driver)"
            >
              <div class="font-medium">{{ getDriverDisplayName(driver) }}</div>
              <div class="text-sm text-gray-600">
                {{ getDriverPhone(driver) || 'No Phone' }} •
                {{ getDriverVehiclePlate(driver) || 'No Vehicle' }}
              </div>
            </li>
          </ul>
        </div>

        <div class="flex justify-end mt-4">
          <button
            (click)="close.emit()"
            class="px-4 py-2 text-white bg-red-500 hover:bg-red-600 rounded"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  `,
})
export class AppDriverModalComponent implements OnInit {
  @Input() visible = false;
  @Output() close = new EventEmitter<void>();
  @Output() selected = new EventEmitter<Driver>();

  searchTerm = '';
  drivers: Driver[] = []; // full list from initial load
  sourceDrivers: Driver[] = []; // current list from search/all
  filteredDrivers: Driver[] = [];

  filterStatus = '';
  filterZone = '';
  filterType = '';
  filterPartner = '';
  loading = false;
  errorMsg = '';

  private searchSubject = new Subject<string>();

  constructor(private readonly driverService: DriverService) {}

  /**
   * Normalizes driver responses from the API.
   * The backend sometimes returns a plain array and other times wraps it in a PageResponse.
   */
  private extractDrivers(response: ApiResponse<any>): any[] {
    if (!response) return [];
    if (Array.isArray(response.data)) return response.data;
    if (Array.isArray(response.data?.content)) return response.data.content;
    if (Array.isArray((response as any).content)) return (response as any).content;
    return [];
  }

  getDriverDisplayName(driver: any): string {
    if (!driver) return 'Unknown Driver';
    if (driver.name && String(driver.name).trim()) return String(driver.name).trim();
    if (driver.fullName && String(driver.fullName).trim()) return String(driver.fullName).trim();

    const first = String(driver.firstName || '').trim();
    const last = String(driver.lastName || '').trim();
    const full = `${first} ${last}`.trim();
    if (full) return full;

    return 'Unknown Driver';
  }

  getDriverPhone(driver: any): string {
    if (!driver) return '';
    return String(driver.phone || driver.phoneNumber || '').trim();
  }

  getDriverVehiclePlate(driver: any): string {
    if (!driver) return '';
    return String(driver.currentVehiclePlate || driver.assignedVehicle?.licensePlate || '').trim();
  }

  ngOnInit(): void {
    this.loadDrivers();

    this.searchSubject.pipe(debounceTime(300), distinctUntilChanged()).subscribe((term) => {
      if (term.trim()) {
        this.searchDrivers(term);
      } else {
        this.filteredDrivers = [...this.drivers];
        this.applyFilters();
      }
    });
  }

  loadDrivers(): void {
    this.loading = true;
    this.errorMsg = '';
    this.driverService.getAllDriversModal().subscribe({
      next: (response: ApiResponse<any>) => {
        this.drivers = this.extractDrivers(response);
        this.sourceDrivers = [...this.drivers];
        this.filteredDrivers = [...this.drivers];
        this.applyFilters();
        this.loading = false;
      },
      error: (err) => {
        console.error(' Failed to load drivers:', err);
        this.errorMsg = 'Failed to load drivers';
        this.loading = false;
      },
    });
  }

  onSearchInput(): void {
    this.searchSubject.next(this.searchTerm);
  }

  searchDrivers(term: string): void {
    this.loading = true;
    this.errorMsg = '';
    this.driverService.searchDrivers(term).subscribe({
      next: (response: ApiResponse<any>) => {
        const content = this.extractDrivers(response);
        this.sourceDrivers = content;
        this.filteredDrivers = [...content];
        this.applyFilters();
        this.loading = false;
      },
      error: (err) => {
        console.error('Search error:', err);
        this.errorMsg = 'Search failed';
        // Preserve last known list instead of clearing the UI
        this.filteredDrivers = this.sourceDrivers.length
          ? [...this.sourceDrivers]
          : [...this.drivers];
        this.loading = false;
      },
    });
  }

  applyFilters(): void {
    const base = this.sourceDrivers.length ? this.sourceDrivers : this.drivers;
    this.filteredDrivers = base.filter((driver) => {
      const displayName = this.getDriverDisplayName(driver).toLowerCase();
      const phone = this.getDriverPhone(driver).toLowerCase();
      const matchNameOrPhone = this.searchTerm
        ? displayName.includes(this.searchTerm.toLowerCase()) ||
          phone.includes(this.searchTerm.toLowerCase())
        : true;

      const matchStatus = this.filterStatus ? driver.status === this.filterStatus : true;
      const matchType = this.filterType ? driver.assignedVehicle?.type === this.filterType : true;
      const matchZone = this.filterZone
        ? (driver.zone || '').toLowerCase().includes(this.filterZone.toLowerCase())
        : true;
      const matchPartner =
        this.filterPartner === 'partner'
          ? driver.isPartner === true
          : this.filterPartner === 'internal'
            ? driver.isPartner === false
            : true;

      return matchNameOrPhone && matchStatus && matchType && matchZone && matchPartner;
    });
  }

  filteredDriversList(): Driver[] {
    return this.filteredDrivers;
  }

  private normalizeDriverForSelection(driver: Driver): Driver {
    const displayName = this.getDriverDisplayName(driver);
    const phone = this.getDriverPhone(driver);

    return {
      ...driver,
      name: displayName,
      fullName: displayName,
      phone,
    } as Driver;
  }

  chooseDriver(driver: Driver): void {
    this.selected.emit(this.normalizeDriverForSelection(driver));
    this.close.emit();
  }
}
