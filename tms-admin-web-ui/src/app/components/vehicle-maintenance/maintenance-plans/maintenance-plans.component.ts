import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';

import type { Vehicle } from '../../../models/vehicle.model';
import { VehicleService } from '../../../services/vehicle.service';
import {
  type PMTaskDto,
  type PreventiveMaintenancePlanDto,
  type PMIntervalType,
  PmPlanService,
} from '../../../services/pm-plan.service';

@Component({
  selector: 'app-maintenance-plans',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './maintenance-plans.component.html',
  styleUrls: ['./maintenance-plans.component.scss'],
})
export class MaintenancePlanListComponent implements OnInit {
  plans: PreventiveMaintenancePlanDto[] = [];
  vehicles: Vehicle[] = [];

  page = 0;
  size = 10;
  totalPages = 1;

  filters: { active: '' | 'true' | 'false'; vehicleId: number | null } = {
    active: 'true',
    vehicleId: null,
  };

  loading = false;
  error = '';

  createOpen = false;
  createLoading = false;
  create: PreventiveMaintenancePlanDto = {
    vehicleId: 0,
    planName: '',
    description: '',
    intervalType: 'MILEAGE',
    intervalValue: 10000,
    active: true,
    tasks: [],
  };

  intervalTypes: PMIntervalType[] = ['MILEAGE', 'TIME', 'HOURS', 'COMPLIANCE'];

  constructor(
    private readonly pmPlanService: PmPlanService,
    private readonly vehicleService: VehicleService,
  ) {}

  ngOnInit(): void {
    this.loadVehicles();
    this.loadPlans();
  }

  loadVehicles(): void {
    this.vehicleService.getVehicles(0, 200, {}).subscribe({
      next: (res: any) => {
        this.vehicles = res?.data?.content ?? [];
      },
      error: () => {
        this.vehicles = [];
      },
    });
  }

  loadPlans(): void {
    this.loading = true;
    this.error = '';
    const active = this.filters.active === '' ? undefined : this.filters.active === 'true';
    this.pmPlanService.list({ active, page: this.page, size: this.size }).subscribe({
      next: (res) => {
        const pageData = res?.data;
        const content = pageData?.content ?? [];
        this.plans = this.filters.vehicleId
          ? content.filter((p) => p.vehicleId === this.filters.vehicleId)
          : content;
        this.totalPages = pageData?.totalPages ?? 1;
        this.loading = false;
      },
      error: () => {
        this.plans = [];
        this.loading = false;
        this.error = 'Failed to load PM plans.';
      },
    });
  }

  applyFilters(): void {
    this.page = 0;
    this.loadPlans();
  }

  prevPage(): void {
    if (this.page > 0) {
      this.page -= 1;
      this.loadPlans();
    }
  }

  nextPage(): void {
    if (this.page + 1 < this.totalPages) {
      this.page += 1;
      this.loadPlans();
    }
  }

  openCreate(): void {
    this.create = {
      vehicleId: this.filters.vehicleId || 0,
      planName: '',
      description: '',
      intervalType: 'MILEAGE',
      intervalValue: 10000,
      active: true,
      tasks: [],
    };
    this.createOpen = true;
  }

  addTaskRow(): void {
    if (!this.create.tasks) this.create.tasks = [];
    this.create.tasks.push({ taskName: '', required: true, notes: '' } as PMTaskDto);
  }

  removeTaskRow(idx: number): void {
    if (!this.create.tasks) return;
    this.create.tasks.splice(idx, 1);
  }

  submitCreate(): void {
    if (!this.create.vehicleId || !this.create.planName) {
      this.error = 'Vehicle and plan name are required.';
      return;
    }
    this.createLoading = true;
    this.pmPlanService.create(this.create).subscribe({
      next: () => {
        this.createLoading = false;
        this.createOpen = false;
        this.loadPlans();
      },
      error: () => {
        this.createLoading = false;
        this.error = 'Failed to create PM plan.';
      },
    });
  }

  deactivate(plan: PreventiveMaintenancePlanDto): void {
    if (!plan?.id) return;
    this.pmPlanService.deactivate(plan.id).subscribe({
      next: () => this.loadPlans(),
      error: () => {
        this.error = 'Failed to deactivate plan.';
      },
    });
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

  getIntervalUnit(type: PMIntervalType): string {
    if (type === 'HOURS') return 'hrs';
    if (type === 'TIME' || type === 'COMPLIANCE') return 'days';
    return 'km';
  }

  getVehicleLabel(plan: PreventiveMaintenancePlanDto): string {
    if (plan.vehiclePlate) return plan.vehiclePlate;
    const match = this.vehicles.find((v) => v.id === plan.vehicleId);
    return match?.licensePlate || String(plan.vehicleId ?? '');
  }
}
