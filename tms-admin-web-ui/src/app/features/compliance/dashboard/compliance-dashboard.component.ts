import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { forkJoin } from 'rxjs';
import {
  ComplianceService,
  type ComplianceSummary,
  type ExpiringDocument,
} from '../services/compliance.service';

@Component({
  selector: 'app-compliance-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <!-- Loading skeleton -->
    <div *ngIf="loading && !loadError" class="p-4 space-y-4 animate-pulse">
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <div *ngFor="let _ of [1, 2, 3, 4]" class="h-24 rounded-xl bg-gray-200"></div>
      </div>
      <div class="h-64 rounded-xl bg-gray-100"></div>
    </div>

    <!-- Error banner -->
    <div *ngIf="loadError && !loading" class="p-4">
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
        Failed to load compliance data. Please try again.
        <button class="ml-auto text-red-600 underline hover:text-red-800" (click)="load()">
          Retry
        </button>
      </div>
    </div>

    <div *ngIf="!loading || summary" class="p-4 space-y-6">
      <!-- Header -->
      <div class="flex items-start justify-between flex-wrap gap-3">
        <div>
          <h1 class="text-xl font-semibold text-gray-900">Document Compliance Dashboard</h1>
          <p class="mt-0.5 text-sm text-gray-500">
            Cross-driver document expiry tracking and compliance overview
          </p>
        </div>
        <!-- Horizon selector -->
        <div class="flex items-center gap-2">
          <label class="text-xs font-medium text-gray-600">Expiry horizon:</label>
          <select
            class="rounded-md border-gray-300 text-sm shadow-sm"
            [(ngModel)]="days"
            (change)="onDaysChange()"
          >
            <option value="14">14 days</option>
            <option value="30">30 days</option>
            <option value="60">60 days</option>
            <option value="90">90 days</option>
          </select>
        </div>
      </div>

      <!-- KPI cards -->
      <div *ngIf="summary" class="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <!-- Total documents -->
        <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-gray-200">
          <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Total Documents</p>
          <p class="mt-2 text-3xl font-bold text-gray-900">{{ summary.totalDocuments }}</p>
          <p class="mt-1 text-xs text-gray-400">Across all drivers</p>
        </div>
        <!-- Active -->
        <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-green-200">
          <p class="text-xs font-medium text-green-700 uppercase tracking-wide">Active</p>
          <p class="mt-2 text-3xl font-bold text-green-700">{{ summary.active }}</p>
          <p class="mt-1 text-xs text-green-500">Compliance: {{ summary.overallCompliancePct }}%</p>
        </div>
        <!-- Expiring soon -->
        <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-amber-200">
          <p class="text-xs font-medium text-amber-700 uppercase tracking-wide">Expiring ≤ 30d</p>
          <p class="mt-2 text-3xl font-bold text-amber-600">{{ summary.expiringSoon30Days }}</p>
          <p class="mt-1 text-xs text-amber-500">Action required</p>
        </div>
        <!-- Expired -->
        <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-red-200">
          <p class="text-xs font-medium text-red-700 uppercase tracking-wide">Expired</p>
          <p class="mt-2 text-3xl font-bold text-red-600">{{ summary.expired }}</p>
          <p class="mt-1 text-xs text-red-400">Immediate attention needed</p>
        </div>
      </div>

      <!-- Expiring documents table -->
      <div class="rounded-xl bg-white shadow-sm ring-1 ring-gray-200 overflow-hidden">
        <div class="border-b border-gray-200 px-4 py-3 flex items-center justify-between">
          <h2 class="text-sm font-semibold text-gray-900">
            Expiring within {{ days }} days
            <span
              *ngIf="expiringDocs.length"
              class="ml-1.5 rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-700"
            >
              {{ expiringDocs.length }}
            </span>
          </h2>
        </div>

        <!-- Empty state -->
        <div
          *ngIf="!expiringDocs.length && !loading"
          class="px-4 py-8 text-center text-sm text-gray-400"
        >
          No documents expiring within {{ days }} days.
        </div>

        <div *ngIf="expiringDocs.length" class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-100 text-sm">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Driver</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Document</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Category</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Expires</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Days Left</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Required</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr
                *ngFor="let doc of expiringDocs"
                [ngClass]="rowClass(doc)"
                class="hover:bg-gray-50"
              >
                <td class="px-4 py-2.5">
                  <p class="font-medium text-gray-900">{{ doc.driverName || '—' }}</p>
                  <p class="text-xs text-gray-400">{{ doc.driverPhone || '' }}</p>
                </td>
                <td class="px-4 py-2.5 text-gray-800">{{ doc.documentName }}</td>
                <td class="px-4 py-2.5">
                  <span
                    class="inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600 capitalize"
                  >
                    {{ doc.category }}
                  </span>
                </td>
                <td class="px-4 py-2.5 text-gray-700">{{ doc.expiryDate || '—' }}</td>
                <td class="px-4 py-2.5">
                  <span
                    class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium"
                    [ngClass]="urgencyClass(doc.daysUntilExpiry)"
                  >
                    {{ doc.daysUntilExpiry != null ? doc.daysUntilExpiry + 'd' : '—' }}
                  </span>
                </td>
                <td class="px-4 py-2.5 text-center">
                  <span *ngIf="doc.isRequired" class="text-red-500" title="Required">●</span>
                  <span *ngIf="!doc.isRequired" class="text-gray-300" title="Optional">○</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Expired documents table -->
      <div class="rounded-xl bg-white shadow-sm ring-1 ring-gray-200 overflow-hidden">
        <div class="border-b border-gray-200 px-4 py-3 flex items-center">
          <h2 class="text-sm font-semibold text-gray-900">
            Expired Documents
            <span
              *ngIf="expiredDocs.length"
              class="ml-1.5 rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-700"
            >
              {{ expiredDocs.length }}
            </span>
          </h2>
        </div>

        <div
          *ngIf="!expiredDocs.length && !loading"
          class="px-4 py-8 text-center text-sm text-gray-400"
        >
          No expired documents found.
        </div>

        <div *ngIf="expiredDocs.length" class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-100 text-sm">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Driver</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Document</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Category</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Expired On</th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">
                  Days Overdue
                </th>
                <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Required</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr *ngFor="let doc of expiredDocs" class="bg-red-50 hover:bg-red-100">
                <td class="px-4 py-2.5">
                  <p class="font-medium text-gray-900">{{ doc.driverName || '—' }}</p>
                  <p class="text-xs text-gray-400">{{ doc.driverPhone || '' }}</p>
                </td>
                <td class="px-4 py-2.5 text-gray-800">{{ doc.documentName }}</td>
                <td class="px-4 py-2.5">
                  <span
                    class="inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600 capitalize"
                  >
                    {{ doc.category }}
                  </span>
                </td>
                <td class="px-4 py-2.5 text-red-700 font-medium">{{ doc.expiryDate || '—' }}</td>
                <td class="px-4 py-2.5">
                  <span
                    class="inline-flex items-center rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700"
                  >
                    {{ doc.daysUntilExpiry != null ? Math.abs(doc.daysUntilExpiry) + 'd' : '—' }}
                  </span>
                </td>
                <td class="px-4 py-2.5 text-center">
                  <span *ngIf="doc.isRequired" class="text-red-500" title="Required">●</span>
                  <span *ngIf="!doc.isRequired" class="text-gray-300" title="Optional">○</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `,
})
export class ComplianceDashboardComponent implements OnInit {
  private readonly complianceService = inject(ComplianceService);

  summary: ComplianceSummary | null = null;
  expiringDocs: ExpiringDocument[] = [];
  expiredDocs: ExpiringDocument[] = [];

  loading = true;
  loadError = false;
  days = 30;

  // Expose Math for template
  readonly Math = Math;

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.loadError = false;

    forkJoin({
      summary: this.complianceService.getSummary(),
      expiring: this.complianceService.getExpiring(this.days),
      expired: this.complianceService.getExpired(),
    }).subscribe({
      next: ({ summary, expiring, expired }) => {
        this.summary = summary.data;
        this.expiringDocs = expiring.data ?? [];
        this.expiredDocs = expired.data ?? [];
        this.loading = false;
      },
      error: () => {
        this.loadError = true;
        this.loading = false;
      },
    });
  }

  onDaysChange(): void {
    this.complianceService.getExpiring(this.days).subscribe({
      next: (res) => {
        this.expiringDocs = res.data ?? [];
      },
    });
  }

  rowClass(doc: ExpiringDocument): string {
    if (doc.daysUntilExpiry != null && doc.daysUntilExpiry <= 7) return 'bg-red-50';
    if (doc.daysUntilExpiry != null && doc.daysUntilExpiry <= 14) return 'bg-amber-50';
    return '';
  }

  urgencyClass(days: number | null): string {
    if (days == null) return 'bg-gray-100 text-gray-500';
    if (days <= 7) return 'bg-red-100 text-red-700';
    if (days <= 14) return 'bg-orange-100 text-orange-700';
    return 'bg-amber-100 text-amber-700';
  }
}
