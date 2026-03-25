import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';

import { PmPlanV2Service, type PmPlanDto } from '../../../services/pm-plan-v2.service';
import { VehicleService } from '../../../services/vehicle.service';
import type { Vehicle } from '../../../models/vehicle.model';

@Component({
  selector: 'app-pm-plan-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">PM Plan</h1>
          <p class="text-gray-600">Create or edit a preventive maintenance schedule</p>
        </div>
        <button class="px-4 py-2 bg-gray-100 rounded" type="button" (click)="back()">Back</button>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="bg-white rounded-lg border p-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="text-sm text-gray-600">Vehicle</label>
            <select class="border rounded px-3 py-2 w-full" [(ngModel)]="plan.vehicleId">
              <option [ngValue]="0">Select vehicle</option>
              <option *ngFor="let v of vehicles" [ngValue]="v.id">
                {{ v.licensePlate }} - {{ v.manufacturer }} {{ v.model }}
              </option>
            </select>
          </div>
          <div>
            <label class="text-sm text-gray-600">PM Name</label>
            <input class="border rounded px-3 py-2 w-full" [(ngModel)]="plan.pmName" />
          </div>
          <div class="md:col-span-2">
            <label class="text-sm text-gray-600">Description</label>
            <textarea
              class="border rounded px-3 py-2 w-full"
              rows="3"
              [(ngModel)]="plan.description"
            ></textarea>
          </div>
          <div>
            <label class="text-sm text-gray-600">Trigger Type</label>
            <select class="border rounded px-3 py-2 w-full" [(ngModel)]="plan.triggerType">
              <option value="KILOMETER">Kilometer</option>
              <option value="DATE">Date</option>
              <option value="ENGINE_HOUR">Engine Hour</option>
            </select>
          </div>
          <div *ngIf="showKm">
            <label class="text-sm text-gray-600">Interval KM</label>
            <input
              class="border rounded px-3 py-2 w-full"
              type="number"
              [(ngModel)]="plan.intervalKm"
            />
          </div>
          <div *ngIf="showDays">
            <label class="text-sm text-gray-600">Interval Days</label>
            <input
              class="border rounded px-3 py-2 w-full"
              type="number"
              [(ngModel)]="plan.intervalDays"
            />
          </div>
          <div *ngIf="showHours">
            <label class="text-sm text-gray-600">Interval Engine Hours</label>
            <input
              class="border rounded px-3 py-2 w-full"
              type="number"
              [(ngModel)]="plan.intervalEngineHours"
            />
          </div>

          <div>
            <label class="text-sm text-gray-600">Active</label>
            <select class="border rounded px-3 py-2 w-full" [(ngModel)]="plan.active">
              <option [ngValue]="true">Active</option>
              <option [ngValue]="false">Inactive</option>
            </select>
          </div>
        </div>

        <div class="mt-6 bg-gray-50 border rounded p-4">
          <div class="text-sm text-gray-500">Computed Next Due</div>
          <div class="text-lg font-semibold text-gray-900">
            {{ displayNextDue(plan) }}
          </div>
          <div class="text-xs text-gray-500">
            Last completed:
            {{ plan.lastPerformedDate || '-' }} · {{ plan.lastPerformedKm || '-' }} km
          </div>
        </div>

        <div class="mt-6 flex gap-3">
          <button class="px-4 py-2 bg-blue-600 text-white rounded" type="button" (click)="save()">
            Save
          </button>
          <button class="px-4 py-2 bg-gray-100 rounded" type="button" (click)="back()">
            Cancel
          </button>
        </div>
      </div>
    </div>
  `,
})
export class PmPlanDetailComponent implements OnInit {
  plan: PmPlanDto = {
    vehicleId: 0,
    pmName: '',
    triggerType: 'KILOMETER',
    active: true,
  };
  error = '';
  private id?: number;
  vehicles: Vehicle[] = [];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly pmPlanService: PmPlanV2Service,
    private readonly vehicleService: VehicleService,
  ) {}

  ngOnInit(): void {
    this.vehicleService.getVehicles(0, 200, {}).subscribe({
      next: (res: any) => (this.vehicles = res?.data?.content ?? []),
      error: () => {},
    });
    const idParam = this.route.snapshot.paramMap.get('id');
    const vehicleIdParam = this.route.snapshot.queryParamMap.get('vehicleId');
    if (vehicleIdParam && !this.id) {
      this.plan.vehicleId = Number(vehicleIdParam);
    }
    if (idParam && idParam !== 'new') {
      this.id = Number(idParam);
      this.pmPlanService.get(this.id).subscribe({
        next: (res) => (this.plan = res || this.plan),
        error: () => (this.error = 'Failed to load PM plan.'),
      });
    }
  }

  get showKm(): boolean {
    return this.plan.triggerType === 'KILOMETER';
  }

  get showDays(): boolean {
    return this.plan.triggerType === 'DATE';
  }

  get showHours(): boolean {
    return this.plan.triggerType === 'ENGINE_HOUR';
  }

  save(): void {
    this.error = '';
    if (!this.plan.vehicleId) {
      this.error = 'Vehicle ID is required.';
      return;
    }
    if (!this.plan.pmName) {
      this.error = 'PM name is required.';
      return;
    }
    if (this.showKm && !this.plan.intervalKm) {
      this.error = 'Interval KM is required.';
      return;
    }
    if (this.showDays && !this.plan.intervalDays) {
      this.error = 'Interval days is required.';
      return;
    }
    if (this.showHours && !this.plan.intervalEngineHours) {
      this.error = 'Interval engine hours is required.';
      return;
    }
    const payload: PmPlanDto = {
      ...this.plan,
      intervalKm: this.showKm ? (this.plan.intervalKm ?? null) : null,
      intervalDays: this.showDays ? (this.plan.intervalDays ?? null) : null,
      intervalEngineHours: this.showHours ? (this.plan.intervalEngineHours ?? null) : null,
    };
    if (this.id) {
      this.pmPlanService.update(this.id, payload).subscribe({
        next: () => this.back(),
        error: (err) => (this.error = err?.error?.message || 'Failed to update PM plan.'),
      });
    } else {
      this.pmPlanService.create(payload).subscribe({
        next: () => this.back(),
        error: (err) => (this.error = err?.error?.message || 'Failed to create PM plan.'),
      });
    }
  }

  back(): void {
    this.router.navigate(['/fleet/maintenance/pm-plans']);
  }

  displayNextDue(plan: PmPlanDto): string {
    if (plan.nextDueDate) return plan.nextDueDate;
    if (plan.nextDueKm != null) return `${plan.nextDueKm} km`;
    if (plan.nextDueEngineHours != null) return `${plan.nextDueEngineHours} hrs`;
    return '-';
  }
}
