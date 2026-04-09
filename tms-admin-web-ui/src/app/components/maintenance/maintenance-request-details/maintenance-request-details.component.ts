import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';

import type { OnInit } from '@angular/core';

import { MaintenanceRequestService } from '../../../services/maintenance-request.service';
import type {
  MaintenanceRequestAttachmentDto,
  MaintenanceRequestDto,
  MaintenanceAttachmentType,
} from '../../../services/maintenance-request.service';
import { MaintenanceWorkOrderService } from '../../../services/maintenance-work-order.service';
import type { WorkOrderDto, WorkOrderType } from '../../../services/maintenance-work-order.service';

@Component({
  selector: 'app-maintenance-request-details',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="container px-6 py-8 mx-auto">
      <nav class="flex mb-4" aria-label="Breadcrumb">
        <ol class="inline-flex items-center space-x-1 md:space-x-3">
          <li class="inline-flex items-center">
            <a
              [routerLink]="['/fleet/maintenance/dashboard']"
              class="inline-flex items-center text-sm font-medium text-gray-700 hover:text-blue-600"
            >
              Maintenance
            </a>
          </li>
          <li class="inline-flex items-center">
            <a
              [routerLink]="['/fleet/maintenance/requests']"
              class="inline-flex items-center text-sm font-medium text-gray-700 hover:text-blue-600"
            >
              Maintenance Requests
            </a>
          </li>
          <li aria-current="page">
            <div class="flex items-center">
              <svg class="w-6 h-6 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
              <span class="ml-1 text-sm font-medium text-gray-500 md:ml-2">
                {{ mr?.mrNumber || 'MR' }}
              </span>
            </div>
          </li>
        </ol>
      </nav>

      <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Maintenance Request Details</h1>
          <div class="flex items-center gap-3 mt-1">
            <p class="text-gray-600">MR {{ mr?.mrNumber || '-' }}</p>
            <span class="px-2 py-1 text-xs rounded-full border" [ngClass]="statusClass(mr?.status)">
              {{ mr?.status || '-' }}
            </span>
          </div>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-4 py-2 border rounded-lg" (click)="goBack()" type="button">Back</button>
          <button
            *ngIf="mr?.workOrderId"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg"
            (click)="openWorkOrder()"
            type="button"
          >
            View Work Order
          </button>
          <button
            *ngIf="mr?.status === 'APPROVED' && !mr?.workOrderId"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-50"
            (click)="openCreateWoModal()"
            [disabled]="actionLoading"
            type="button"
          >
            Create WO
          </button>
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div *ngIf="!mr && !error" class="text-sm text-gray-500">Loading...</div>

      <div *ngIf="mr" class="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <aside class="lg:col-span-3">
          <div class="lg:sticky lg:top-24">
            <div class="bg-white shadow rounded-xl p-4">
              <div class="text-xs font-semibold tracking-wide text-gray-500 uppercase">
                Maintenance Request
              </div>
              <nav class="hidden lg:block mt-3 space-y-1">
                <a
                  [routerLink]="[]"
                  [queryParams]="{ group: 'overview' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'overview'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Overview
                </a>
                <a
                  [routerLink]="[]"
                  [queryParams]="{ group: 'work-order' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'work-order'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Work Order
                </a>
                <a
                  [routerLink]="[]"
                  [queryParams]="{ group: 'timeline' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'timeline'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Timeline
                </a>
              </nav>

              <div class="lg:hidden mt-3 -mx-1 overflow-x-auto">
                <div class="flex gap-2 px-1">
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ group: 'overview' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'overview' ? 'text-blue-700 bg-blue-50' : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Overview
                  </a>
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ group: 'work-order' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'work-order'
                        ? 'text-blue-700 bg-blue-50'
                        : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Work Order
                  </a>
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ group: 'timeline' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'timeline' ? 'text-blue-700 bg-blue-50' : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Timeline
                  </a>
                </div>
              </div>
            </div>
          </div>
        </aside>

        <div class="lg:col-span-9">
          <div *ngIf="group === 'overview'" class="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <div class="lg:col-span-3 text-sm font-semibold text-gray-600">Overview</div>
            <div class="lg:col-span-2 space-y-4">
              <div class="border rounded-lg p-4 bg-white">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <div class="md:col-span-2">
                    <label class="block text-xs font-medium text-gray-700 mb-1">Title</label>
                    <input
                      class="w-full px-3 py-2 border rounded-lg"
                      [(ngModel)]="edit.title"
                      [disabled]="!canEdit"
                    />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Priority</label>
                    <select
                      class="w-full px-3 py-2 border rounded-lg"
                      [(ngModel)]="edit.priority"
                      [disabled]="!canEdit"
                    >
                      <option value="NORMAL">NORMAL</option>
                      <option value="LOW">LOW</option>
                      <option value="HIGH">HIGH</option>
                      <option value="URGENT">URGENT</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Vehicle</label>
                    <div class="px-3 py-2 border rounded-lg bg-gray-50 text-sm text-gray-800">
                      {{ mr.vehiclePlate || '-' }}
                    </div>
                  </div>
                  <div class="md:col-span-2">
                    <label class="block text-xs font-medium text-gray-700 mb-1">Description</label>
                    <textarea
                      class="w-full px-3 py-2 border rounded-lg"
                      rows="4"
                      [(ngModel)]="edit.description"
                      [disabled]="!canEdit"
                    ></textarea>
                  </div>
                </div>
                <div class="mt-3 flex items-center justify-end gap-2">
                  <button
                    class="px-4 py-2 border rounded-lg disabled:opacity-50"
                    (click)="resetEdit()"
                    [disabled]="!canEdit || actionLoading"
                    type="button"
                  >
                    Reset
                  </button>
                  <button
                    class="px-4 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-50"
                    (click)="saveEdit()"
                    [disabled]="!canEdit || actionLoading"
                    type="button"
                  >
                    Save Changes
                  </button>
                </div>
              </div>
              <div class="border rounded-lg p-4 bg-white">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <div class="text-sm font-semibold text-gray-700">Attachments</div>
                  <div class="flex flex-wrap items-center gap-2">
                    <select class="px-2 py-1 border rounded text-xs" [(ngModel)]="attachmentType">
                      <option value="BEFORE">BEFORE</option>
                      <option value="AFTER">AFTER</option>
                      <option value="ACCIDENT">ACCIDENT</option>
                      <option value="INVOICE">INVOICE</option>
                      <option value="OTHER">OTHER</option>
                    </select>
                    <input type="file" (change)="onAttachmentSelected($event)" />
                    <button
                      class="px-3 py-1 text-xs bg-blue-600 text-white rounded disabled:opacity-50"
                      type="button"
                      (click)="uploadAttachment()"
                      [disabled]="uploadingAttachment || !attachmentFile"
                    >
                      Upload
                    </button>
                  </div>
                </div>
                <div class="mt-3 space-y-2">
                  <div *ngIf="attachments.length === 0" class="text-xs text-gray-500">
                    No attachments.
                  </div>
                  <div
                    *ngFor="let item of attachments"
                    class="flex items-center justify-between rounded border px-3 py-2 text-sm"
                  >
                    <div class="flex flex-col">
                      <a
                        [href]="item.fileUrl"
                        target="_blank"
                        class="text-blue-700 hover:underline"
                      >
                        {{ item.fileName || 'Attachment' }}
                      </a>
                      <span class="text-xs text-gray-500"
                        >{{ item.attachmentType }} • {{ formatDate(item.uploadedAt) }}</span
                      >
                    </div>
                    <button
                      class="text-xs text-red-600 hover:text-red-700"
                      type="button"
                      (click)="deleteAttachment(item)"
                      [disabled]="uploadingAttachment"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="space-y-4">
              <div class="border rounded-lg p-4 bg-white">
                <p class="text-xs font-semibold text-gray-600 mb-1">Status</p>
                <p class="text-sm text-gray-900">{{ mr.status || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Request Type</p>
                <p class="text-sm text-gray-900">{{ mr.requestType || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Safety Level</p>
                <p class="text-sm text-gray-900">{{ mr.safetyLevel || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">PM Plan</p>
                <p class="text-sm text-gray-900">{{ mr.pmPlanName || mr.pmPlanId || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Failure Code</p>
                <p class="text-sm text-gray-900">{{ mr.failureCode || '-' }}</p>
                <p *ngIf="mr.failureCodeDescription" class="text-xs text-gray-500">
                  {{ mr.failureCodeDescription }}
                </p>
                <p class="text-xs text-gray-500 mt-2">Requested</p>
                <p class="text-sm text-gray-900">{{ formatDate(mr.requestedAt) }}</p>
                <p class="text-xs text-gray-500 mt-2">Requested By</p>
                <p class="text-sm text-gray-900">{{ mr.createdByName || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Approved</p>
                <p class="text-sm text-gray-900">{{ formatDate(mr.approvedAt) }}</p>
                <p class="text-xs text-gray-500 mt-2">Approved By</p>
                <p class="text-sm text-gray-900">{{ mr.approvedByName || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Approval Remarks</p>
                <p class="text-sm text-gray-900">{{ mr.approvalRemarks || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Rejected</p>
                <p class="text-sm text-gray-900">{{ formatDate(mr.rejectedAt) }}</p>
                <p class="text-xs text-gray-500 mt-2">Rejected By</p>
                <p class="text-sm text-gray-900">{{ mr.rejectedByName || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Rejection Reason</p>
                <p class="text-sm text-gray-900">{{ mr.rejectionReason || '-' }}</p>
              </div>
            </div>
          </div>

          <div *ngIf="group === 'work-order'" class="grid grid-cols-1 gap-4">
            <div class="text-sm font-semibold text-gray-600">Work Orders</div>
            <div class="bg-white border rounded-lg shadow-sm">
              <div class="p-4 grid grid-cols-1 md:grid-cols-4 gap-3">
                <input
                  class="px-3 py-2 border rounded-lg"
                  [(ngModel)]="woSearch"
                  placeholder="Search WO number, title, vehicle"
                  (keyup.enter)="applyWoFilter()"
                />
                <select
                  class="px-3 py-2 border rounded-lg"
                  [(ngModel)]="woStatus"
                  (change)="applyWoFilter()"
                >
                  <option value="">All Status</option>
                  <option value="OPEN">OPEN</option>
                  <option value="IN_PROGRESS">IN_PROGRESS</option>
                  <option value="WAITING_PARTS">WAITING_PARTS</option>
                  <option value="COMPLETED">COMPLETED</option>
                  <option value="CANCELLED">CANCELLED</option>
                </select>
                <div class="flex items-center gap-2">
                  <span class="text-sm text-gray-600">Rows</span>
                  <select
                    class="px-2 py-2 border rounded-lg"
                    [(ngModel)]="woPageSize"
                    (change)="applyWoFilter()"
                  >
                    <option *ngFor="let s of woPageSizes" [ngValue]="s">{{ s }}</option>
                  </select>
                </div>
                <div class="flex gap-2">
                  <button
                    class="px-4 py-2 bg-green-600 text-white rounded-lg"
                    (click)="applyWoFilter()"
                    type="button"
                  >
                    Apply
                  </button>
                  <button
                    class="px-4 py-2 border rounded-lg"
                    (click)="woSearch = ''; woStatus = ''; applyWoFilter()"
                    type="button"
                  >
                    Reset
                  </button>
                </div>
              </div>

              <div class="overflow-x-auto">
                <table class="w-full">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">WO #</th>
                      <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                        Vehicle
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Title</th>
                      <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Type</th>
                      <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                        Repair
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                        Status
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                        Priority
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                        Created
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                        Deadline
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">
                        Details
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr *ngFor="let wo of pagedWorkOrders" class="border-t">
                      <td class="px-4 py-3 text-sm font-medium text-gray-900">
                        {{ wo.woNumber || '-' }}
                      </td>
                      <td class="px-4 py-3 text-sm text-gray-700">{{ wo.vehiclePlate || '-' }}</td>
                      <td class="px-4 py-3 text-sm text-gray-700">{{ wo.title || '-' }}</td>
                      <td class="px-4 py-3 text-sm text-gray-700">{{ wo.type || '-' }}</td>
                      <td class="px-4 py-3 text-sm text-gray-700">{{ wo.repairType || '-' }}</td>
                      <td class="px-4 py-3 text-sm text-gray-700">
                        <span class="px-2 py-1 text-xs rounded-full border">{{
                          wo.status || '-'
                        }}</span>
                      </td>
                      <td class="px-4 py-3 text-sm text-gray-700">{{ wo.priority || '-' }}</td>
                      <td class="px-4 py-3 text-sm text-gray-700">
                        {{ formatDate(wo.createdAt) }}
                      </td>
                      <td class="px-4 py-3 text-sm text-gray-700">
                        {{ formatDate(wo.scheduledDate) }}
                      </td>
                      <td class="px-4 py-3 text-right">
                        <button
                          class="px-3 py-1 border rounded-lg hover:bg-gray-50"
                          (click)="router.navigate(['/fleet/maintenance/work-orders', wo.id])"
                          type="button"
                        >
                          Details
                        </button>
                      </td>
                    </tr>
                    <tr *ngIf="pagedWorkOrders.length === 0">
                      <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="10">
                        No results
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div
                class="px-4 py-3 border-t flex items-center justify-between text-sm text-gray-600"
              >
                <div>
                  Page <span class="font-medium">{{ woPage }}</span> of
                  <span class="font-medium">{{ woTotalPages }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <button
                    class="px-3 py-1 border rounded"
                    (click)="woPrev()"
                    [disabled]="woPage <= 1"
                    type="button"
                  >
                    Prev
                  </button>
                  <button
                    class="px-3 py-1 border rounded"
                    (click)="woNext()"
                    [disabled]="woPage >= woTotalPages"
                    type="button"
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <div class="bg-white border rounded-lg shadow-sm">
                <div class="px-4 py-3 border-b text-sm font-semibold text-gray-700">
                  Work Order Tasks
                </div>
                <div class="overflow-x-auto">
                  <table class="w-full">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Task
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Status
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Assigned
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Est (h)
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Actual (h)
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Completed
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr *ngFor="let task of workOrderTasks" class="border-t">
                        <td class="px-4 py-3 text-sm text-gray-900">{{ task.taskName || '-' }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">{{ task.status || '-' }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">
                          {{ task.assignedTechnicianName || '-' }}
                        </td>
                        <td class="px-4 py-3 text-sm text-gray-700">
                          {{ task.estimatedHours ?? '-' }}
                        </td>
                        <td class="px-4 py-3 text-sm text-gray-700">
                          {{ task.actualHours ?? '-' }}
                        </td>
                        <td class="px-4 py-3 text-sm text-gray-700">
                          {{ formatDate(task.completedAt) }}
                        </td>
                      </tr>
                      <tr *ngIf="workOrderTasks.length === 0">
                        <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="6">
                          No tasks
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <div class="bg-white border rounded-lg shadow-sm">
                <div class="px-4 py-3 border-b text-sm font-semibold text-gray-700">Parts Used</div>
                <div class="overflow-x-auto">
                  <table class="w-full">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Part
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Qty</th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Unit
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Total
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                          Notes
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr *ngFor="let part of workOrderParts" class="border-t">
                        <td class="px-4 py-3 text-sm text-gray-900">
                          {{ part.partName || part.partCode || '-' }}
                        </td>
                        <td class="px-4 py-3 text-sm text-gray-700">{{ part.quantity ?? '-' }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">
                          {{ formatAmount(part.unitPrice) }}
                        </td>
                        <td class="px-4 py-3 text-sm text-gray-700">
                          {{ formatAmount(part.totalCost) }}
                        </td>
                        <td class="px-4 py-3 text-sm text-gray-700">{{ part.notes || '-' }}</td>
                      </tr>
                      <tr *ngIf="workOrderParts.length === 0">
                        <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="5">
                          No parts
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>

          <div *ngIf="group === 'timeline'" class="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <div class="lg:col-span-3 text-sm font-semibold text-gray-600">Timeline</div>
            <div class="lg:col-span-2">
              <div class="border rounded-lg p-4 bg-white">
                <p class="text-xs font-semibold text-gray-600 mb-2">Timeline</p>
                <div class="text-sm text-gray-700 space-y-2">
                  <div>
                    <span class="font-medium">Requested</span>
                    <div class="text-xs text-gray-500">{{ formatDate(mr.requestedAt) }}</div>
                  </div>
                  <div>
                    <span class="font-medium">Approved</span>
                    <div class="text-xs text-gray-500">{{ formatDate(mr.approvedAt) }}</div>
                  </div>
                  <div>
                    <span class="font-medium">Rejected</span>
                    <div class="text-xs text-gray-500">{{ formatDate(mr.rejectedAt) }}</div>
                  </div>
                  <div>
                    <span class="font-medium">WO Created</span>
                    <div class="text-xs text-gray-500">{{ formatDate(workOrder?.createdAt) }}</div>
                  </div>
                  <div>
                    <span class="font-medium">WO Completed</span>
                    <div class="text-xs text-gray-500">
                      {{ formatDate(workOrder?.completedAt) }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="space-y-4">
              <div class="border rounded-lg p-4 bg-white">
                <p class="text-xs font-semibold text-gray-600 mb-1">Status</p>
                <p class="text-sm text-gray-900">{{ mr.status || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Requested By</p>
                <p class="text-sm text-gray-900">{{ mr.createdByName || '-' }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        *ngIf="createWoOpen"
        class="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50"
      >
        <div class="bg-white rounded-lg w-full max-w-2xl shadow-lg">
          <div class="px-5 py-4 border-b flex items-center justify-between">
            <div>
              <h3 class="font-semibold text-gray-900">Create Work Order</h3>
              <p class="text-xs text-gray-500">
                MR {{ mr?.mrNumber || '-' }} • {{ mr?.vehiclePlate || '-' }}
              </p>
            </div>
            <button
              class="text-gray-500 hover:text-gray-700"
              (click)="closeCreateWoModal()"
              type="button"
            >
              <i class="fas fa-times"></i>
            </button>
          </div>
          <div class="p-5 grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Type</label>
              <ng-container *ngIf="mr?.requestType === 'PM'; else typeSelect">
                <div class="w-full px-3 py-2 border rounded-lg bg-gray-50 text-gray-700 text-sm">
                  PREVENTIVE (PM)
                </div>
              </ng-container>
              <ng-template #typeSelect>
                <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="createWoDraft.type">
                  <option value="REPAIR">REPAIR</option>
                  <option value="EMERGENCY">EMERGENCY</option>
                </select>
              </ng-template>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Repair Type</label>
              <select
                class="w-full px-3 py-2 border rounded-lg"
                [(ngModel)]="createWoDraft.repairType"
              >
                <option value="OWN">OWN</option>
                <option value="VENDOR">VENDOR</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Priority</label>
              <select
                class="w-full px-3 py-2 border rounded-lg"
                [(ngModel)]="createWoDraft.priority"
              >
                <option value="NORMAL">NORMAL</option>
                <option value="LOW">LOW</option>
                <option value="HIGH">HIGH</option>
                <option value="URGENT">URGENT</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Estimated Deadline</label>
              <input
                class="w-full px-3 py-2 border rounded-lg"
                type="datetime-local"
                [(ngModel)]="createWoDraft.scheduledDate"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-xs font-medium text-gray-700 mb-1">Title</label>
              <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="createWoDraft.title" />
            </div>
            <div class="md:col-span-2">
              <label class="block text-xs font-medium text-gray-700 mb-1">Description</label>
              <textarea
                class="w-full px-3 py-2 border rounded-lg"
                rows="4"
                [(ngModel)]="createWoDraft.description"
              ></textarea>
            </div>
          </div>
          <div class="px-5 py-4 border-t flex items-center justify-end gap-2">
            <button
              class="px-4 py-2 border rounded-lg"
              (click)="closeCreateWoModal()"
              type="button"
            >
              Cancel
            </button>
            <button
              class="px-4 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-50"
              (click)="submitCreateWo()"
              [disabled]="actionLoading"
              type="button"
            >
              Create Work Order
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class MaintenanceRequestDetailsComponent implements OnInit {
  mr: MaintenanceRequestDto | null = null;
  workOrder: WorkOrderDto | null = null;
  error = '';
  actionLoading = false;
  group: 'overview' | 'work-order' | 'timeline' = 'overview';
  woSearch = '';
  woStatus: '' | 'OPEN' | 'IN_PROGRESS' | 'WAITING_PARTS' | 'COMPLETED' | 'CANCELLED' = '';
  woPage = 1;
  woPageSize = 5;
  woPageSizes = [5, 10, 25];
  createWoOpen = false;
  createWoDraft: {
    type: WorkOrderType;
    repairType: 'OWN' | 'VENDOR';
    priority: 'URGENT' | 'HIGH' | 'NORMAL' | 'LOW';
    title: string;
    description: string;
    scheduledDate: string;
  } = {
    type: 'REPAIR',
    repairType: 'OWN',
    priority: 'NORMAL',
    title: '',
    description: '',
    scheduledDate: '',
  };

  edit: { title: string; description: string; priority: string } = {
    title: '',
    description: '',
    priority: 'NORMAL',
  };

  attachments: MaintenanceRequestAttachmentDto[] = [];
  attachmentType: MaintenanceAttachmentType = 'BEFORE';
  attachmentFile: File | null = null;
  uploadingAttachment = false;

  constructor(
    private readonly route: ActivatedRoute,
    public readonly router: Router,
    private readonly mrService: MaintenanceRequestService,
    private readonly woService: MaintenanceWorkOrderService,
  ) {}

  ngOnInit(): void {
    this.route.queryParamMap.subscribe((params) => {
      const group = params.get('group');
      if (group === 'work-order' || group === 'timeline' || group === 'overview') {
        this.group = group;
      } else {
        this.group = 'overview';
      }
    });
    this.load();
  }

  get canEdit(): boolean {
    return !!this.mr && this.mr.status !== 'APPROVED';
  }

  private load(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (!id) {
      this.error = 'Invalid maintenance request id.';
      return;
    }
    this.mrService.get(id).subscribe({
      next: (res) => {
        this.mr = res?.data ?? null;
        if (this.mr) {
          this.edit = {
            title: this.mr.title || '',
            description: this.mr.description || '',
            priority: this.mr.priority || 'NORMAL',
          };
          this.loadAttachments();
        }
        if (this.mr?.workOrderId) {
          this.woService.getLegacy(this.mr.workOrderId).subscribe({
            next: (woRes: any) => {
              this.workOrder = woRes?.data ?? woRes;
              this.woPage = 1;
            },
            error: () => {},
          });
        }
      },
      error: () => {
        this.error = 'Failed to load maintenance request.';
      },
    });
  }

  private loadAttachments(): void {
    if (!this.mr?.id) return;
    this.mrService.listAttachments(this.mr.id).subscribe({
      next: (res) => {
        this.attachments = res?.data ?? [];
      },
      error: () => {
        this.attachments = [];
      },
    });
  }

  onAttachmentSelected(event: Event): void {
    const target = event.target as HTMLInputElement;
    if (target?.files && target.files.length > 0) {
      this.attachmentFile = target.files[0];
    }
  }

  uploadAttachment(): void {
    if (!this.mr?.id || !this.attachmentFile) return;
    this.uploadingAttachment = true;
    this.mrService
      .uploadAttachment(this.mr.id, this.attachmentFile, this.attachmentType)
      .subscribe({
        next: () => {
          this.uploadingAttachment = false;
          this.attachmentFile = null;
          this.loadAttachments();
        },
        error: () => {
          this.uploadingAttachment = false;
        },
      });
  }

  deleteAttachment(item: MaintenanceRequestAttachmentDto): void {
    if (!this.mr?.id || !item?.id) return;
    this.uploadingAttachment = true;
    this.mrService.deleteAttachment(this.mr.id, item.id).subscribe({
      next: () => {
        this.uploadingAttachment = false;
        this.loadAttachments();
      },
      error: () => {
        this.uploadingAttachment = false;
      },
    });
  }

  goBack(): void {
    this.router.navigate(['/fleet/maintenance/requests']);
  }

  openWorkOrder(): void {
    if (!this.mr?.workOrderId) return;
    this.router.navigate(['/fleet/maintenance/work-orders', this.mr.workOrderId]);
  }

  get workOrders(): WorkOrderDto[] {
    return this.workOrder ? [this.workOrder] : [];
  }

  get workOrderTasks() {
    return this.workOrder?.tasks ?? [];
  }

  get workOrderParts() {
    return this.workOrder?.parts ?? [];
  }

  get filteredWorkOrders(): WorkOrderDto[] {
    const q = this.woSearch.trim().toLowerCase();
    return this.workOrders.filter((wo) => {
      const matchesSearch =
        !q ||
        (wo.woNumber || '').toLowerCase().includes(q) ||
        (wo.title || '').toLowerCase().includes(q) ||
        (wo.vehiclePlate || '').toLowerCase().includes(q);
      const matchesStatus = !this.woStatus || wo.status === this.woStatus;
      return matchesSearch && matchesStatus;
    });
  }

  get pagedWorkOrders(): WorkOrderDto[] {
    const start = (this.woPage - 1) * this.woPageSize;
    return this.filteredWorkOrders.slice(start, start + this.woPageSize);
  }

  get woTotalPages(): number {
    return Math.max(1, Math.ceil(this.filteredWorkOrders.length / this.woPageSize));
  }

  applyWoFilter(): void {
    this.woPage = 1;
  }

  woPrev(): void {
    if (this.woPage <= 1) return;
    this.woPage -= 1;
  }

  woNext(): void {
    if (this.woPage >= this.woTotalPages) return;
    this.woPage += 1;
  }

  openCreateWoModal(): void {
    if (!this.mr) return;
    const type: WorkOrderType = this.mr.requestType === 'PM' ? 'PREVENTIVE' : 'REPAIR';
    this.createWoDraft = {
      type,
      repairType: 'OWN',
      priority: (this.mr.priority as any) || 'NORMAL',
      title: this.mr.title || '',
      description: this.mr.description || '',
      scheduledDate: '',
    };
    this.createWoOpen = true;
  }

  closeCreateWoModal(): void {
    this.createWoOpen = false;
  }

  submitCreateWo(): void {
    if (!this.mr?.id) return;
    this.actionLoading = true;
    if (this.mr.requestType === 'PM') {
      this.createWoDraft.type = 'PREVENTIVE';
    }
    const dto: WorkOrderDto = {
      type: this.createWoDraft.type,
      priority: this.createWoDraft.priority,
      title: this.createWoDraft.title,
      description: this.createWoDraft.description,
      repairType: this.createWoDraft.repairType,
      scheduledDate: this.createWoDraft.scheduledDate || undefined,
    };
    this.woService.createFromMaintenanceRequest(this.mr.id, dto).subscribe({
      next: () => {
        this.actionLoading = false;
        this.createWoOpen = false;
        this.load();
      },
      error: () => {
        this.actionLoading = false;
        this.error = 'Failed to create work order.';
      },
    });
  }

  resetEdit(): void {
    if (!this.mr) return;
    this.edit = {
      title: this.mr.title || '',
      description: this.mr.description || '',
      priority: this.mr.priority || 'NORMAL',
    };
  }

  saveEdit(): void {
    if (!this.mr?.id || !this.canEdit) return;
    this.actionLoading = true;
    this.mrService
      .update(this.mr.id, {
        title: this.edit.title,
        description: this.edit.description,
        priority: this.edit.priority as any,
      })
      .subscribe({
        next: (res) => {
          this.actionLoading = false;
          this.mr = res?.data ?? this.mr;
        },
        error: () => {
          this.actionLoading = false;
          this.error = 'Failed to update maintenance request.';
        },
      });
  }

  statusClass(status?: string | null): string {
    switch (status) {
      case 'APPROVED':
        return 'bg-green-50 text-green-700 border-green-200';
      case 'REJECTED':
        return 'bg-red-50 text-red-700 border-red-200';
      case 'SUBMITTED':
        return 'bg-blue-50 text-blue-700 border-blue-200';
      case 'DRAFT':
        return 'bg-gray-50 text-gray-700 border-gray-200';
      case 'CANCELLED':
        return 'bg-yellow-50 text-yellow-700 border-yellow-200';
      default:
        return 'bg-gray-50 text-gray-700 border-gray-200';
    }
  }

  formatDate(value?: string | null): string {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  }

  formatAmount(value?: number | null): string {
    if (value === null || value === undefined) return '-';
    return new Intl.NumberFormat('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value);
  }
}
