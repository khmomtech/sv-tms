import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { PmReportService, type PmReportSummaryDto } from '../../../services/pm-report.service';
import { PmRunService, type PmRunDto, type PmRunStatus } from '../../../services/pm-run.service';

@Component({
  selector: 'app-pm-reports',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="p-6">
      <div class="mb-6 flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">PM Reports</h1>
          <p class="text-gray-600">Completion, overdue, cost, and downtime insights</p>
        </div>
        <div class="flex items-center gap-2">
          <button
            class="px-4 py-2 border rounded-lg text-sm"
            type="button"
            (click)="exportSummaryJson()"
          >
            Export JSON
          </button>
          <button
            class="px-4 py-2 bg-blue-600 text-white rounded-lg"
            type="button"
            (click)="load()"
          >
            Refresh
          </button>
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6" *ngIf="summary">
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Completion Rate</div>
          <div class="text-2xl font-bold text-emerald-600">
            {{ summary.completionRate | percent: '1.0-0' }}
          </div>
        </div>
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Overdue Rate</div>
          <div class="text-2xl font-bold text-red-600">
            {{ summary.overdueRate | percent: '1.0-0' }}
          </div>
        </div>
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Total PM Cost</div>
          <div class="text-2xl font-bold text-gray-900">
            {{ summary.totalPmCost | number: '1.0-0' }}
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div class="bg-white rounded-lg border">
          <div class="p-4 border-b font-semibold">Top PM Costs</div>
          <div class="p-4">
            <div *ngIf="summary?.topCosts?.length === 0" class="text-sm text-gray-500">
              No cost data.
            </div>
            <button
              *ngIf="summary?.topCosts?.length"
              class="mb-3 text-xs font-semibold text-blue-600 hover:underline"
              type="button"
              (click)="exportTopCosts()"
            >
              Export CSV
            </button>
            <div *ngFor="let item of summary?.topCosts" class="border rounded p-3 mb-2">
              <div class="font-medium">{{ item.workOrderNumber || 'WO ' + item.workOrderId }}</div>
              <div class="text-xs text-gray-500">
                {{ item.vehiclePlate || 'Vehicle ' + item.vehicleId }}
              </div>
              <div class="text-sm text-gray-900">{{ item.actualCost | number: '1.0-0' }}</div>
            </div>
          </div>
        </div>
        <div class="bg-white rounded-lg border">
          <div class="p-4 border-b font-semibold">Vehicle Downtime</div>
          <div class="p-4">
            <div *ngIf="summary?.downtime?.length === 0" class="text-sm text-gray-500">
              No downtime records.
            </div>
            <button
              *ngIf="summary?.downtime?.length"
              class="mb-3 text-xs font-semibold text-blue-600 hover:underline"
              type="button"
              (click)="exportDowntime()"
            >
              Export CSV
            </button>
            <div *ngFor="let item of summary?.downtime" class="border rounded p-3 mb-2">
              <div class="font-medium">{{ item.vehiclePlate || 'Vehicle ' + item.vehicleId }}</div>
              <div class="text-xs text-gray-500">
                {{ item.startAt }} → {{ item.endAt || 'ongoing' }}
              </div>
              <div class="text-sm text-gray-900">{{ item.reason || '-' }}</div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white rounded-lg border">
        <div
          class="p-4 border-b flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
        >
          <div>
            <h2 class="text-lg font-semibold text-gray-900">PM Daily Details</h2>
            <p class="text-sm text-gray-500">Filter PM runs by date range</p>
          </div>
          <div class="flex flex-wrap items-end gap-2">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">From</label>
              <input type="date" class="border rounded px-3 py-2 text-sm" [(ngModel)]="dailyFrom" />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">To</label>
              <input type="date" class="border rounded px-3 py-2 text-sm" [(ngModel)]="dailyTo" />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Status</label>
              <select class="border rounded px-3 py-2 text-sm" [(ngModel)]="dailyStatus">
                <option [ngValue]="undefined">All</option>
                <option value="DUE">DUE</option>
                <option value="IN_PROGRESS">IN_PROGRESS</option>
                <option value="COMPLETED">COMPLETED</option>
                <option value="SKIPPED">SKIPPED</option>
                <option value="RESCHEDULED">RESCHEDULED</option>
                <option value="CANCELLED">CANCELLED</option>
              </select>
            </div>
            <button
              class="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm"
              type="button"
              (click)="loadDaily()"
            >
              Apply
            </button>
          </div>
        </div>
        <div class="p-4 overflow-x-auto">
          <div *ngIf="dailyLoading" class="text-sm text-gray-500">Loading PM daily details…</div>
          <table class="min-w-full text-sm" *ngIf="!dailyLoading">
            <thead class="text-xs uppercase tracking-wide text-gray-500">
              <tr>
                <th class="py-2 px-3 text-left">Date</th>
                <th class="py-2 px-3 text-left">Plan</th>
                <th class="py-2 px-3 text-left">Vehicle</th>
                <th class="py-2 px-3 text-left">Status</th>
                <th class="py-2 px-3 text-left">Due</th>
                <th class="py-2 px-3 text-left">Performed</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngIf="dailyRuns.length === 0">
                <td class="py-4 px-3 text-gray-500" colspan="6">No PM runs found.</td>
              </tr>
              <tr *ngFor="let run of dailyRuns" class="border-t">
                <td class="py-2 px-3">{{ run.dueDate || run.performedAt || '-' }}</td>
                <td class="py-2 px-3">{{ run.planName || run.itemName || 'PM Plan' }}</td>
                <td class="py-2 px-3">{{ run.vehiclePlate || 'Vehicle ' + run.vehicleId }}</td>
                <td class="py-2 px-3">{{ run.status }}</td>
                <td class="py-2 px-3">{{ run.dueKm ? run.dueKm + ' km' : run.dueDate || '-' }}</td>
                <td class="py-2 px-3">{{ run.performedAt || '-' }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `,
})
export class PmReportsComponent implements OnInit {
  summary?: PmReportSummaryDto;
  error = '';
  dailyRuns: PmRunDto[] = [];
  dailyLoading = false;
  dailyFrom = '';
  dailyTo = '';
  dailyStatus?: PmRunStatus;

  constructor(
    private readonly reportService: PmReportService,
    private readonly pmRunService: PmRunService,
  ) {}

  ngOnInit(): void {
    const today = new Date();
    const from = new Date();
    from.setDate(today.getDate() - 7);
    this.dailyFrom = from.toISOString().slice(0, 10);
    this.dailyTo = today.toISOString().slice(0, 10);
    this.load();
    this.loadDaily();
  }

  load(): void {
    this.error = '';
    this.reportService.getSummary().subscribe({
      next: (res) => (this.summary = res.data),
      error: () => (this.error = 'Failed to load PM reports.'),
    });
  }

  loadDaily(): void {
    this.dailyLoading = true;
    this.pmRunService
      .list({
        from: this.dailyFrom || undefined,
        to: this.dailyTo || undefined,
        status: this.dailyStatus,
        page: 0,
        size: 100,
      })
      .subscribe({
        next: (res) => {
          const payload = res?.data ?? (res as any);
          this.dailyRuns = payload?.content ?? [];
          this.dailyLoading = false;
        },
        error: () => {
          this.dailyRuns = [];
          this.dailyLoading = false;
        },
      });
  }

  exportSummaryJson(): void {
    if (!this.summary) return;
    const blob = new Blob([JSON.stringify(this.summary, null, 2)], {
      type: 'application/json;charset=utf-8;',
    });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'pm_report_summary.json';
    link.click();
    URL.revokeObjectURL(link.href);
  }

  exportTopCosts(): void {
    const rows = this.summary?.topCosts ?? [];
    this.downloadCsv('pm_top_costs.csv', rows, ['work_order', 'vehicle', 'actual_cost'], (row) => [
      row.workOrderNumber || row.workOrderId,
      row.vehiclePlate || row.vehicleId,
      row.actualCost,
    ]);
  }

  exportDowntime(): void {
    const rows = this.summary?.downtime ?? [];
    this.downloadCsv(
      'pm_vehicle_downtime.csv',
      rows,
      ['vehicle', 'start', 'end', 'reason'],
      (row) => [row.vehiclePlate || row.vehicleId, row.startAt, row.endAt, row.reason],
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
