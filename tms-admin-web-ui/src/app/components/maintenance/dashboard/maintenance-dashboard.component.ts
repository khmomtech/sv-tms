import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { Router } from '@angular/router';

import { MaintenanceReportService } from '../../../services/maintenance-report.service';
import { MaintenanceRequestService } from '../../../services/maintenance-request.service';
import type { MaintenanceRequestDto } from '../../../services/maintenance-request.service';
import { MaintenanceWorkOrderService } from '../../../services/maintenance-work-order.service';
import type { WorkOrderDto } from '../../../services/maintenance-work-order.service';

type PagedRows<T> = { content: T[]; totalElements: number; totalPages: number };

type WorkloadRow = {
  assignee: string;
  open: number;
  inProgress: number;
  waitingParts: number;
  totalActive: number;
};

@Component({
  selector: 'app-maintenance-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
            <i class="text-2xl text-blue-600 fas fa-tools"></i>
          </div>
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Vehicle Maintenance</h1>
            <p class="text-gray-600">SV Standard: MR → WO (OWN / VENDOR)</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <a
            routerLink="/admin/employees"
            class="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
            >Employees</a
          >
          <a
            routerLink="/fleet/maintenance/requests"
            class="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
            >Maintenance Requests</a
          >
          <a
            routerLink="/fleet/maintenance/work-orders"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >Work Orders</a
          >
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-gray-900">{{ kpi?.['workOrdersOpen'] ?? '-' }}</p>
              <p class="text-sm text-gray-600">Open WOs</p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <i class="text-blue-600 fas fa-folder-open"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-yellow-600">
                {{ kpi?.['workOrdersInProgress'] ?? '-' }}
              </p>
              <p class="text-sm text-gray-600">In Progress</p>
            </div>
            <div class="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
              <i class="text-yellow-600 fas fa-cog"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-indigo-600">
                {{ kpi?.['workOrdersWaitingParts'] ?? '-' }}
              </p>
              <p class="text-sm text-gray-600">Waiting Parts</p>
            </div>
            <div class="w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center">
              <i class="text-indigo-600 fas fa-box"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-green-600">
                {{ kpi?.['workOrdersCompleted'] ?? '-' }}
              </p>
              <p class="text-sm text-gray-600">Completed</p>
            </div>
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <i class="text-green-600 fas fa-check-circle"></i>
            </div>
          </div>
        </div>
      </div>

      <section class="bg-white rounded-lg shadow-sm border mb-6">
        <div class="px-6 py-4 border-b flex items-center justify-between">
          <h3 class="font-semibold text-gray-900">Requests</h3>
          <div class="flex items-center gap-2">
            <input
              class="px-3 py-2 border border-gray-300 rounded-lg text-sm"
              [(ngModel)]="requestSearch"
              (keyup.enter)="searchRequests()"
              placeholder="Search MR#, vehicle, title"
            />
            <button
              class="px-3 py-2 border border-gray-300 rounded-lg text-sm hover:bg-gray-50"
              (click)="searchRequests()"
              type="button"
            >
              Search
            </button>
          </div>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">MR#</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Vehicle</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Title</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Priority</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Status</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Requested</th>
              </tr>
            </thead>
            <tbody>
              <tr
                *ngFor="let row of requests"
                class="border-t cursor-pointer hover:bg-blue-50"
                (click)="openRequest(row)"
              >
                <td class="px-4 py-3 text-sm font-medium text-gray-900">
                  {{ row.mrNumber || '-' }}
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.vehiclePlate || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.title || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.priority || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.status || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ formatDate(row.requestedAt) }}</td>
              </tr>
              <tr *ngIf="!requests.length">
                <td colspan="6" class="px-4 py-6 text-center text-sm text-gray-500">
                  No requests found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="px-6 py-3 border-t flex items-center justify-between text-sm">
          <span>Page {{ requestPage + 1 }} / {{ requestTotalPages }}</span>
          <div class="flex gap-2">
            <button
              class="px-3 py-1 border rounded disabled:opacity-50"
              (click)="prevRequestPage()"
              [disabled]="requestPage <= 0"
              type="button"
            >
              Prev
            </button>
            <button
              class="px-3 py-1 border rounded disabled:opacity-50"
              (click)="nextRequestPage()"
              [disabled]="requestPage + 1 >= requestTotalPages"
              type="button"
            >
              Next
            </button>
          </div>
        </div>
      </section>

      <section class="bg-white rounded-lg shadow-sm border mb-6">
        <div class="px-6 py-4 border-b flex items-center justify-between">
          <h3 class="font-semibold text-gray-900">Work Orders</h3>
          <div class="flex items-center gap-2">
            <input
              class="px-3 py-2 border border-gray-300 rounded-lg text-sm"
              [(ngModel)]="workOrderSearch"
              (input)="applyWorkOrderView()"
              placeholder="Search WO#, vehicle, title"
            />
          </div>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">WO#</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Vehicle</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Title</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Priority</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Status</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Planned</th>
              </tr>
            </thead>
            <tbody>
              <tr
                *ngFor="let row of workOrdersView"
                class="border-t cursor-pointer hover:bg-blue-50"
                (click)="openWorkOrder(row)"
              >
                <td class="px-4 py-3 text-sm font-medium text-gray-900">
                  {{ row.woNumber || '-' }}
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.vehiclePlate || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.title || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.priority || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.status || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ formatDate(row.scheduledDate) }}</td>
              </tr>
              <tr *ngIf="!workOrdersView.length">
                <td colspan="6" class="px-4 py-6 text-center text-sm text-gray-500">
                  No work orders found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="px-6 py-3 border-t flex items-center justify-between text-sm">
          <span>Page {{ workOrderPage + 1 }} / {{ workOrderTotalPages }}</span>
          <div class="flex gap-2">
            <button
              class="px-3 py-1 border rounded disabled:opacity-50"
              (click)="prevWorkOrderPage()"
              [disabled]="workOrderPage <= 0"
              type="button"
            >
              Prev
            </button>
            <button
              class="px-3 py-1 border rounded disabled:opacity-50"
              (click)="nextWorkOrderPage()"
              [disabled]="workOrderPage + 1 >= workOrderTotalPages"
              type="button"
            >
              Next
            </button>
          </div>
        </div>
      </section>

      <section class="bg-white rounded-lg shadow-sm border">
        <div class="px-6 py-4 border-b flex items-center justify-between">
          <h3 class="font-semibold text-gray-900">Work Loads</h3>
          <div class="flex items-center gap-2">
            <input
              class="px-3 py-2 border border-gray-300 rounded-lg text-sm"
              [(ngModel)]="workloadSearch"
              (input)="applyWorkloadView()"
              placeholder="Search assignee"
            />
          </div>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Assignee</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Open</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">In Progress</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                  Waiting Parts
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                  Total Active
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                *ngFor="let row of workloadView"
                class="border-t cursor-pointer hover:bg-blue-50"
                (click)="openWorkload(row)"
              >
                <td class="px-4 py-3 text-sm font-medium text-gray-900">{{ row.assignee }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.open }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.inProgress }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.waitingParts }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ row.totalActive }}</td>
              </tr>
              <tr *ngIf="!workloadView.length">
                <td colspan="5" class="px-4 py-6 text-center text-sm text-gray-500">
                  No workloads found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="px-6 py-3 border-t flex items-center justify-between text-sm">
          <span>Page {{ workloadPage + 1 }} / {{ workloadTotalPages }}</span>
          <div class="flex gap-2">
            <button
              class="px-3 py-1 border rounded disabled:opacity-50"
              (click)="prevWorkloadPage()"
              [disabled]="workloadPage <= 0"
              type="button"
            >
              Prev
            </button>
            <button
              class="px-3 py-1 border rounded disabled:opacity-50"
              (click)="nextWorkloadPage()"
              [disabled]="workloadPage + 1 >= workloadTotalPages"
              type="button"
            >
              Next
            </button>
          </div>
        </div>
      </section>
    </div>
  `,
})
export class MaintenanceDashboardComponent implements OnInit {
  kpi: Record<string, any> | null = null;
  error = '';

  readonly requestPageSize = 5;
  requestPage = 0;
  requestTotalPages = 1;
  requestSearch = '';
  requests: MaintenanceRequestDto[] = [];

  readonly workOrderPageSize = 5;
  workOrderPage = 0;
  workOrderTotalPages = 1;
  workOrderSearch = '';
  workOrdersAll: WorkOrderDto[] = [];
  workOrdersView: WorkOrderDto[] = [];

  readonly workloadPageSize = 5;
  workloadPage = 0;
  workloadTotalPages = 1;
  workloadSearch = '';
  workloadsAll: WorkloadRow[] = [];
  workloadView: WorkloadRow[] = [];

  constructor(
    private readonly reportService: MaintenanceReportService,
    private readonly maintenanceRequestService: MaintenanceRequestService,
    private readonly maintenanceWorkOrderService: MaintenanceWorkOrderService,
    private readonly router: Router,
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.error = '';
    this.reportService.dashboard().subscribe({
      next: (res) => {
        this.kpi = res.data ?? null;
      },
      error: (err) => {
        console.error(err);
        this.error = 'Failed to load maintenance dashboard.';
      },
    });

    this.loadRequests();
    this.loadWorkOrders();
  }

  searchRequests(): void {
    this.requestPage = 0;
    this.loadRequests();
  }

  prevRequestPage(): void {
    if (this.requestPage <= 0) return;
    this.requestPage--;
    this.loadRequests();
  }

  nextRequestPage(): void {
    if (this.requestPage + 1 >= this.requestTotalPages) return;
    this.requestPage++;
    this.loadRequests();
  }

  prevWorkOrderPage(): void {
    if (this.workOrderPage <= 0) return;
    this.workOrderPage--;
    this.applyWorkOrderView();
  }

  nextWorkOrderPage(): void {
    if (this.workOrderPage + 1 >= this.workOrderTotalPages) return;
    this.workOrderPage++;
    this.applyWorkOrderView();
  }

  prevWorkloadPage(): void {
    if (this.workloadPage <= 0) return;
    this.workloadPage--;
    this.applyWorkloadView();
  }

  nextWorkloadPage(): void {
    if (this.workloadPage + 1 >= this.workloadTotalPages) return;
    this.workloadPage++;
    this.applyWorkloadView();
  }

  openRequest(row: MaintenanceRequestDto): void {
    if (!row.id) return;
    this.router.navigate(['/fleet/maintenance/requests', row.id]);
  }

  openWorkOrder(row: WorkOrderDto): void {
    if (!row.id) return;
    this.router.navigate(['/fleet/maintenance/work-orders', row.id]);
  }

  openWorkload(row: WorkloadRow): void {
    this.router.navigate(['/fleet/maintenance/work-orders'], {
      queryParams: { view: 'workload', assignee: row.assignee },
    });
  }

  formatDate(value?: string | null): string {
    if (!value) return '-';
    const dt = new Date(value);
    if (Number.isNaN(dt.getTime())) return '-';
    return dt.toLocaleString();
  }

  private loadRequests(): void {
    this.maintenanceRequestService
      .list({
        search: this.requestSearch || undefined,
        page: this.requestPage,
        size: this.requestPageSize,
      })
      .subscribe({
        next: (res) => {
          const page = this.normalizePaged<MaintenanceRequestDto>(res);
          this.requests = page.content;
          this.requestTotalPages = Math.max(1, page.totalPages);
        },
        error: (err) => {
          console.error(err);
          this.requests = [];
          this.requestTotalPages = 1;
        },
      });
  }

  private loadWorkOrders(): void {
    this.maintenanceWorkOrderService
      .listLegacy({
        page: 0,
        size: 200,
      })
      .subscribe({
        next: (res) => {
          const page = this.normalizePaged<WorkOrderDto>(res);
          this.workOrdersAll = page.content;
          this.workOrderPage = 0;
          this.applyWorkOrderView();

          this.workloadsAll = this.buildWorkloads(this.workOrdersAll);
          this.workloadPage = 0;
          this.applyWorkloadView();
        },
        error: (err) => {
          console.error(err);
          this.workOrdersAll = [];
          this.workOrdersView = [];
          this.workloadsAll = [];
          this.workloadView = [];
          this.workOrderTotalPages = 1;
          this.workloadTotalPages = 1;
        },
      });
  }

  applyWorkOrderView(): void {
    const q = this.workOrderSearch.trim().toLowerCase();
    const filtered = this.workOrdersAll.filter((row) => {
      if (!q) return true;
      return (
        (row.woNumber || '').toLowerCase().includes(q) ||
        (row.vehiclePlate || '').toLowerCase().includes(q) ||
        (row.title || '').toLowerCase().includes(q) ||
        (row.status || '').toLowerCase().includes(q)
      );
    });

    this.workOrderTotalPages = Math.max(1, Math.ceil(filtered.length / this.workOrderPageSize));
    if (this.workOrderPage >= this.workOrderTotalPages) {
      this.workOrderPage = this.workOrderTotalPages - 1;
    }
    const start = this.workOrderPage * this.workOrderPageSize;
    this.workOrdersView = filtered.slice(start, start + this.workOrderPageSize);
  }

  applyWorkloadView(): void {
    const q = this.workloadSearch.trim().toLowerCase();
    const filtered = this.workloadsAll.filter((row) =>
      !q ? true : row.assignee.toLowerCase().includes(q),
    );

    this.workloadTotalPages = Math.max(1, Math.ceil(filtered.length / this.workloadPageSize));
    if (this.workloadPage >= this.workloadTotalPages) {
      this.workloadPage = this.workloadTotalPages - 1;
    }
    const start = this.workloadPage * this.workloadPageSize;
    this.workloadView = filtered.slice(start, start + this.workloadPageSize);
  }

  private buildWorkloads(rows: WorkOrderDto[]): WorkloadRow[] {
    const map = new Map<string, WorkloadRow>();
    rows.forEach((row) => {
      const assignee =
        row.tasks?.[0]?.assignedTechnicianName ||
        (row.repairType === 'VENDOR' ? 'Vendor Team' : 'Unassigned');

      if (!map.has(assignee)) {
        map.set(assignee, { assignee, open: 0, inProgress: 0, waitingParts: 0, totalActive: 0 });
      }
      const target = map.get(assignee)!;
      if (row.status === 'OPEN') target.open += 1;
      if (row.status === 'IN_PROGRESS') target.inProgress += 1;
      if (row.status === 'WAITING_PARTS') target.waitingParts += 1;
      target.totalActive = target.open + target.inProgress + target.waitingParts;
    });

    return Array.from(map.values()).sort((a, b) => b.totalActive - a.totalActive);
  }

  private normalizePaged<T>(res: any): PagedRows<T> {
    const payload = res?.data ?? res;
    if (Array.isArray(payload)) {
      return {
        content: payload as T[],
        totalElements: payload.length,
        totalPages: 1,
      };
    }
    const content = Array.isArray(payload?.content) ? payload.content : [];
    const totalElements =
      typeof payload?.totalElements === 'number' ? payload.totalElements : content.length;
    const totalPages =
      typeof payload?.totalPages === 'number'
        ? payload.totalPages
        : Math.max(1, Math.ceil(totalElements / 5));
    return { content, totalElements, totalPages };
  }
}
