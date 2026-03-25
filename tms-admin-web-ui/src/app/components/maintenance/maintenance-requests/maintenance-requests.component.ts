import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';

import type { PagedResponse } from '../../../models/api-response-page.model';
import type { Vehicle } from '../../../models/vehicle.model';
import { VehicleService } from '../../../services/vehicle.service';
import type {
  MaintenanceRequestDto,
  MaintenanceRequestStatus,
  MaintenanceRequestType,
  Priority,
  SafetyLevel,
} from '../../../services/maintenance-request.service';
import { MaintenanceRequestService } from '../../../services/maintenance-request.service';
import { MaintenanceImportService } from '../../../services/maintenance-import.service';
import { MaintenanceWorkOrderService } from '../../../services/maintenance-work-order.service';
import { ConfirmService } from '../../../services/confirm.service';
import { InputPromptService } from '../../../core/input-prompt.service';
import type { RepairType, WorkOrderDto } from '../../../services/maintenance-work-order.service';
import { Router } from '@angular/router';
import { FailureCodeService, type FailureCodeDto } from '../../../services/failure-code.service';
import {
  PmPlanService,
  type PreventiveMaintenancePlanDto,
} from '../../../services/pm-plan.service';
import { getMaintenanceRequestStatusClass } from '../maintenance-status.utils';

@Component({
  selector: 'app-maintenance-requests',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
            <i class="text-2xl text-blue-600 fas fa-clipboard-check"></i>
          </div>
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Maintenance Requests</h1>
            <p class="text-gray-600">All maintenance starts from MR (SV Standard)</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <label
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 cursor-pointer"
          >
            <input type="file" class="hidden" accept=".xlsx,.xls" (change)="onImport($event)" />
            <i class="fas fa-file-import mr-2"></i>Import Excel
          </label>
          <button
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            (click)="openCreate()"
            type="button"
          >
            <i class="fas fa-plus mr-2"></i>Create MR
          </button>
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>
      <div
        *ngIf="importStatus"
        class="mb-4 p-3 rounded border border-blue-200 bg-blue-50 text-blue-700"
      >
        {{ importStatus }}
      </div>

      <div class="grid grid-cols-2 md:grid-cols-5 gap-3 mb-4">
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Draft</div>
          <div class="text-xl font-bold text-amber-700">{{ kpis.draft }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Submitted</div>
          <div class="text-xl font-bold text-blue-700">{{ kpis.submitted }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Approved</div>
          <div class="text-xl font-bold text-emerald-700">{{ kpis.approved }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Rejected</div>
          <div class="text-xl font-bold text-red-700">{{ kpis.rejected }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">With WO</div>
          <div class="text-xl font-bold text-indigo-700">{{ kpis.withWo }}</div>
        </div>
      </div>

      <div class="bg-white border rounded-lg shadow-sm mb-4">
        <div class="p-4 grid grid-cols-1 md:grid-cols-6 gap-3">
          <input
            class="px-3 py-2 border rounded-lg"
            [(ngModel)]="filters.search"
            placeholder="Search MR number or title"
            (keyup.enter)="apply()"
          />
          <select class="px-3 py-2 border rounded-lg" [(ngModel)]="filters.status">
            <option value="">All Status</option>
            <option *ngFor="let s of statuses" [ngValue]="s">{{ s }}</option>
          </select>
          <select class="px-3 py-2 border rounded-lg" [(ngModel)]="filters.vehicleId">
            <option [ngValue]="''">All Vehicles</option>
            <option *ngFor="let v of vehicles" [ngValue]="v.id">{{ v.licensePlate }}</option>
          </select>
          <select class="px-3 py-2 border rounded-lg" [(ngModel)]="filters.failureCodeId">
            <option [ngValue]="''">All Failure Codes</option>
            <option *ngFor="let code of failureCodes" [ngValue]="code.id">
              {{ code.code }}{{ code.description ? ' · ' + code.description : '' }}
            </option>
          </select>
          <div class="flex items-center gap-3 text-xs text-gray-700">
            <label class="inline-flex items-center gap-2">
              <input type="checkbox" [(ngModel)]="filters.needsWoOnly" />
              Needs WO
            </label>
            <label class="inline-flex items-center gap-2">
              <input type="checkbox" [(ngModel)]="filters.pmOnly" />
              PM only
            </label>
          </div>
          <div class="flex gap-2">
            <button
              class="px-4 py-2 bg-green-600 text-white rounded-lg"
              (click)="apply()"
              [disabled]="isLoading"
              type="button"
            >
              Apply
            </button>
            <button
              class="px-4 py-2 border rounded-lg"
              (click)="reset()"
              [disabled]="isLoading"
              type="button"
            >
              Reset
            </button>
          </div>
        </div>
      </div>

      <div
        *ngIf="isLoading"
        class="mb-4 p-3 rounded border border-blue-200 bg-blue-50 text-blue-700 text-sm"
      >
        Loading maintenance requests...
      </div>

      <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">MR #</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Vehicle</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Title</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Type</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Safety</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Priority</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Status</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">WO</th>
                <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let mr of filteredRows" class="border-t">
                <td class="px-4 py-3 text-sm font-medium text-gray-900">
                  <a
                    class="text-blue-700 hover:underline"
                    [routerLink]="['/fleet/maintenance/requests', mr.id]"
                    [queryParams]="{ group: 'overview' }"
                  >
                    {{ mr.mrNumber }}
                  </a>
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  <a
                    *ngIf="mr.vehicleId"
                    class="text-blue-700 hover:underline"
                    [routerLink]="['/fleet/vehicles', mr.vehicleId]"
                  >
                    {{ mr.vehiclePlate }}
                  </a>
                  <span *ngIf="!mr.vehicleId">{{ mr.vehiclePlate || '-' }}</span>
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ mr.title }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ mr.requestType || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  <span
                    class="px-2 py-1 text-xs rounded-full border"
                    [ngClass]="
                      mr.safetyLevel === 'CRITICAL'
                        ? 'border-red-200 text-red-700 bg-red-50'
                        : mr.safetyLevel === 'MAJOR'
                          ? 'border-yellow-200 text-yellow-700 bg-yellow-50'
                          : 'border-green-200 text-green-700 bg-green-50'
                    "
                  >
                    {{ mr.safetyLevel || 'MINOR' }}
                  </span>
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ mr.priority || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  <span
                    class="px-2 py-1 text-xs rounded-full border font-semibold"
                    [ngClass]="getStatusClass(mr.status)"
                  >
                    {{ mr.status }}
                  </span>
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  <a
                    *ngIf="mr.workOrderId"
                    class="text-blue-700 hover:underline"
                    [routerLink]="['/fleet/maintenance/work-orders', mr.workOrderId]"
                  >
                    {{ mr.workOrderNumber }}
                  </a>
                  <span *ngIf="!mr.workOrderId">{{ mr.workOrderNumber || '-' }}</span>
                </td>
                <td class="px-4 py-3 text-sm text-right relative">
                  <button
                    *ngIf="mr.status === 'APPROVED' && !mr.workOrderId"
                    class="px-3 py-1 mr-2 text-xs text-indigo-700 border border-indigo-200 rounded-lg hover:bg-indigo-50"
                    (click)="openCreateWo(mr)"
                    [disabled]="actionLoading"
                    type="button"
                  >
                    Create WO
                  </button>
                  <button
                    class="px-3 py-1 border rounded-lg hover:bg-gray-50"
                    (click)="toggleMenu(mr)"
                    type="button"
                  >
                    Actions
                  </button>
                  <div
                    *ngIf="menuOpenId === mr.id"
                    class="absolute right-4 mt-2 w-44 bg-white border rounded-lg shadow-md z-10 text-left"
                  >
                    <button
                      class="w-full px-3 py-2 text-sm hover:bg-gray-50"
                      (click)="goToMrDetails(mr)"
                      type="button"
                    >
                      View Details
                    </button>
                    <button
                      *ngIf="mr.status === 'SUBMITTED' || mr.status === 'DRAFT'"
                      class="w-full px-3 py-2 text-sm hover:bg-gray-50"
                      (click)="approve(mr); closeMenu()"
                      [disabled]="actionLoading"
                      type="button"
                    >
                      Approve
                    </button>
                    <button
                      *ngIf="mr.status === 'SUBMITTED' || mr.status === 'DRAFT'"
                      class="w-full px-3 py-2 text-sm hover:bg-gray-50"
                      (click)="reject(mr); closeMenu()"
                      [disabled]="actionLoading"
                      type="button"
                    >
                      Reject
                    </button>
                    <button
                      *ngIf="mr.status === 'APPROVED' && !mr.workOrderId"
                      class="w-full px-3 py-2 text-sm hover:bg-gray-50 text-indigo-700 font-semibold"
                      (click)="openCreateWo(mr); closeMenu()"
                      [disabled]="actionLoading"
                      type="button"
                    >
                      Create WO
                    </button>
                    <button
                      *ngIf="mr.status === 'APPROVED' && mr.workOrderId"
                      class="w-full px-3 py-2 text-sm hover:bg-gray-50"
                      (click)="goToWorkOrder(mr); closeMenu()"
                      type="button"
                    >
                      View WO
                    </button>
                  </div>
                </td>
              </tr>
              <tr *ngIf="!isLoading && (filteredRows.length || 0) === 0">
                <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="9">No results</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="px-4 py-3 border-t flex items-center justify-between text-sm text-gray-600">
          <div>
            Showing
            <span class="font-medium">{{ (page?.number || 0) * (page?.size || 0) + 1 }}</span>
            to
            <span class="font-medium">{{
              Math.min(((page?.number || 0) + 1) * (page?.size || 0), page?.totalElements || 0)
            }}</span>
            of <span class="font-medium">{{ page?.totalElements || 0 }}</span>
          </div>
          <div class="flex items-center gap-2">
            <button
              class="px-3 py-1 border rounded"
              (click)="prev()"
              [disabled]="(page?.number || 0) <= 0 || isLoading"
              type="button"
            >
              Prev
            </button>
            <button
              class="px-3 py-1 border rounded"
              (click)="next()"
              [disabled]="(page?.number || 0) >= (page?.totalPages || 1) - 1 || isLoading"
              type="button"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      <!-- Create modal -->
      <div
        *ngIf="createOpen"
        class="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50"
      >
        <div class="bg-white rounded-lg w-full max-w-xl shadow-lg">
          <div class="px-5 py-4 border-b flex items-center justify-between">
            <h3 class="font-semibold text-gray-900">Create Maintenance Request</h3>
            <button
              class="text-gray-500 hover:text-gray-700"
              (click)="createOpen = false"
              type="button"
            >
              <i class="fas fa-times"></i>
            </button>
          </div>
          <div class="p-5 space-y-3">
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Vehicle</label>
              <select
                class="w-full px-3 py-2 border rounded-lg"
                [(ngModel)]="create.vehicleId"
                (change)="onCreateVehicleChange()"
              >
                <option [ngValue]="null">Select vehicle</option>
                <option *ngFor="let v of vehicles" [ngValue]="v.id">{{ v.licensePlate }}</option>
              </select>
              <p *ngIf="createSubmitted && !create.vehicleId" class="mt-1 text-xs text-red-600">
                Vehicle is required.
              </p>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-medium text-gray-700 mb-1">Request Type</label>
                <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="create.requestType">
                  <option *ngFor="let t of requestTypes" [ngValue]="t">{{ t }}</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 mb-1">Safety Level</label>
                <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="create.safetyLevel">
                  <option *ngFor="let s of safetyLevels" [ngValue]="s">{{ s }}</option>
                </select>
              </div>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Failure Code</label>
              <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="create.failureCodeId">
                <option [ngValue]="null">None</option>
                <option *ngFor="let code of failureCodes" [ngValue]="code.id">
                  {{ code.code }} - {{ code.description }}
                </option>
              </select>
            </div>
            <div *ngIf="create.requestType === 'PM'">
              <label class="block text-xs font-medium text-gray-700 mb-1">PM Plan</label>
              <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="create.pmPlanId">
                <option [ngValue]="null">Select PM plan</option>
                <option *ngFor="let plan of pmPlans" [ngValue]="plan.id">
                  {{ plan.planName }} ({{ plan.intervalType }} {{ plan.intervalValue }})
                </option>
              </select>
              <p class="text-xs text-gray-500 mt-1">PM requests should reference a plan.</p>
              <p *ngIf="createSubmitted && !create.pmPlanId" class="mt-1 text-xs text-red-600">
                PM plan is required for PM request.
              </p>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Title</label>
              <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="create.title" />
              <p *ngIf="createSubmitted && !create.title" class="mt-1 text-xs text-red-600">
                Title is required.
              </p>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Priority</label>
              <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="create.priority">
                <option [ngValue]="'NORMAL'">NORMAL</option>
                <option [ngValue]="'LOW'">LOW</option>
                <option [ngValue]="'HIGH'">HIGH</option>
                <option [ngValue]="'URGENT'">URGENT</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Description</label>
              <textarea
                class="w-full px-3 py-2 border rounded-lg"
                rows="4"
                [(ngModel)]="create.description"
              ></textarea>
            </div>
          </div>
          <div class="px-5 py-4 border-t flex items-center justify-end gap-2">
            <button class="px-4 py-2 border rounded-lg" (click)="createOpen = false" type="button">
              Cancel
            </button>
            <button
              class="px-4 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-50"
              (click)="submitCreate()"
              [disabled]="createLoading"
              type="button"
            >
              {{ createLoading ? 'Creating...' : 'Create' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Create WO modal -->
      <div
        *ngIf="createWoOpen"
        class="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50"
      >
        <div class="bg-white rounded-lg w-full max-w-lg shadow-lg">
          <div class="px-5 py-4 border-b flex items-center justify-between">
            <div>
              <h3 class="font-semibold text-gray-900">Create Work Order</h3>
              <p class="text-xs text-gray-500">
                {{ createWoMr?.mrNumber }} • {{ createWoMr?.vehiclePlate }}
              </p>
            </div>
            <button
              class="text-gray-500 hover:text-gray-700"
              (click)="closeCreateWo()"
              type="button"
            >
              <i class="fas fa-times"></i>
            </button>
          </div>
          <div class="p-5 space-y-3">
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Repair Type</label>
              <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="createWo.repairType">
                <option value="OWN">OWN</option>
                <option value="VENDOR">VENDOR</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Estimated Deadline</label>
              <input
                class="w-full px-3 py-2 border rounded-lg"
                type="datetime-local"
                [(ngModel)]="createWo.scheduledDate"
              />
            </div>
            <div class="text-sm text-gray-600">
              Title: <span class="font-medium text-gray-900">{{ createWoMr?.title }}</span>
            </div>
            <div class="text-sm text-gray-600">
              Priority: <span class="font-medium text-gray-900">{{ createWoMr?.priority }}</span>
            </div>
          </div>
          <div class="px-5 py-4 border-t flex items-center justify-end gap-2">
            <button class="px-4 py-2 border rounded-lg" (click)="closeCreateWo()" type="button">
              Cancel
            </button>
            <button
              class="px-4 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-50"
              (click)="submitCreateWo()"
              [disabled]="actionLoading"
              type="button"
            >
              Create WO
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class MaintenanceRequestsComponent implements OnInit {
  Math = Math;

  vehicles: Vehicle[] = [];
  page: PagedResponse<MaintenanceRequestDto> | null = null;

  error = '';
  importStatus = '';
  actionLoading = false;
  createLoading = false;
  isLoading = false;
  createSubmitted = false;

  filters: {
    search: string;
    status: '' | MaintenanceRequestStatus;
    vehicleId: '' | number;
    failureCodeId: '' | number;
    needsWoOnly: boolean;
    pmOnly: boolean;
  } = {
    search: '',
    status: '',
    vehicleId: '',
    failureCodeId: '',
    needsWoOnly: false,
    pmOnly: false,
  };

  statuses: MaintenanceRequestStatus[] = [
    'DRAFT',
    'SUBMITTED',
    'APPROVED',
    'REJECTED',
    'CANCELLED',
  ];
  requestTypes: MaintenanceRequestType[] = ['REPAIR', 'EMERGENCY', 'PM', 'INSPECTION'];
  safetyLevels: SafetyLevel[] = ['CRITICAL', 'MAJOR', 'MINOR'];
  failureCodes: FailureCodeDto[] = [];
  pmPlans: PreventiveMaintenancePlanDto[] = [];

  pageIndex = 0;
  pageSize = 10;

  createOpen = false;
  create: {
    vehicleId: number | null;
    title: string;
    description: string;
    priority: Priority;
    requestType: MaintenanceRequestType;
    safetyLevel: SafetyLevel;
    failureCodeId?: number | null;
    pmPlanId?: number | null;
  } = {
    vehicleId: null,
    title: '',
    description: '',
    priority: 'NORMAL',
    requestType: 'REPAIR',
    safetyLevel: 'MINOR',
    failureCodeId: null,
    pmPlanId: null,
  };

  menuOpenId: number | null = null;

  createWoOpen = false;
  createWoMr: MaintenanceRequestDto | null = null;
  createWo: { repairType: RepairType; scheduledDate: string } = {
    repairType: 'OWN',
    scheduledDate: '',
  };

  get filteredRows(): MaintenanceRequestDto[] {
    let rows = this.page?.content || [];
    if (this.filters.needsWoOnly) {
      rows = rows.filter((mr) => !mr.workOrderId);
    }
    if (this.filters.pmOnly) {
      rows = rows.filter((mr) => mr.requestType === 'PM');
    }
    return rows;
  }

  get kpis(): {
    draft: number;
    submitted: number;
    approved: number;
    rejected: number;
    withWo: number;
  } {
    const rows = this.page?.content || [];
    return {
      draft: rows.filter((x) => x.status === 'DRAFT').length,
      submitted: rows.filter((x) => x.status === 'SUBMITTED').length,
      approved: rows.filter((x) => x.status === 'APPROVED').length,
      rejected: rows.filter((x) => x.status === 'REJECTED').length,
      withWo: rows.filter((x) => !!x.workOrderId).length,
    };
  }

  constructor(
    private readonly mrService: MaintenanceRequestService,
    private readonly vehicleService: VehicleService,
    private readonly importService: MaintenanceImportService,
    private readonly woService: MaintenanceWorkOrderService,
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly confirm: ConfirmService,
    private readonly inputPrompt: InputPromptService,
    private readonly failureCodeService: FailureCodeService,
    private readonly pmPlanService: PmPlanService,
  ) {}

  ngOnInit(): void {
    this.loadVehicles();
    this.loadFailureCodes();
    this.route.queryParamMap.subscribe((params) => {
      const vehicleId = params.get('vehicleId');
      const failureCodeId = params.get('failureCodeId');
      const status = params.get('status') as MaintenanceRequestStatus | null;
      const search = params.get('search');
      if (vehicleId) {
        this.filters.vehicleId = Number(vehicleId);
      }
      if (failureCodeId) {
        this.filters.failureCodeId = Number(failureCodeId);
      }
      if (status) {
        this.filters.status = status;
      }
      if (search) {
        this.filters.search = search;
      }
      this.load();
    });
  }

  loadVehicles(): void {
    // Grab a small page of vehicles for selection.
    this.vehicleService.getVehicles(0, 200, {}).subscribe({
      next: (res: any) => {
        this.vehicles = res?.data?.content ?? [];
      },
      error: () => {
        // non-fatal; MR page can still load
      },
    });
  }

  loadFailureCodes(): void {
    this.failureCodeService.listActive().subscribe({
      next: (res) => {
        this.failureCodes = res?.data ?? [];
      },
      error: () => {
        this.failureCodes = [];
      },
    });
  }

  loadPmPlansForVehicle(vehicleId?: number | null): void {
    if (!vehicleId) {
      this.pmPlans = [];
      return;
    }
    this.pmPlanService.listByVehicle(vehicleId).subscribe({
      next: (res) => {
        this.pmPlans = res?.data ?? [];
      },
      error: () => {
        this.pmPlans = [];
      },
    });
  }

  load(): void {
    this.error = '';
    this.importStatus = '';
    this.isLoading = true;
    this.mrService
      .list({
        search: this.filters.search || undefined,
        status: this.filters.status || undefined,
        vehicleId: (this.filters.vehicleId as any) || undefined,
        failureCodeId: (this.filters.failureCodeId as any) || undefined,
        page: this.pageIndex,
        size: this.pageSize,
      })
      .subscribe({
        next: (res) => {
          this.page = res.data;
        },
        error: (err) => {
          console.error(err);
          this.error = 'Failed to load maintenance requests.';
        },
        complete: () => {
          this.isLoading = false;
        },
      });
  }

  apply(): void {
    this.pageIndex = 0;
    this.load();
  }

  reset(): void {
    this.filters = {
      search: '',
      status: '',
      vehicleId: '',
      failureCodeId: '',
      needsWoOnly: false,
      pmOnly: false,
    };
    this.apply();
  }

  prev(): void {
    if (this.pageIndex <= 0) return;
    this.pageIndex--;
    this.load();
  }

  next(): void {
    if (this.page && this.pageIndex >= (this.page.totalPages || 1) - 1) return;
    this.pageIndex++;
    this.load();
  }

  openCreate(): void {
    this.error = '';
    this.createSubmitted = false;
    this.create = {
      vehicleId: (this.filters.vehicleId as number) || null,
      title: '',
      description: '',
      priority: 'NORMAL',
      requestType: 'REPAIR',
      safetyLevel: 'MINOR',
      failureCodeId: null,
      pmPlanId: null,
    };
    this.pmPlans = [];
    this.createOpen = true;
    if (this.create.vehicleId) {
      this.loadPmPlansForVehicle(this.create.vehicleId);
    }
  }

  onCreateVehicleChange(): void {
    this.create.pmPlanId = null;
    this.loadPmPlansForVehicle(this.create.vehicleId);
  }

  submitCreate(): void {
    this.error = '';
    this.createSubmitted = true;
    if (!this.create.vehicleId || !this.create.title) {
      return;
    }
    if (this.create.requestType === 'PM' && !this.create.pmPlanId) {
      return;
    }
    const payload: MaintenanceRequestDto = {
      vehicleId: Number(this.create.vehicleId),
      title: this.create.title,
      description: this.create.description,
      priority: this.create.priority,
      requestType: this.create.requestType,
      failureCodeId: this.create.failureCodeId ?? undefined,
    };
    this.createLoading = true;
    this.mrService.create(payload).subscribe({
      next: () => {
        this.createOpen = false;
        this.createLoading = false;
        this.apply();
      },
      error: (err) => {
        console.error(err);
        this.error = 'Failed to create maintenance request.';
        this.createLoading = false;
      },
    });
  }

  getStatusClass(status?: MaintenanceRequestStatus): string {
    return getMaintenanceRequestStatusClass(status);
  }

  toggleMenu(mr: MaintenanceRequestDto): void {
    this.menuOpenId = this.menuOpenId === mr.id ? null : (mr.id ?? null);
  }

  closeMenu(): void {
    this.menuOpenId = null;
  }

  goToMrDetails(mr: MaintenanceRequestDto): void {
    this.closeMenu();
    if (!mr.id) return;
    this.router.navigate(['/fleet/maintenance/requests', mr.id], {
      queryParams: { group: 'overview' },
    });
  }

  openCreateWo(mr: MaintenanceRequestDto): void {
    this.error = '';
    this.createWoMr = mr;
    this.createWo = { repairType: 'OWN', scheduledDate: '' };
    this.createWoOpen = true;
  }

  closeCreateWo(): void {
    this.createWoOpen = false;
    this.createWoMr = null;
  }

  submitCreateWo(): void {
    if (!this.createWoMr?.id) return;
    this.actionLoading = true;
    const dto = {
      type: this.createWoMr.requestType === 'PM' ? 'PREVENTIVE' : 'REPAIR',
      priority: this.createWoMr.priority || 'NORMAL',
      title: this.createWoMr.title,
      description: this.createWoMr.description,
      repairType: this.createWo.repairType,
      scheduledDate: this.createWo.scheduledDate || undefined,
    } as WorkOrderDto;

    this.woService.createFromMaintenanceRequest(this.createWoMr.id, dto).subscribe({
      next: () => {
        this.actionLoading = false;
        this.createWoOpen = false;
        this.createWoMr = null;
        this.load();
      },
      error: (err) => {
        console.error(err);
        this.actionLoading = false;
        this.error = 'Failed to create work order.';
      },
    });
  }

  goToWorkOrder(mr: MaintenanceRequestDto): void {
    if (!mr.workOrderId) return;
    this.router.navigate(['/fleet/maintenance/work-orders', mr.workOrderId]);
  }

  async approve(mr: MaintenanceRequestDto): Promise<void> {
    if (!mr.id) return;
    if (!(await this.confirm.confirm(`Approve MR ${mr.mrNumber}?`))) return;
    this.actionLoading = true;
    this.mrService.approve(mr.id).subscribe({
      next: () => this.load(),
      error: () => (this.error = 'Failed to approve MR.'),
      complete: () => (this.actionLoading = false),
    });
  }

  async reject(mr: MaintenanceRequestDto): Promise<void> {
    if (!mr.id) return;
    const reason =
      (await this.inputPrompt.prompt('Rejection reason (optional):', {
        placeholder: 'Optional reason',
      })) || '';
    if (!(await this.confirm.confirm(`Reject MR ${mr.mrNumber}?`))) return;
    this.actionLoading = true;
    this.mrService.reject(mr.id, reason).subscribe({
      next: () => this.load(),
      error: () => (this.error = 'Failed to reject MR.'),
      complete: () => (this.actionLoading = false),
    });
  }

  onImport(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.importStatus = 'Importing...';
    this.importService.importExcel(file).subscribe({
      next: (res) => {
        this.importStatus = `Import completed. ${JSON.stringify(res.data?.['imported'] || {})}`;
        this.load();
      },
      error: (err) => {
        console.error(err);
        this.importStatus = 'Import failed. Please check the Excel format.';
      },
    });
    input.value = '';
  }
}
