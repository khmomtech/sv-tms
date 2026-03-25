import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';

import {
  PmPlanV2Service,
  type PmPlanDto,
  type PmPlanStatus,
} from '../../../services/pm-plan-v2.service';
import { VehicleService } from '../../../services/vehicle.service';
import type { Vehicle } from '../../../models/vehicle.model';

@Component({
  selector: 'app-pm-plans',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">PM Plans</h1>
          <p class="text-gray-600">Preventive maintenance schedules per vehicle</p>
        </div>
        <a
          class="px-4 py-2 bg-blue-600 text-white rounded-lg"
          [routerLink]="['/fleet/maintenance/pm-plans/new']"
        >
          New Plan
        </a>
      </div>

      <div class="bg-white rounded-lg border p-4 mb-4">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
          <input class="border rounded px-3 py-2" placeholder="Search name" [(ngModel)]="q" />
          <select class="border rounded px-3 py-2" [(ngModel)]="vehicleId">
            <option [ngValue]="undefined">All Vehicles</option>
            <option *ngFor="let v of vehicles" [ngValue]="v.id">
              {{ v.licensePlate }} - {{ v.manufacturer }} {{ v.model }}
            </option>
          </select>
          <select class="border rounded px-3 py-2" [(ngModel)]="status">
            <option [ngValue]="undefined">All Status</option>
            <option value="ACTIVE">Active</option>
            <option value="INACTIVE">Inactive</option>
          </select>
          <div class="flex gap-2">
            <button class="px-4 py-2 bg-gray-900 text-white rounded" type="button" (click)="load()">
              Apply
            </button>
            <button class="px-4 py-2 border rounded" type="button" (click)="reset()">Reset</button>
          </div>
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="bg-white rounded-lg border">
        <div class="p-4 border-b flex items-center justify-between">
          <div class="font-semibold text-gray-900">Plans</div>
          <div class="text-sm text-gray-500">{{ plans.length }} items</div>
        </div>
        <div class="overflow-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="text-left text-gray-500">
                <th class="py-2 px-4">Vehicle</th>
                <th class="py-2 px-4">PM Name</th>
                <th class="py-2 px-4">Trigger</th>
                <th class="py-2 px-4">Next Due</th>
                <th class="py-2 px-4">Active</th>
                <th class="py-2 px-4">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let plan of plans" class="border-t">
                <td class="py-2 px-4">{{ plan.vehiclePlate || 'ID ' + plan.vehicleId }}</td>
                <td class="py-2 px-4">{{ plan.pmName }}</td>
                <td class="py-2 px-4">{{ plan.triggerType }}</td>
                <td class="py-2 px-4">{{ displayNextDue(plan) }}</td>
                <td class="py-2 px-4">
                  <span
                    class="px-2 py-1 rounded text-xs"
                    [ngClass]="{
                      'bg-emerald-100 text-emerald-700': plan.active,
                      'bg-gray-100 text-gray-700': !plan.active,
                    }"
                    >{{ plan.active ? 'ACTIVE' : 'INACTIVE' }}</span
                  >
                </td>
                <td class="py-2 px-4">
                  <a
                    class="text-blue-600 hover:underline"
                    [routerLink]="['/fleet/maintenance/pm-plans', plan.id]"
                    >Edit</a
                  >
                </td>
              </tr>
              <tr *ngIf="plans.length === 0">
                <td class="py-6 px-4 text-gray-500" colspan="6">No plans found.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `,
})
export class PmPlansComponent implements OnInit {
  plans: PmPlanDto[] = [];
  q = '';
  vehicleId?: number;
  status?: PmPlanStatus;
  error = '';
  vehicles: Vehicle[] = [];

  constructor(
    private readonly pmPlanService: PmPlanV2Service,
    private readonly vehicleService: VehicleService,
    private readonly route: ActivatedRoute,
  ) {}

  ngOnInit(): void {
    this.vehicleService.getVehicles(0, 200, {}).subscribe({
      next: (res: any) => (this.vehicles = res?.data?.content ?? []),
      error: () => {},
    });
    this.route.queryParamMap.subscribe((params) => {
      const vehicleId = params.get('vehicleId');
      const status = params.get('status') as PmPlanStatus | null;
      if (vehicleId) this.vehicleId = Number(vehicleId);
      if (status) this.status = status;
      this.load();
    });
  }

  load(): void {
    this.error = '';
    if (this.vehicleId) {
      this.pmPlanService.listByVehicle(this.vehicleId).subscribe({
        next: (items) => {
          const filtered = this.applyClientFilters(items);
          this.plans = filtered;
        },
        error: () => (this.error = 'Failed to load PM plans.'),
      });
      return;
    }

    this.pmPlanService.list({ status: this.status, q: this.q, page: 0, size: 50 }).subscribe({
      next: (res) => {
        const content = res?.content || [];
        this.plans = this.applyClientFilters(content);
      },
      error: () => (this.error = 'Failed to load PM plans.'),
    });
  }

  reset(): void {
    this.q = '';
    this.vehicleId = undefined;
    this.status = undefined;
    this.load();
  }

  displayNextDue(plan: PmPlanDto): string {
    if (plan.nextDueDate) return plan.nextDueDate;
    if (plan.nextDueKm != null) return `${plan.nextDueKm} km`;
    if (plan.nextDueEngineHours != null) return `${plan.nextDueEngineHours} hrs`;
    return '-';
  }

  private applyClientFilters(items: PmPlanDto[]): PmPlanDto[] {
    let filtered = items || [];
    if (this.status) {
      const wantActive = this.status === 'ACTIVE';
      filtered = filtered.filter((item) => Boolean(item.active) === wantActive);
    }
    if (this.q) {
      const query = this.q.toLowerCase();
      filtered = filtered.filter((item) => (item.pmName || '').toLowerCase().includes(query));
    }
    return filtered;
  }
}
