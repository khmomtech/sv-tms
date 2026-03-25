import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { MaintenanceReportService } from '../../../services/maintenance-report.service';

@Component({
  selector: 'app-repairs',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="p-6">
      <div class="flex items-center gap-3 mb-6">
        <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
          <i class="text-2xl text-blue-600 fas fa-chart-line"></i>
        </div>
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Repairs</h1>
          <p class="text-gray-600">PM vs corrective, breakdowns after PM, cost analysis</p>
          <p class="text-xs text-gray-500 mt-1">
            Last refresh: {{ asOf ? (asOf | date: 'medium') : '-' }}
          </p>
        </div>
      </div>

      <div
        *ngIf="isLoading"
        class="mb-4 p-3 rounded border border-blue-200 bg-blue-50 text-blue-700 text-sm"
      >
        Loading repair analytics...
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>
      <div
        *ngIf="failedWidgets.length"
        class="mb-4 p-3 rounded border border-amber-200 bg-amber-50 text-amber-800 text-sm"
      >
        Partial data failed: {{ failedWidgets.join(', ') }}
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div class="bg-white border rounded-lg shadow-sm p-4">
          <div class="text-sm text-gray-600">PM vs Corrective</div>
          <div class="mt-2 text-2xl font-bold text-gray-900">
            {{ pmVsCorrective?.pmCount ?? 0 }} / {{ pmVsCorrective?.totalCompleted ?? 0 }}
          </div>
          <div class="text-xs text-gray-500 mt-1">
            PM share {{ (pmVsCorrective?.pmShare ?? 0) * 100 | number: '1.0-1' }}%
          </div>
        </div>
        <div class="bg-white border rounded-lg shadow-sm p-4">
          <div class="text-sm text-gray-600">Breakdowns After PM</div>
          <div class="mt-2 text-2xl font-bold text-gray-900">
            {{ breakdownAfterPm?.breakdownCount ?? 0 }}
          </div>
          <div class="text-xs text-gray-500 mt-1">
            Window {{ breakdownAfterPm?.windowDays ?? breakdownDays }} days
          </div>
        </div>
        <div class="bg-white border rounded-lg shadow-sm p-4">
          <div class="text-sm text-gray-600">OWN vs VENDOR Cost</div>
          <div class="mt-2 text-2xl font-bold text-gray-900">
            {{ formatCurrency(costByRepairType?.totalCost) }}
          </div>
          <div class="text-xs text-gray-500 mt-1">
            OWN {{ formatCurrency(costByRepairType?.ownCost) }} · VENDOR
            {{ formatCurrency(costByRepairType?.vendorCost) }}
          </div>
        </div>
      </div>

      <div class="bg-white border rounded-lg shadow-sm p-4 mb-6 flex flex-wrap items-center gap-3">
        <div class="flex items-center gap-2">
          <label class="text-sm text-gray-700">Top vehicles:</label>
          <select class="px-3 py-2 border rounded-lg text-sm" [(ngModel)]="limit" (change)="load()">
            <option [ngValue]="10">10</option>
            <option [ngValue]="20">20</option>
            <option [ngValue]="50">50</option>
          </select>
        </div>
        <div class="flex items-center gap-2">
          <label class="text-sm text-gray-700">Breakdown window:</label>
          <select
            class="px-3 py-2 border rounded-lg text-sm"
            [(ngModel)]="breakdownDays"
            (change)="load()"
          >
            <option [ngValue]="14">14 days</option>
            <option [ngValue]="30">30 days</option>
            <option [ngValue]="60">60 days</option>
          </select>
        </div>
        <div class="flex items-center gap-2">
          <label class="text-sm text-gray-700">Preset:</label>
          <select
            class="px-3 py-2 border rounded-lg text-sm"
            [(ngModel)]="breakdownPresetDays"
            (change)="onPresetChange()"
          >
            <option [ngValue]="7">Last 7 days</option>
            <option [ngValue]="30">Last 30 days</option>
            <option [ngValue]="90">Last 90 days</option>
          </select>
        </div>
        <button
          class="ml-auto px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          (click)="load()"
          type="button"
        >
          Refresh
        </button>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
          <div class="px-5 py-4 border-b">
            <div class="flex items-center justify-between">
              <h3 class="font-semibold text-gray-900">Cost Per Vehicle</h3>
              <button
                class="text-xs font-semibold text-blue-600 hover:underline"
                type="button"
                (click)="exportCostPerVehicle()"
                [disabled]="rows.length === 0"
                [title]="rows.length === 0 ? 'No data to export' : ''"
              >
                Export CSV
              </button>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Vehicle</th>
                  <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">
                    Total Cost
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr *ngFor="let row of rows" class="border-t">
                  <td class="px-4 py-3 text-sm text-gray-800">
                    {{ row.licensePlate || row.vehicleId }}
                  </td>
                  <td class="px-4 py-3 text-sm text-right text-gray-800">
                    {{ formatCurrency(row.totalCost) }}
                  </td>
                </tr>
                <tr *ngIf="rows.length === 0">
                  <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="2">No data</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
          <div class="px-5 py-4 border-b">
            <div class="flex items-center justify-between">
              <h3 class="font-semibold text-gray-900">Cost Per Vehicle / Km</h3>
              <button
                class="text-xs font-semibold text-blue-600 hover:underline"
                type="button"
                (click)="exportCostPerVehicleKm()"
                [disabled]="kmRows.length === 0"
                [title]="kmRows.length === 0 ? 'No data to export' : ''"
              >
                Export CSV
              </button>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Vehicle</th>
                  <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">
                    Total Cost
                  </th>
                  <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">Mileage</th>
                  <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">Cost/Km</th>
                </tr>
              </thead>
              <tbody>
                <tr *ngFor="let row of kmRows" class="border-t">
                  <td class="px-4 py-3 text-sm text-gray-800">
                    {{ row.licensePlate || row.vehicleId }}
                  </td>
                  <td class="px-4 py-3 text-sm text-right text-gray-800">
                    {{ formatCurrency(row.totalCost) }}
                  </td>
                  <td class="px-4 py-3 text-sm text-right text-gray-800">
                    {{ row.mileage ?? '-' }}
                  </td>
                  <td class="px-4 py-3 text-sm text-right text-gray-800">
                    {{ row.costPerKm ?? '-' }}
                  </td>
                </tr>
                <tr *ngIf="kmRows.length === 0">
                  <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="4">No data</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="bg-white border rounded-lg shadow-sm overflow-hidden mt-6">
        <div class="px-5 py-4 border-b flex items-center justify-between">
          <h3 class="font-semibold text-gray-900">
            Breakdowns After PM ({{ breakdownDays }} days)
          </h3>
          <span class="text-xs text-gray-500"
            >Total: {{ breakdownAfterPm?.breakdownCount ?? 0 }}</span
          >
          <button
            class="ml-auto text-xs font-semibold text-blue-600 hover:underline"
            type="button"
            (click)="exportBreakdowns()"
            [disabled]="breakdownOccurrences.length === 0"
            [title]="breakdownOccurrences.length === 0 ? 'No data to export' : ''"
          >
            Export CSV
          </button>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Vehicle</th>
                <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">PM WO</th>
                <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">
                  Corrective WO
                </th>
                <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">Days After</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let row of breakdownOccurrences" class="border-t">
                <td class="px-4 py-3 text-sm text-gray-800">{{ row.vehicleId }}</td>
                <td class="px-4 py-3 text-sm text-right text-gray-800">{{ row.pmWorkOrderId }}</td>
                <td class="px-4 py-3 text-sm text-right text-gray-800">
                  {{ row.correctiveWorkOrderId }}
                </td>
                <td class="px-4 py-3 text-sm text-right text-gray-800">{{ row.daysAfter }}</td>
              </tr>
              <tr *ngIf="breakdownOccurrences.length === 0">
                <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="4">
                  No breakdowns detected in the selected window.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `,
})
export class RepairsComponent implements OnInit {
  rows: any[] = [];
  kmRows: any[] = [];
  pmVsCorrective: Record<string, any> | null = null;
  breakdownAfterPm: Record<string, any> | null = null;
  breakdownOccurrences: any[] = [];
  costByRepairType: Record<string, any> | null = null;
  limit = 20;
  breakdownDays = 30;
  breakdownPresetDays = 30;
  error = '';
  asOf: Date | null = null;
  isLoading = false;
  failedWidgets: string[] = [];

  constructor(private readonly reportService: MaintenanceReportService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.error = '';
    this.failedWidgets = [];
    this.isLoading = true;
    forkJoin({
      costPerVehicle: this.reportService
        .costPerVehicle(this.limit)
        .pipe(catchError(() => of(null))),
      costPerVehicleKm: this.reportService
        .costPerVehicleKm(this.limit)
        .pipe(catchError(() => of(null))),
      pmVsCorrective: this.reportService.pmVsCorrective().pipe(catchError(() => of(null))),
      breakdownAfterPm: this.reportService
        .breakdownsAfterPm(this.breakdownDays)
        .pipe(catchError(() => of(null))),
      costByRepairType: this.reportService.costByRepairType().pipe(catchError(() => of(null))),
    }).subscribe({
      next: (res) => {
        let partial = false;
        if (res.costPerVehicle?.data) {
          this.rows = res.costPerVehicle.data || [];
        } else {
          this.rows = [];
          partial = true;
          this.failedWidgets.push('Cost Per Vehicle');
        }
        if (res.costPerVehicleKm?.data) {
          this.kmRows = res.costPerVehicleKm.data || [];
        } else {
          this.kmRows = [];
          partial = true;
          this.failedWidgets.push('Cost Per Vehicle / Km');
        }
        if (res.pmVsCorrective?.data) {
          this.pmVsCorrective = res.pmVsCorrective.data || null;
        } else {
          this.pmVsCorrective = null;
          partial = true;
          this.failedWidgets.push('PM vs Corrective');
        }
        if (res.breakdownAfterPm?.data) {
          this.breakdownAfterPm = res.breakdownAfterPm.data || null;
          this.breakdownOccurrences = this.breakdownAfterPm?.['occurrences'] || [];
        } else {
          this.breakdownAfterPm = null;
          this.breakdownOccurrences = [];
          partial = true;
          this.failedWidgets.push('Breakdowns After PM');
        }
        if (res.costByRepairType?.data) {
          this.costByRepairType = res.costByRepairType.data || null;
        } else {
          this.costByRepairType = null;
          partial = true;
          this.failedWidgets.push('OWN vs VENDOR Cost');
        }
        this.error = partial ? 'Some report data failed to load.' : '';
        this.asOf = new Date();
      },
      error: (err) => {
        console.error(err);
        this.error = 'Failed to load maintenance reports.';
      },
      complete: () => {
        this.isLoading = false;
      },
    });
  }

  onPresetChange(): void {
    this.breakdownDays = this.breakdownPresetDays;
    this.load();
  }

  formatCurrency(value: any): string {
    const amount = Number(value ?? 0);
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 2,
    }).format(Number.isFinite(amount) ? amount : 0);
  }

  exportCostPerVehicle(): void {
    this.downloadCsv('cost_per_vehicle.csv', this.rows, ['vehicle', 'total_cost'], (row) => [
      row.licensePlate || row.vehicleId,
      row.totalCost,
    ]);
  }

  exportCostPerVehicleKm(): void {
    this.downloadCsv(
      'cost_per_vehicle_km.csv',
      this.kmRows,
      ['vehicle', 'total_cost', 'mileage', 'cost_per_km'],
      (row) => [row.licensePlate || row.vehicleId, row.totalCost, row.mileage, row.costPerKm],
    );
  }

  exportBreakdowns(): void {
    this.downloadCsv(
      'breakdowns_after_pm.csv',
      this.breakdownOccurrences,
      ['vehicle_id', 'pm_work_order_id', 'corrective_work_order_id', 'days_after'],
      (row) => [row.vehicleId, row.pmWorkOrderId, row.correctiveWorkOrderId, row.daysAfter],
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
