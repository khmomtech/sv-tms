import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { forkJoin } from 'rxjs';
import {
  TrainingService,
  type TrainingRecord,
  type TrainingSummary,
  type TrainingListFilter,
} from '../services/training.service';

@Component({
  selector: 'app-training-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <!-- Loading skeleton -->
    <div *ngIf="loading && !records.length" class="p-4 space-y-4 animate-pulse">
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <div *ngFor="let _ of [1, 2, 3, 4]" class="h-20 rounded-xl bg-gray-200"></div>
      </div>
      <div class="h-10 rounded-lg bg-gray-200"></div>
      <div class="h-64 rounded-xl bg-gray-100"></div>
    </div>

    <!-- Error -->
    <div *ngIf="loadError" class="p-4">
      <div
        class="flex items-center gap-2 rounded-lg bg-red-50 p-4 text-sm text-red-700 ring-1 ring-red-200"
      >
        <svg class="h-4 w-4 flex-shrink-0 text-red-500" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
            clip-rule="evenodd"
          />
        </svg>
        Failed to load training records.
        <button class="ml-auto underline text-red-600 hover:text-red-800" (click)="reload()">
          Retry
        </button>
      </div>
    </div>

    <div *ngIf="!loading || records.length" class="p-4 space-y-5">
      <!-- Header -->
      <div class="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 class="text-xl font-semibold text-gray-900">Training Records</h1>
          <p class="mt-0.5 text-sm text-gray-500">All driver training documents across the fleet</p>
        </div>
        <a
          routerLink="expiring"
          class="inline-flex items-center gap-1.5 rounded-md bg-amber-50 px-3 py-1.5 text-sm font-medium text-amber-700 ring-1 ring-amber-200 hover:bg-amber-100"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          View Expiring
        </a>
      </div>

      <!-- KPI cards from summary -->
      <div *ngIf="summary" class="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-gray-200">
          <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Total</p>
          <p class="mt-2 text-3xl font-bold text-gray-900">{{ summary.total }}</p>
        </div>
        <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-green-200">
          <p class="text-xs font-medium text-green-700 uppercase tracking-wide">Active</p>
          <p class="mt-2 text-3xl font-bold text-green-700">{{ summary.active }}</p>
          <p class="mt-1 text-xs text-green-500">{{ summary.compliancePercent }}% compliant</p>
        </div>
        <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-amber-200">
          <p class="text-xs font-medium text-amber-700 uppercase tracking-wide">Expiring Soon</p>
          <p class="mt-2 text-3xl font-bold text-amber-600">{{ summary.expiringSoon }}</p>
        </div>
        <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-red-200">
          <p class="text-xs font-medium text-red-700 uppercase tracking-wide">Expired</p>
          <p class="mt-2 text-3xl font-bold text-red-600">{{ summary.expired }}</p>
        </div>
      </div>

      <!-- Search and filters -->
      <div class="flex items-center gap-3 flex-wrap">
        <div class="relative flex-1 min-w-[200px]">
          <svg
            class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            />
          </svg>
          <input
            type="text"
            class="block w-full rounded-md border-gray-300 pl-9 text-sm shadow-sm"
            placeholder="Search by driver name, phone, or training name..."
            [(ngModel)]="filter.search"
            (input)="onSearchInput()"
          />
        </div>
        <select
          class="rounded-md border-gray-300 text-sm shadow-sm"
          [(ngModel)]="statusFilter"
          (change)="onStatusChange()"
        >
          <option value="">All statuses</option>
          <option value="ACTIVE">Active</option>
          <option value="EXPIRING_SOON">Expiring Soon</option>
          <option value="EXPIRED">Expired</option>
        </select>
        <button
          *ngIf="filter.search || statusFilter"
          class="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-50"
          (click)="clearFilters()"
        >
          Clear
        </button>
      </div>

      <!-- Table -->
      <div class="rounded-xl bg-white shadow-sm ring-1 ring-gray-200 overflow-hidden">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-100 text-sm">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Driver</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Training</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Expires</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Days Left</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Status</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Required</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr
                *ngFor="let rec of filteredRecords()"
                [ngClass]="rowBg(rec.status)"
                class="hover:brightness-95"
              >
                <td class="px-4 py-2.5">
                  <p class="font-medium text-gray-900">{{ rec.driverName || '—' }}</p>
                  <p class="text-xs text-gray-400">{{ rec.driverPhone || '' }}</p>
                </td>
                <td class="px-4 py-2.5">
                  <p class="text-gray-900">{{ rec.trainingName }}</p>
                  <p *ngIf="rec.description" class="text-xs text-gray-400 mt-0.5 truncate max-w-xs">
                    {{ rec.description }}
                  </p>
                </td>
                <td class="px-4 py-2.5 text-gray-700">{{ rec.expiryDate || '—' }}</td>
                <td class="px-4 py-2.5">
                  <span
                    class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium"
                    [ngClass]="daysClass(rec.daysUntilExpiry)"
                  >
                    {{
                      rec.daysUntilExpiry != null
                        ? rec.daysUntilExpiry < 0
                          ? Math.abs(rec.daysUntilExpiry) + 'd ago'
                          : rec.daysUntilExpiry + 'd'
                        : '—'
                    }}
                  </span>
                </td>
                <td class="px-4 py-2.5">
                  <span
                    class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
                    [ngClass]="statusClass(rec.status)"
                  >
                    {{ statusLabel(rec.status) }}
                  </span>
                </td>
                <td class="px-4 py-2.5 text-center">
                  <span *ngIf="rec.isRequired" class="text-red-500 text-xs font-medium"
                    >Required</span
                  >
                  <span *ngIf="!rec.isRequired" class="text-gray-400 text-xs">—</span>
                </td>
              </tr>
              <tr *ngIf="!filteredRecords().length">
                <td colspan="6" class="px-4 py-8 text-center text-sm text-gray-400">
                  No training records found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
        <div
          *ngIf="totalPages > 1"
          class="flex items-center justify-between border-t border-gray-100 px-4 py-3"
        >
          <p class="text-xs text-gray-500">
            Page {{ currentPage + 1 }} of {{ totalPages }} ({{ totalElements }} records)
          </p>
          <div class="flex gap-2">
            <button
              class="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-50 disabled:opacity-40"
              [disabled]="currentPage === 0"
              (click)="prevPage()"
            >
              Previous
            </button>
            <button
              class="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-50 disabled:opacity-40"
              [disabled]="currentPage >= totalPages - 1"
              (click)="nextPage()"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class TrainingListComponent implements OnInit {
  private readonly trainingService = inject(TrainingService);

  records: TrainingRecord[] = [];
  summary: TrainingSummary | null = null;

  filter: TrainingListFilter = { search: '', page: 0, size: 20 };
  statusFilter = '';

  loading = true;
  loadError = false;

  currentPage = 0;
  totalPages = 1;
  totalElements = 0;

  private searchDebounce: ReturnType<typeof setTimeout> | null = null;

  readonly Math = Math;

  ngOnInit(): void {
    this.loadSummary();
    this.reload();
  }

  loadSummary(): void {
    this.trainingService.getSummary().subscribe({
      next: (res) => (this.summary = res.data),
    });
  }

  reload(): void {
    this.loading = true;
    this.loadError = false;
    this.trainingService.list({ ...this.filter, page: this.currentPage }).subscribe({
      next: (res) => {
        this.records = res.data?.content ?? [];
        this.totalPages = res.data?.totalPages ?? 1;
        this.totalElements = res.data?.totalElements ?? 0;
        this.loading = false;
      },
      error: () => {
        this.loadError = true;
        this.loading = false;
      },
    });
  }

  onSearchInput(): void {
    if (this.searchDebounce) clearTimeout(this.searchDebounce);
    this.searchDebounce = setTimeout(() => {
      this.currentPage = 0;
      this.reload();
    }, 400);
  }

  onStatusChange(): void {
    this.currentPage = 0;
    this.reload();
  }

  clearFilters(): void {
    this.filter.search = '';
    this.statusFilter = '';
    this.currentPage = 0;
    this.reload();
  }

  filteredRecords(): TrainingRecord[] {
    if (!this.statusFilter) return this.records;
    return this.records.filter((r) => r.status === this.statusFilter);
  }

  prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.reload();
    }
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.reload();
    }
  }

  rowBg(status: string): string {
    switch (status) {
      case 'EXPIRED':
        return 'bg-red-50';
      case 'EXPIRING_SOON':
        return 'bg-amber-50';
      default:
        return '';
    }
  }

  statusClass(status: string): string {
    switch (status) {
      case 'ACTIVE':
        return 'bg-green-100 text-green-800';
      case 'EXPIRING_SOON':
        return 'bg-amber-100 text-amber-800';
      case 'EXPIRED':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-600';
    }
  }

  statusLabel(status: string): string {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'EXPIRING_SOON':
        return 'Expiring Soon';
      case 'EXPIRED':
        return 'Expired';
      default:
        return status;
    }
  }

  daysClass(days: number | null): string {
    if (days == null) return 'bg-gray-100 text-gray-500';
    if (days < 0) return 'bg-red-100 text-red-700';
    if (days <= 14) return 'bg-orange-100 text-orange-700';
    if (days <= 30) return 'bg-amber-100 text-amber-700';
    return 'bg-gray-100 text-gray-500';
  }
}
