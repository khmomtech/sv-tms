import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { forkJoin } from 'rxjs';
import { SafetyCheckService } from '../services/safety-check.service';
import type { SafetyCheck } from '../models/safety-check.model';

interface StatusStat {
  label: string;
  count: number;
  colorClass: string;
}

@Component({
  selector: 'app-safety-check-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-4 space-y-4">
      <!-- Header -->
      <div class="flex items-start justify-between">
        <div>
          <h1 class="text-xl font-semibold text-gray-900">ត្រួតពិនិត្យសុវត្ថិភាពប្រចាំថ្ងៃ</h1>
          <p class="text-sm text-gray-500 mt-0.5">
            ត្រួតពិនិត្យ និងអនុម័តការត្រួតពិនិត្យសុវត្ថិភាពរបស់អ្នកបើកបរ
          </p>
        </div>
        <div class="flex gap-2 flex-shrink-0">
          <button
            class="inline-flex items-center gap-1.5 rounded-md border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 disabled:opacity-50"
            (click)="doExportCsv()"
            [disabled]="exporting"
          >
            <svg
              class="h-4 w-4 text-green-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            {{ exporting ? 'Exporting...' : 'CSV' }}
          </button>
          <button
            class="inline-flex items-center gap-1.5 rounded-md border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 disabled:opacity-50"
            (click)="doExportExcel()"
            [disabled]="exporting"
          >
            <svg
              class="h-4 w-4 text-blue-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            {{ exporting ? 'Exporting...' : 'Excel' }}
          </button>
        </div>
      </div>

      <!-- KPI Cards (server-side totals, loaded in parallel) -->
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-gray-200 text-center">
          <div class="text-2xl font-bold text-gray-900">
            {{ statsLoading ? '–' : totalElements }}
          </div>
          <div class="text-xs text-gray-500 mt-1">សរុបទាំងអស់</div>
        </div>
        <div
          *ngFor="let stat of statusStats"
          class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-gray-200 text-center"
        >
          <div class="text-2xl font-bold" [ngClass]="stat.colorClass">
            {{ statsLoading ? '–' : stat.count }}
          </div>
          <div class="text-xs text-gray-500 mt-1">{{ stat.label }}</div>
        </div>
      </div>

      <!-- Filters -->
      <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-gray-200">
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
          <div class="lg:col-span-2">
            <label class="block text-xs font-medium text-gray-700 mb-1">ស្វែងរក</label>
            <input
              type="text"
              class="block w-full rounded-md border-gray-300 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
              placeholder="ឈ្មោះ, ទូរស័ព្ទ, ស្លាកលេខ..."
              [(ngModel)]="filters.search"
              (input)="onSearchInput()"
            />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">ចាប់ពីថ្ងៃ</label>
            <input
              type="date"
              class="block w-full rounded-md border-gray-300 text-sm shadow-sm"
              [(ngModel)]="filters.from"
              (change)="reload()"
            />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">ដល់ថ្ងៃ</label>
            <input
              type="date"
              class="block w-full rounded-md border-gray-300 text-sm shadow-sm"
              [(ngModel)]="filters.to"
              (change)="reload()"
            />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">ស្ថានភាព</label>
            <select
              class="block w-full rounded-md border-gray-300 text-sm shadow-sm"
              [(ngModel)]="filters.status"
              (change)="reload()"
            >
              <option value="">ទាំងអស់</option>
              <option value="DRAFT">កំពុងបំពេញ</option>
              <option value="WAITING_APPROVAL">រង់ចាំអនុម័ត</option>
              <option value="APPROVED">បានអនុម័ត</option>
              <option value="REJECTED">ត្រូវបានបដិសេធ</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">ហានិភ័យ</label>
            <select
              class="block w-full rounded-md border-gray-300 text-sm shadow-sm"
              [(ngModel)]="filters.risk"
              (change)="reload()"
            >
              <option value="">ទាំងអស់</option>
              <option value="LOW">LOW</option>
              <option value="MEDIUM">MEDIUM</option>
              <option value="HIGH">HIGH</option>
            </select>
          </div>
        </div>
        <div class="mt-3 flex justify-end">
          <button
            class="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50"
            (click)="clearFilters()"
          >
            សម្អាតតម្រង
          </button>
        </div>
      </div>

      <!-- Table -->
      <div class="rounded-lg bg-white shadow-sm ring-1 ring-gray-200 overflow-hidden">
        <!-- Loading -->
        <div *ngIf="loading" class="py-16 text-center text-gray-400 text-sm">
          <svg class="mx-auto h-6 w-6 animate-spin text-gray-400" fill="none" viewBox="0 0 24 24">
            <circle
              class="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              stroke-width="4"
            ></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"></path>
          </svg>
          <p class="mt-2">កំពុងផ្ទុក...</p>
        </div>

        <!-- Empty -->
        <div
          *ngIf="!loading && safetyChecks.length === 0"
          class="py-16 text-center text-gray-400 text-sm"
        >
          <svg
            class="mx-auto h-10 w-10 text-gray-300"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="1.5"
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <p class="mt-2">គ្មានទិន្នន័យ</p>
        </div>

        <!-- Data table -->
        <table
          *ngIf="!loading && safetyChecks.length > 0"
          class="min-w-full divide-y divide-gray-200 text-sm"
        >
          <thead class="bg-gray-50">
            <tr>
              <th
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                កាលបរិច្ឆេទ
              </th>
              <th
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                អ្នកបើកបរ
              </th>
              <th
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                យានយន្ត
              </th>
              <th
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                ស្ថានភាព
              </th>
              <th
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                ហានិភ័យ
              </th>
              <th
                class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                សកម្មភាព
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 bg-white">
            <tr *ngFor="let check of safetyChecks" class="hover:bg-gray-50 transition-colors">
              <td class="px-4 py-3 whitespace-nowrap text-gray-900 font-medium">
                {{ check.checkDate }}
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-gray-700">
                {{ check.driverName || '–' }}
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-gray-700">
                {{ check.vehiclePlate || '–' }}
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <span
                  class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
                  [ngClass]="statusClass(check.status)"
                >
                  {{ statusLabel(check.status) }}
                </span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <span
                  class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
                  [ngClass]="riskClass(check.riskOverride || check.riskLevel)"
                >
                  {{ check.riskOverride || check.riskLevel || '–' }}
                </span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-right">
                <a
                  class="text-blue-600 hover:text-blue-800 font-medium text-xs"
                  [routerLink]="['/safety', check.id]"
                  >មើល</a
                >
              </td>
            </tr>
          </tbody>
        </table>

        <!-- Pagination -->
        <div
          *ngIf="!loading && safetyChecks.length > 0"
          class="flex items-center justify-between border-t border-gray-200 px-4 py-3"
        >
          <span class="text-xs text-gray-500">
            ទំព័រ {{ page + 1 }} / {{ totalPages }} &nbsp;·&nbsp;
            {{ totalElements }} កំណត់ត្រាទាំងអស់
          </span>
          <div class="flex gap-2">
            <button
              class="rounded-md border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-40"
              [disabled]="page === 0"
              (click)="prevPage()"
            >
              ← ថយក្រោយ
            </button>
            <button
              class="rounded-md border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-40"
              [disabled]="page + 1 >= totalPages"
              (click)="nextPage()"
            >
              បន្ទាប់ →
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class SafetyCheckListComponent implements OnInit {
  safetyChecks: SafetyCheck[] = [];
  loading = false;
  statsLoading = false;
  exporting = false;

  page = 0;
  size = 20;
  totalPages = 1;
  totalElements = 0;

  filters: {
    search?: string;
    from?: string;
    to?: string;
    status?: string;
    risk?: string;
  } = {};

  statusStats: StatusStat[] = [
    { label: 'កំពុងបំពេញ', count: 0, colorClass: 'text-blue-600' },
    { label: 'រង់ចាំអនុម័ត', count: 0, colorClass: 'text-amber-600' },
    { label: 'បានអនុម័ត', count: 0, colorClass: 'text-green-600' },
    { label: 'ត្រូវបានបដិសេធ', count: 0, colorClass: 'text-red-600' },
  ];

  private searchDebounce: ReturnType<typeof setTimeout> | null = null;

  constructor(private safetyService: SafetyCheckService) {}

  ngOnInit(): void {
    this.loadStats();
    this.load();
  }

  load(): void {
    this.loading = true;
    this.safetyService.list({ ...this.filters, page: this.page, size: this.size }).subscribe({
      next: (res) => {
        const data = res.data;
        this.safetyChecks = data?.content ?? [];
        this.totalElements = data?.totalElements ?? this.safetyChecks.length;
        this.totalPages = data?.totalPages ?? 1;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.safetyChecks = [];
      },
    });
  }

  /** Fire 4 parallel single-item calls to get accurate per-status server counts. */
  loadStats(): void {
    this.statsLoading = true;
    const statuses = ['DRAFT', 'WAITING_APPROVAL', 'APPROVED', 'REJECTED'];
    forkJoin(
      statuses.map((s) => this.safetyService.list({ status: s, page: 0, size: 1 })),
    ).subscribe({
      next: (results) => {
        results.forEach((res, i) => {
          this.statusStats[i].count = res.data?.totalElements ?? 0;
        });
        this.statsLoading = false;
      },
      error: () => {
        this.statsLoading = false;
      },
    });
  }

  reload(): void {
    this.page = 0;
    this.load();
  }

  onSearchInput(): void {
    if (this.searchDebounce) clearTimeout(this.searchDebounce);
    this.searchDebounce = setTimeout(() => this.reload(), 400);
  }

  clearFilters(): void {
    this.filters = {};
    this.page = 0;
    this.load();
  }

  nextPage(): void {
    if (this.page + 1 < this.totalPages) {
      this.page++;
      this.load();
    }
  }

  prevPage(): void {
    if (this.page > 0) {
      this.page--;
      this.load();
    }
  }

  doExportCsv(): void {
    this.exporting = true;
    this.safetyService.exportCsv(this.filters).subscribe({
      next: (blob) => {
        this.triggerDownload(blob, 'safety_checks.csv', 'text/csv');
        this.exporting = false;
      },
      error: () => {
        this.exporting = false;
      },
    });
  }

  doExportExcel(): void {
    this.exporting = true;
    this.safetyService.exportExcel(this.filters).subscribe({
      next: (blob) => {
        this.triggerDownload(
          blob,
          'safety_checks.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        this.exporting = false;
      },
      error: () => {
        this.exporting = false;
      },
    });
  }

  private triggerDownload(blob: Blob, filename: string, type: string): void {
    const url = window.URL.createObjectURL(new Blob([blob], { type }));
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    window.URL.revokeObjectURL(url);
  }

  statusLabel(status?: string): string {
    switch ((status || '').toUpperCase()) {
      case 'DRAFT':
        return 'កំពុងបំពេញ';
      case 'WAITING_APPROVAL':
        return 'រង់ចាំអនុម័ត';
      case 'APPROVED':
        return 'បានអនុម័ត';
      case 'REJECTED':
        return 'ត្រូវបានបដិសេធ';
      default:
        return 'មិនទាន់ចាប់ផ្តើម';
    }
  }

  statusClass(status?: string): string {
    switch ((status || '').toUpperCase()) {
      case 'DRAFT':
        return 'bg-blue-100 text-blue-800';
      case 'WAITING_APPROVAL':
        return 'bg-amber-100 text-amber-800';
      case 'APPROVED':
        return 'bg-green-100 text-green-800';
      case 'REJECTED':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  }

  riskClass(risk?: string): string {
    switch ((risk || '').toUpperCase()) {
      case 'HIGH':
        return 'bg-red-100 text-red-800';
      case 'MEDIUM':
        return 'bg-amber-100 text-amber-800';
      case 'LOW':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-600';
    }
  }
}
