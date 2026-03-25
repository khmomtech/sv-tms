import { CommonModule } from '@angular/common';
import { OverlayModule, CdkOverlayOrigin, ConnectedPosition } from '@angular/cdk/overlay';
import { Component, HostListener, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { forkJoin, of } from 'rxjs';
import { catchError, finalize, map, switchMap } from 'rxjs/operators';

import type { Dispatch } from '../../models/dispatch.model';
import { DispatchService } from '../../services/dispatch.service';
import type { SafetyMasterItem } from '../safety/models/safety-master.model';
import { PreEntryMasterDataService } from './pre-entry-master-data.service';

interface PreEntryLaneRow {
  dispatchId: number;
  routeCode?: string;
  status: 'ARRIVED_LOADING' | 'IN_QUEUE' | 'LOADING' | 'LOADED';
  driverId?: number;
  driverName?: string;
  vehicleId?: number;
  truckPlate?: string;
  warehouseCode?: string;
  preEntrySafetyRequired: boolean;
  preEntrySafetyStatus: string;
  loadingSafetyStatus: string;
  preEntryCheckId?: number;
}

interface DrawerSafetyDetailVm {
  id?: number;
  status?: string;
  checkDate?: string;
  remarks?: string;
  checkedBy?: { username?: string; firstName?: string; lastName?: string } | null;
  checkedAt?: string;
  overrideApprovedBy?: { username?: string; firstName?: string; lastName?: string } | null;
  overrideApprovedAt?: string;
  overrideRemarks?: string;
  totalItems?: number;
  passedItems?: number;
  failedItems?: number;
  conditionalItems?: number;
  items?: Array<{
    category?: string;
    categoryCode?: string;
    itemName?: string;
    status?: string;
    statusCode?: string;
    remarks?: string;
    photoPath?: string;
  }>;
}

interface ChecklistItemVm {
  categoryCode: string;
  categoryLabel: string;
  itemName: string;
  status: '' | 'OK' | 'FAILED' | 'CONDITIONAL';
  remarks: string;
  photoUrl: string;
  photoPreviewUrl?: string;
  uploadingPhoto?: boolean;
  uploadError?: string;
}

type ChecklistField = 'itemName' | 'status' | 'remarks' | 'photoUrl';

type ViewMode = 'ALL' | 'PENDING' | 'COMPLETED';
type StageFilter = 'ALL' | 'ARRIVED_LOADING' | 'IN_QUEUE' | 'LOADING' | 'LOADED';

@Component({
  selector: 'app-pre-entry-safety-management',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, OverlayModule],
  template: `
    <div class="p-6 space-y-4 max-w-7xl mx-auto">
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="text-xs uppercase tracking-wide text-slate-500">G-Management</p>
          <h2 class="text-2xl font-bold text-slate-900">Pre-entry Safety (KHB) Management</h2>
          <p class="text-sm text-slate-600">
            After Get Ticket (IN_QUEUE), complete Pre-entry Safety (KHB). PASS will auto move to
            LOADING.
          </p>
        </div>
        <div class="flex items-center gap-2">
          <button
            type="button"
            class="px-3 py-2 text-sm font-semibold border border-slate-300 rounded-lg text-slate-700 bg-white hover:bg-slate-100"
            (click)="openSafetyMasterCategories()"
            title="Manage safety categories"
          >
            Manage Categories
          </button>
          <button
            type="button"
            class="px-3 py-2 text-sm font-semibold border border-slate-300 rounded-lg text-slate-700 bg-white hover:bg-slate-100"
            (click)="openSafetyMasterItems()"
            title="Manage safety items"
          >
            Manage Items
          </button>
          <select
            [(ngModel)]="viewMode"
            class="px-3 py-2 border rounded-lg text-sm"
            (change)="loadRows()"
            title="View mode"
          >
            <option value="ALL">All</option>
            <option value="PENDING">Pending</option>
            <option value="COMPLETED">Completed</option>
          </select>
          <select
            [(ngModel)]="stageFilter"
            class="px-3 py-2 border rounded-lg text-sm"
            (change)="loadRows()"
            title="Stage"
          >
            <option value="ALL">All Stages</option>
            <option value="ARRIVED_LOADING">Arrived Loading</option>
            <option value="IN_QUEUE">In Queue</option>
            <option value="LOADING">Loading</option>
            <option value="LOADED">Loaded</option>
          </select>
          <input
            type="date"
            [(ngModel)]="fromDate"
            class="px-3 py-2 border rounded-lg text-sm"
            (change)="loadRows()"
            title="From date"
          />
          <input
            type="date"
            [(ngModel)]="toDate"
            class="px-3 py-2 border rounded-lg text-sm"
            (change)="loadRows()"
            title="To date"
          />
          <button
            class="px-4 py-2 text-sm font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700"
            (click)="loadRows()"
          >
            Refresh
          </button>
        </div>
      </div>

      <div class="text-xs text-slate-600 bg-slate-50 border border-slate-200 rounded p-3">
        Flow: Driver arrives (ARRIVED_LOADING) -> Get Ticket (IN_QUEUE) -> Pre-entry Safety (KHB)
        PASS -> Auto transition to LOADING.
      </div>

      <div
        *ngIf="listError"
        class="p-3 text-sm text-red-700 border border-red-200 rounded-lg bg-red-50"
      >
        {{ listError }}
      </div>

      <div class="grid gap-3 sm:grid-cols-3">
        <div class="p-3 border rounded-lg bg-white">
          <div class="text-xs text-slate-500">Pending</div>
          <div class="text-2xl font-bold text-amber-700">{{ pendingCount }}</div>
        </div>
        <div class="p-3 border rounded-lg bg-white">
          <div class="text-xs text-slate-500">Completed</div>
          <div class="text-2xl font-bold text-emerald-700">{{ completedCount }}</div>
        </div>
        <div class="p-3 border rounded-lg bg-white">
          <div class="text-xs text-slate-500">Awaiting Ticket</div>
          <div class="text-2xl font-bold text-orange-700">{{ awaitingTicketCount }}</div>
        </div>
      </div>

      <div *ngIf="loading" class="p-6 text-center text-slate-500 border rounded-lg bg-white">
        Loading rows...
      </div>
      <div
        *ngIf="!loading && rows.length === 0"
        class="p-6 text-center text-slate-500 border rounded-lg bg-white"
      >
        No dispatches found for selected filters.
      </div>

      <div *ngIf="!loading && rows.length > 0" class="overflow-auto border rounded-lg bg-white">
        <table class="min-w-full text-sm">
          <thead class="bg-slate-50 text-slate-700">
            <tr>
              <th class="px-3 py-2 text-left">Dispatch</th>
              <th class="px-3 py-2 text-left">Driver</th>
              <th class="px-3 py-2 text-left">Truck</th>
              <th class="px-3 py-2 text-left">Stage</th>
              <th class="px-3 py-2 text-left">Warehouse</th>
              <th class="px-3 py-2 text-left">Pre-Entry Safety</th>
              <th class="px-3 py-2 text-left">Loading Safety</th>
              <th class="px-3 py-2 text-left">Next Step</th>
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
                  >#{{ row.dispatchId }}</a
                >
                <div class="text-xs text-slate-500">{{ row.routeCode || '-' }}</div>
              </td>
              <td class="px-3 py-2">{{ row.driverName || '-' }}</td>
              <td class="px-3 py-2">{{ row.truckPlate || '-' }}</td>
              <td class="px-3 py-2">
                <span
                  class="px-2 py-1 rounded text-xs font-semibold"
                  [ngClass]="stageClass(row.status)"
                  >{{ row.status }}</span
                >
              </td>
              <td class="px-3 py-2">{{ row.warehouseCode || 'KHB' }}</td>
              <td class="px-3 py-2">
                <span
                  class="px-2 py-1 rounded text-xs font-semibold"
                  [ngClass]="preEntryClass(row.preEntrySafetyStatus)"
                  >{{ row.preEntrySafetyStatus }}</span
                >
              </td>
              <td class="px-3 py-2">{{ row.loadingSafetyStatus }}</td>
              <td class="px-3 py-2 text-slate-600">{{ nextStepText(row) }}</td>
              <td class="px-3 py-2" (click)="$event.stopPropagation()">
                <button
                  type="button"
                  class="w-9 h-9 rounded-lg border border-slate-300 text-slate-700 hover:bg-slate-100"
                  cdkOverlayOrigin
                  #menuOrigin="cdkOverlayOrigin"
                  (click)="openRowActionMenu(row, menuOrigin, $event)"
                  title="More actions"
                >
                  ⋮
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <ng-template
        cdkConnectedOverlay
        [cdkConnectedOverlayOrigin]="activeMenuOrigin"
        [cdkConnectedOverlayOpen]="!!activeMenuRow"
        [cdkConnectedOverlayPositions]="menuPositions"
        [cdkConnectedOverlayHasBackdrop]="true"
        cdkConnectedOverlayBackdropClass="cdk-overlay-transparent-backdrop"
        (backdropClick)="closeRowActionMenu()"
        (detach)="closeRowActionMenu()"
      >
        <div
          class="min-w-52 bg-white border border-slate-200 rounded-lg shadow-lg p-1"
          (click)="$event.stopPropagation()"
        >
          <button
            *ngIf="activeMenuRow"
            type="button"
            class="w-full text-left px-3 py-2 rounded hover:bg-slate-100 disabled:text-slate-400 disabled:hover:bg-white"
            [disabled]="checklistSaving"
            (click)="openChecklist(activeMenuRow); closeRowActionMenu()"
          >
            Open Checklist
          </button>
          <button
            *ngIf="activeMenuRow"
            type="button"
            class="w-full text-left px-3 py-2 rounded hover:bg-slate-100"
            (click)="openLoadingLane(activeMenuRow); closeRowActionMenu()"
          >
            Open Loading Lane
          </button>
          <button
            *ngIf="activeMenuRow"
            type="button"
            class="w-full text-left px-3 py-2 rounded hover:bg-slate-100"
            (click)="openSafetyMasterItems(); closeRowActionMenu()"
          >
            Manage Pre-entry Items
          </button>
          <button
            *ngIf="activeMenuRow"
            type="button"
            class="w-full text-left px-3 py-2 rounded hover:bg-slate-100"
            (click)="openDispatchDetail(activeMenuRow); closeRowActionMenu()"
          >
            View Dispatch
          </button>
          <button
            *ngIf="activeMenuRow?.preEntryCheckId"
            type="button"
            class="w-full text-left px-3 py-2 rounded text-red-700 hover:bg-red-50 disabled:text-red-300 disabled:hover:bg-white"
            [disabled]="
              deletingCheckId === activeMenuRow?.preEntryCheckId || !canDeleteCheck(activeMenuRow)
            "
            [title]="deleteBlockReason(activeMenuRow)"
            (click)="deletePreEntryCheck(activeMenuRow); closeRowActionMenu()"
          >
            {{
              deletingCheckId === activeMenuRow?.preEntryCheckId ? 'Deleting...' : 'Delete Check'
            }}
          </button>
        </div>
      </ng-template>

      <div *ngIf="isChecklistOpen && checklistRow" class="fixed inset-0 z-50">
        <div class="absolute inset-0 bg-black/30" (click)="closeChecklist()"></div>
        <div class="absolute inset-0 flex items-center justify-center p-4">
          <div
            class="w-full max-w-[1200px] max-h-[92vh] overflow-auto bg-white rounded-xl shadow-2xl p-4"
          >
            <div class="flex items-start justify-between">
              <div>
                <h3 class="text-xl font-semibold text-slate-900">
                  {{ checklistCheckId ? 'Edit' : 'Create' }} Pre-Entry Checklist
                </h3>
                <p class="text-sm text-slate-500">
                  Dispatch #{{ checklistRow.dispatchId }} - {{ checklistRow.routeCode || '-' }}
                </p>
              </div>
              <button
                type="button"
                class="text-slate-600 hover:text-slate-900"
                (click)="closeChecklist()"
              >
                ✕
              </button>
            </div>

            <div
              *ngIf="checklistError"
              class="mt-3 p-3 text-sm text-red-700 border border-red-200 rounded-lg bg-red-50"
            >
              {{ checklistError }}
            </div>

            <div class="mt-4 rounded-lg border border-slate-200 bg-slate-50 p-3">
              <div class="grid gap-2 text-xs text-slate-700 sm:grid-cols-5">
                <div>
                  <span class="font-semibold text-slate-500">Dispatch:</span> #{{
                    checklistRow.dispatchId
                  }}
                </div>
                <div>
                  <span class="font-semibold text-slate-500">Truck:</span>
                  {{ checklistRow.truckPlate || '-' }}
                </div>
                <div>
                  <span class="font-semibold text-slate-500">Driver:</span>
                  {{ checklistRow.driverName || '-' }}
                </div>
                <div>
                  <span class="font-semibold text-slate-500">Warehouse:</span>
                  {{ checklistRow.warehouseCode || 'KHB' }}
                </div>
                <div>
                  <span class="font-semibold text-slate-500">Current Status:</span>
                  {{ checklistRow.preEntrySafetyStatus || 'NOT_STARTED' }}
                </div>
              </div>
            </div>

            <div class="mt-3 flex flex-wrap items-center justify-between gap-2">
              <p class="text-xs text-slate-500">ជ្រើសស្ថានភាពតាមធាតុនីមួយៗ (មាន / មិនមាន)។</p>
              <div class="flex items-center gap-2">
                <button
                  type="button"
                  class="px-3 py-1.5 text-xs font-semibold rounded border border-emerald-200 text-emerald-700 bg-emerald-50 hover:bg-emerald-100"
                  [disabled]="checklistSaving"
                  (click)="setAllChecklistStatuses('OK')"
                >
                  កំណត់ទាំងអស់ = មាន
                </button>
                <button
                  type="button"
                  class="px-3 py-1.5 text-xs font-semibold rounded border border-slate-300 text-slate-700 bg-white hover:bg-slate-100"
                  [disabled]="checklistSaving"
                  (click)="clearAllChecklistStatuses()"
                >
                  សម្អាតស្ថានភាព
                </button>
              </div>
            </div>

            <div class="mt-3 space-y-4 max-h-[56vh] overflow-auto pr-1">
              <section
                *ngFor="let group of groupedChecklistItems()"
                class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm"
              >
                <h4 class="text-2xl font-bold text-slate-900">{{ group.categoryLabel }}</h4>
                <div class="mt-3 space-y-2">
                  <div
                    *ngFor="let row of group.rows"
                    class="rounded-lg border border-slate-100 px-3 py-2"
                    [ngClass]="isAbsentStatus(row.item.status) ? 'bg-red-50/40' : 'bg-white'"
                  >
                    <div class="flex items-center justify-between gap-4">
                      <div class="text-base text-slate-900">{{ row.item.itemName }}</div>
                      <div class="flex items-center gap-4 shrink-0">
                        <label class="inline-flex items-center gap-2 text-base text-slate-800">
                          <input
                            type="radio"
                            class="h-5 w-5 accent-blue-600"
                            [name]="'item-status-' + row.index"
                            [checked]="checklistItems[row.index].status === 'OK'"
                            (click)="setChecklistStatus(row.index, 'OK')"
                          />
                          <span>មាន</span>
                        </label>
                        <label class="inline-flex items-center gap-2 text-base text-slate-800">
                          <input
                            type="radio"
                            class="h-5 w-5 accent-blue-600"
                            [name]="'item-status-' + row.index"
                            [checked]="isAbsentStatus(checklistItems[row.index].status)"
                            (click)="setChecklistStatus(row.index, 'FAILED')"
                          />
                          <span>មិនមាន</span>
                        </label>
                      </div>
                    </div>

                    <p *ngIf="fieldError(row.index, 'status')" class="mt-1 text-xs text-red-600">
                      {{ fieldError(row.index, 'status') }}
                    </p>

                    <div
                      *ngIf="isAbsentStatus(row.item.status)"
                      class="mt-3 grid gap-2 md:grid-cols-2"
                    >
                      <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1"
                          >Remarks</label
                        >
                        <textarea
                          rows="2"
                          class="w-full px-2 py-1.5 border rounded"
                          [ngClass]="
                            fieldHasError(row.index, 'remarks')
                              ? 'border-red-300 bg-red-50'
                              : 'border-slate-300'
                          "
                          [(ngModel)]="checklistItems[row.index].remarks"
                          (ngModelChange)="clearFieldError(row.index, 'remarks')"
                          placeholder="បញ្ចូលមូលហេតុ"
                        ></textarea>
                        <p
                          *ngIf="fieldError(row.index, 'remarks')"
                          class="mt-1 text-xs text-red-600"
                        >
                          {{ fieldError(row.index, 'remarks') }}
                        </p>
                      </div>
                      <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1">Photo</label>
                        <div class="space-y-2">
                          <div class="flex items-center gap-2">
                            <input
                              type="file"
                              accept="image/*"
                              capture="environment"
                              class="block w-full text-xs text-slate-600 file:mr-2 file:rounded file:border-0 file:bg-blue-50 file:px-2 file:py-1 file:text-blue-700 hover:file:bg-blue-100"
                              [disabled]="checklistSaving || row.item.uploadingPhoto"
                              (change)="onChecklistFileSelected($event, row.index)"
                            />
                            <button
                              *ngIf="row.item.photoUrl || row.item.photoPreviewUrl"
                              type="button"
                              class="px-2 py-1 text-xs border rounded text-slate-700 hover:bg-slate-100"
                              [disabled]="checklistSaving || row.item.uploadingPhoto"
                              (click)="removeChecklistPhoto(row.index)"
                            >
                              Remove
                            </button>
                          </div>
                          <div
                            class="flex items-center gap-2 text-xs text-slate-500"
                            *ngIf="row.item.uploadingPhoto"
                          >
                            <span
                              class="inline-block h-2 w-2 rounded-full bg-blue-500 animate-pulse"
                            ></span>
                            Uploading photo...
                          </div>
                          <p *ngIf="row.item.uploadError" class="text-xs text-red-600">
                            {{ row.item.uploadError }}
                          </p>
                          <div
                            *ngIf="row.item.photoPreviewUrl || row.item.photoUrl"
                            class="flex items-center gap-2"
                          >
                            <img
                              [src]="row.item.photoPreviewUrl || row.item.photoUrl"
                              alt="Checklist evidence"
                              class="h-12 w-12 rounded border object-cover"
                            />
                            <a
                              *ngIf="row.item.photoUrl"
                              [href]="row.item.photoUrl"
                              target="_blank"
                              class="text-xs text-blue-700 hover:underline"
                              >View full</a
                            >
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </section>
            </div>

            <div class="mt-3">
              <label class="text-sm font-medium text-slate-700">Overall Note</label>
              <textarea
                rows="3"
                class="mt-1 w-full px-3 py-2 border rounded"
                [(ngModel)]="checklistRemarks"
                placeholder="Operation note"
              ></textarea>
            </div>

            <div class="mt-4 flex items-center justify-end gap-2">
              <button
                type="button"
                class="px-4 py-2 border rounded-lg"
                (click)="closeChecklist()"
                [disabled]="checklistSaving"
              >
                Cancel
              </button>
              <button
                type="button"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-60"
                (click)="saveChecklist()"
                [disabled]="checklistSaving || hasPhotoUploadInProgress"
              >
                {{
                  checklistSaving
                    ? 'Saving...'
                    : checklistCheckId
                      ? 'Update Checklist'
                      : 'Submit Checklist'
                }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div *ngIf="isDrawerOpen" class="fixed inset-0 z-40">
        <div class="absolute inset-0 bg-black/25" (click)="closeDrawer()"></div>
        <aside
          class="absolute right-0 top-0 h-full w-full max-w-2xl bg-white shadow-2xl overflow-auto p-4"
        >
          <div class="flex items-start justify-between gap-2">
            <div>
              <div class="text-xs uppercase tracking-wide text-slate-500">
                Pre-Entry Safety Detail
              </div>
              <h3 class="text-lg font-semibold text-slate-900">
                Dispatch #{{ selectedRow?.dispatchId }}
              </h3>
              <p class="text-xs text-slate-500">{{ selectedRow?.routeCode || '-' }}</p>
            </div>
            <button
              type="button"
              class="text-slate-600 hover:text-slate-900"
              (click)="closeDrawer()"
            >
              ✕
            </button>
          </div>

          <div *ngIf="selectedRow" class="mt-4 p-3 rounded-lg border border-slate-200 bg-slate-50">
            <div class="flex items-center gap-2 mb-2">
              <span
                class="px-2 py-1 rounded text-xs font-semibold"
                [ngClass]="stageClass(selectedRow.status)"
                >{{ selectedRow.status }}</span
              >
              <span
                class="px-2 py-1 rounded text-xs font-semibold"
                [ngClass]="preEntryClass(selectedRow.preEntrySafetyStatus)"
              >
                Pre-Entry: {{ selectedRow.preEntrySafetyStatus }}
              </span>
            </div>
            <div class="text-sm text-slate-600 mb-2">
              <span class="text-slate-500">Next Step:</span> {{ nextStepText(selectedRow) }}
            </div>
            <div class="grid grid-cols-2 gap-2 text-sm">
              <div>
                <span class="text-slate-500">Driver:</span> {{ selectedRow.driverName || '-' }}
              </div>
              <div>
                <span class="text-slate-500">Truck:</span> {{ selectedRow.truckPlate || '-' }}
              </div>
              <div>
                <span class="text-slate-500">Warehouse:</span>
                {{ selectedRow.warehouseCode || 'KHB' }}
              </div>
              <div>
                <span class="text-slate-500">Daily/Loading:</span>
                {{ selectedRow.loadingSafetyStatus }}
              </div>
              <div class="col-span-2">
                <span class="text-slate-500">Pre-entry Required:</span>
                {{ selectedRow.preEntrySafetyRequired ? 'YES' : 'NO' }}
              </div>
            </div>
          </div>

          <div *ngIf="drawerLoading" class="mt-4 p-4 text-sm text-slate-500 border rounded-lg">
            Loading safety detail...
          </div>
          <div
            *ngIf="drawerError"
            class="mt-4 p-4 text-sm text-amber-700 border border-amber-200 rounded-lg bg-amber-50"
          >
            {{ drawerError }}
          </div>

          <div *ngIf="!drawerLoading && drawerSafetyDetail" class="mt-4 space-y-4">
            <div class="p-3 rounded-lg border border-slate-200">
              <h4 class="font-semibold text-slate-900">Safety Check Summary</h4>
              <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span class="text-slate-500">Status:</span> {{ drawerSafetyDetail.status || '-' }}
                </div>
                <div>
                  <span class="text-slate-500">Check Date:</span>
                  {{ drawerSafetyDetail.checkDate || '-' }}
                </div>
                <div>
                  <span class="text-slate-500">Checked At:</span>
                  {{ formatDateTime(drawerSafetyDetail.checkedAt) }}
                </div>
                <div>
                  <span class="text-slate-500">Checked By:</span>
                  {{ resolveUserName(drawerSafetyDetail.checkedBy) }}
                </div>
                <div class="col-span-2">
                  <span class="text-slate-500">Remarks:</span>
                  {{ drawerSafetyDetail.remarks || '-' }}
                </div>
              </div>
              <div class="mt-3 flex flex-wrap gap-2 text-xs">
                <span class="px-2 py-1 rounded bg-slate-100 text-slate-700"
                  >Total: {{ drawerSafetyDetail.totalItems || 0 }}</span
                >
                <span class="px-2 py-1 rounded bg-emerald-100 text-emerald-700"
                  >Passed: {{ drawerSafetyDetail.passedItems || 0 }}</span
                >
                <span class="px-2 py-1 rounded bg-red-100 text-red-700"
                  >Failed: {{ drawerSafetyDetail.failedItems || 0 }}</span
                >
                <span class="px-2 py-1 rounded bg-amber-100 text-amber-700"
                  >Conditional: {{ drawerSafetyDetail.conditionalItems || 0 }}</span
                >
              </div>
            </div>

            <div class="p-3 rounded-lg border border-slate-200">
              <h4 class="font-semibold text-slate-900">Pre-entry Items</h4>
              <div
                *ngIf="!drawerSafetyDetail.items || drawerSafetyDetail.items.length === 0"
                class="mt-2 text-sm text-slate-500"
              >
                No pre-entry items recorded.
              </div>
              <div
                *ngIf="drawerSafetyDetail.items && drawerSafetyDetail.items.length > 0"
                class="mt-2 overflow-auto border rounded-lg"
              >
                <table class="min-w-full text-sm">
                  <thead class="bg-slate-50 text-slate-700">
                    <tr>
                      <th class="px-2 py-2 text-left">Category</th>
                      <th class="px-2 py-2 text-left">Item</th>
                      <th class="px-2 py-2 text-left">Status</th>
                      <th class="px-2 py-2 text-left">Remarks</th>
                      <th class="px-2 py-2 text-left">Photo</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr *ngFor="let item of drawerSafetyDetail.items" class="border-t">
                      <td class="px-2 py-2">{{ item.category || item.categoryCode || '-' }}</td>
                      <td class="px-2 py-2">{{ item.itemName || '-' }}</td>
                      <td class="px-2 py-2">
                        <span
                          class="px-2 py-1 rounded text-xs"
                          [ngClass]="itemStatusClass(item.statusCode || item.status)"
                          >{{ item.statusCode || item.status || '-' }}</span
                        >
                      </td>
                      <td class="px-2 py-2">{{ item.remarks || '-' }}</td>
                      <td class="px-2 py-2">
                        <a
                          *ngIf="item.photoPath"
                          [href]="item.photoPath"
                          target="_blank"
                          class="text-blue-700 hover:underline"
                          >View</a
                        >
                        <span *ngIf="!item.photoPath">-</span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div class="p-3 rounded-lg border border-slate-200">
              <h4 class="font-semibold text-slate-900">Override / Audit</h4>
              <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span class="text-slate-500">Approved By:</span>
                  {{ resolveUserName(drawerSafetyDetail.overrideApprovedBy) }}
                </div>
                <div>
                  <span class="text-slate-500">Approved At:</span>
                  {{ formatDateTime(drawerSafetyDetail.overrideApprovedAt) }}
                </div>
                <div class="col-span-2">
                  <span class="text-slate-500">Override Remarks:</span>
                  {{ drawerSafetyDetail.overrideRemarks || '-' }}
                </div>
              </div>
            </div>
          </div>

          <div *ngIf="selectedRow" class="mt-4 p-3 rounded-lg border border-slate-200">
            <h4 class="font-semibold text-slate-900">Actions</h4>
            <div class="mt-2 flex flex-wrap gap-2">
              <button
                type="button"
                class="px-3 py-1.5 rounded border border-slate-300 text-slate-700 hover:bg-slate-100 disabled:opacity-50"
                [disabled]="checklistSaving"
                (click)="openChecklist(selectedRow, $event)"
              >
                Open Checklist
              </button>
              <button
                type="button"
                class="px-3 py-1.5 rounded border border-slate-300 text-slate-700 hover:bg-slate-100"
                (click)="openLoadingLane(selectedRow, $event)"
              >
                Open Loading Lane
              </button>
              <button
                type="button"
                class="px-3 py-1.5 rounded border border-slate-300 text-slate-700 hover:bg-slate-100"
                (click)="openDispatchDetail(selectedRow, $event)"
              >
                View Dispatch
              </button>
              <button
                *ngIf="selectedRow.preEntryCheckId"
                type="button"
                class="px-3 py-1.5 rounded border border-red-300 text-red-700 hover:bg-red-50 disabled:opacity-50"
                [disabled]="
                  deletingCheckId === selectedRow.preEntryCheckId || !canDeleteCheck(selectedRow)
                "
                [title]="deleteBlockReason(selectedRow)"
                (click)="deletePreEntryCheck(selectedRow, $event)"
              >
                {{
                  deletingCheckId === selectedRow.preEntryCheckId ? 'Deleting...' : 'Delete Check'
                }}
              </button>
            </div>
          </div>
        </aside>
      </div>
    </div>
  `,
})
export class PreEntrySafetyManagementComponent implements OnInit {
  loading = false;
  rows: PreEntryLaneRow[] = [];
  fromDate = '';
  toDate = '';
  viewMode: ViewMode = 'ALL';
  stageFilter: StageFilter = 'ALL';
  deletingCheckId: number | null = null;
  isDrawerOpen = false;
  selectedRow: PreEntryLaneRow | null = null;
  drawerLoading = false;
  drawerError: string | null = null;
  drawerSafetyDetail: DrawerSafetyDetailVm | null = null;
  listError: string | null = null;

  activeMenuRow: PreEntryLaneRow | null = null;
  activeMenuOrigin: CdkOverlayOrigin | null = null;
  readonly menuPositions: ConnectedPosition[] = [
    { originX: 'end', originY: 'bottom', overlayX: 'end', overlayY: 'top', offsetY: 8 },
    { originX: 'end', originY: 'top', overlayX: 'end', overlayY: 'bottom', offsetY: -8 },
  ];

  isChecklistOpen = false;
  checklistSaving = false;
  checklistError: string | null = null;
  checklistRow: PreEntryLaneRow | null = null;
  checklistCheckId: number | null = null;
  checklistRemarks = '';
  checklistItems: ChecklistItemVm[] = [];
  checklistRowErrors: Record<number, Partial<Record<ChecklistField, string>>> = {};

  private readonly checklistCategoryDefs: Array<{ code: string; label: string }> = [
    { code: 'LOAD', label: 'សម្ភារះលើឡានមុនចូលរោងចក្រ' },
    { code: 'DOCUMENTS', label: 'តង់គ្របទំនិញគ្រប់គ្រាន់ នឹងត្រឹមត្រូវអត់' },
    { code: 'WINDSHIELD', label: 'ត្រួតពិនិត្យឡាន' },
  ];

  constructor(
    private readonly dispatchService: DispatchService,
    private readonly preEntryMasterDataService: PreEntryMasterDataService,
    private readonly toastr: ToastrService,
    private readonly router: Router,
  ) {}

  ngOnInit(): void {
    this.loadRows();
  }

  loadRows(): void {
    this.loading = true;
    this.listError = null;

    if (this.fromDate && this.toDate && this.fromDate > this.toDate) {
      this.toastr.warning('From date cannot be later than To date.');
      this.loading = false;
      return;
    }

    const start = this.fromDate ? new Date(`${this.fromDate}T00:00:00`).toISOString() : undefined;
    const end = this.toDate ? new Date(`${this.toDate}T23:59:59`).toISOString() : undefined;

    this.dispatchService
      .filterDispatches({ page: 0, size: 500, start, end })
      .pipe(
        switchMap((dispatches) => {
          const sourceRows: Dispatch[] = dispatches?.data?.content || [];
          const dispatchIds = sourceRows
            .map((dispatch) => Number(dispatch?.id))
            .filter((dispatchId) => Number.isFinite(dispatchId));

          if (dispatchIds.length === 0) {
            return of({ dispatches, preEntryChecks: [] as any[] });
          }

          return this.dispatchService
            .listPreEntrySafetyChecks({
              fromDate: this.fromDate || undefined,
              toDate: this.toDate || undefined,
              dispatchIds,
            })
            .pipe(
              catchError(() => of([] as any[])),
              map((preEntryChecks) => ({ dispatches, preEntryChecks })),
            );
        }),
      )
      .subscribe({
        next: ({ dispatches, preEntryChecks }) => {
          const sourceRows: Dispatch[] = dispatches?.data?.content || [];
          const checksByDispatchId = new Map<number, any>(
            (preEntryChecks || [])
              .filter((check) => check && typeof check.dispatchId === 'number')
              .map((check) => [Number(check.dispatchId), check]),
          );

          this.rows = sourceRows
            .filter((d) => {
              const status = String((d as any)?.status || '').toUpperCase();
              return (
                status === 'ARRIVED_LOADING' ||
                status === 'IN_QUEUE' ||
                status === 'LOADING' ||
                status === 'LOADED'
              );
            })
            .map((d) => {
              const rawStatus = String((d as any)?.status || '').toUpperCase();
              const dispatchStatus = (
                rawStatus === 'IN_QUEUE' || rawStatus === 'LOADING' || rawStatus === 'LOADED'
                  ? rawStatus
                  : 'ARRIVED_LOADING'
              ) as PreEntryLaneRow['status'];
              const check = checksByDispatchId.get(Number(d.id));
              return {
                dispatchId: d.id!,
                routeCode: d.routeCode,
                status: dispatchStatus,
                driverId: (d as any)?.driverId,
                driverName: (d as any)?.driverName,
                vehicleId: (d as any)?.vehicleId,
                truckPlate: (d as any)?.licensePlate,
                warehouseCode:
                  (d as any)?.warehouseCode ||
                  (d as any)?.warehouse ||
                  check?.warehouseCode ||
                  'KHB',
                preEntrySafetyRequired: (d as any)?.preEntrySafetyRequired === true,
                preEntrySafetyStatus: String(
                  check?.status || (d as any)?.preEntrySafetyStatus || 'NOT_STARTED',
                ).toUpperCase(),
                loadingSafetyStatus: String((d as any)?.safetyStatus || 'PENDING').toUpperCase(),
                preEntryCheckId: typeof check?.id === 'number' ? check.id : undefined,
              };
            })
            .filter((row) => this.matchesViewMode(row))
            .filter((row) => this.matchesStageFilter(row))
            .sort((a, b) => a.dispatchId - b.dispatchId);

          this.refreshDrawerAfterRowsLoaded();
          this.loading = false;
        },
        error: (err) => {
          this.listError = err?.error?.message || 'Unable to load pre-entry safety rows.';
          this.toastr.error(this.listError || undefined);
          this.loading = false;
        },
      });
  }

  openRowActionMenu(row: PreEntryLaneRow, origin: CdkOverlayOrigin, event?: MouseEvent): void {
    event?.stopPropagation();
    if (this.activeMenuRow?.dispatchId === row.dispatchId) {
      this.closeRowActionMenu();
      return;
    }
    this.activeMenuRow = row;
    this.activeMenuOrigin = origin;
  }

  closeRowActionMenu(): void {
    this.activeMenuRow = null;
    this.activeMenuOrigin = null;
  }

  openChecklist(row: PreEntryLaneRow, event?: MouseEvent): void {
    event?.stopPropagation();

    this.revokeAllPhotoPreviews();
    this.checklistRow = row;
    this.checklistCheckId = null;
    this.checklistRemarks = '';
    this.checklistError = null;
    this.checklistRowErrors = {};
    this.checklistItems = [];
    this.isChecklistOpen = true;

    const masterItems$ = this.preEntryMasterDataService.getItems({ activeOnly: true }).pipe(
      catchError((err) => {
        this.toastr.warning(
          err?.error?.message || 'Unable to load pre-entry master items. Using default checklist.',
        );
        return of({ data: [] as SafetyMasterItem[] } as any);
      }),
    );

    const detail$ = row.preEntryCheckId
      ? this.dispatchService.getPreEntrySafetyCheck(row.dispatchId).pipe(
          catchError((err) => {
            if (err?.status !== 404) {
              this.toastr.error(err?.error?.message || 'Unable to load existing checklist detail.');
            }
            return of(null);
          }),
        )
      : of(null);

    forkJoin({ master: masterItems$, detail: detail$ }).subscribe({
      next: ({ master, detail }: { master: any; detail: any }) => {
        const masterRows = this.buildChecklistItemsFromMaster(master?.data || []);
        this.checklistItems = masterRows;
        if (masterRows.length === 0) {
          this.checklistError =
            'No pre-entry master items found. Please configure master items first.';
        }

        const checkDetail = detail && (detail as any)?.data ? (detail as any).data : detail;
        if (!checkDetail) {
          return;
        }
        this.checklistCheckId = Number((checkDetail as any)?.id) || null;
        this.checklistRemarks = (checkDetail as any)?.remarks || '';
        this.patchChecklistFromDetail(checkDetail);
      },
    });
  }

  closeChecklist(): void {
    this.revokeAllPhotoPreviews();
    this.isChecklistOpen = false;
    this.checklistSaving = false;
    this.checklistError = null;
    this.checklistRow = null;
    this.checklistCheckId = null;
    this.checklistRemarks = '';
    this.checklistItems = [];
    this.checklistRowErrors = {};
  }

  saveChecklist(): void {
    if (!this.checklistRow) {
      return;
    }
    if (!this.checklistRow.vehicleId || !this.checklistRow.driverId) {
      this.checklistError = 'Missing vehicle or driver assignment for this dispatch.';
      return;
    }
    const validationError = this.validateChecklist();
    if (validationError) {
      this.checklistError = validationError;
      return;
    }
    if (this.checklistItems.some((item) => item.uploadingPhoto)) {
      this.checklistError = 'Please wait for photo upload to finish before saving.';
      return;
    }

    this.checklistSaving = true;
    this.checklistError = null;
    this.checklistRowErrors = {};

    const payload = {
      dispatchId: this.checklistRow.dispatchId,
      vehicleId: this.checklistRow.vehicleId!,
      driverId: this.checklistRow.driverId!,
      warehouseCode: this.checklistRow.warehouseCode || 'KHB',
      remarks: this.checklistRemarks?.trim() || undefined,
      items: this.checklistItems.map((item) => ({
        category: item.categoryCode,
        itemName: item.itemName.trim(),
        status: item.status,
        remarks: item.remarks.trim() || undefined,
        photoUrl: item.photoUrl.trim() || undefined,
      })),
    };

    const request$ = this.checklistCheckId
      ? this.dispatchService.updatePreEntrySafetyCheck(this.checklistCheckId, payload)
      : this.dispatchService.submitPreEntrySafetyCheck(payload);

    request$.subscribe({
      next: (response: any) => {
        const payload = response?.data ?? response ?? {};
        const action = this.checklistCheckId ? 'updated' : 'submitted';
        const transitionApplied = payload?.autoTransitionApplied === true;
        const dispatchStatusAfterCheck = (payload?.dispatchStatusAfterCheck || '')
          .toString()
          .toUpperCase();
        const transitionMessage = payload?.transitionMessage as string | undefined;

        if (dispatchStatusAfterCheck === 'LOADING' && transitionApplied) {
          this.toastr.success(
            'ពិនិត្យសុវត្ថិភាពមុនចូល (KHB) បានជាប់ និងបានផ្លាស់ទៅ LOADING ដោយស្វ័យប្រវត្តិ។',
          );
        } else if (transitionMessage && payload?.status === 'PASSED' && !transitionApplied) {
          this.toastr.warning(transitionMessage);
        } else {
          this.toastr.success(
            `Pre-entry Safety (KHB) ${action} for dispatch #${this.checklistRow?.dispatchId}.`,
          );
        }
        const dispatchId = this.checklistRow!.dispatchId;
        this.checklistSaving = false;
        this.closeChecklist();
        this.loadRows();
        if (this.isDrawerOpen && this.selectedRow?.dispatchId === dispatchId) {
          this.loadDrawerSafetyDetail(dispatchId);
        }
      },
      error: (err) => {
        this.applyServerValidationErrors(err);
        this.checklistError = err?.error?.message || 'Unable to save checklist.';
        this.checklistSaving = false;
      },
    });
  }

  setAllChecklistStatuses(status: 'OK' | 'FAILED' | 'CONDITIONAL'): void {
    this.checklistItems = this.checklistItems.map((item) => ({
      ...item,
      status,
    }));
    this.checklistError = null;
    this.checklistRowErrors = {};
  }

  clearAllChecklistStatuses(): void {
    this.checklistItems = this.checklistItems.map((item) => ({
      ...item,
      status: '',
    }));
    this.checklistError = null;
    this.checklistRowErrors = {};
  }

  resetChecklistRow(index: number): void {
    const item = this.checklistItems[index];
    if (!item) return;
    this.clearChecklistPhoto(index);
    this.checklistItems[index] = {
      ...item,
      status: '',
      remarks: '',
      photoUrl: '',
      photoPreviewUrl: undefined,
      uploadingPhoto: false,
      uploadError: undefined,
    };
    delete this.checklistRowErrors[index];
  }

  onChecklistStatusChange(index: number): void {
    this.clearFieldError(index, 'status');
    const item = this.checklistItems[index];
    if (!item) return;
    if (!this.requiresRemarks(item.status)) {
      item.remarks = '';
      item.uploadError = undefined;
      if (item.photoUrl || item.photoPreviewUrl) {
        this.clearChecklistPhoto(index);
        item.photoUrl = '';
      }
      this.clearFieldError(index, 'remarks');
    }
  }

  onChecklistFileSelected(event: Event, index: number): void {
    if (!this.checklistItems[index]) return;
    const target = event.target as HTMLInputElement | null;
    const file = target?.files && target.files.length > 0 ? target.files[0] : null;
    if (!file) return;

    this.clearChecklistPhoto(index);
    const previewUrl = URL.createObjectURL(file);
    this.checklistItems[index] = {
      ...this.checklistItems[index],
      photoPreviewUrl: previewUrl,
      photoUrl: '',
      uploadingPhoto: true,
      uploadError: undefined,
    };

    this.dispatchService
      .uploadPreEntrySafetyPhoto(file)
      .pipe(
        finalize(() => {
          const item = this.checklistItems[index];
          if (item) {
            item.uploadingPhoto = false;
          }
          if (target) {
            target.value = '';
          }
        }),
      )
      .subscribe({
        next: (response) => {
          const uploadedUrl = response?.data?.url;
          if (!uploadedUrl) {
            this.checklistItems[index].uploadError = 'Upload completed but no URL was returned.';
            return;
          }
          this.checklistItems[index].photoUrl = uploadedUrl;
          this.checklistItems[index].uploadError = undefined;
        },
        error: (err) => {
          this.toastr.error(err?.error?.message || 'Photo upload failed.');
          this.clearChecklistPhoto(index);
          this.checklistItems[index].uploadError =
            err?.error?.message || 'Photo upload failed. Please retry.';
        },
      });
  }

  removeChecklistPhoto(index: number): void {
    if (!this.checklistItems[index]) return;
    this.clearChecklistPhoto(index);
    this.checklistItems[index] = {
      ...this.checklistItems[index],
      photoUrl: '',
      uploadError: undefined,
    };
  }

  requiresRemarks(status: ChecklistItemVm['status']): boolean {
    return status === 'FAILED' || status === 'CONDITIONAL';
  }

  isAbsentStatus(status: ChecklistItemVm['status']): boolean {
    return status === 'FAILED' || status === 'CONDITIONAL';
  }

  setChecklistStatus(index: number, status: 'OK' | 'FAILED'): void {
    if (!this.checklistItems[index]) return;
    if (this.checklistItems[index].status === status) return;
    this.checklistItems[index].status = status;
    this.onChecklistStatusChange(index);
  }

  groupedChecklistItems(): Array<{
    categoryCode: string;
    categoryLabel: string;
    rows: Array<{ index: number; item: ChecklistItemVm }>;
  }> {
    const groupMap = new Map<
      string,
      {
        categoryCode: string;
        categoryLabel: string;
        rows: Array<{ index: number; item: ChecklistItemVm }>;
      }
    >();
    this.checklistItems.forEach((item, index) => {
      const key = item.categoryCode || item.categoryLabel || 'UNKNOWN';
      if (!groupMap.has(key)) {
        groupMap.set(key, {
          categoryCode: item.categoryCode,
          categoryLabel: item.categoryLabel || item.categoryCode,
          rows: [],
        });
      }
      groupMap.get(key)!.rows.push({ index, item });
    });

    const categoryOrder = this.checklistCategoryDefs.map((cat) => cat.code);
    return Array.from(groupMap.values()).sort((a, b) => {
      const ai = categoryOrder.indexOf(a.categoryCode);
      const bi = categoryOrder.indexOf(b.categoryCode);
      if (ai === -1 && bi === -1) return a.categoryLabel.localeCompare(b.categoryLabel);
      if (ai === -1) return 1;
      if (bi === -1) return -1;
      return ai - bi;
    });
  }

  statusSelectClass(status: ChecklistItemVm['status'], index: number): string {
    if (this.fieldHasError(index, 'status')) return 'border-red-300 bg-red-50 text-red-700';
    if (status === 'OK') return 'border-emerald-300 bg-emerald-50 text-emerald-700';
    if (status === 'FAILED') return 'border-red-300 bg-red-50 text-red-700';
    if (status === 'CONDITIONAL') return 'border-amber-300 bg-amber-50 text-amber-700';
    return 'border-slate-300 bg-white text-slate-700';
  }

  fieldError(index: number, field: ChecklistField): string {
    return this.checklistRowErrors[index]?.[field] || '';
  }

  fieldHasError(index: number, field: ChecklistField): boolean {
    return !!this.fieldError(index, field);
  }

  clearFieldError(index: number, field: ChecklistField): void {
    if (!this.checklistRowErrors[index]?.[field]) return;
    delete this.checklistRowErrors[index][field];
    if (Object.keys(this.checklistRowErrors[index]).length === 0) {
      delete this.checklistRowErrors[index];
    }
  }

  openLoadingLane(row: PreEntryLaneRow, event?: MouseEvent): void {
    event?.stopPropagation();
    this.router.navigate(['/dispatch/loading-khb'], {
      queryParams: { dispatchId: row.dispatchId },
    });
  }

  openDispatchDetail(row: PreEntryLaneRow, event?: MouseEvent): void {
    event?.stopPropagation();
    this.router.navigate(['/dispatch', row.dispatchId]);
  }

  openSafetyMasterItems(): void {
    this.router.navigate(['/admin/pre-entry-master/items']);
  }

  openSafetyMasterCategories(): void {
    this.router.navigate(['/admin/pre-entry-master/categories']);
  }

  deletePreEntryCheck(row: PreEntryLaneRow, event?: MouseEvent): void {
    event?.stopPropagation();
    if (!row.preEntryCheckId || this.deletingCheckId !== null) {
      return;
    }
    if (!this.canDeleteCheck(row)) {
      const reason = this.deleteBlockReason(row);
      if (reason) {
        this.toastr.warning(reason);
      }
      return;
    }

    const confirmed = window.confirm(
      `Delete pre-entry safety check for dispatch #${row.dispatchId}?\nThis will reset pre-entry status to NOT_STARTED.`,
    );
    if (!confirmed) {
      return;
    }

    this.deletingCheckId = row.preEntryCheckId;
    this.dispatchService.deletePreEntrySafetyCheck(row.preEntryCheckId).subscribe({
      next: () => {
        this.toastr.success(`Deleted pre-entry safety check for dispatch #${row.dispatchId}.`);
        this.deletingCheckId = null;
        this.loadRows();
        if (this.isDrawerOpen && this.selectedRow?.dispatchId === row.dispatchId) {
          this.loadDrawerSafetyDetail(row.dispatchId);
        }
      },
      error: (err) => {
        this.toastr.error(err?.error?.message || 'Unable to delete pre-entry safety check.');
        this.deletingCheckId = null;
      },
    });
  }

  openRowDrawer(row: PreEntryLaneRow): void {
    this.closeRowActionMenu();
    this.selectedRow = row;
    this.isDrawerOpen = true;
    this.drawerError = null;
    this.drawerSafetyDetail = null;
    if (!row.preEntryCheckId) {
      this.drawerError = 'No pre-entry safety check created yet for this dispatch.';
      return;
    }
    this.loadDrawerSafetyDetail(row.dispatchId);
  }

  closeDrawer(): void {
    this.isDrawerOpen = false;
    this.selectedRow = null;
    this.drawerLoading = false;
    this.drawerError = null;
    this.drawerSafetyDetail = null;
  }

  @HostListener('document:keydown.escape')
  onEscKey(): void {
    this.closeRowActionMenu();
    if (this.isChecklistOpen) {
      this.closeChecklist();
      return;
    }
    if (this.isDrawerOpen) {
      this.closeDrawer();
    }
  }

  @HostListener('document:click')
  onDocumentClick(): void {
    this.closeRowActionMenu();
  }

  preEntryClass(status: string): string {
    switch (String(status || '').toUpperCase()) {
      case 'PASSED':
        return 'bg-emerald-100 text-emerald-800';
      case 'FAILED':
        return 'bg-red-100 text-red-800';
      case 'CONDITIONAL':
        return 'bg-amber-100 text-amber-800';
      default:
        return 'bg-slate-100 text-slate-700';
    }
  }

  stageClass(status: string): string {
    if (status === 'IN_QUEUE') return 'bg-indigo-100 text-indigo-800';
    if (status === 'LOADING') return 'bg-blue-100 text-blue-800';
    if (status === 'LOADED') return 'bg-emerald-100 text-emerald-800';
    return 'bg-orange-100 text-orange-800';
  }

  canDeleteCheck(row: PreEntryLaneRow | null): boolean {
    if (!row?.preEntryCheckId) return false;
    return row.status === 'ARRIVED_LOADING' || row.status === 'IN_QUEUE';
  }

  deleteBlockReason(row: PreEntryLaneRow): string {
    if (!row.preEntryCheckId) return 'No check exists.';
    if (this.canDeleteCheck(row)) return '';
    return 'Delete is allowed only while dispatch is ARRIVED_LOADING or IN_QUEUE.';
  }

  nextStepText(row: PreEntryLaneRow): string {
    const preEntryPassed = String(row.preEntrySafetyStatus || '').toUpperCase() === 'PASSED';
    if (row.status === 'ARRIVED_LOADING') return 'Get Ticket in Loading Management';
    if (row.status === 'IN_QUEUE' && !preEntryPassed) return 'Complete Pre-Entry Checklist';
    if (row.status === 'IN_QUEUE' && preEntryPassed) return 'Ready for Call Bay';
    if ((row.status === 'LOADING' || row.status === 'LOADED') && preEntryPassed)
      return 'Completed pre-entry';
    return '-';
  }

  get pendingCount(): number {
    return this.rows.filter((row) => this.isPendingRow(row)).length;
  }

  get completedCount(): number {
    return this.rows.filter((row) => this.isCompletedRow(row)).length;
  }

  get awaitingTicketCount(): number {
    return this.rows.filter((row) => row.status === 'ARRIVED_LOADING').length;
  }

  get hasPhotoUploadInProgress(): boolean {
    return this.checklistItems.some((item) => item.uploadingPhoto);
  }

  itemStatusClass(status?: string): string {
    const normalized = this.normalizeStatusCode(status || '');
    if (normalized === 'FAILED') return 'bg-red-100 text-red-700';
    if (normalized === 'CONDITIONAL') return 'bg-amber-100 text-amber-700';
    if (normalized === 'OK') return 'bg-emerald-100 text-emerald-700';
    return 'bg-slate-100 text-slate-700';
  }

  resolveUserName(
    user: { username?: string; firstName?: string; lastName?: string } | null | undefined,
  ): string {
    if (!user) return '-';
    const fullName = `${user.firstName || ''} ${user.lastName || ''}`.trim();
    if (fullName) return fullName;
    return user.username || '-';
  }

  formatDateTime(raw?: unknown): string {
    if (!raw) return '-';

    if (Array.isArray(raw) && raw.length >= 6) {
      const [year, month, day, hour, minute, second, nano = 0] = raw.map((n) => Number(n));

      const millis = Math.floor(nano / 1_000_000);
      const dt = new Date(year, month - 1, day, hour, minute, second, millis);
      if (!Number.isNaN(dt.getTime())) {
        return dt.toLocaleString();
      }
    }

    const dt = new Date(String(raw));
    if (Number.isNaN(dt.getTime())) return String(raw);
    return dt.toLocaleString();
  }

  private loadDrawerSafetyDetail(dispatchId: number): void {
    this.drawerLoading = true;
    this.drawerError = null;
    this.drawerSafetyDetail = null;

    this.dispatchService.getPreEntrySafetyCheck(dispatchId).subscribe({
      next: (res) => {
        const detail = (res as any)?.data ? (res as any).data : res;
        this.drawerSafetyDetail = detail || null;
        this.drawerLoading = false;
      },
      error: (err) => {
        const serverMessage = err?.error?.message || '';
        if (
          err?.status === 404 ||
          String(serverMessage).toLowerCase().includes('safety check not found for dispatch')
        ) {
          this.drawerError = 'No pre-entry safety check created yet for this dispatch.';
        } else {
          this.drawerError = serverMessage || 'Unable to load pre-entry safety detail.';
        }
        this.drawerLoading = false;
      },
    });
  }

  private refreshDrawerAfterRowsLoaded(): void {
    if (!this.isDrawerOpen || !this.selectedRow) {
      return;
    }
    const updatedRow = this.rows.find((r) => r.dispatchId === this.selectedRow!.dispatchId);
    if (updatedRow) {
      this.selectedRow = updatedRow;
    }
  }

  private patchChecklistFromDetail(detail: any): void {
    const sourceItems: any[] = Array.isArray(detail?.items) ? detail.items : [];
    if (sourceItems.length === 0) {
      return;
    }

    const normalized = sourceItems
      .map((item) => {
        const categoryCode = this.normalizeCategoryCode(item?.categoryCode || item?.category);
        if (!categoryCode) {
          return null;
        }
        const itemName = String(item?.itemName || '').trim();
        if (!itemName) {
          return null;
        }
        return {
          categoryCode,
          itemName,
          status: this.normalizeStatusCode(
            item?.statusCode || item?.status,
          ) as ChecklistItemVm['status'],
          remarks: item?.remarks || '',
          photoUrl: item?.photoPath || item?.photoUrl || '',
        };
      })
      .filter((item): item is NonNullable<typeof item> => !!item);

    const usedIndexes = new Set<number>();
    const merged = this.checklistItems.map((row) => {
      const expectedName = row.itemName.trim().toLowerCase();
      let index = normalized.findIndex(
        (item, idx) =>
          !usedIndexes.has(idx) &&
          item.categoryCode === row.categoryCode &&
          item.itemName.trim().toLowerCase() === expectedName,
      );
      if (index < 0) {
        index = normalized.findIndex(
          (item, idx) => !usedIndexes.has(idx) && item.categoryCode === row.categoryCode,
        );
      }
      if (index < 0) {
        return row;
      }

      usedIndexes.add(index);
      const source = normalized[index];
      return {
        ...row,
        status: source.status || row.status,
        remarks: source.remarks || '',
        photoUrl: source.photoUrl || '',
        photoPreviewUrl: undefined,
        uploadingPhoto: false,
        uploadError: undefined,
      };
    });

    this.checklistItems = merged;
  }

  private normalizeCategoryCode(value: string): string {
    const normalized = String(value || '')
      .trim()
      .toUpperCase()
      .replace(/[-\s]/g, '_')
      .replace(/&/g, '');
    if (normalized === 'LOAD' || normalized === 'LOAD_SECURING' || normalized === 'LOADSECURING')
      return 'LOAD';
    if (normalized === 'TIRES') return 'TIRES';
    if (normalized === 'LIGHTS') return 'LIGHTS';
    if (normalized === 'DOCUMENTS') return 'DOCUMENTS';
    if (normalized === 'WEIGHT') return 'WEIGHT';
    if (normalized === 'BRAKES') return 'BRAKES';
    if (normalized === 'WINDSHIELD') return 'WINDSHIELD';
    return '';
  }

  private normalizeStatusCode(value: string): '' | 'OK' | 'FAILED' | 'CONDITIONAL' {
    const normalized = String(value || '')
      .trim()
      .toUpperCase()
      .replace(/[-\s]/g, '_');
    if (normalized === 'OK' || normalized === 'PASS' || normalized === 'PASSED') return 'OK';
    if (normalized === 'FAILED' || normalized === 'FAIL') return 'FAILED';
    if (normalized === 'CONDITIONAL') return 'CONDITIONAL';

    // Backward compatibility with description labels
    if (normalized === 'PASSED') return 'OK';
    if (normalized === 'NEEDS_SUPERVISOR_APPROVAL') return 'CONDITIONAL';
    return '';
  }

  private validateChecklist(): string {
    if (!this.checklistRow) {
      return 'Checklist context is missing.';
    }
    this.checklistRowErrors = {};

    for (let index = 0; index < this.checklistItems.length; index += 1) {
      const item = this.checklistItems[index];
      if (!item.itemName.trim()) {
        this.setFieldError(index, 'itemName', 'Item name is required.');
      }
      if (!item.status) {
        this.setFieldError(index, 'status', 'Status is required.');
      }
      if (this.requiresRemarks(item.status) && !item.remarks.trim()) {
        this.setFieldError(index, 'remarks', 'Remarks are required for FAILED/CONDITIONAL status.');
      }
    }

    if (Object.keys(this.checklistRowErrors).length > 0) {
      return 'Please fix highlighted checklist rows before submitting.';
    }

    return '';
  }

  private buildChecklistItemsFromMaster(masterItems: SafetyMasterItem[]): ChecklistItemVm[] {
    if (!Array.isArray(masterItems) || masterItems.length === 0) {
      return [];
    }

    const categoryOrder = new Map<string, number>(
      this.checklistCategoryDefs.map((cat, index) => [cat.code, index]),
    );

    const rows: Array<ChecklistItemVm & { sortOrder: number }> = [];
    const seenKeys = new Set<string>();
    for (const item of masterItems) {
      if (item?.isActive === false) {
        continue;
      }
      const categoryCode = this.normalizeCategoryCode(item?.categoryCode || '');
      if (!categoryCode) {
        continue;
      }
      const itemName = String(item?.itemLabelKm || '').trim();
      if (!itemName) {
        continue;
      }
      const uniqueKey = `${categoryCode}::${itemName.toLowerCase()}`;
      if (seenKeys.has(uniqueKey)) {
        continue;
      }
      seenKeys.add(uniqueKey);

      rows.push({
        categoryCode,
        categoryLabel: this.categoryLabelByCode(categoryCode, item?.categoryNameKm),
        itemName,
        status: 'OK',
        remarks: '',
        photoUrl: '',
        photoPreviewUrl: undefined,
        uploadingPhoto: false,
        uploadError: undefined,
        sortOrder: item?.sortOrder ?? 9999,
      });
    }

    rows.sort((a, b) => {
      const categoryA = categoryOrder.get(a.categoryCode) ?? 999;
      const categoryB = categoryOrder.get(b.categoryCode) ?? 999;
      if (categoryA !== categoryB) {
        return categoryA - categoryB;
      }
      if (a.sortOrder !== b.sortOrder) {
        return a.sortOrder - b.sortOrder;
      }
      return a.itemName.localeCompare(b.itemName);
    });

    return rows.map(({ sortOrder, ...row }) => row);
  }

  private categoryLabelByCode(categoryCode: string, categoryNameKm?: string): string {
    if (categoryNameKm && categoryNameKm.trim()) {
      return categoryNameKm.trim();
    }
    const label = this.checklistCategoryDefs.find((cat) => cat.code === categoryCode)?.label;
    return label || categoryCode;
  }

  private clearChecklistPhoto(index: number): void {
    const item = this.checklistItems[index];
    if (!item) return;
    const existingPreview = item.photoPreviewUrl;
    if (existingPreview && existingPreview.startsWith('blob:')) {
      URL.revokeObjectURL(existingPreview);
    }
    item.photoPreviewUrl = undefined;
  }

  private revokeAllPhotoPreviews(): void {
    this.checklistItems.forEach((_, index) => this.clearChecklistPhoto(index));
  }

  private setFieldError(index: number, field: ChecklistField, message: string): void {
    if (!this.checklistRowErrors[index]) {
      this.checklistRowErrors[index] = {};
    }
    this.checklistRowErrors[index][field] = message;
  }

  private applyServerValidationErrors(err: any): void {
    const validationErrors = err?.error?.validationErrors;
    if (!validationErrors || typeof validationErrors !== 'object') {
      return;
    }

    const rowPattern = /^items\[(\d+)\]\.(itemName|status|remarks|photoUrl)$/;
    for (const [key, value] of Object.entries(validationErrors as Record<string, string>)) {
      const match = rowPattern.exec(key);
      if (!match) {
        continue;
      }
      const rowIndex = Number(match[1]);
      const field = match[2] as ChecklistField;
      if (Number.isNaN(rowIndex)) {
        continue;
      }
      this.setFieldError(rowIndex, field, String(value || 'Invalid value'));
    }
  }

  private isPendingRow(row: PreEntryLaneRow): boolean {
    return (
      row.preEntrySafetyRequired &&
      String(row.preEntrySafetyStatus || '').toUpperCase() !== 'PASSED'
    );
  }

  private isCompletedRow(row: PreEntryLaneRow): boolean {
    return String(row.preEntrySafetyStatus || '').toUpperCase() === 'PASSED';
  }

  private matchesViewMode(row: PreEntryLaneRow): boolean {
    if (this.viewMode === 'PENDING') return this.isPendingRow(row);
    if (this.viewMode === 'COMPLETED') return this.isCompletedRow(row);
    return true;
  }

  private matchesStageFilter(row: PreEntryLaneRow): boolean {
    if (this.stageFilter === 'ALL') return true;
    return row.status === this.stageFilter;
  }
}
