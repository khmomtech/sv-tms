import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import type { DriverPerformance } from '../../../models/driver-performance.model';

@Component({
  standalone: true,
  selector: 'app-driver-performance-tab',
  imports: [CommonModule, MatProgressSpinnerModule],
  template: `
    <div class="space-y-6 rounded-lg bg-white p-8 shadow-sm">
      <div *ngIf="loading" class="flex items-center justify-center py-12">
        <mat-progress-spinner diameter="40" mode="indeterminate"></mat-progress-spinner>
      </div>

      <div *ngIf="!loading" class="space-y-6">
        <div class="grid gap-4 md:grid-cols-4">
          <div class="rounded-xl border border-gray-100 p-4 text-center">
            <p class="text-xs uppercase text-gray-400">Total Trips</p>
            <p class="text-3xl font-semibold text-gray-900">{{ summary?.totalDeliveries ?? '—' }}</p>
          </div>
          <div class="rounded-xl border border-gray-100 p-4 text-center">
            <p class="text-xs uppercase text-gray-400">On-Time</p>
            <p class="text-3xl font-semibold text-blue-600">{{ onTimePercent | number: '1.0-1' }}%</p>
          </div>
          <div class="rounded-xl border border-gray-100 p-4 text-center">
            <p class="text-xs uppercase text-gray-400">Cancel Rate</p>
            <p class="text-3xl font-semibold text-red-600">{{ cancelRate | number: '1.0-1' }}%</p>
          </div>
          <div class="rounded-xl border border-gray-100 p-4 text-center">
            <p class="text-xs uppercase text-gray-400">Incidents</p>
            <p class="text-3xl font-semibold text-orange-600">{{ incidentCount }}</p>
          </div>
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <div class="space-y-1 rounded-xl border border-gray-100 p-4">
            <p class="text-xs text-gray-500">Performance Score</p>
            <p class="text-xl font-semibold text-blue-600">{{ summary?.performanceScore ?? '—' }}</p>
            <p class="text-xs text-gray-500">
              Rank: {{ summary?.leaderboardRank ?? '—' }} · {{ summary?.rankTier || 'Tier TBD' }}
            </p>
          </div>
          <div class="space-y-1 rounded-xl border border-gray-100 p-4">
            <p class="text-xs text-gray-500">Fuel Efficiency</p>
            <p class="text-xl font-semibold text-green-600">
              {{ fuelEfficiencyDisplay !== '—' ? fuelEfficiencyDisplay + ' km/l' : '—' }}
            </p>
            <p class="text-xs text-gray-500">Avg. Rating: {{ averageRatingDisplay }}</p>
          </div>
        </div>

        <div class="space-y-3">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-semibold text-gray-900">Monthly Trip Trend Chart</h3>
              <p class="text-xs text-gray-500">
                Last {{ trend.length || 0 }} month{{ trend.length === 1 ? '' : 's' }}
              </p>
            </div>
            <p class="text-xs text-gray-500">
              {{ summary?.monthName || '—' }} · {{ summary?.year || '—' }}
            </p>
          </div>

          <div *ngIf="trend.length; else noTrend">
            <div *ngFor="let point of trend" class="flex items-center gap-3 text-xs text-gray-600">
              <span class="w-14 text-left font-semibold text-gray-700">{{ point.label }}</span>
              <div class="h-2 flex-1 overflow-hidden rounded bg-gray-200">
                <div class="h-2 rounded bg-blue-500" [style.width.%]="point.width"></div>
              </div>
              <span class="w-12 text-right">{{ point.value }}</span>
            </div>
          </div>

          <ng-template #noTrend>
            <p class="text-xs text-gray-500">No trend data available yet.</p>
          </ng-template>
        </div>
      </div>
    </div>
  `,
})
export class DriverPerformanceTabComponent {
  @Input() loading = false;
  @Input() summary: DriverPerformance | null = null;
  @Input() onTimePercent = 0;
  @Input() cancelRate = 0;
  @Input() incidentCount = 0;
  @Input() fuelEfficiencyDisplay = '—';
  @Input() averageRatingDisplay = '—';
  @Input() trend: Array<{ label: string; value: number; width: number }> = [];
}
