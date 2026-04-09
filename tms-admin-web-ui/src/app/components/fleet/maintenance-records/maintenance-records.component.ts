import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';

import type { PagedResponse } from '../../../models/api-response-page.model';
import type { Vehicle } from '../../../models/vehicle.model';
import { VehicleService } from '../../../services/vehicle.service';
import { MaintenanceReportService } from '../../../services/maintenance-report.service';
import type { MaintenanceRequestDto } from '../../../services/maintenance-request.service';
import type { WorkOrderDto } from '../../../services/maintenance-work-order.service';

@Component({
  selector: 'app-maintenance-records',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6">
      <div class="flex flex-wrap items-center justify-between gap-3 mb-6">
        <div class="flex items-center gap-3">
          <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
            <i class="text-2xl text-blue-600 fas fa-history"></i>
          </div>
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Maintenance Records</h1>
            <p class="text-gray-600">Maintenance history per vehicle (MR + WO)</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <a
            class="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50"
            [routerLink]="['/fleet/maintenance/requests']"
            [queryParams]="vehicleId ? { vehicleId } : {}"
            >Open Requests</a
          >
          <a
            class="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700"
            [routerLink]="['/fleet/maintenance/work-orders']"
            [queryParams]="vehicleId ? { vehicleId } : {}"
            >Open Work Orders</a
          >
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="bg-white border rounded-lg shadow-sm p-4 mb-4">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
          <div class="md:col-span-2">
            <label class="block text-xs font-medium text-gray-700 mb-1">Vehicle</label>
            <input
              class="w-full px-3 py-2 border rounded-lg mb-2"
              [(ngModel)]="vehicleSearch"
              placeholder="Search vehicle plate..."
            />
            <select
              class="w-full px-3 py-2 border rounded-lg"
              [(ngModel)]="vehicleId"
              (change)="load()"
            >
              <option value="">Select vehicle</option>
              <option *ngFor="let v of filteredVehicles" [value]="v.id">
                {{ v.licensePlate }}
              </option>
            </select>
          </div>
          <div class="flex items-end gap-2">
            <button
              class="px-4 py-2 bg-blue-600 text-white rounded-lg"
              (click)="load()"
              [disabled]="isLoading"
              type="button"
            >
              Load
            </button>
            <button
              class="px-4 py-2 border rounded-lg"
              (click)="reset()"
              [disabled]="isLoading"
              type="button"
            >
              Reset
            </button>
          </div>
        </div>
      </div>

      <div
        *ngIf="isLoading"
        class="mb-4 p-3 rounded border border-blue-200 bg-blue-50 text-blue-700 text-sm"
      >
        Loading maintenance history...
      </div>

      <div
        *ngIf="!vehicleId && !isLoading"
        class="mb-6 rounded-lg border border-dashed border-gray-200 bg-gray-50 p-6 text-center text-sm text-gray-500"
      >
        Select a vehicle to view its maintenance history.
      </div>

      <div
        *ngIf="vehicleId && !isLoading && !history"
        class="mb-6 rounded-lg border border-dashed border-amber-200 bg-amber-50 p-6 text-center text-sm text-amber-700"
      >
        No maintenance history found for the selected vehicle.
      </div>

      <div *ngIf="history" class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Total MRs</div>
          <div class="text-xl font-bold text-gray-900">{{ summary.totalMrs }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Total WOs</div>
          <div class="text-xl font-bold text-gray-900">{{ summary.totalWos }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Open WOs</div>
          <div class="text-xl font-bold text-amber-700">{{ summary.openWos }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Last Maintenance</div>
          <div class="text-sm font-semibold text-gray-900">{{ summary.lastMaintenanceDate }}</div>
        </div>
      </div>

      <div *ngIf="history" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
          <div class="px-5 py-4 border-b">
            <h3 class="font-semibold text-gray-900">Maintenance Requests</h3>
            <p class="text-sm text-gray-600">{{ history.licensePlate }}</p>
            <button
              class="mt-2 text-xs font-semibold text-blue-600 hover:underline"
              type="button"
              (click)="exportMrCsv()"
              [disabled]="(mrs?.content?.length || 0) === 0"
            >
              Export CSV
            </button>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">MR #</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Title</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Requested</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Status</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr *ngFor="let mr of mrs?.content" class="border-t">
                  <td class="px-4 py-3 text-sm font-medium text-gray-900">{{ mr.mrNumber }}</td>
                  <td class="px-4 py-3 text-sm text-gray-700">{{ mr.title }}</td>
                  <td class="px-4 py-3 text-sm text-gray-700">{{ formatDate(mr.requestedAt) }}</td>
                  <td class="px-4 py-3 text-sm text-gray-700">{{ mr.status }}</td>
                  <td class="px-4 py-3 text-sm text-gray-700">
                    <a
                      class="text-blue-600 hover:underline"
                      [routerLink]="['/fleet/maintenance/requests', mr.id]"
                      [queryParams]="{ group: 'overview' }"
                      >Open</a
                    >
                  </td>
                </tr>
                <tr *ngIf="(mrs?.content?.length || 0) === 0">
                  <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="5">
                    No maintenance requests
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
          <div class="px-5 py-4 border-b">
            <h3 class="font-semibold text-gray-900">Work Orders</h3>
            <p class="text-sm text-gray-600">{{ history.licensePlate }}</p>
            <button
              class="mt-2 text-xs font-semibold text-blue-600 hover:underline"
              type="button"
              (click)="exportWoCsv()"
              [disabled]="(wos?.content?.length || 0) === 0"
            >
              Export CSV
            </button>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">WO #</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Repair</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Planned</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Actual</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Status</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr *ngFor="let wo of wos?.content" class="border-t">
                  <td class="px-4 py-3 text-sm font-medium text-gray-900">{{ wo.woNumber }}</td>
                  <td class="px-4 py-3 text-sm text-gray-700">{{ wo.repairType || '-' }}</td>
                  <td class="px-4 py-3 text-sm text-gray-700">
                    {{ formatDate(wo.scheduledDate) }}
                  </td>
                  <td class="px-4 py-3 text-sm text-gray-700">{{ formatDate(wo.completedAt) }}</td>
                  <td class="px-4 py-3 text-sm text-gray-700">{{ wo.status }}</td>
                  <td class="px-4 py-3 text-sm text-gray-700">
                    <a
                      class="text-blue-600 hover:underline"
                      [routerLink]="['/fleet/maintenance/work-orders', wo.id]"
                      [queryParams]="{ group: 'overview' }"
                      >Open</a
                    >
                  </td>
                </tr>
                <tr *ngIf="(wos?.content?.length || 0) === 0">
                  <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="6">
                    No work orders
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class MaintenanceRecordsComponent implements OnInit {
  vehicles: Vehicle[] = [];
  vehicleSearch = '';
  vehicleId: number | '' = '';
  isLoading = false;

  history: any = null;
  mrs: PagedResponse<MaintenanceRequestDto> | null = null;
  wos: PagedResponse<WorkOrderDto> | null = null;

  error = '';

  get filteredVehicles(): Vehicle[] {
    const q = this.vehicleSearch.trim().toLowerCase();
    if (!q) return this.vehicles;
    return this.vehicles.filter((v) => (v.licensePlate || '').toLowerCase().includes(q));
  }

  get summary(): {
    totalMrs: number;
    totalWos: number;
    openWos: number;
    lastMaintenanceDate: string;
  } {
    const mrs = this.mrs?.content ?? [];
    const wos = this.wos?.content ?? [];
    const openWos = wos.filter(
      (wo) => wo.status !== 'COMPLETED' && wo.status !== 'CANCELLED',
    ).length;
    const allDates = [
      ...mrs.map((mr) => mr.requestedAt).filter(Boolean),
      ...wos.map((wo) => wo.completedAt || wo.scheduledDate).filter(Boolean),
    ] as string[];
    const lastDate = allDates
      .map((d) => new Date(d))
      .filter((d) => !Number.isNaN(d.getTime()))
      .sort((a, b) => b.getTime() - a.getTime())[0];
    return {
      totalMrs: mrs.length,
      totalWos: wos.length,
      openWos,
      lastMaintenanceDate: lastDate ? this.formatDate(lastDate.toISOString()) : '-',
    };
  }

  constructor(
    private readonly vehicleService: VehicleService,
    private readonly reportService: MaintenanceReportService,
    private readonly route: ActivatedRoute,
  ) {}

  formatDate(value?: string | null): string {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
    }).format(date);
  }

  ngOnInit(): void {
    this.vehicleService.getVehicles(0, 200, {}).subscribe({
      next: (res: any) => (this.vehicles = res?.data?.content ?? []),
      error: () => {},
    });
    this.route.queryParamMap.subscribe((params) => {
      const vehicleId = params.get('vehicleId');
      if (vehicleId) {
        this.vehicleId = Number(vehicleId);
        this.load();
      }
    });
  }

  reset(): void {
    this.vehicleSearch = '';
    this.vehicleId = '';
    this.isLoading = false;
    this.history = null;
    this.mrs = null;
    this.wos = null;
    this.error = '';
  }

  load(): void {
    this.error = '';
    if (!this.vehicleId) return;
    this.isLoading = true;
    this.reportService.vehicleHistory(Number(this.vehicleId), { page: 0, size: 20 }).subscribe({
      next: (res) => {
        this.history = res.data;
        this.mrs = (res.data as any)?.maintenanceRequests ?? null;
        this.wos = (res.data as any)?.workOrders ?? null;
      },
      error: (err) => {
        console.error(err);
        this.error = 'Failed to load maintenance history.';
      },
      complete: () => {
        this.isLoading = false;
      },
    });
  }

  exportMrCsv(): void {
    const rows = this.mrs?.content ?? [];
    this.downloadCsv(
      'maintenance_requests.csv',
      rows,
      ['mr_number', 'vehicle_id', 'title', 'status', 'priority', 'requested_at'],
      (mr) => [mr.mrNumber, mr.vehicleId, mr.title, mr.status, mr.priority, mr.requestedAt],
    );
  }

  exportWoCsv(): void {
    const rows = this.wos?.content ?? [];
    this.downloadCsv(
      'work_orders.csv',
      rows,
      ['wo_number', 'vehicle_id', 'repair_type', 'status', 'scheduled_date', 'completed_at'],
      (wo) => [
        wo.woNumber,
        wo.vehicleId,
        wo.repairType,
        wo.status,
        wo.scheduledDate,
        wo.completedAt,
      ],
    );
  }

  private downloadCsv(
    filename: string,
    rows: any[],
    headers: string[],
    mapRow: (row: any) => Array<string | number | null | undefined>,
  ): void {
    const escape = (value: string) => `"${value.replace(/"/g, '""')}"`;
    const lines = [headers.join(',')];
    rows.forEach((row) => {
      const values = mapRow(row).map((value) => {
        if (value === null || value === undefined) return '';
        const str = String(value);
        return str.includes(',') || str.includes('"') || str.includes('\n') ? escape(str) : str;
      });
      lines.push(values.join(','));
    });
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.click();
    URL.revokeObjectURL(link.href);
  }
}
