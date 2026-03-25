import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

import {
  type PreventiveMaintenancePlanDto,
  PmPlanService,
} from '../../../services/pm-plan.service';

@Component({
  selector: 'app-pm-schedule',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
            <i class="text-2xl text-blue-600 fas fa-calendar-check"></i>
          </div>
          <div>
            <h1 class="text-2xl font-bold text-gray-900">PM Schedule</h1>
            <p class="text-gray-600">Preventive maintenance due list and calendar</p>
          </div>
        </div>
        <button
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          type="button"
          (click)="refresh()"
        >
          Refresh
        </button>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div class="bg-white rounded-lg shadow-sm border p-4">
          <p class="text-2xl font-bold text-gray-900">{{ duePlans.length }}</p>
          <p class="text-sm text-gray-600">Due Now</p>
        </div>
        <div class="bg-white rounded-lg shadow-sm border p-4">
          <p class="text-2xl font-bold text-gray-900">{{ calendarPlans.length }}</p>
          <p class="text-sm text-gray-600">Next 30 Days</p>
        </div>
        <div class="bg-white rounded-lg shadow-sm border p-4">
          <p class="text-2xl font-bold text-gray-900">{{ upcomingVehicles }}</p>
          <p class="text-sm text-gray-600">Vehicles Impacted</p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-white rounded-lg shadow-sm border">
          <div class="px-6 py-4 border-b">
            <h3 class="font-semibold text-gray-900">Due List</h3>
          </div>
          <div class="p-6">
            <div *ngIf="duePlans.length === 0" class="text-sm text-gray-500">No PM due.</div>
            <div class="space-y-3" *ngIf="duePlans.length > 0">
              <div
                *ngFor="let plan of duePlans"
                class="flex items-center justify-between p-3 border rounded-lg"
              >
                <div>
                  <div class="font-medium text-gray-900">{{ plan.planName }}</div>
                  <div class="text-xs text-gray-500">
                    Vehicle: {{ plan.vehiclePlate || 'ID ' + plan.vehicleId }}
                  </div>
                </div>
                <div class="text-xs text-gray-600">{{ displayNextDue(plan) }}</div>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border">
          <div class="px-6 py-4 border-b flex items-center justify-between">
            <h3 class="font-semibold text-gray-900">Calendar (Next 30 Days)</h3>
            <div class="text-xs text-gray-500">{{ rangeLabel }}</div>
          </div>
          <div class="p-6">
            <div *ngIf="calendarPlans.length === 0" class="text-sm text-gray-500">
              No scheduled PM in this window.
            </div>
            <div class="space-y-4" *ngIf="calendarPlans.length > 0">
              <div *ngFor="let group of calendarGroups">
                <div class="text-xs font-semibold text-gray-500 mb-2">{{ group.date }}</div>
                <div class="space-y-2">
                  <div
                    *ngFor="let plan of group.items"
                    class="flex items-center justify-between rounded-lg border px-3 py-2 text-sm"
                  >
                    <div>
                      <div class="font-medium text-gray-900">{{ plan.planName }}</div>
                      <div class="text-xs text-gray-500">
                        Vehicle: {{ plan.vehiclePlate || 'ID ' + plan.vehicleId }}
                      </div>
                    </div>
                    <div class="text-xs text-gray-600">{{ displayNextDue(plan) }}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: [],
})
export class PmScheduleComponent implements OnInit {
  duePlans: PreventiveMaintenancePlanDto[] = [];
  calendarPlans: PreventiveMaintenancePlanDto[] = [];
  error = '';
  rangeLabel = '';

  constructor(private readonly pmPlanService: PmPlanService) {}

  ngOnInit(): void {
    this.refresh();
  }

  refresh(): void {
    this.error = '';
    const today = new Date();
    const to = new Date();
    to.setDate(today.getDate() + 30);
    this.rangeLabel = `${today.toISOString().slice(0, 10)} → ${to.toISOString().slice(0, 10)}`;

    this.pmPlanService.dueList().subscribe({
      next: (res) => {
        this.duePlans = res?.data ?? [];
      },
      error: () => {
        this.duePlans = [];
        this.error = 'Failed to load PM due list.';
      },
    });

    this.pmPlanService
      .calendar(today.toISOString().slice(0, 10), to.toISOString().slice(0, 10))
      .subscribe({
        next: (res) => {
          this.calendarPlans = res?.data ?? [];
        },
        error: () => {
          this.calendarPlans = [];
        },
      });
  }

  get upcomingVehicles(): number {
    const ids = new Set((this.calendarPlans || []).map((p) => p.vehicleId));
    return ids.size;
  }

  get calendarGroups() {
    const groups: Record<string, PreventiveMaintenancePlanDto[]> = {};
    for (const plan of this.calendarPlans) {
      const key = plan.nextDueDate || 'No date';
      if (!groups[key]) groups[key] = [];
      groups[key].push(plan);
    }
    return Object.keys(groups)
      .sort()
      .map((date) => ({ date, items: groups[date] }));
  }

  displayNextDue(plan: PreventiveMaintenancePlanDto): string {
    if (plan.nextDueDate) return plan.nextDueDate;
    if (plan.nextDueValue != null) {
      let unit = 'km';
      if (plan.intervalType === 'HOURS') unit = 'hrs';
      if (plan.intervalType === 'TIME' || plan.intervalType === 'COMPLIANCE') unit = 'days';
      return `${plan.nextDueValue} ${unit}`;
    }
    return '-';
  }
}
