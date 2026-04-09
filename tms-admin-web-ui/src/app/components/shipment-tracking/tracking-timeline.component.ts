/**
 * Tracking Timeline Component
 * Displays status progression with visual timeline
 */

import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';

import type { StatusTimeline, ShipmentStatus } from '../../models/shipment-tracking.model';
import { STATUS_COLORS, STATUS_DISPLAY_NAMES } from '../../models/shipment-tracking.model';

@Component({
  selector: 'app-tracking-timeline',
  standalone: true,
  imports: [CommonModule],
  template: `
    <ng-container *ngIf="groupByDay; else flatList">
      <div class="space-y-6">
        <div *ngFor="let group of grouped" class="space-y-4">
          <div class="text-sm font-semibold text-slate-600">{{ group.dateLabel }}</div>
          <ol class="relative border-l-2 border-slate-300 ml-4 space-y-5">
            <li *ngFor="let item of group.items; let isLast = last" class="ml-6">
              <!-- Timeline dot -->
              <span
                class="absolute -left-3 h-6 w-6 rounded-full flex items-center justify-center ring-4 ring-white transition"
                [ngClass]="[
                  item.completed ? getStatusColor(item.status) : 'bg-slate-300',
                  item.completed ? 'shadow-md' : 'shadow-sm',
                ]"
              >
                <span *ngIf="item.completed" class="text-white text-xs font-bold"> ✓ </span>
              </span>

              <!-- Timeline content -->
              <div
                class="p-4 rounded-lg border transition hover:shadow-md"
                [ngClass]="
                  item.completed ? 'bg-white border-slate-200' : 'bg-slate-50 border-slate-200'
                "
              >
                <div
                  class="font-semibold"
                  [ngClass]="item.completed ? 'text-slate-900' : 'text-slate-400'"
                >
                  {{ item.displayName || getStatusName(item.status) }}
                </div>

                <!-- Timestamp -->
                <div *ngIf="item.timestamp" class="text-sm text-slate-500 mt-1">
                  {{ item.timestamp | date: 'dd-MMM-yyyy HH:mm' }}
                </div>

                <!-- Raw Status -->
                <div *ngIf="item.rawStatus" class="text-sm text-slate-600 mt-2 font-medium">
                  Status: {{ item.rawStatus }}
                </div>

                <!-- Updated By -->
                <div *ngIf="item.updatedBy" class="text-sm text-slate-600 mt-1">
                  By: {{ item.updatedBy }}
                </div>

                <!-- Location -->
                <div *ngIf="item.location" class="text-sm text-slate-600 mt-2">
                  📍 {{ item.location.city || item.location.address || 'Unknown Location' }}
                </div>

                <!-- Notes -->
                <div
                  *ngIf="item.notes"
                  class="text-sm text-slate-600 mt-2 italic whitespace-pre-line"
                >
                  {{ item.notes }}
                </div>
              </div>

              <!-- Timeline connector -->
              <div
                *ngIf="!isLast"
                class="absolute left-0 top-full h-5 border-l-2"
                [ngClass]="timeline[0] ? 'border-slate-300' : 'border-slate-200'"
              ></div>
            </li>
          </ol>
        </div>
      </div>
    </ng-container>
    <ng-template #flatList>
      <ol class="relative border-l-2 border-slate-300 ml-4 space-y-5">
        <li *ngFor="let item of timeline; let isLast = last" class="ml-6">
          <!-- Timeline dot -->
          <span
            class="absolute -left-3 h-6 w-6 rounded-full flex items-center justify-center ring-4 ring-white transition"
            [ngClass]="[
              item.completed ? getStatusColor(item.status) : 'bg-slate-300',
              item.completed ? 'shadow-md' : 'shadow-sm',
            ]"
          >
            <span *ngIf="item.completed" class="text-white text-xs font-bold"> ✓ </span>
          </span>

          <!-- Timeline content -->
          <div
            class="bg-slate-50 p-4 rounded-lg border border-slate-200 transition hover:shadow-md"
          >
            <div
              class="font-semibold"
              [ngClass]="item.completed ? 'text-slate-900' : 'text-slate-400'"
            >
              {{ item.displayName || getStatusName(item.status) }}
            </div>

            <!-- Timestamp -->
            <div *ngIf="item.timestamp" class="text-sm text-slate-500 mt-1">
              {{ item.timestamp | date: 'dd-MMM-yyyy HH:mm' }}
            </div>

            <!-- Raw Status -->
            <div *ngIf="item.rawStatus" class="text-sm text-slate-600 mt-2 font-medium">
              Status: {{ item.rawStatus }}
            </div>

            <!-- Updated By -->
            <div *ngIf="item.updatedBy" class="text-sm text-slate-600 mt-1">
              By: {{ item.updatedBy }}
            </div>

            <!-- Location -->
            <div *ngIf="item.location" class="text-sm text-slate-600 mt-2">
              📍 {{ item.location.city || item.location.address || 'Unknown Location' }}
            </div>

            <!-- Notes -->
            <div *ngIf="item.notes" class="text-sm text-slate-600 mt-2 italic whitespace-pre-line">
              {{ item.notes }}
            </div>
          </div>

          <!-- Timeline connector -->
          <div
            *ngIf="!isLast"
            class="absolute left-0 top-full h-5 border-l-2"
            [ngClass]="timeline[0] ? 'border-slate-300' : 'border-slate-200'"
          ></div>
        </li>
      </ol>
    </ng-template>
  `,
})
export class TrackingTimelineComponent {
  @Input() timeline: StatusTimeline[] = [];
  @Input() currentStatus: string = '';
  @Input() groupByDay: boolean = true;

  getStatusColor(status: ShipmentStatus): string {
    return STATUS_COLORS[status] || 'bg-slate-600';
  }

  getStatusName(status: ShipmentStatus): string {
    return STATUS_DISPLAY_NAMES[status] || status;
  }

  get grouped(): { dateLabel: string; items: StatusTimeline[] }[] {
    if (!this.timeline || this.timeline.length === 0) return [];
    const groups: Record<string, StatusTimeline[]> = {};
    for (const t of this.timeline) {
      const d = t.timestamp ? new Date(t.timestamp) : null;
      const key = d ? `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}` : 'Unknown';
      if (!groups[key]) groups[key] = [];
      groups[key].push(t);
    }
    const order = Object.keys(groups).sort((a, b) => {
      // sort by actual date ascending, unknown last
      if (a === 'Unknown') return 1;
      if (b === 'Unknown') return -1;
      return a.localeCompare(b);
    });
    return order.map((k) => {
      const parts = k.split('-');
      const label =
        k === 'Unknown'
          ? 'Unknown Date'
          : new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])).toLocaleDateString(
              undefined,
              {
                day: '2-digit',
                month: 'short',
                year: 'numeric',
              },
            );
      return { dateLabel: label, items: groups[k] };
    });
  }
}
