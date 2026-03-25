import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { TrainingService, type TrainingRecord } from '../services/training.service';

@Component({
  selector: 'app-training-expiry',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <!-- Loading -->
    <div *ngIf="loading && !records.length" class="p-4 space-y-4 animate-pulse">
      <div class="h-8 w-48 rounded-lg bg-gray-200"></div>
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
        Failed to load expiring training records.
        <button class="ml-auto underline text-red-600 hover:text-red-800" (click)="load()">
          Retry
        </button>
      </div>
    </div>

    <div *ngIf="!loading || records.length" class="p-4 space-y-5">
      <!-- Header -->
      <div class="flex items-start justify-between flex-wrap gap-3">
        <div>
          <h1 class="text-xl font-semibold text-gray-900">Expiring Training Records</h1>
          <p class="mt-0.5 text-sm text-gray-500">
            Training documents expiring within the selected window
          </p>
        </div>
        <div class="flex items-center gap-3">
          <!-- Horizon selector -->
          <div class="flex items-center gap-2">
            <label class="text-xs font-medium text-gray-600">Within:</label>
            <select
              class="rounded-md border-gray-300 text-sm shadow-sm"
              [(ngModel)]="days"
              (change)="load()"
            >
              <option [value]="14">14 days</option>
              <option [value]="30">30 days</option>
              <option [value]="60">60 days</option>
              <option [value]="90">90 days</option>
            </select>
          </div>
          <a
            routerLink=".."
            class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
          >
            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 19l-7-7 7-7"
              />
            </svg>
            All Records
          </a>
        </div>
      </div>

      <!-- Band legend -->
      <div class="flex items-center gap-4 text-xs flex-wrap">
        <span class="flex items-center gap-1.5"
          ><span class="inline-block h-3 w-3 rounded-full bg-red-400"></span>≤ 7 days</span
        >
        <span class="flex items-center gap-1.5"
          ><span class="inline-block h-3 w-3 rounded-full bg-orange-400"></span>8–14 days</span
        >
        <span class="flex items-center gap-1.5"
          ><span class="inline-block h-3 w-3 rounded-full bg-amber-400"></span>15–30 days</span
        >
        <span class="flex items-center gap-1.5"
          ><span class="inline-block h-3 w-3 rounded-full bg-gray-300"></span>30+ days</span
        >
      </div>

      <!-- Empty state -->
      <div
        *ngIf="!records.length && !loading"
        class="rounded-xl bg-green-50 p-8 text-center ring-1 ring-green-200"
      >
        <svg
          class="mx-auto mb-2 h-10 w-10 text-green-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="1.5"
            d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        <p class="text-sm font-medium text-green-800">All clear!</p>
        <p class="mt-1 text-xs text-green-600">
          No training records expiring within {{ days }} days.
        </p>
      </div>

      <!-- Urgency bands -->
      <ng-container *ngIf="records.length">
        <!-- Critical: ≤ 7 days -->
        <div
          *ngIf="band(records, 0, 7).length"
          class="rounded-xl overflow-hidden ring-1 ring-red-200"
        >
          <div class="bg-red-600 px-4 py-2 flex items-center gap-2">
            <svg class="h-4 w-4 text-red-100" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                clip-rule="evenodd"
              />
            </svg>
            <span class="text-sm font-semibold text-white"
              >Critical — Expiring in 7 days or less ({{ band(records, 0, 7).length }})</span
            >
          </div>
          <ng-container
            *ngTemplateOutlet="recordTable; context: { $implicit: band(records, 0, 7) }"
          ></ng-container>
        </div>

        <!-- Warning: 8–14 days -->
        <div
          *ngIf="band(records, 8, 14).length"
          class="rounded-xl overflow-hidden ring-1 ring-orange-200"
        >
          <div class="bg-orange-500 px-4 py-2 flex items-center gap-2">
            <svg class="h-4 w-4 text-orange-100" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                clip-rule="evenodd"
              />
            </svg>
            <span class="text-sm font-semibold text-white"
              >Warning — Expiring in 8–14 days ({{ band(records, 8, 14).length }})</span
            >
          </div>
          <ng-container
            *ngTemplateOutlet="recordTable; context: { $implicit: band(records, 8, 14) }"
          ></ng-container>
        </div>

        <!-- Notice: 15–30 days -->
        <div
          *ngIf="band(records, 15, 30).length"
          class="rounded-xl overflow-hidden ring-1 ring-amber-200"
        >
          <div class="bg-amber-400 px-4 py-2 flex items-center gap-2">
            <svg class="h-4 w-4 text-amber-900" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 002 0V6zm-1 8a1.5 1.5 0 100-3 1.5 1.5 0 000 3z"
                clip-rule="evenodd"
              />
            </svg>
            <span class="text-sm font-semibold text-amber-900"
              >Notice — Expiring in 15–30 days ({{ band(records, 15, 30).length }})</span
            >
          </div>
          <ng-container
            *ngTemplateOutlet="recordTable; context: { $implicit: band(records, 15, 30) }"
          ></ng-container>
        </div>

        <!-- Upcoming: 31+ days (only shown if user selected horizon > 30) -->
        <div
          *ngIf="days > 30 && band(records, 31, days).length"
          class="rounded-xl overflow-hidden ring-1 ring-gray-200"
        >
          <div class="bg-gray-100 px-4 py-2 flex items-center gap-2">
            <svg class="h-4 w-4 text-gray-500" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 002 0V6zm-1 8a1.5 1.5 0 100-3 1.5 1.5 0 000 3z"
                clip-rule="evenodd"
              />
            </svg>
            <span class="text-sm font-semibold text-gray-700"
              >Upcoming — Expiring in 31–{{ days }} days ({{
                band(records, 31, days).length
              }})</span
            >
          </div>
          <ng-container
            *ngTemplateOutlet="recordTable; context: { $implicit: band(records, 31, days) }"
          ></ng-container>
        </div>
      </ng-container>
    </div>

    <!-- Shared record table template -->
    <ng-template #recordTable let-rows>
      <div class="overflow-x-auto bg-white">
        <table class="min-w-full divide-y divide-gray-100 text-sm">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Driver</th>
              <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Training</th>
              <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Expires</th>
              <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Days Left</th>
              <th class="px-4 py-2.5 text-left text-xs font-medium text-gray-500">Required</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr *ngFor="let rec of rows" class="hover:bg-gray-50">
              <td class="px-4 py-2.5">
                <p class="font-medium text-gray-900">{{ rec.driverName || '—' }}</p>
                <p class="text-xs text-gray-400">{{ rec.driverPhone || '' }}</p>
              </td>
              <td class="px-4 py-2.5 text-gray-800">{{ rec.trainingName }}</td>
              <td class="px-4 py-2.5 text-gray-700">{{ rec.expiryDate || '—' }}</td>
              <td class="px-4 py-2.5">
                <span
                  class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold"
                  [ngClass]="daysClass(rec.daysUntilExpiry)"
                >
                  {{ rec.daysUntilExpiry != null ? rec.daysUntilExpiry + 'd' : '—' }}
                </span>
              </td>
              <td class="px-4 py-2.5 text-center">
                <span *ngIf="rec.isRequired" class="text-xs font-medium text-red-500"
                  >Required</span
                >
                <span *ngIf="!rec.isRequired" class="text-xs text-gray-400">—</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </ng-template>
  `,
})
export class TrainingExpiryComponent implements OnInit {
  private readonly trainingService = inject(TrainingService);

  records: TrainingRecord[] = [];
  days = 30;
  loading = true;
  loadError = false;

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.loadError = false;
    this.trainingService.getExpiring(this.days).subscribe({
      next: (res) => {
        this.records = res.data ?? [];
        this.loading = false;
      },
      error: () => {
        this.loadError = true;
        this.loading = false;
      },
    });
  }

  band(records: TrainingRecord[], min: number, max: number): TrainingRecord[] {
    return records.filter(
      (r) => r.daysUntilExpiry != null && r.daysUntilExpiry >= min && r.daysUntilExpiry <= max,
    );
  }

  daysClass(days: number | null): string {
    if (days == null) return 'bg-gray-100 text-gray-500';
    if (days <= 7) return 'bg-red-100 text-red-700';
    if (days <= 14) return 'bg-orange-100 text-orange-700';
    if (days <= 30) return 'bg-amber-100 text-amber-700';
    return 'bg-gray-100 text-gray-500';
  }
}
