import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';

import { PmDashboardService, type PmDashboardDto } from '../../../services/pm-dashboard.service';
import { PmRunService, type PmRunDto } from '../../../services/pm-run.service';
import { VehicleService } from '../../../services/vehicle.service';
import type { Vehicle } from '../../../models/vehicle.model';

@Component({
  selector: 'app-pm-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">PM Dashboard</h1>
          <p class="text-gray-600">Preventive maintenance overview and due queue</p>
        </div>
        <div class="flex items-center gap-2">
          <select
            class="border rounded px-3 py-2 text-sm"
            [(ngModel)]="vehicleId"
            (change)="refresh()"
          >
            <option [ngValue]="undefined">All Vehicles</option>
            <option *ngFor="let v of vehicles" [ngValue]="v.id">
              {{ v.licensePlate }} - {{ v.manufacturer }} {{ v.model }}
            </option>
          </select>
          <button
            class="px-4 py-2 bg-blue-600 text-white rounded-lg"
            type="button"
            (click)="refresh()"
          >
            Refresh
          </button>
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">OK</div>
          <div class="text-2xl font-bold text-gray-900">{{ kpis?.okCount || 0 }}</div>
        </div>
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Due Soon (7d)</div>
          <div class="text-2xl font-bold text-amber-600">{{ kpis?.dueSoonCount || 0 }}</div>
        </div>
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Overdue</div>
          <div class="text-2xl font-bold text-red-600">{{ kpis?.overdueCount || 0 }}</div>
        </div>
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Open Work Orders</div>
          <div class="text-2xl font-bold text-gray-900">{{ kpis?.openWorkOrders || 0 }}</div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-6">
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Total PM Cost</div>
          <div class="text-xl font-semibold text-gray-900">
            {{ kpis?.totalCost || 0 | number: '1.0-0' }}
          </div>
        </div>
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Avg PM Cost</div>
          <div class="text-xl font-semibold text-gray-900">
            {{ kpis?.avgCost || 0 | number: '1.0-0' }}
          </div>
        </div>
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Due & Overdue Runs</div>
          <div class="text-xl font-semibold text-gray-900">{{ dueRuns.length }}</div>
        </div>
      </div>

      <div class="bg-white rounded-lg border">
        <div class="px-6 py-4 border-b flex items-center justify-between">
          <h3 class="font-semibold text-gray-900">Due & Overdue Runs</h3>
          <div class="text-sm text-gray-500">Showing latest 50</div>
        </div>
        <div class="p-6">
          <div *ngIf="dueRuns.length === 0" class="text-sm text-gray-500">No due runs.</div>
          <div class="overflow-auto" *ngIf="dueRuns.length > 0">
            <table class="min-w-full text-sm">
              <thead>
                <tr class="text-left text-gray-500">
                  <th class="py-2">Vehicle</th>
                  <th class="py-2">Item</th>
                  <th class="py-2">Due</th>
                  <th class="py-2">Status</th>
                  <th class="py-2">Action</th>
                </tr>
              </thead>
              <tbody>
                <tr *ngFor="let run of dueRuns" class="border-t">
                  <td class="py-2">{{ run.vehiclePlate || 'ID ' + run.vehicleId }}</td>
                  <td class="py-2">{{ run.itemName || run.planName }}</td>
                  <td class="py-2">
                    {{ run.triggerExplanation || run.dueDate || run.dueKm + ' km' }}
                  </td>
                  <td class="py-2">
                    <span
                      class="px-2 py-1 rounded text-xs"
                      [ngClass]="{
                        'bg-red-100 text-red-700': run.dueStatus === 'OVERDUE',
                        'bg-amber-100 text-amber-700': run.dueStatus === 'DUE_SOON',
                        'bg-emerald-100 text-emerald-700': run.dueStatus === 'OK',
                      }"
                    >
                      {{ run.dueStatus || run.status }}
                    </span>
                  </td>
                  <td class="py-2">
                    <a
                      class="text-blue-600 hover:underline"
                      [routerLink]="['/fleet/maintenance/pm-runs', run.pmRunId]"
                      >Open</a
                    >
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class PmDashboardComponent implements OnInit {
  kpis?: PmDashboardDto;
  dueRuns: PmRunDto[] = [];
  error = '';
  vehicles: Vehicle[] = [];
  vehicleId?: number;

  constructor(
    private readonly dashboardService: PmDashboardService,
    private readonly runService: PmRunService,
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
      if (vehicleId) this.vehicleId = Number(vehicleId);
      this.refresh();
    });
  }

  refresh(): void {
    this.error = '';
    this.dashboardService.getDashboard().subscribe({
      next: (res) => (this.kpis = res.data),
      error: () => (this.error = 'Failed to load PM dashboard.'),
    });

    this.runService
      .list({ status: 'DUE', vehicleId: this.vehicleId, page: 0, size: 50 })
      .subscribe({
        next: (res) => (this.dueRuns = res.data?.content || []),
        error: () => (this.dueRuns = []),
      });
  }
}
