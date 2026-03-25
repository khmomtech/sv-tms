import { CommonModule } from '@angular/common';
import { Component, HostListener, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { ToastrService } from 'ngx-toastr';

import { DispatchStatus } from '../../models/dispatch-status.enum';
import type { Dispatch } from '../../models/dispatch.model';
import type { DispatchStatusHistory } from '../../models/dispatch-status-history.model';
import type { LoadingQueue, WarehouseCode } from '../../models/loading-queue.model';
import { DispatchService } from '../../services/dispatch.service';
import {
  LoadingOpsService,
  type LoadingDispatchDetail,
  type LoadingGateUpdatePayload,
} from '../../services/loading-ops.service';
import { AuthService } from '../../services/auth.service';

type LoadingLaneStatus = 'ARRIVED_LOADING' | 'IN_QUEUE' | 'LOADING' | 'LOADED';

interface LoadingLaneRow {
  dispatchId: number;
  routeCode?: string;
  driverName?: string;
  driverPhone?: string;
  truckPlate?: string;
  warehouseCode?: WarehouseCode;
  status: LoadingLaneStatus;
  queueId?: number;
  queueStatus?: string;
  queuePosition?: number;
  bay?: string | null;
  calledAt?: string | null;
  remarks?: string | null;
  preEntrySafetyStatus?: string;
  loadingSafetyStatus?: string;
  preEntrySafetyRequired?: boolean;
  actionBlockReason?: string;
}

interface LoadingLaneDetailVm {
  row: LoadingLaneRow;
  dispatch: any | null;
  queue: LoadingQueue | null;
  session: any | null;
  preEntrySafetyRequired: boolean;
  preEntrySafetyStatus: string;
  loadingSafetyStatus: string;
}

type LoadingMenuActionKey =
  | 'GET_TICKET'
  | 'CALL_TO_BAY'
  | 'START_LOADING'
  | 'OVERRIDE_STATUS'
  | 'VIEW_DISPATCH'
  | 'VIEW_HISTORY'
  | 'VIEW_SESSION'
  | 'OPEN_DETAIL';

interface LoadingMenuAction {
  key: LoadingMenuActionKey;
  label: string;
  mutating: boolean;
  disabled?: boolean;
  reason?: string;
}

interface ManualStatusOption {
  label: string;
  value: string;
}

@Component({
  selector: 'app-loading-khb',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6 space-y-4 max-w-7xl mx-auto">
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="text-xs uppercase tracking-wide text-slate-500">G-Management</p>
          <h2 class="text-2xl font-bold text-slate-900">Loading Management</h2>
          <p class="text-sm text-slate-600">
            Dispatches from ARRIVED_LOADING to LOADED (before transit)
          </p>
        </div>
        <div class="flex items-center gap-2">
          <select
            [(ngModel)]="warehouseFilter"
            (change)="loadRows()"
            class="px-3 py-2 border rounded-lg text-sm"
          >
            <option value="ALL">ALL</option>
            <option value="KHB">KHB</option>
            <option value="W2">W2</option>
            <option value="W3">W3</option>
          </select>
          <input
            type="date"
            [(ngModel)]="fromDate"
            class="px-3 py-2 border rounded-lg text-sm"
            title="From date"
            (change)="loadRows()"
          />
          <input
            type="date"
            [(ngModel)]="toDate"
            class="px-3 py-2 border rounded-lg text-sm"
            title="To date"
            (change)="loadRows()"
          />
          <input
            [(ngModel)]="bayInput"
            placeholder="Bay (e.g. B-01)"
            class="px-3 py-2 border rounded-lg text-sm"
          />
          <button
            class="px-3 py-2 text-sm font-semibold text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200"
            (click)="resetDateFilter()"
          >
            Reset Dates
          </button>
          <button
            class="px-4 py-2 text-sm font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700"
            (click)="loadRows()"
          >
            Refresh
          </button>
        </div>
      </div>

      <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <div class="p-3 bg-orange-50 border border-orange-200 rounded-lg">
          <p class="text-xs text-orange-700">Arrived Loading</p>
          <p class="text-2xl font-bold text-orange-900">{{ metrics.arrivedLoading }}</p>
        </div>
        <div class="p-3 bg-indigo-50 border border-indigo-200 rounded-lg">
          <p class="text-xs text-indigo-700">In Queue</p>
          <p class="text-2xl font-bold text-indigo-900">{{ metrics.inQueue }}</p>
        </div>
        <div class="p-3 bg-blue-50 border border-blue-200 rounded-lg">
          <p class="text-xs text-blue-700">Loading</p>
          <p class="text-2xl font-bold text-blue-900">{{ metrics.loading }}</p>
        </div>
        <div class="p-3 bg-emerald-50 border border-emerald-200 rounded-lg">
          <p class="text-xs text-emerald-700">Loaded</p>
          <p class="text-2xl font-bold text-emerald-900">{{ metrics.loaded }}</p>
        </div>
      </div>

      <div class="text-xs text-slate-600 bg-slate-50 border border-slate-200 rounded p-3">
        Pre-entry Safety (KHB) is the gate check before loading flow starts.
      </div>
      <div *ngIf="fromDate || toDate" class="text-xs text-blue-700">
        Filtered date range:
        {{ fromDate || '...' }} to {{ toDate || '...' }}
      </div>

      <div *ngIf="loading" class="p-6 text-center text-slate-500 border rounded-lg bg-white">
        Loading dispatches...
      </div>

      <div
        *ngIf="!loading && rows.length === 0"
        class="p-6 text-center text-slate-500 border rounded-lg bg-white"
      >
        No dispatches in loading lane for selected warehouse.
      </div>

      <div *ngIf="!loading && rows.length > 0" class="overflow-auto border rounded-lg bg-white">
        <table class="min-w-full text-sm">
          <thead class="bg-slate-50 text-slate-700">
            <tr>
              <th class="px-3 py-2 text-left">Dispatch</th>
              <th class="px-3 py-2 text-left">Driver</th>
              <th class="px-3 py-2 text-left">Truck</th>
              <th class="px-3 py-2 text-left">Stage</th>
              <th class="px-3 py-2 text-left">Queue</th>
              <th class="px-3 py-2 text-left">Loading Gate</th>
              <th class="px-3 py-2 text-left">Pre-Entry Safety</th>
              <th class="px-3 py-2 text-left">Daily/Loading Safety</th>
              <th class="px-3 py-2 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              *ngFor="let row of rows"
              class="border-t hover:bg-slate-50 cursor-pointer"
              (click)="openRowDrawer(row)"
            >
              <td class="px-3 py-2">
                <a
                  [routerLink]="['/dispatch', row.dispatchId]"
                  class="text-blue-700 hover:underline"
                  (click)="$event.stopPropagation()"
                >
                  #{{ row.dispatchId }}
                </a>
                <div class="text-xs text-slate-500">{{ row.routeCode || '-' }}</div>
              </td>
              <td class="px-3 py-2">
                <div>{{ row.driverName || '-' }}</div>
                <div class="text-xs text-slate-500">{{ row.driverPhone || '-' }}</div>
              </td>
              <td class="px-3 py-2">{{ row.truckPlate || '-' }}</td>
              <td class="px-3 py-2">
                <span
                  class="px-2 py-1 rounded text-xs font-semibold"
                  [ngClass]="stageClass(row.status)"
                >
                  {{ row.status }}
                </span>
                <div class="text-[11px] text-slate-500 mt-1">
                  Next: {{ getNextActionText(row) }}
                </div>
              </td>
              <td class="px-3 py-2">
                <div>#{{ row.queuePosition || '-' }}</div>
                <div class="text-xs text-slate-500">
                  {{ row.queueStatus || '-' }} {{ row.bay ? '· ' + row.bay : '' }}
                </div>
              </td>
              <td class="px-3 py-2">
                <div class="font-medium text-slate-800">{{ loadingGateState(row) }}</div>
                <div class="text-xs text-slate-500" *ngIf="row.calledAt">
                  {{ formatDateTime(row.calledAt) }}
                </div>
                <div class="text-xs text-slate-500" *ngIf="!row.calledAt">-</div>
                <div class="text-xs text-slate-500" *ngIf="row.remarks">{{ row.remarks }}</div>
              </td>
              <td class="px-3 py-2">
                {{ getPreEntrySafetyDisplay(row.preEntrySafetyRequired, row.preEntrySafetyStatus) }}
              </td>
              <td class="px-3 py-2">{{ row.loadingSafetyStatus || 'PENDING' }}</td>
              <td class="px-3 py-2 relative row-menu-container" (click)="$event.stopPropagation()">
                <div class="flex justify-end">
                  <button
                    type="button"
                    class="w-8 h-8 rounded border border-slate-200 text-slate-600 hover:bg-slate-100"
                    title="More actions"
                    (click)="toggleRowMenu(row.dispatchId, $event)"
                  >
                    ⋮
                  </button>
                </div>
                <div
                  *ngIf="openMenuDispatchId === row.dispatchId"
                  class="absolute right-3 mt-1 w-48 bg-white border border-slate-200 rounded-lg shadow-lg z-20"
                >
                  <button
                    type="button"
                    *ngFor="let action of getRowMenuActions(row)"
                    class="w-full text-left px-3 py-2 text-sm hover:bg-slate-50 disabled:text-slate-400 disabled:cursor-not-allowed"
                    [disabled]="action.disabled"
                    [title]="action.reason || ''"
                    (click)="onMenuAction(row, action, $event)"
                  >
                    {{ action.label }}
                  </button>
                </div>
                <div *ngIf="row.actionBlockReason" class="mt-1 text-[11px] text-orange-600">
                  {{ row.actionBlockReason }}
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div
        *ngIf="pendingAction"
        class="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4"
      >
        <div class="w-full max-w-md bg-white rounded-lg shadow-xl p-4">
          <h3 class="text-lg font-semibold text-slate-900">Confirm Action</h3>
          <p class="text-sm text-slate-600 mt-1">
            {{
              pendingAction.action.key === 'OVERRIDE_STATUS'
                ? 'Manual override for dispatch #' + pendingAction.row.dispatchId
                : 'Update dispatch #' +
                  pendingAction.row.dispatchId +
                  ' to ' +
                  pendingAction.action.label +
                  '?'
            }}
          </p>
          <div *ngIf="pendingAction.action.key === 'OVERRIDE_STATUS'" class="mt-3">
            <label class="block text-sm font-medium text-slate-700">Status</label>
            <select
              [(ngModel)]="pendingStatusValue"
              class="mt-1 w-full border rounded-lg p-2 text-sm"
            >
              <option *ngFor="let s of overrideStatusOptions" [value]="s.value">
                {{ s.label }}
              </option>
            </select>
          </div>
          <label class="block text-sm font-medium text-slate-700 mt-4">Add note (optional)</label>
          <textarea
            [(ngModel)]="pendingActionNote"
            rows="3"
            class="mt-1 w-full border rounded-lg p-2 text-sm"
            placeholder="Add operation note..."
          ></textarea>
          <div class="flex justify-end gap-2 mt-4">
            <button
              type="button"
              class="px-3 py-2 rounded bg-slate-100 text-slate-700 hover:bg-slate-200"
              (click)="cancelPendingAction()"
            >
              Cancel
            </button>
            <button
              type="button"
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              [disabled]="actionSubmitting"
              (click)="confirmPendingAction()"
            >
              {{ actionSubmitting ? 'Saving...' : 'Confirm' }}
            </button>
          </div>
        </div>
      </div>

      <div
        *ngIf="historyDispatchId !== null"
        class="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4"
      >
        <div class="w-full max-w-2xl bg-white rounded-lg shadow-xl p-4 max-h-[80vh] overflow-auto">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-slate-900">
              Status History · Dispatch #{{ historyDispatchId }}
            </h3>
            <button
              type="button"
              class="text-slate-600 hover:text-slate-900"
              (click)="closeHistory()"
            >
              ✕
            </button>
          </div>
          <div *ngIf="historyLoading" class="py-4 text-sm text-slate-500">Loading history...</div>
          <div *ngIf="historyError" class="py-4 text-sm text-red-600">{{ historyError }}</div>
          <div
            *ngIf="!historyLoading && !historyError && statusHistory.length === 0"
            class="py-4 text-sm text-slate-500"
          >
            No status history records.
          </div>
          <div
            *ngIf="!historyLoading && !historyError && statusHistory.length > 0"
            class="mt-3 space-y-2"
          >
            <div *ngFor="let h of statusHistory" class="border border-slate-200 rounded p-2">
              <div class="text-xs text-slate-500">
                {{ formatDateTime(h.updatedAt) }} · {{ h.updatedBy || 'system' }}
              </div>
              <div class="font-semibold text-slate-800">{{ h.status }}</div>
              <div *ngIf="h.remarks" class="text-sm text-slate-700 mt-1">{{ h.remarks }}</div>
            </div>
          </div>
        </div>
      </div>

      <div *ngIf="isDrawerOpen" class="fixed inset-0 z-40">
        <div class="absolute inset-0 bg-black/25" (click)="closeDrawer()"></div>
        <aside
          class="absolute right-0 top-0 h-full w-full max-w-xl bg-white shadow-2xl overflow-auto p-4"
        >
          <div class="flex items-start justify-between gap-2">
            <div>
              <div class="text-xs uppercase tracking-wide text-slate-500">Loading Detail</div>
              <h3 class="text-lg font-semibold text-slate-900">
                Dispatch #{{ selectedRowDispatchId }}
              </h3>
            </div>
            <button
              type="button"
              class="text-slate-600 hover:text-slate-900"
              (click)="closeDrawer()"
            >
              ✕
            </button>
          </div>

          <div *ngIf="drawerLoading" class="mt-4 text-sm text-slate-500">Loading detail...</div>
          <div *ngIf="drawerError" class="mt-4 text-sm text-red-600">{{ drawerError }}</div>

          <div *ngIf="!drawerLoading && detailVm" class="mt-4 space-y-4">
            <div class="p-3 rounded-lg border border-slate-200 bg-slate-50">
              <div class="flex items-center gap-2">
                <span
                  class="px-2 py-1 rounded text-xs font-semibold"
                  [ngClass]="stageClass(detailVm.row.status)"
                >
                  {{ detailVm.row.status }}
                </span>
                <span class="text-xs text-slate-600"
                  >Next: {{ getNextActionText(detailVm.row) }}</span
                >
              </div>
              <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span class="text-slate-500">Route:</span> {{ detailVm.row.routeCode || '-' }}
                </div>
                <div>
                  <span class="text-slate-500">Warehouse:</span>
                  {{ detailVm.row.warehouseCode || '-' }}
                </div>
                <div>
                  <span class="text-slate-500">Driver:</span> {{ detailVm.row.driverName || '-' }}
                </div>
                <div>
                  <span class="text-slate-500">Phone:</span> {{ detailVm.row.driverPhone || '-' }}
                </div>
                <div>
                  <span class="text-slate-500">Truck:</span> {{ detailVm.row.truckPlate || '-' }}
                </div>
                <div>
                  <span class="text-slate-500">Queue ID:</span> {{ detailVm.row.queueId || '-' }}
                </div>
              </div>
            </div>

            <div class="p-3 rounded-lg border border-slate-200">
              <h4 class="font-semibold text-slate-900">Safety</h4>
              <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span class="text-slate-500">Pre-Entry:</span>
                  {{
                    getPreEntrySafetyDisplay(
                      detailVm.preEntrySafetyRequired,
                      detailVm.preEntrySafetyStatus
                    )
                  }}
                </div>
                <div>
                  <span class="text-slate-500">Daily/Loading:</span>
                  {{ detailVm.loadingSafetyStatus || 'PENDING' }}
                </div>
              </div>
            </div>

            <div class="p-3 rounded-lg border border-slate-200">
              <h4 class="font-semibold text-slate-900">Loading Gate</h4>
              <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span class="text-slate-500">Gate State:</span>
                  {{ loadingGateState(detailVm.row) }}
                </div>
                <div>
                  <span class="text-slate-500">Called At:</span>
                  {{ formatDateTime(detailVm.row.calledAt) }}
                </div>
              </div>
              <div class="mt-3 space-y-2">
                <label class="block text-xs font-medium text-slate-700">Bay</label>
                <input
                  [(ngModel)]="drawerBay"
                  class="w-full border rounded-lg p-2 text-sm"
                  placeholder="e.g. B-01"
                />

                <label class="block text-xs font-medium text-slate-700">Queue Position</label>
                <input
                  type="number"
                  min="1"
                  [(ngModel)]="drawerQueuePosition"
                  class="w-full border rounded-lg p-2 text-sm"
                  placeholder="e.g. 12"
                />

                <label class="block text-xs font-medium text-slate-700">Operation Note</label>
                <textarea
                  rows="3"
                  [(ngModel)]="drawerNote"
                  class="w-full border rounded-lg p-2 text-sm"
                  placeholder="Add loading gate note..."
                ></textarea>

                <div class="flex justify-end">
                  <button
                    type="button"
                    class="px-3 py-2 rounded bg-slate-100 text-slate-700 hover:bg-slate-200 disabled:opacity-50"
                    [disabled]="!canSaveGateInfo() || actionSubmitting"
                    [title]="
                      canSaveGateInfo() ? 'Save loading gate data' : getGateSaveBlockReason()
                    "
                    (click)="saveGateInfo()"
                  >
                    Save Gate Info
                  </button>
                </div>
                <div *ngIf="!canSaveGateInfo()" class="mt-2 text-xs text-slate-500">
                  {{ getGateSaveBlockReason() }}
                </div>
              </div>
            </div>

            <div class="p-3 rounded-lg border border-slate-200">
              <h4 class="font-semibold text-slate-900">Actions</h4>
              <div class="mt-2 flex flex-wrap gap-2">
                <button
                  *ngFor="let action of getDrawerActions()"
                  type="button"
                  class="px-3 py-2 text-sm rounded border border-slate-200 hover:bg-slate-50 disabled:opacity-50"
                  [disabled]="action.disabled || actionSubmitting"
                  [title]="action.reason || ''"
                  (click)="handleDrawerAction(action)"
                >
                  {{ action.label }}
                </button>
              </div>
              <div *ngIf="detailVm.row.actionBlockReason" class="mt-2 text-xs text-orange-600">
                {{ detailVm.row.actionBlockReason }}
              </div>
              <div *ngIf="drawerActionError" class="mt-2 text-xs text-red-600">
                {{ drawerActionError }}
              </div>
            </div>
          </div>
        </aside>
      </div>
    </div>
  `,
})
export class LoadingKhbComponent implements OnInit {
  loading = false;
  actionSubmitting = false;
  bayInput = '';
  warehouseFilter: 'ALL' | WarehouseCode = 'ALL';
  fromDate = '';
  toDate = '';
  rows: LoadingLaneRow[] = [];
  openMenuDispatchId: number | null = null;
  pendingAction: { row: LoadingLaneRow; action: LoadingMenuAction } | null = null;
  pendingActionNote = '';
  pendingStatusValue = '';
  overrideStatusOptions: ManualStatusOption[] = [];
  historyDispatchId: number | null = null;
  historyLoading = false;
  historyError: string | null = null;
  statusHistory: DispatchStatusHistory[] = [];
  metrics = { arrivedLoading: 0, inQueue: 0, loading: 0, loaded: 0 };

  selectedRowDispatchId: number | null = null;
  isDrawerOpen = false;
  drawerLoading = false;
  drawerError: string | null = null;
  detailVm: LoadingLaneDetailVm | null = null;
  drawerBay = '';
  drawerQueuePosition: number | null = null;
  drawerNote = '';
  drawerActionError: string | null = null;
  private pendingOpenDispatchId: number | null = null;

  constructor(
    private readonly loadingOpsService: LoadingOpsService,
    private readonly dispatchService: DispatchService,
    private readonly authService: AuthService,
    private readonly toastr: ToastrService,
    private readonly route: ActivatedRoute,
    private readonly router: Router,
  ) {}

  ngOnInit(): void {
    this.route.queryParamMap.subscribe((params) => {
      const dispatchId = Number(params.get('dispatchId'));
      this.pendingOpenDispatchId =
        Number.isFinite(dispatchId) && dispatchId > 0 ? dispatchId : null;
      this.openRowDrawerByPendingId();
    });
    this.loadRows();
  }

  resetDateFilter(): void {
    this.fromDate = '';
    this.toDate = '';
    this.loadRows();
  }

  loadRows(): void {
    this.loading = true;
    if (this.fromDate && this.toDate && this.fromDate > this.toDate) {
      this.toastr.warning('From date cannot be later than To date.');
      this.loading = false;
      return;
    }

    const start = this.fromDate ? new Date(`${this.fromDate}T00:00:00`).toISOString() : undefined;
    const end = this.toDate ? new Date(`${this.toDate}T23:59:59`).toISOString() : undefined;
    const queueCalls =
      this.warehouseFilter === 'ALL'
        ? [
            this.loadingOpsService.queueByWarehouse('KHB').pipe(catchError(() => of([]))),
            this.loadingOpsService.queueByWarehouse('W2').pipe(catchError(() => of([]))),
            this.loadingOpsService.queueByWarehouse('W3').pipe(catchError(() => of([]))),
          ]
        : [
            this.loadingOpsService
              .queueByWarehouse(this.warehouseFilter)
              .pipe(catchError(() => of([]))),
          ];

    forkJoin({
      queues: forkJoin(queueCalls),
      dispatches: this.dispatchService.filterDispatches({
        page: 0,
        size: 500,
        start,
        end,
      }),
    }).subscribe({
      next: ({ queues, dispatches }) => {
        this.rows = this.buildRows(queues, dispatches);
        this.openRowDrawerByPendingId();
        if (this.rows.length > 0 || this.fromDate || this.toDate) {
          this.computeMetrics();
          this.loading = false;
          this.refreshDrawerIfOpen();
          return;
        }

        this.dispatchService.getAllDispatches(0, 500).subscribe({
          next: (allRes) => {
            this.rows = this.buildRows(queues, allRes);
            this.openRowDrawerByPendingId();
            this.computeMetrics();
            this.loading = false;
            this.refreshDrawerIfOpen();
          },
          error: (allErr) => {
            console.error('Fallback load failed', allErr);
            this.toastr.error(allErr?.error?.message || 'Unable to load loading management data');
            this.loading = false;
          },
        });
      },
      error: (err) => {
        console.error('Failed to load loading lane rows', err);
        this.toastr.error(err?.error?.message || 'Unable to load loading management data');
        this.loading = false;
      },
    });
  }

  private buildRows(queueRes: any[], dispatchRes: any): LoadingLaneRow[] {
    const queueRows: LoadingQueue[] = (queueRes || []).flatMap((q) =>
      Array.isArray(q) ? q : q?.content || [],
    );
    const queueByDispatchId = new Map<number, LoadingQueue>(
      queueRows.filter((q) => typeof q?.dispatchId === 'number').map((q) => [q.dispatchId, q]),
    );

    const dispatchRows: Dispatch[] = dispatchRes?.data?.content || [];
    const laneStatuses = new Set<string>([
      DispatchStatus.ARRIVED_LOADING,
      DispatchStatus.IN_QUEUE,
      DispatchStatus.LOADING,
      DispatchStatus.LOADED,
    ]);

    return dispatchRows
      .filter((d) => {
        if (!d?.id || !laneStatuses.has(String(d.status))) return false;
        const queueEntry = queueByDispatchId.get(d.id);
        return this.matchesWarehouse(d, queueEntry, this.warehouseFilter);
      })
      .map((d) => {
        const queueEntry = queueByDispatchId.get(d.id!);
        const row = {
          dispatchId: d.id!,
          routeCode: d.routeCode,
          driverName: (d as any).driverName,
          driverPhone: (d as any).driverPhone,
          truckPlate: (d as any).licensePlate,
          status: String(d.status) as LoadingLaneStatus,
          warehouseCode:
            this.normalizeWarehouseCode((queueEntry as any)?.warehouseCode) ||
            this.resolveDispatchWarehouse(d) ||
            undefined,
          queueId: queueEntry?.id,
          queueStatus: queueEntry?.status,
          queuePosition: queueEntry?.queuePosition,
          bay: queueEntry?.bay,
          calledAt: queueEntry?.calledAt || null,
          remarks: queueEntry?.remarks || null,
          preEntrySafetyRequired: (d as any).preEntrySafetyRequired === true,
          preEntrySafetyStatus:
            String((d as any).preEntrySafetyStatus || '').toUpperCase() || 'PENDING',
          loadingSafetyStatus: String((d as any).safetyStatus || '').toUpperCase() || 'PENDING',
        } as LoadingLaneRow;
        row.actionBlockReason = this.getActionBlockReason(row);
        return row;
      })
      .sort((a, b) => a.dispatchId - b.dispatchId);
  }

  stageClass(status: LoadingLaneStatus): string {
    switch (status) {
      case 'ARRIVED_LOADING':
        return 'bg-orange-100 text-orange-800';
      case 'IN_QUEUE':
        return 'bg-indigo-100 text-indigo-800';
      case 'LOADING':
        return 'bg-blue-100 text-blue-800';
      case 'LOADED':
        return 'bg-emerald-100 text-emerald-800';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  }

  canEnqueue(row: LoadingLaneRow): boolean {
    return !row.queueId && (row.status === 'ARRIVED_LOADING' || row.status === 'IN_QUEUE');
  }

  canCall(row: LoadingLaneRow): boolean {
    return (
      row.status === 'IN_QUEUE' &&
      !!row.queueId &&
      row.queueStatus === 'WAITING' &&
      this.isPreEntryPassedIfRequired(row)
    );
  }

  canStart(row: LoadingLaneRow): boolean {
    return (
      row.status === 'IN_QUEUE' &&
      !!row.queueId &&
      row.queueStatus === 'CALLED' &&
      this.isPreEntryPassedIfRequired(row)
    );
  }

  getRowMenuActions(row: LoadingLaneRow): LoadingMenuAction[] {
    const actions: LoadingMenuAction[] = [];

    if (this.canEnqueue(row)) {
      const label = row.status === 'IN_QUEUE' ? 'Rebuild Queue Entry' : 'Get Ticket';
      actions.push({
        key: 'GET_TICKET',
        label,
        mutating: true,
        disabled: !this.canEnqueue(row),
        reason: this.canEnqueue(row) ? undefined : this.getActionBlockReason(row),
      });
    } else if (row.status === 'IN_QUEUE' && row.queueStatus === 'WAITING') {
      actions.push({
        key: 'CALL_TO_BAY',
        label: 'Loading Gate',
        mutating: true,
        disabled: !this.canCall(row),
        reason: this.canCall(row) ? undefined : this.getActionBlockReason(row),
      });
    } else if (row.status === 'IN_QUEUE' && row.queueStatus === 'CALLED') {
      actions.push({
        key: 'START_LOADING',
        label: 'Start Loading',
        mutating: true,
        disabled: !this.canStart(row),
        reason: this.canStart(row) ? undefined : this.getActionBlockReason(row),
      });
    }

    if (row.status === 'LOADING' || row.status === 'LOADED') {
      actions.push({ key: 'VIEW_SESSION', label: 'View Session', mutating: false });
    }

    if (this.canManualOverride()) {
      actions.push({ key: 'OVERRIDE_STATUS', label: 'Manual Status Override', mutating: true });
    }

    actions.push({ key: 'OPEN_DETAIL', label: 'Open Detail', mutating: false });
    actions.push({ key: 'VIEW_DISPATCH', label: 'View Dispatch', mutating: false });
    actions.push({ key: 'VIEW_HISTORY', label: 'View Status History', mutating: false });
    return actions;
  }

  getDrawerActions(): LoadingMenuAction[] {
    if (!this.detailVm) return [];
    return this.getRowMenuActions(this.detailVm.row).filter((a) => a.key !== 'OPEN_DETAIL');
  }

  toggleRowMenu(dispatchId: number, event: MouseEvent): void {
    event.stopPropagation();
    this.openMenuDispatchId = this.openMenuDispatchId === dispatchId ? null : dispatchId;
  }

  onMenuAction(row: LoadingLaneRow, action: LoadingMenuAction, event: MouseEvent): void {
    event.stopPropagation();
    this.handleAction(row, action);
  }

  handleDrawerAction(action: LoadingMenuAction): void {
    if (!this.detailVm) return;
    this.handleAction(this.detailVm.row, action);
  }

  private handleAction(row: LoadingLaneRow, action: LoadingMenuAction): void {
    if (action.disabled) return;

    if (action.key === 'OPEN_DETAIL') {
      this.openMenuDispatchId = null;
      this.openRowDrawer(row);
      return;
    }

    if (action.key === 'VIEW_DISPATCH') {
      this.openMenuDispatchId = null;
      this.router.navigate(['/dispatch', row.dispatchId]);
      return;
    }

    if (action.key === 'VIEW_HISTORY') {
      this.openMenuDispatchId = null;
      this.openHistory(row.dispatchId);
      return;
    }

    if (action.key === 'VIEW_SESSION') {
      this.openMenuDispatchId = null;
      this.router.navigate(['/dispatch/loading-session', row.dispatchId]);
      return;
    }

    this.openMenuDispatchId = null;
    this.pendingAction = { row, action };
    this.pendingActionNote = this.drawerNote?.trim() || '';
    this.pendingStatusValue = row.status;
    this.overrideStatusOptions = this.buildOverrideStatusOptions(row.status);
  }

  cancelPendingAction(): void {
    if (this.actionSubmitting) return;
    this.pendingAction = null;
    this.pendingActionNote = '';
    this.pendingStatusValue = '';
    this.overrideStatusOptions = [];
  }

  confirmPendingAction(): void {
    if (!this.pendingAction || this.actionSubmitting) return;

    const { row, action } = this.pendingAction;
    const note = this.pendingActionNote?.trim() || '';
    this.actionSubmitting = true;

    if (action.key === 'GET_TICKET') {
      this.executeEnqueue(row, note);
      return;
    }
    if (action.key === 'CALL_TO_BAY') {
      this.executeCallToBay(row, note);
      return;
    }
    if (action.key === 'START_LOADING') {
      this.executeStartLoading(row, note);
      return;
    }
    if (action.key === 'OVERRIDE_STATUS') {
      this.executeManualOverride(row, note);
      return;
    }

    this.actionSubmitting = false;
    this.cancelPendingAction();
  }

  private executeManualOverride(row: LoadingLaneRow, note: string): void {
    const status = String(this.pendingStatusValue || '')
      .trim()
      .toUpperCase();
    if (!status) {
      this.toastr.warning('Please select a status.');
      this.actionSubmitting = false;
      return;
    }
    if (status === String(row.status || '').toUpperCase()) {
      this.toastr.info('Dispatch is already in selected status.');
      this.actionSubmitting = false;
      this.cancelPendingAction();
      return;
    }

    if (status === 'PRE_ENTRY_SAFETY_PASSED') {
      this.markPreEntrySafetyPassed(row, note);
      return;
    }

    this.dispatchService
      .updateDispatchStatus(row.dispatchId, status, note || this.drawerNote || '', {
        forceOverride: true,
      })
      .subscribe({
        next: () => {
          this.toastr.success(`Dispatch #${row.dispatchId} updated to ${status}.`);
          this.actionSubmitting = false;
          this.cancelPendingAction();
          this.loadRows();
        },
        error: (err) => {
          console.error('Manual override failed', err);
          const msg = err?.error?.message || 'Unable to override dispatch status';
          this.toastr.error(msg);
          this.drawerActionError = msg;
          this.actionSubmitting = false;
        },
      });
  }

  private markPreEntrySafetyPassed(row: LoadingLaneRow, note: string): void {
    if (!row.preEntrySafetyRequired) {
      this.toastr.info('Pre-entry safety is NOT_REQUIRED for this dispatch.');
      this.actionSubmitting = false;
      this.cancelPendingAction();
      this.loadRows();
      return;
    }

    if ((row.preEntrySafetyStatus || '').toUpperCase() === 'PASSED') {
      this.toastr.info(`Pre-entry safety is already PASSED for dispatch #${row.dispatchId}.`);
      this.actionSubmitting = false;
      this.cancelPendingAction();
      this.loadRows();
      return;
    }

    this.dispatchService.getPreEntrySafetyCheck(row.dispatchId).subscribe({
      next: (checkRes) => {
        const checkId = Number(checkRes?.data?.id);
        if (!checkId) {
          const msg =
            'No pre-entry safety check found. Submit Pre-entry Safety (KHB) in management first.';
          this.toastr.error(msg);
          this.drawerActionError = msg;
          this.actionSubmitting = false;
          return;
        }

        this.dispatchService
          .approveConditionalOverride(checkId, {
            decision: 'APPROVED',
            remarks:
              note || this.drawerNote || 'Manual pre-entry safety approval from Loading Management',
          })
          .subscribe({
            next: () => {
              this.toastr.success(`Pre-entry safety approved for dispatch #${row.dispatchId}.`);
              this.actionSubmitting = false;
              this.cancelPendingAction();
              this.loadRows();
            },
            error: (err) => {
              console.error('Pre-entry safety approval failed', err);
              const msg = err?.error?.message || 'Unable to approve pre-entry safety';
              this.toastr.error(msg);
              this.drawerActionError = msg;
              this.actionSubmitting = false;
            },
          });
      },
      error: (err) => {
        console.error('Load pre-entry safety check failed', err);
        if ((row.preEntrySafetyStatus || '').toUpperCase() === 'PASSED') {
          this.toastr.info(`Pre-entry safety is already PASSED for dispatch #${row.dispatchId}.`);
          this.actionSubmitting = false;
          this.cancelPendingAction();
          this.loadRows();
          return;
        }
        const msg =
          err?.error?.message ||
          'No pre-entry safety check found. Submit Pre-entry Safety (KHB) in management first.';
        this.toastr.error(msg);
        this.drawerActionError = msg;
        this.actionSubmitting = false;
      },
    });
  }

  private executeEnqueue(row: LoadingLaneRow, note: string): void {
    if (!this.canEnqueue(row)) {
      this.actionSubmitting = false;
      return;
    }
    this.loadingOpsService
      .enqueue({
        dispatchId: row.dispatchId,
        warehouseCode: this.resolveActionWarehouse(row),
        queuePosition: this.drawerQueuePosition || undefined,
        remarks: note || this.drawerNote?.trim() || 'Queued from Loading Management',
      })
      .subscribe({
        next: () => {
          const actionText = row.status === 'IN_QUEUE' ? 'queue entry rebuilt' : 'moved to queue';
          this.toastr.success(`Dispatch #${row.dispatchId} ${actionText}.`);
          this.actionSubmitting = false;
          this.cancelPendingAction();
          this.loadRows();
        },
        error: (err) => {
          console.error('Enqueue failed', err);
          const msg = err?.error?.message || 'Unable to add dispatch to queue';
          this.toastr.error(msg);
          this.drawerActionError = msg;
          this.actionSubmitting = false;
        },
      });
  }

  private executeCallToBay(row: LoadingLaneRow, note: string): void {
    if (!this.canCall(row) || !row.queueId) {
      this.actionSubmitting = false;
      return;
    }
    this.loadingOpsService
      .callToBay(row.queueId, this.resolveBayValue(row), note || this.drawerNote || '')
      .subscribe({
        next: () => {
          this.toastr.success(`Dispatch #${row.dispatchId} moved through loading gate.`);
          this.actionSubmitting = false;
          this.cancelPendingAction();
          this.loadRows();
        },
        error: (err) => {
          console.error('Call to bay failed', err);
          const msg = err?.error?.message || 'Unable to call queue entry to bay';
          this.toastr.error(msg);
          this.drawerActionError = msg;
          this.actionSubmitting = false;
        },
      });
  }

  private executeStartLoading(row: LoadingLaneRow, note: string): void {
    if (!this.canStart(row) || !row.queueId) {
      this.actionSubmitting = false;
      return;
    }
    this.loadingOpsService
      .startLoading({
        dispatchId: row.dispatchId,
        queueId: row.queueId,
        warehouseCode: this.resolveActionWarehouse(row),
        bay: this.resolveBayValue(row) || null,
        remarks: note || this.drawerNote?.trim() || 'Started from Loading Management',
      })
      .subscribe({
        next: () => {
          this.toastr.success(`Dispatch #${row.dispatchId} loading started.`);
          this.actionSubmitting = false;
          this.cancelPendingAction();
          this.loadRows();
        },
        error: (err) => {
          console.error('Start loading failed', err);
          const msg = err?.error?.message || 'Unable to start loading';
          this.toastr.error(msg);
          this.drawerActionError = msg;
          this.actionSubmitting = false;
        },
      });
  }

  getNextActionText(row: LoadingLaneRow): string {
    if (this.canEnqueue(row)) {
      return row.status === 'IN_QUEUE' ? 'Rebuild Queue Entry' : 'Get Ticket';
    }
    if (row.status === 'IN_QUEUE' && row.queueStatus === 'WAITING') {
      return this.canCall(row) ? 'Loading Gate' : this.getActionBlockReason(row) || 'Blocked';
    }
    if (row.status === 'IN_QUEUE' && row.queueStatus === 'CALLED') {
      return this.canStart(row) ? 'Start Loading' : this.getActionBlockReason(row) || 'Blocked';
    }
    if (row.status === 'LOADING') {
      return 'Loading in progress';
    }
    if (row.status === 'LOADED') {
      return 'Completed in loading lane';
    }
    return '-';
  }

  openHistory(dispatchId: number): void {
    this.historyDispatchId = dispatchId;
    this.historyLoading = true;
    this.historyError = null;
    this.statusHistory = [];

    this.dispatchService.getStatusHistory(dispatchId).subscribe({
      next: (res) => {
        this.statusHistory = res?.data || [];
        this.historyLoading = false;
      },
      error: (err) => {
        console.error('Status history load failed', err);
        this.historyError = err?.error?.message || 'Unable to load status history.';
        this.historyLoading = false;
      },
    });
  }

  closeHistory(): void {
    this.historyDispatchId = null;
    this.historyLoading = false;
    this.historyError = null;
    this.statusHistory = [];
  }

  openRowDrawer(row: LoadingLaneRow): void {
    this.selectedRowDispatchId = row.dispatchId;
    this.isDrawerOpen = true;
    this.drawerLoading = true;
    this.drawerError = null;
    this.drawerActionError = null;
    this.detailVm = {
      row,
      dispatch: null,
      queue: null,
      session: null,
      preEntrySafetyRequired: !!row.preEntrySafetyRequired,
      preEntrySafetyStatus: row.preEntrySafetyStatus || 'PENDING',
      loadingSafetyStatus: row.loadingSafetyStatus || 'PENDING',
    };
    this.drawerBay = row.bay || '';
    this.drawerQueuePosition = row.queuePosition || null;
    this.drawerNote = row.remarks || '';

    this.loadingOpsService.getDispatchDetail(row.dispatchId).subscribe({
      next: (detail) => {
        this.applyDrawerDetail(detail, row);
        this.drawerLoading = false;
      },
      error: (err) => {
        console.error('Failed to load dispatch detail', err);
        this.drawerError =
          err?.error?.message || 'Unable to load full detail. Showing table snapshot.';
        this.drawerLoading = false;
      },
    });
  }

  closeDrawer(): void {
    this.isDrawerOpen = false;
    this.selectedRowDispatchId = null;
    this.drawerLoading = false;
    this.drawerError = null;
    this.drawerActionError = null;
    this.detailVm = null;
    this.drawerBay = '';
    this.drawerQueuePosition = null;
    this.drawerNote = '';
  }

  canSaveGateInfo(): boolean {
    if (!this.detailVm) return false;
    return !!this.detailVm.row.queueId && this.detailVm.row.status !== 'LOADED';
  }

  getGateSaveBlockReason(): string {
    if (!this.detailVm) return 'Loading detail is not ready.';
    if (this.detailVm.row.status === 'LOADED') {
      return 'Gate info is read-only for LOADED dispatches.';
    }
    if (!this.detailVm.row.queueId) {
      return 'Get Ticket first to create queue entry, then you can save gate info.';
    }
    return '';
  }

  saveGateInfo(): void {
    if (!this.detailVm?.row.queueId) {
      this.toastr.info('Queue entry is not created yet. Use Get Ticket first.');
      return;
    }

    if (this.drawerQueuePosition != null && this.drawerQueuePosition <= 0) {
      this.toastr.warning('Queue position must be greater than 0.');
      return;
    }

    const payload: LoadingGateUpdatePayload = {
      bay: this.drawerBay?.trim() || null,
      queuePosition: this.drawerQueuePosition || null,
      remarks: this.drawerNote?.trim() || null,
    };

    this.actionSubmitting = true;
    this.loadingOpsService.updateGateInfo(this.detailVm.row.queueId, payload).subscribe({
      next: () => {
        this.toastr.success(`Loading gate info updated for #${this.detailVm?.row.dispatchId}.`);
        this.actionSubmitting = false;
        this.loadRows();
      },
      error: (err) => {
        console.error('Failed to save gate info', err);
        const msg = err?.error?.message || 'Unable to save loading gate info';
        this.toastr.error(msg);
        this.drawerActionError = msg;
        this.actionSubmitting = false;
      },
    });
  }

  formatDateTime(raw?: string): string {
    if (!raw) return '-';
    const d = new Date(raw);
    if (Number.isNaN(d.getTime())) return raw;
    return d.toLocaleString();
  }

  loadingGateState(row: LoadingLaneRow): string {
    const q = String(row.queueStatus || '').toUpperCase();
    if (q === 'CALLED') return 'Gate Called';
    if (q === 'LOADING') return 'Gate Passed';
    if (q === 'LOADED') return 'Gate Completed';
    if (q === 'WAITING' && row.status === 'IN_QUEUE') return 'Waiting Gate';
    if (row.status === 'ARRIVED_LOADING') return 'Pending Gate';
    if (row.status === 'LOADING') return 'Gate Passed';
    if (row.status === 'LOADED') return 'Gate Completed';
    return '-';
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const target = event.target as HTMLElement | null;
    if (!target) return;
    if (!target.closest('.row-menu-container')) {
      this.openMenuDispatchId = null;
    }
  }

  @HostListener('document:keydown.escape')
  onEscKey(): void {
    this.openMenuDispatchId = null;
    if (this.pendingAction) {
      this.cancelPendingAction();
    }
    if (this.historyDispatchId !== null) {
      this.closeHistory();
    }
    if (this.isDrawerOpen) {
      this.closeDrawer();
    }
  }

  private refreshDrawerIfOpen(): void {
    if (!this.isDrawerOpen || this.selectedRowDispatchId == null) {
      return;
    }
    const row = this.rows.find((r) => r.dispatchId === this.selectedRowDispatchId);
    if (!row) {
      this.closeDrawer();
      return;
    }
    this.openRowDrawer(row);
  }

  private openRowDrawerByPendingId(): void {
    if (this.pendingOpenDispatchId == null || this.rows.length === 0) {
      return;
    }
    const row = this.rows.find((r) => r.dispatchId === this.pendingOpenDispatchId);
    if (!row) {
      return;
    }
    this.openRowDrawer(row);
    this.pendingOpenDispatchId = null;
  }

  private applyDrawerDetail(detail: LoadingDispatchDetail, fallbackRow: LoadingLaneRow): void {
    const queue = detail?.queue || null;
    const session = detail?.session || null;
    const dispatch = detail?.dispatch || null;

    const mergedRow: LoadingLaneRow = {
      ...fallbackRow,
      routeCode: dispatch?.routeCode || fallbackRow.routeCode,
      driverName: dispatch?.driverName || fallbackRow.driverName,
      driverPhone: dispatch?.driverPhone || fallbackRow.driverPhone,
      truckPlate: dispatch?.licensePlate || fallbackRow.truckPlate,
      queueId: queue?.id || fallbackRow.queueId,
      queueStatus: String(queue?.status || fallbackRow.queueStatus || ''),
      queuePosition: queue?.queuePosition ?? fallbackRow.queuePosition,
      bay: queue?.bay ?? fallbackRow.bay,
      calledAt: queue?.calledAt ?? fallbackRow.calledAt,
      remarks: queue?.remarks ?? fallbackRow.remarks,
      preEntrySafetyRequired: detail?.preEntrySafetyRequired ?? fallbackRow.preEntrySafetyRequired,
      preEntrySafetyStatus:
        String(
          detail?.preEntrySafetyStatus || fallbackRow.preEntrySafetyStatus || '',
        ).toUpperCase() || 'PENDING',
      loadingSafetyStatus:
        String(
          detail?.loadingSafetyStatus || fallbackRow.loadingSafetyStatus || '',
        ).toUpperCase() || 'PENDING',
    };
    mergedRow.actionBlockReason = this.getActionBlockReason(mergedRow);

    this.detailVm = {
      row: mergedRow,
      dispatch,
      queue,
      session,
      preEntrySafetyRequired: !!mergedRow.preEntrySafetyRequired,
      preEntrySafetyStatus: mergedRow.preEntrySafetyStatus || 'PENDING',
      loadingSafetyStatus: mergedRow.loadingSafetyStatus || 'PENDING',
    };

    this.drawerBay = mergedRow.bay || '';
    this.drawerQueuePosition = mergedRow.queuePosition || null;
    this.drawerNote = mergedRow.remarks || '';
  }

  private computeMetrics(): void {
    this.metrics.arrivedLoading = this.rows.filter((r) => r.status === 'ARRIVED_LOADING').length;
    this.metrics.inQueue = this.rows.filter((r) => r.status === 'IN_QUEUE').length;
    this.metrics.loading = this.rows.filter((r) => r.status === 'LOADING').length;
    this.metrics.loaded = this.rows.filter((r) => r.status === 'LOADED').length;
  }

  private normalizeWarehouseCode(raw: unknown): WarehouseCode | null {
    const normalized = String(raw || '')
      .trim()
      .toUpperCase();
    if (!normalized) return null;
    if (normalized === 'W1' || normalized === 'KHB') return 'KHB';
    if (normalized === 'W2') return 'W2';
    if (normalized === 'W3') return 'W3';
    return null;
  }

  private resolveDispatchWarehouse(dispatch: Dispatch): WarehouseCode | null {
    return (
      this.normalizeWarehouseCode((dispatch as any)?.warehouseCode) ||
      this.normalizeWarehouseCode((dispatch as any)?.warehouse) ||
      this.normalizeWarehouseCode((dispatch as any)?.transportOrder?.warehouseCode) ||
      this.normalizeWarehouseCode((dispatch as any)?.transportOrder?.warehouse) ||
      this.normalizeWarehouseCode((dispatch as any)?.transportOrder?.items?.[0]?.warehouse) ||
      this.normalizeWarehouseCode((dispatch as any)?.items?.[0]?.warehouse)
    );
  }

  private matchesWarehouse(
    dispatch: Dispatch,
    queueEntry: LoadingQueue | undefined,
    selectedWarehouse: 'ALL' | WarehouseCode,
  ): boolean {
    if (selectedWarehouse === 'ALL') {
      return true;
    }

    const queueWarehouse = this.normalizeWarehouseCode((queueEntry as any)?.warehouseCode);
    if (queueWarehouse) {
      return queueWarehouse === selectedWarehouse;
    }

    const dispatchWarehouse = this.resolveDispatchWarehouse(dispatch);
    if (dispatchWarehouse) {
      return dispatchWarehouse === selectedWarehouse;
    }

    return true;
  }

  private resolveActionWarehouse(row: LoadingLaneRow): WarehouseCode {
    if (row.warehouseCode) return row.warehouseCode;
    if (this.warehouseFilter !== 'ALL') return this.warehouseFilter;
    return 'KHB';
  }

  private resolveBayValue(row: LoadingLaneRow): string {
    const fromDrawer = (this.drawerBay || '').trim();
    if (fromDrawer) return fromDrawer;
    const fromGlobal = (this.bayInput || '').trim();
    if (fromGlobal) return fromGlobal;
    return (row.bay || '').trim();
  }

  private canManualOverride(): boolean {
    return (
      this.authService.hasRole('ADMIN') ||
      this.authService.hasRole('SUPERADMIN') ||
      this.authService.hasRole('DISPATCH_MONITOR') ||
      this.authService.hasRole('LOADING')
    );
  }

  private buildOverrideStatusOptions(currentStatus: LoadingLaneStatus): ManualStatusOption[] {
    const options: ManualStatusOption[] = [
      { label: 'ARRIVED_LOADING', value: 'ARRIVED_LOADING' },
      { label: 'GET_TICKET', value: 'IN_QUEUE' },
      { label: 'PASS_SAFETY (PRE-ENTRY)', value: 'PRE_ENTRY_SAFETY_PASSED' },
      { label: 'IN_QUEUE', value: 'IN_QUEUE' },
      { label: 'LOADING', value: 'LOADING' },
      { label: 'LOADED', value: 'LOADED' },
    ];

    const current = String(currentStatus || '').toUpperCase();
    if (!current || options.some((o) => o.value === current || o.label === current)) {
      return options;
    }

    return [...options, { label: current, value: current }];
  }

  getPreEntrySafetyDisplay(
    required: boolean | null | undefined,
    status: string | null | undefined,
  ): string {
    const normalized = String(status || '').toUpperCase();
    if (normalized === 'PASSED' || normalized === 'FAILED' || normalized === 'CONDITIONAL') {
      return normalized;
    }
    return required ? 'PENDING' : 'NOT_REQUIRED';
  }

  private isPreEntryPassedIfRequired(row: LoadingLaneRow): boolean {
    if (!row.preEntrySafetyRequired) return true;
    return (row.preEntrySafetyStatus || '').toUpperCase() === 'PASSED';
  }

  private getActionBlockReason(row: LoadingLaneRow): string | undefined {
    if (row.status === 'LOADED' || row.status === 'LOADING') {
      return undefined;
    }

    if (row.status === 'ARRIVED_LOADING') {
      return row.queueId ? 'Queue entry already exists.' : undefined;
    }

    if (row.preEntrySafetyRequired && (row.preEntrySafetyStatus || '').toUpperCase() !== 'PASSED') {
      return 'Waiting pre-entry safety approval.';
    }

    if (
      row.status === 'IN_QUEUE' &&
      row.queueStatus !== 'WAITING' &&
      row.queueStatus !== 'CALLED'
    ) {
      return 'Queue state is not ready for next action.';
    }

    return undefined;
  }
}
