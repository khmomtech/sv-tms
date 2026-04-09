import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

import { PmCalendarService, type PmCalendarItemDto } from '../../../services/pm-calendar.service';

@Component({
  selector: 'app-pm-calendar',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">PM Calendar</h1>
          <p class="text-gray-600">Monthly view of due maintenance</p>
        </div>
        <div class="flex items-center gap-2">
          <input class="border rounded px-3 py-2" type="month" [(ngModel)]="month" />
          <button class="px-4 py-2 bg-blue-600 text-white rounded" type="button" (click)="load()">
            Load
          </button>
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="bg-white rounded-lg border">
        <div class="p-4 border-b font-semibold text-gray-900">Due items</div>
        <div class="p-4">
          <div *ngIf="items.length === 0" class="text-sm text-gray-500">
            No items for this month.
          </div>
          <div *ngFor="let item of items" class="mb-4">
            <div class="text-xs text-gray-500 mb-2">{{ item.date }}</div>
            <div class="space-y-2">
              <div
                *ngFor="let run of item.runs"
                class="flex items-center justify-between border rounded p-3 text-sm"
              >
                <div>
                  <div class="font-medium text-gray-900">{{ run.itemName || run.planName }}</div>
                  <div class="text-xs text-gray-500">
                    {{ run.vehiclePlate || 'ID ' + run.vehicleId }}
                  </div>
                </div>
                <a
                  class="text-blue-600 hover:underline"
                  [routerLink]="['/fleet/maintenance/pm-runs', run.pmRunId]"
                  >Open</a
                >
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class PmCalendarComponent implements OnInit {
  month = new Date().toISOString().slice(0, 7);
  items: PmCalendarItemDto[] = [];
  error = '';

  constructor(private readonly calendarService: PmCalendarService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.error = '';
    this.calendarService.getCalendar(this.month).subscribe({
      next: (res) => (this.items = res.data || []),
      error: () => (this.error = 'Failed to load calendar.'),
    });
  }
}
