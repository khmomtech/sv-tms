import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';

import { PmRunService, type PmRunDto, type PmRunStatus } from '../../../services/pm-run.service';
import { VehicleService } from '../../../services/vehicle.service';
import type { Vehicle } from '../../../models/vehicle.model';

@Component({
  selector: 'app-pm-runs',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">PM Runs</h1>
          <p class="text-gray-600">Execution queue and history</p>
        </div>
        <button class="px-4 py-2 bg-blue-600 text-white rounded" type="button" (click)="generate()">
          Generate Runs
        </button>
      </div>

      <div class="bg-white rounded-lg border p-4 mb-4">
        <div class="grid grid-cols-1 md:grid-cols-6 gap-3">
          <select class="border rounded px-3 py-2" [(ngModel)]="status">
            <option [ngValue]="undefined">All Status</option>
            <option value="DUE">DUE</option>
            <option value="IN_PROGRESS">IN_PROGRESS</option>
            <option value="COMPLETED">COMPLETED</option>
            <option value="SKIPPED">SKIPPED</option>
            <option value="RESCHEDULED">RESCHEDULED</option>
          </select>
          <select class="border rounded px-3 py-2" [(ngModel)]="vehicleId">
            <option [ngValue]="undefined">All Vehicles</option>
            <option *ngFor="let v of vehicles" [ngValue]="v.id">
              {{ v.licensePlate }} - {{ v.manufacturer }} {{ v.model }}
            </option>
          </select>
          <input class="border rounded px-3 py-2" type="date" [(ngModel)]="from" />
          <input class="border rounded px-3 py-2" type="date" [(ngModel)]="to" />
          <button class="px-4 py-2 bg-gray-900 text-white rounded" type="button" (click)="load()">
            Apply
          </button>
          <button class="px-4 py-2 border rounded" type="button" (click)="reset()">Reset</button>
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="bg-white rounded-lg border">
        <div class="p-4 border-b flex items-center justify-between">
          <div class="font-semibold text-gray-900">Runs</div>
          <div class="text-sm text-gray-500">{{ runs.length }} items</div>
        </div>
        <div class="overflow-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="text-left text-gray-500">
                <th class="py-2 px-4">Vehicle</th>
                <th class="py-2 px-4">Item</th>
                <th class="py-2 px-4">Due</th>
                <th class="py-2 px-4">Status</th>
                <th class="py-2 px-4">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let run of runs" class="border-t">
                <td class="py-2 px-4">{{ run.vehiclePlate || 'ID ' + run.vehicleId }}</td>
                <td class="py-2 px-4">{{ run.itemName || run.planName }}</td>
                <td class="py-2 px-4">
                  {{ run.triggerExplanation || run.dueDate || run.dueKm + ' km' }}
                </td>
                <td class="py-2 px-4">
                  <span
                    class="inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-semibold"
                    [ngClass]="getRunStatusClass(run)"
                  >
                    {{ run.dueStatus || run.status }}
                  </span>
                </td>
                <td class="py-2 px-4">
                  <div class="flex flex-wrap gap-2">
                    <a
                      class="text-blue-600 hover:underline"
                      [routerLink]="['/fleet/maintenance/pm-runs', run.pmRunId]"
                      >Open</a
                    >
                    <button
                      type="button"
                      class="text-emerald-600 hover:underline"
                      (click)="createWorkOrder(run)"
                      [disabled]="!run.pmRunId || !!run.relatedWoId"
                    >
                      Create WO
                    </button>
                  </div>
                </td>
              </tr>
              <tr *ngIf="runs.length === 0">
                <td class="py-6 px-4 text-gray-500" colspan="5">No runs found.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `,
})
export class PmRunsComponent implements OnInit {
  runs: PmRunDto[] = [];
  status?: PmRunStatus;
  vehicleId?: number;
  from?: string;
  to?: string;
  error = '';
  vehicles: Vehicle[] = [];

  constructor(
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
      const status = params.get('status') as PmRunStatus | null;
      if (vehicleId) this.vehicleId = Number(vehicleId);
      if (status) this.status = status;
      this.load();
    });
  }

  load(): void {
    this.error = '';
    this.runService
      .list({
        status: this.status,
        vehicleId: this.vehicleId,
        from: this.from,
        to: this.to,
        page: 0,
        size: 50,
      })
      .subscribe({
        next: (res) => (this.runs = res.data?.content || []),
        error: () => (this.error = 'Failed to load PM runs.'),
      });
  }

  generate(): void {
    this.runService.generate().subscribe({
      next: () => this.load(),
      error: () => (this.error = 'Failed to generate PM runs.'),
    });
  }

  reset(): void {
    this.status = undefined;
    this.vehicleId = undefined;
    this.from = undefined;
    this.to = undefined;
    this.load();
  }

  getRunStatusClass(run: PmRunDto): string {
    const due = run.dueStatus;
    const status = run.status;
    if (due === 'OVERDUE') return 'border-red-200 bg-red-50 text-red-700';
    if (due === 'DUE_SOON') return 'border-amber-200 bg-amber-50 text-amber-700';
    if (status === 'COMPLETED') return 'border-emerald-200 bg-emerald-50 text-emerald-700';
    if (status === 'IN_PROGRESS') return 'border-blue-200 bg-blue-50 text-blue-700';
    if (status === 'SKIPPED' || status === 'RESCHEDULED') {
      return 'border-gray-200 bg-gray-50 text-gray-700';
    }
    return 'border-indigo-200 bg-indigo-50 text-indigo-700';
  }

  createWorkOrder(run: PmRunDto): void {
    if (!run?.pmRunId) return;
    this.runService.createWorkOrder(run.pmRunId).subscribe({
      next: (res) => {
        const updated = res.data;
        if (updated?.relatedWoId) {
          this.error = '';
          this.load();
        } else {
          this.error = 'Work order created but response was empty.';
        }
      },
      error: (err) => {
        this.error = err?.message ?? 'Failed to create work order.';
      },
    });
  }
}
