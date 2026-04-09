import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import type { OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';

import { MaintenanceRequestService } from '../../../services/maintenance-request.service';
import type { MaintenanceRequestDto } from '../../../services/maintenance-request.service';
import { MaintenanceWorkOrderService } from '../../../services/maintenance-work-order.service';
import type {
  WorkOrderDto,
  InvoiceAttachmentDto,
} from '../../../services/maintenance-work-order.service';

@Component({
  selector: 'app-work-order-details',
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
              [routerLink]="['/fleet/maintenance/work-orders']"
              class="inline-flex items-center text-sm font-medium text-gray-700 hover:text-blue-600"
            >
              Work Orders
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
                {{ wo?.woNumber || 'WO' }}
              </span>
            </div>
          </li>
        </ol>
      </nav>

      <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Work Order Details</h1>
          <div class="flex items-center gap-3 mt-1">
            <p class="text-gray-600">WO {{ wo?.woNumber || '-' }}</p>
            <span class="px-2 py-1 text-xs rounded-full border" [ngClass]="statusClass(wo?.status)">
              {{ wo?.status || '-' }}
            </span>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <a
            routerLink="/admin/employees"
            class="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50"
            >Employees</a
          >
          <a
            [routerLink]="['/fleet/maintenance/work-orders']"
            [queryParams]="wo?.id ? { openId: wo?.id } : {}"
            class="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50"
            >Assign Technician</a
          >
          <button class="px-4 py-2 border rounded-lg" (click)="goBack()" type="button">Back</button>
          <button
            *ngIf="mr?.id"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg"
            (click)="openMr()"
            type="button"
          >
            View MR
          </button>
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>
      <div
        *ngIf="success"
        class="mb-4 p-3 rounded border border-green-200 bg-green-50 text-green-700"
      >
        {{ success }}
      </div>

      <div *ngIf="!wo && !error" class="text-sm text-gray-500">Loading...</div>

      <div *ngIf="wo" class="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <aside class="lg:col-span-3">
          <div class="lg:sticky lg:top-24">
            <div class="bg-white shadow rounded-xl p-4">
              <div class="text-xs font-semibold tracking-wide text-gray-500 uppercase">
                Work Order
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
                  [queryParams]="{ group: 'tasks' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'tasks'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Tasks
                </a>
                <a
                  [routerLink]="[]"
                  [queryParams]="{ group: 'parts' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'parts'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Parts
                </a>
                <a
                  [routerLink]="[]"
                  [queryParams]="{ group: 'photos' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'photos'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Photos
                </a>
                <a
                  [routerLink]="[]"
                  [queryParams]="{ group: 'costs' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'costs'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Costs
                </a>
                <a
                  [routerLink]="[]"
                  [queryParams]="{ group: 'approvals' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'approvals'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Approvals
                </a>
                <a
                  [routerLink]="[]"
                  [queryParams]="{ group: 'vendor' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'vendor'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Vendor / Invoice
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
                <a
                  [routerLink]="[]"
                  [queryParams]="{ group: 'links' }"
                  queryParamsHandling="merge"
                  class="block w-full text-left px-3 py-2 rounded-lg text-sm transition"
                  [ngClass]="
                    group === 'links'
                      ? 'text-blue-700 bg-blue-50 hover:bg-blue-100'
                      : 'text-gray-700 hover:bg-gray-50'
                  "
                >
                  Links
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
                    [queryParams]="{ group: 'tasks' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'tasks' ? 'text-blue-700 bg-blue-50' : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Tasks
                  </a>
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ group: 'parts' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'parts' ? 'text-blue-700 bg-blue-50' : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Parts
                  </a>
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ group: 'photos' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'photos' ? 'text-blue-700 bg-blue-50' : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Photos
                  </a>
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ group: 'costs' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'costs' ? 'text-blue-700 bg-blue-50' : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Costs
                  </a>
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ group: 'approvals' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'approvals'
                        ? 'text-blue-700 bg-blue-50'
                        : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Approvals
                  </a>
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ group: 'vendor' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'vendor' ? 'text-blue-700 bg-blue-50' : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Vendor
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
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ group: 'links' }"
                    queryParamsHandling="merge"
                    class="shrink-0 px-3 py-2 rounded-lg text-sm"
                    [ngClass]="
                      group === 'links' ? 'text-blue-700 bg-blue-50' : 'text-gray-700 bg-gray-50'
                    "
                  >
                    Links
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
                    <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="edit.title" />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Type</label>
                    <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="edit.type">
                      <option value="PREVENTIVE">PREVENTIVE</option>
                      <option value="REPAIR">REPAIR</option>
                      <option value="EMERGENCY">EMERGENCY</option>
                      <option value="INSPECTION">INSPECTION</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Repair Type</label>
                    <select
                      class="w-full px-3 py-2 border rounded-lg"
                      [(ngModel)]="edit.repairType"
                    >
                      <option value="OWN">OWN</option>
                      <option value="VENDOR">VENDOR</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Priority</label>
                    <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="edit.priority">
                      <option value="NORMAL">NORMAL</option>
                      <option value="LOW">LOW</option>
                      <option value="HIGH">HIGH</option>
                      <option value="URGENT">URGENT</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1"
                      >Estimated Deadline</label
                    >
                    <input
                      class="w-full px-3 py-2 border rounded-lg"
                      type="datetime-local"
                      [(ngModel)]="edit.scheduledDate"
                    />
                  </div>
                  <div class="md:col-span-2">
                    <label class="block text-xs font-medium text-gray-700 mb-1">Description</label>
                    <textarea
                      class="w-full px-3 py-2 border rounded-lg"
                      rows="4"
                      [(ngModel)]="edit.description"
                    ></textarea>
                  </div>
                </div>
                <div class="mt-3 flex items-center justify-end gap-2">
                  <button class="px-4 py-2 border rounded-lg" (click)="resetEdit()" type="button">
                    Reset
                  </button>
                  <button
                    class="px-4 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-50"
                    (click)="saveEdit()"
                    [disabled]="actionLoading"
                    type="button"
                  >
                    Save Changes
                  </button>
                </div>
              </div>
            </div>
            <div class="space-y-4">
              <div class="border rounded-lg p-4 bg-white">
                <p class="text-xs font-semibold text-gray-600 mb-1">Status</p>
                <p class="text-sm text-gray-900">{{ wo.status || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Type / Repair</p>
                <p class="text-sm text-gray-900">
                  {{ wo.type || '-' }} • {{ wo.repairType || '-' }}
                </p>
                <p class="text-xs text-gray-500 mt-2">Priority</p>
                <p class="text-sm text-gray-900">{{ wo.priority || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">PM Plan</p>
                <p class="text-sm text-gray-900">{{ wo.pmPlanName || wo.pmPlanId || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Failure Code</p>
                <p class="text-sm text-gray-900">{{ wo.failureCode || '-' }}</p>
                <p *ngIf="wo.failureCodeDescription" class="text-xs text-gray-500">
                  {{ wo.failureCodeDescription }}
                </p>
              </div>
            </div>
          </div>

          <div *ngIf="group === 'tasks'" class="grid grid-cols-1 gap-4">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div class="text-sm font-semibold text-gray-600">Tasks</div>
              <button
                class="px-3 py-2 bg-blue-600 text-white rounded-lg"
                type="button"
                (click)="openTaskModal()"
              >
                Add Task
              </button>
            </div>
            <div *ngIf="wo?.pmPlanId" class="border rounded-lg p-4 bg-blue-50">
              <div class="flex items-center justify-between mb-2">
                <div class="text-sm font-semibold text-blue-800">PM Checklist</div>
                <div class="text-xs text-blue-700">
                  {{ wo?.pmPlanName || 'PM Plan' }}
                </div>
              </div>
              <div *ngIf="pmTasks.length === 0" class="text-xs text-blue-700">
                No PM tasks found for this work order.
              </div>
              <div *ngIf="pmTasks.length > 0" class="space-y-2">
                <div
                  *ngFor="let task of pmTasks"
                  class="flex items-center justify-between rounded border border-blue-100 bg-white px-3 py-2 text-sm"
                >
                  <div class="flex items-center gap-2">
                    <input type="checkbox" [checked]="task.status === 'COMPLETED'" disabled />
                    <span class="text-gray-800">{{ task.taskName }}</span>
                  </div>
                  <span class="text-xs text-gray-500">{{ task.status }}</span>
                </div>
              </div>
            </div>
            <div class="bg-white border rounded-lg shadow-sm p-4">
              <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
                <div class="md:col-span-2">
                  <label class="block text-xs font-medium text-gray-700 mb-1">Search</label>
                  <input
                    class="w-full px-3 py-2 border rounded-lg"
                    placeholder="Search task name or description..."
                    [(ngModel)]="taskFilterText"
                    (ngModelChange)="onTaskFilterChange()"
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Status</label>
                  <select
                    class="w-full px-3 py-2 border rounded-lg"
                    [(ngModel)]="taskStatusFilter"
                    (ngModelChange)="onTaskFilterChange()"
                  >
                    <option value="">All</option>
                    <option *ngFor="let s of taskStatuses" [value]="s">{{ s }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Page Size</label>
                  <select
                    class="w-full px-3 py-2 border rounded-lg"
                    [(ngModel)]="taskPageSize"
                    (ngModelChange)="onTaskFilterChange()"
                  >
                    <option *ngFor="let s of taskPageSizes" [value]="s">{{ s }}</option>
                  </select>
                </div>
              </div>
            </div>
            <div class="bg-white border rounded-lg shadow-sm overflow-x-auto">
              <table class="w-full">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Task</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Status</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                      Assigned
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Est (h)</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                      Actual (h)
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Started</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">
                      Completed
                    </th>
                    <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr *ngFor="let task of pagedTasks" class="border-t">
                    <td class="px-4 py-3 text-sm text-gray-900">{{ task.taskName || '-' }}</td>
                    <td class="px-4 py-3 text-sm text-gray-700">{{ task.status || '-' }}</td>
                    <td class="px-4 py-3 text-sm text-gray-700">
                      {{ task.assignedTechnicianName || '-' }}
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-700">
                      {{ task.estimatedHours ?? '-' }}
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-700">{{ task.actualHours ?? '-' }}</td>
                    <td class="px-4 py-3 text-sm text-gray-700">
                      {{ formatDate(task.startedAt) }}
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-700">
                      {{ formatDate(task.completedAt) }}
                    </td>
                    <td class="px-4 py-3 text-right">
                      <div class="inline-flex items-center gap-2">
                        <button
                          class="text-sm text-gray-700 hover:text-gray-900"
                          type="button"
                          (click)="openTaskModal(task)"
                          [disabled]="actionLoading"
                        >
                          Edit
                        </button>
                        <button
                          class="text-sm text-blue-600 hover:text-blue-700"
                          type="button"
                          (click)="startTask(task)"
                          [disabled]="
                            actionLoading ||
                            task.status === 'IN_PROGRESS' ||
                            task.status === 'COMPLETED'
                          "
                        >
                          Start
                        </button>
                        <button
                          class="text-sm text-green-600 hover:text-green-700"
                          type="button"
                          (click)="completeTask(task)"
                          [disabled]="actionLoading || task.status === 'COMPLETED'"
                        >
                          Complete
                        </button>
                        <button
                          class="text-sm text-red-600 hover:text-red-700"
                          type="button"
                          (click)="deleteTask(task)"
                          [disabled]="actionLoading"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                  <tr *ngIf="filteredTasks.length === 0">
                    <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="8">
                      No tasks
                    </td>
                  </tr>
                </tbody>
              </table>
              <div
                class="flex items-center justify-between px-4 py-3 border-t text-sm text-gray-600"
              >
                <div>Showing {{ pagedTasks.length }} of {{ filteredTasks.length }} tasks</div>
                <div class="flex items-center gap-2">
                  <button
                    class="px-2 py-1 border rounded"
                    (click)="prevTaskPage()"
                    [disabled]="taskPage === 0"
                  >
                    Prev
                  </button>
                  <span>Page {{ taskPage + 1 }} of {{ taskTotalPages }}</span>
                  <button
                    class="px-2 py-1 border rounded"
                    (click)="nextTaskPage()"
                    [disabled]="taskPage + 1 >= taskTotalPages"
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div *ngIf="group === 'parts'" class="grid grid-cols-1 gap-4">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div class="text-sm font-semibold text-gray-600">Parts Used</div>
              <button
                class="px-3 py-2 bg-blue-600 text-white rounded-lg"
                type="button"
                (click)="openPartModal()"
              >
                Add Part
              </button>
            </div>
            <div class="bg-white border rounded-lg shadow-sm p-4">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
                <div class="md:col-span-2">
                  <label class="block text-xs font-medium text-gray-700 mb-1">Search</label>
                  <input
                    class="w-full px-3 py-2 border rounded-lg"
                    placeholder="Search part name, code, or notes..."
                    [(ngModel)]="partFilterText"
                    (ngModelChange)="onPartFilterChange()"
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Page Size</label>
                  <select
                    class="w-full px-3 py-2 border rounded-lg"
                    [(ngModel)]="partPageSize"
                    (ngModelChange)="onPartFilterChange()"
                  >
                    <option *ngFor="let s of partPageSizes" [value]="s">{{ s }}</option>
                  </select>
                </div>
              </div>
            </div>
            <div class="bg-white border rounded-lg shadow-sm overflow-x-auto">
              <table class="w-full">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Part</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Qty</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Unit</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Total</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Notes</th>
                    <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr *ngFor="let part of pagedParts" class="border-t">
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
                    <td class="px-4 py-3 text-right">
                      <button
                        class="text-sm text-red-600 hover:text-red-700"
                        type="button"
                        (click)="deletePart(part)"
                        [disabled]="actionLoading"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                  <tr *ngIf="filteredParts.length === 0">
                    <td class="px-4 py-6 text-center text-sm text-gray-500" colspan="6">
                      No parts
                    </td>
                  </tr>
                </tbody>
              </table>
              <div
                class="flex items-center justify-between px-4 py-3 border-t text-sm text-gray-600"
              >
                <div>Showing {{ pagedParts.length }} of {{ filteredParts.length }} parts</div>
                <div class="flex items-center gap-2">
                  <button
                    class="px-2 py-1 border rounded"
                    (click)="prevPartPage()"
                    [disabled]="partPage === 0"
                  >
                    Prev
                  </button>
                  <span>Page {{ partPage + 1 }} of {{ partTotalPages }}</span>
                  <button
                    class="px-2 py-1 border rounded"
                    (click)="nextPartPage()"
                    [disabled]="partPage + 1 >= partTotalPages"
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div *ngIf="group === 'photos'" class="grid grid-cols-1 gap-4">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div class="text-sm font-semibold text-gray-600">Photos</div>
              <button
                class="px-3 py-2 bg-blue-600 text-white rounded-lg"
                type="button"
                (click)="openPhotoModal()"
              >
                Add Photo
              </button>
            </div>
            <div class="bg-white border rounded-lg shadow-sm p-4">
              <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
                <div class="md:col-span-2">
                  <label class="block text-xs font-medium text-gray-700 mb-1">Search</label>
                  <input
                    class="w-full px-3 py-2 border rounded-lg"
                    placeholder="Search description or type..."
                    [(ngModel)]="photoFilterText"
                    (ngModelChange)="onPhotoFilterChange()"
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Type</label>
                  <select
                    class="w-full px-3 py-2 border rounded-lg"
                    [(ngModel)]="photoTypeFilter"
                    (ngModelChange)="onPhotoFilterChange()"
                  >
                    <option value="">All</option>
                    <option value="BEFORE">BEFORE</option>
                    <option value="AFTER">AFTER</option>
                    <option value="DIAGNOSTIC">DIAGNOSTIC</option>
                    <option value="ACCIDENT">ACCIDENT</option>
                    <option value="OTHER">OTHER</option>
                  </select>
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Page Size</label>
                  <select
                    class="w-full px-3 py-2 border rounded-lg"
                    [(ngModel)]="photoPageSize"
                    (ngModelChange)="onPhotoFilterChange()"
                  >
                    <option *ngFor="let s of photoPageSizes" [value]="s">{{ s }}</option>
                  </select>
                </div>
              </div>
            </div>
            <div class="bg-white border rounded-lg shadow-sm p-4">
              <div *ngIf="filteredPhotos.length === 0" class="text-sm text-gray-500">No photos</div>
              <div
                *ngIf="filteredPhotos.length > 0"
                class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
              >
                <div *ngFor="let photo of pagedPhotos" class="border rounded-lg overflow-hidden">
                  <div class="bg-gray-100 h-40 flex items-center justify-center">
                    <img
                      *ngIf="photo.photoUrl"
                      [src]="photo.photoUrl"
                      alt="WO photo"
                      class="object-cover w-full h-full"
                    />
                    <div *ngIf="!photo.photoUrl" class="text-xs text-gray-500">No image</div>
                  </div>
                  <div class="p-3 text-sm text-gray-700">
                    <div class="font-medium">{{ photo.photoType || '-' }}</div>
                    <div class="text-xs text-gray-500">{{ formatDate(photo.uploadedAt) }}</div>
                    <div class="mt-1">{{ photo.description || '-' }}</div>
                    <button
                      class="mt-2 text-xs text-red-600 hover:text-red-700"
                      type="button"
                      (click)="deletePhoto(photo)"
                      [disabled]="actionLoading"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
              <div class="flex items-center justify-between px-1 pt-4 text-sm text-gray-600">
                <div>Showing {{ pagedPhotos.length }} of {{ filteredPhotos.length }} photos</div>
                <div class="flex items-center gap-2">
                  <button
                    class="px-2 py-1 border rounded"
                    (click)="prevPhotoPage()"
                    [disabled]="photoPage === 0"
                  >
                    Prev
                  </button>
                  <span>Page {{ photoPage + 1 }} of {{ photoTotalPages }}</span>
                  <button
                    class="px-2 py-1 border rounded"
                    (click)="nextPhotoPage()"
                    [disabled]="photoPage + 1 >= photoTotalPages"
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div *ngIf="group === 'costs'" class="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <div class="lg:col-span-3 text-sm font-semibold text-gray-600">Costs</div>
            <div class="bg-white border rounded-lg p-4">
              <p class="text-xs font-semibold text-gray-600">Estimated Cost</p>
              <p class="text-lg font-semibold text-gray-900">
                {{ formatAmount(wo.estimatedCost) }}
              </p>
            </div>
            <div class="bg-white border rounded-lg p-4">
              <p class="text-xs font-semibold text-gray-600">Labor Cost</p>
              <p class="text-lg font-semibold text-gray-900">{{ formatAmount(wo.laborCost) }}</p>
            </div>
            <div class="bg-white border rounded-lg p-4">
              <p class="text-xs font-semibold text-gray-600">Parts Cost</p>
              <p class="text-lg font-semibold text-gray-900">{{ formatAmount(wo.partsCost) }}</p>
            </div>
            <div class="bg-white border rounded-lg p-4 lg:col-span-3">
              <p class="text-xs font-semibold text-gray-600">Actual Cost</p>
              <p class="text-xl font-semibold text-gray-900">{{ formatAmount(wo.actualCost) }}</p>
            </div>
          </div>

          <div *ngIf="group === 'approvals'" class="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <div class="lg:col-span-3 text-sm font-semibold text-gray-600">Approvals</div>
            <div class="bg-white border rounded-lg p-4">
              <p class="text-xs font-semibold text-gray-600">Requires Approval</p>
              <p class="text-sm text-gray-900">{{ wo.requiresApproval ? 'Yes' : 'No' }}</p>
              <p class="text-xs text-gray-500 mt-2">Approved</p>
              <p class="text-sm text-gray-900">{{ wo.approved ? 'Yes' : 'No' }}</p>
              <p class="text-xs text-gray-500 mt-2">Approved By</p>
              <p class="text-sm text-gray-900">{{ wo.approvedByName || '-' }}</p>
              <p class="text-xs text-gray-500 mt-2">Approved At</p>
              <p class="text-sm text-gray-900">{{ formatDate(wo.approvedAt) }}</p>
            </div>
          </div>

          <div *ngIf="group === 'vendor'" class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div class="bg-white border rounded-lg p-4">
              <p class="text-xs font-semibold text-gray-600 mb-2">Vendor Quotation</p>
              <div class="text-sm text-gray-700 space-y-1">
                <div>
                  Vendor:
                  <span class="font-medium">{{ wo.vendorQuotation?.vendorName || '-' }}</span>
                </div>
                <div>
                  Quotation #:
                  <span class="font-medium">{{ wo.vendorQuotation?.quotationNumber || '-' }}</span>
                </div>
                <div>
                  Status: <span class="font-medium">{{ wo.vendorQuotation?.status || '-' }}</span>
                </div>
                <div>
                  Amount: <span class="font-medium">{{ wo.vendorQuotation?.amount || '-' }}</span>
                </div>
                <div>
                  Notes: <span class="font-medium">{{ wo.vendorQuotation?.notes || '-' }}</span>
                </div>
              </div>
            </div>
            <div class="bg-white border rounded-lg p-4">
              <p class="text-xs font-semibold text-gray-600 mb-2">Invoice</p>
              <div class="text-sm text-gray-700 space-y-1">
                <div>
                  Invoice #: <span class="font-medium">{{ wo.invoice?.id || '-' }}</span>
                </div>
                <div>
                  Date: <span class="font-medium">{{ wo.invoice?.invoiceDate || '-' }}</span>
                </div>
                <div>
                  Total: <span class="font-medium">{{ wo.invoice?.totalAmount || '-' }}</span>
                </div>
                <div>
                  Status: <span class="font-medium">{{ wo.invoice?.paymentStatus || '-' }}</span>
                </div>
              </div>
              <div class="mt-4 border-t pt-3">
                <div class="text-xs font-semibold text-gray-600 mb-2">Invoice Attachments</div>
                <div *ngIf="!wo.invoice?.id" class="text-xs text-gray-500">
                  Create an invoice to upload attachments.
                </div>
                <div *ngIf="wo.invoice?.id" class="space-y-2">
                  <div class="flex flex-wrap items-center gap-2">
                    <select
                      class="px-2 py-1 border rounded text-xs"
                      [(ngModel)]="invoiceAttachmentType"
                    >
                      <option value="INVOICE">INVOICE</option>
                      <option value="OTHER">OTHER</option>
                    </select>
                    <input type="file" (change)="onInvoiceAttachmentSelected($event)" />
                    <button
                      class="px-3 py-1 text-xs bg-blue-600 text-white rounded disabled:opacity-50"
                      type="button"
                      (click)="uploadInvoiceAttachment()"
                      [disabled]="invoiceAttachmentUploading || !invoiceAttachmentFile"
                    >
                      Upload
                    </button>
                  </div>
                  <div *ngIf="invoiceAttachments.length === 0" class="text-xs text-gray-500">
                    No attachments.
                  </div>
                  <div
                    *ngFor="let item of invoiceAttachments"
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
                      <span class="text-xs text-gray-500">{{ item.attachmentType }}</span>
                    </div>
                    <button
                      class="text-xs text-red-600 hover:text-red-700"
                      type="button"
                      (click)="deleteInvoiceAttachment(item)"
                      [disabled]="invoiceAttachmentUploading"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div *ngIf="group === 'timeline'" class="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <div class="lg:col-span-3 text-sm font-semibold text-gray-600">Timeline</div>
            <div class="lg:col-span-2">
              <div class="border rounded-lg p-4 bg-white">
                <p class="text-xs font-semibold text-gray-600 mb-1">Timeline</p>
                <div class="text-sm text-gray-700">
                  <div>
                    Created at: <span class="font-medium">{{ formatDate(wo.createdAt) }}</span>
                  </div>
                  <div class="mt-1">
                    Estimated deadline:
                    <span class="font-medium">{{ formatDate(wo.scheduledDate) }}</span>
                  </div>
                  <div class="mt-1">
                    Completed at: <span class="font-medium">{{ formatDate(wo.completedAt) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div *ngIf="group === 'links'" class="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <div class="lg:col-span-3 text-sm font-semibold text-gray-600">Links</div>
            <div class="lg:col-span-2 space-y-4">
              <div class="border rounded-lg p-4 bg-white">
                <p class="text-xs font-semibold text-gray-600 mb-1">MR</p>
                <p class="text-sm text-gray-900">{{ wo.maintenanceRequestNumber || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">Vehicle</p>
                <p class="text-sm text-gray-900">{{ wo.vehiclePlate || '-' }}</p>
                <div class="mt-3 flex items-center gap-2">
                  <button
                    *ngIf="mr?.id"
                    class="px-3 py-1 border rounded-lg hover:bg-gray-50"
                    (click)="openMr()"
                    type="button"
                  >
                    Open MR
                  </button>
                  <button
                    *ngIf="wo?.vehicleId"
                    class="px-3 py-1 border rounded-lg hover:bg-gray-50"
                    (click)="openVehicle()"
                    type="button"
                  >
                    Open Vehicle
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div
      *ngIf="taskModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
    >
      <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold">
            {{ taskFormMode === 'create' ? 'Add Task' : 'Edit Task' }}
          </h3>
          <button
            class="text-gray-500 hover:text-gray-700"
            type="button"
            (click)="closeTaskModal()"
          >
            ✕
          </button>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
          <div class="md:col-span-2">
            <label class="block text-xs font-medium text-gray-700 mb-1">Task Name</label>
            <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="taskForm.taskName" />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Status</label>
            <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="taskForm.status">
              <option *ngFor="let s of taskStatuses" [value]="s">{{ s }}</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Estimated Hours</label>
            <input
              class="w-full px-3 py-2 border rounded-lg"
              type="number"
              min="0"
              step="0.5"
              [(ngModel)]="taskForm.estimatedHours"
            />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Actual Hours</label>
            <input
              class="w-full px-3 py-2 border rounded-lg"
              type="number"
              min="0"
              step="0.5"
              [(ngModel)]="taskForm.actualHours"
            />
          </div>
          <div class="md:col-span-3">
            <label class="block text-xs font-medium text-gray-700 mb-1">Description</label>
            <textarea
              class="w-full px-3 py-2 border rounded-lg"
              rows="2"
              [(ngModel)]="taskForm.description"
            ></textarea>
          </div>
          <div class="md:col-span-3">
            <label class="block text-xs font-medium text-gray-700 mb-1">Diagnosis Result</label>
            <textarea
              class="w-full px-3 py-2 border rounded-lg"
              rows="2"
              [(ngModel)]="taskForm.diagnosisResult"
            ></textarea>
          </div>
          <div class="md:col-span-3">
            <label class="block text-xs font-medium text-gray-700 mb-1">Actions Taken</label>
            <textarea
              class="w-full px-3 py-2 border rounded-lg"
              rows="2"
              [(ngModel)]="taskForm.actionsTaken"
            ></textarea>
          </div>
          <div class="md:col-span-3">
            <label class="block text-xs font-medium text-gray-700 mb-1">Notes</label>
            <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="taskForm.notes" />
          </div>
        </div>
        <div class="mt-4 flex items-center justify-end gap-2">
          <button class="px-3 py-2 border rounded-lg" type="button" (click)="closeTaskModal()">
            Cancel
          </button>
          <button
            class="px-3 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-50"
            type="button"
            (click)="saveTask()"
            [disabled]="actionLoading || !taskForm.taskName.trim()"
          >
            Save
          </button>
        </div>
      </div>
    </div>
    <div
      *ngIf="partModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
    >
      <div class="w-full max-w-xl bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold">Add Part</h3>
          <button
            class="text-gray-500 hover:text-gray-700"
            type="button"
            (click)="closePartModal()"
          >
            ✕
          </button>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Part ID</label>
            <input
              class="w-full px-3 py-2 border rounded-lg"
              type="number"
              [(ngModel)]="newPart.partId"
            />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Qty</label>
            <input
              class="w-full px-3 py-2 border rounded-lg"
              type="number"
              min="1"
              [(ngModel)]="newPart.quantity"
            />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Unit Cost</label>
            <input
              class="w-full px-3 py-2 border rounded-lg"
              type="number"
              min="0"
              step="0.01"
              [(ngModel)]="newPart.unitPrice"
            />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Task ID (optional)</label>
            <input
              class="w-full px-3 py-2 border rounded-lg"
              type="number"
              [(ngModel)]="newPart.taskId"
            />
          </div>
          <div class="md:col-span-2">
            <label class="block text-xs font-medium text-gray-700 mb-1">Notes</label>
            <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="newPart.notes" />
          </div>
        </div>
        <div class="mt-4 flex items-center justify-end gap-2">
          <button class="px-3 py-2 border rounded-lg" type="button" (click)="closePartModal()">
            Cancel
          </button>
          <button
            class="px-3 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-50"
            type="button"
            (click)="addPart()"
            [disabled]="actionLoading || !newPart.partId"
          >
            Add Part
          </button>
        </div>
      </div>
    </div>
    <div
      *ngIf="photoModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
    >
      <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold">Add Photo</h3>
          <button
            class="text-gray-500 hover:text-gray-700"
            type="button"
            (click)="closePhotoModal()"
          >
            ✕
          </button>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
          <div class="md:col-span-2 space-y-2">
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Upload File</label>
              <input type="file" class="w-full text-sm" (change)="onPhotoFileSelected($event)" />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1"
                >Photo URL (optional)</label
              >
              <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="newPhoto.photoUrl" />
            </div>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Type</label>
            <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="newPhoto.photoType">
              <option value="BEFORE">BEFORE</option>
              <option value="AFTER">AFTER</option>
              <option value="DIAGNOSTIC">DIAGNOSTIC</option>
              <option value="ACCIDENT">ACCIDENT</option>
              <option value="OTHER">OTHER</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Task ID (optional)</label>
            <input
              class="w-full px-3 py-2 border rounded-lg"
              type="number"
              [(ngModel)]="newPhoto.taskId"
            />
          </div>
          <div class="md:col-span-4">
            <label class="block text-xs font-medium text-gray-700 mb-1">Description</label>
            <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="newPhoto.description" />
          </div>
        </div>
        <div class="mt-4 flex items-center justify-end gap-2">
          <button class="px-3 py-2 border rounded-lg" type="button" (click)="closePhotoModal()">
            Cancel
          </button>
          <button
            class="px-3 py-2 bg-blue-600 text-white rounded-lg disabled:opacity-50"
            type="button"
            (click)="addPhoto()"
            [disabled]="actionLoading || (!newPhoto.photoUrl.trim() && !newPhoto.file)"
          >
            Add Photo
          </button>
        </div>
      </div>
    </div>
  `,
})
export class WorkOrderDetailsComponent implements OnInit {
  wo: WorkOrderDto | null = null;
  mr: MaintenanceRequestDto | null = null;
  error = '';
  success = '';
  group:
    | 'overview'
    | 'tasks'
    | 'parts'
    | 'photos'
    | 'costs'
    | 'approvals'
    | 'vendor'
    | 'timeline'
    | 'links' = 'overview';
  actionLoading = false;
  edit: {
    title: string;
    description: string;
    type: 'PREVENTIVE' | 'REPAIR' | 'EMERGENCY' | 'INSPECTION';
    repairType: 'OWN' | 'VENDOR';
    priority: 'URGENT' | 'HIGH' | 'NORMAL' | 'LOW';
    scheduledDate: string;
  } = {
    title: '',
    description: '',
    type: 'REPAIR',
    repairType: 'OWN',
    priority: 'NORMAL',
    scheduledDate: '',
  };
  newTask: {
    taskName: string;
    description: string;
    estimatedHours?: number | null;
    notes: string;
    diagnosisResult: string;
    actionsTaken: string;
  } = {
    taskName: '',
    description: '',
    estimatedHours: null,
    notes: '',
    diagnosisResult: '',
    actionsTaken: '',
  };
  taskModalOpen = false;
  taskFormMode: 'create' | 'edit' = 'create';
  taskForm: {
    id?: number | null;
    taskName: string;
    description: string;
    status: string;
    estimatedHours?: number | null;
    actualHours?: number | null;
    notes: string;
    diagnosisResult: string;
    actionsTaken: string;
  } = {
    id: null,
    taskName: '',
    description: '',
    status: 'OPEN',
    estimatedHours: null,
    actualHours: null,
    notes: '',
    diagnosisResult: '',
    actionsTaken: '',
  };
  taskFilterText = '';
  taskStatusFilter = '';
  taskPage = 0;
  taskPageSize = 10;
  taskPageSizes = [5, 10, 20, 50];
  taskStatuses = [
    'OPEN',
    'IN_PROGRESS',
    'IN_REVIEW',
    'ON_HOLD',
    'BLOCKED',
    'COMPLETED',
    'CANCELLED',
  ];
  partModalOpen = false;
  partFilterText = '';
  partPage = 0;
  partPageSize = 10;
  partPageSizes = [5, 10, 20, 50];
  photoModalOpen = false;
  photoFilterText = '';
  photoTypeFilter = '';
  photoPage = 0;
  photoPageSize = 9;
  photoPageSizes = [6, 9, 12, 18];
  invoiceAttachments: InvoiceAttachmentDto[] = [];
  invoiceAttachmentFile: File | null = null;
  invoiceAttachmentType: 'INVOICE' | 'OTHER' = 'INVOICE';
  invoiceAttachmentUploading = false;
  newPart: {
    partId?: number | null;
    quantity?: number | null;
    unitPrice?: number | null;
    taskId?: number | null;
    notes: string;
  } = {
    partId: null,
    quantity: 1,
    unitPrice: null,
    taskId: null,
    notes: '',
  };
  newPhoto: {
    photoUrl: string;
    photoType: 'BEFORE' | 'AFTER' | 'DIAGNOSTIC' | 'ACCIDENT' | 'OTHER';
    description: string;
    taskId?: number | null;
    file?: File | null;
  } = {
    photoUrl: '',
    photoType: 'BEFORE',
    description: '',
    taskId: null,
    file: null,
  };

  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly woService = inject(MaintenanceWorkOrderService);
  private readonly mrService = inject(MaintenanceRequestService);

  ngOnInit(): void {
    this.route.queryParamMap.subscribe((params) => {
      const group = params.get('group');
      if (
        group === 'overview' ||
        group === 'tasks' ||
        group === 'parts' ||
        group === 'photos' ||
        group === 'costs' ||
        group === 'approvals' ||
        group === 'vendor' ||
        group === 'timeline' ||
        group === 'links'
      ) {
        this.group = group;
      } else {
        this.group = 'overview';
      }
    });
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (!id) {
      this.error = 'Invalid work order id.';
      return;
    }
    this.error = '';
    this.success = '';
    this.refreshWorkOrder(id);
  }

  goBack(): void {
    this.router.navigate(['/fleet/maintenance/work-orders']);
  }

  openMr(): void {
    if (!this.mr?.id) return;
    this.router.navigate(['/fleet/maintenance/requests', this.mr.id], {
      queryParams: { group: 'overview' },
    });
  }

  openVehicle(): void {
    if (!this.wo?.vehicleId) return;
    this.router.navigate(['/fleet/vehicles', this.wo.vehicleId]);
  }

  resetEdit(): void {
    if (!this.wo) return;
    this.edit = {
      title: this.wo.title || '',
      description: this.wo.description || '',
      type: (this.wo.type as any) || 'REPAIR',
      repairType: (this.wo.repairType as any) || 'OWN',
      priority: (this.wo.priority as any) || 'NORMAL',
      scheduledDate: this.toLocalInput(this.wo.scheduledDate),
    };
  }

  saveEdit(): void {
    if (!this.wo?.id) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    this.woService
      .updateLegacy(this.wo.id, {
        title: this.edit.title,
        description: this.edit.description,
        type: this.edit.type as any,
        repairType: this.edit.repairType as any,
        priority: this.edit.priority as any,
        scheduledDate: this.normalizeLocalDate(this.edit.scheduledDate),
      })
      .subscribe({
        next: (res: any) => {
          this.actionLoading = false;
          this.wo = res?.data ?? res;
          this.ensurePaging();
          this.resetEdit();
          this.success = 'Work order updated successfully.';
        },
        error: () => {
          this.actionLoading = false;
          this.error = 'Failed to update work order.';
        },
      });
  }

  addTask(): void {
    if (!this.wo?.id) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    const payload = {
      workOrderId: this.wo.id,
      taskName: this.newTask.taskName.trim(),
      description: this.newTask.description?.trim() || undefined,
      estimatedHours:
        this.newTask.estimatedHours === null || this.newTask.estimatedHours === undefined
          ? undefined
          : Number(this.newTask.estimatedHours),
      notes: this.newTask.notes?.trim() || undefined,
      diagnosisResult: this.newTask.diagnosisResult?.trim() || undefined,
      actionsTaken: this.newTask.actionsTaken?.trim() || undefined,
    };
    this.woService.addTask(this.wo.id, payload).subscribe({
      next: (res: any) => {
        this.actionLoading = false;
        this.wo = res?.data ?? res;
        this.ensurePaging();
        this.resetNewTask();
        this.success = 'Task added successfully.';
      },
      error: () => {
        this.actionLoading = false;
        this.error = 'Failed to add task.';
      },
    });
  }

  deleteTask(task: { id?: number | null }): void {
    if (!this.wo?.id || !task?.id) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    this.woService.deleteTask(this.wo.id, task.id).subscribe({
      next: (res: any) => {
        this.actionLoading = false;
        this.wo = res?.data ?? res;
        this.ensurePaging();
        this.success = 'Task deleted successfully.';
      },
      error: () => {
        this.actionLoading = false;
        this.error = 'Failed to delete task.';
      },
    });
  }

  openTaskModal(task?: any): void {
    if (task) {
      this.taskFormMode = 'edit';
      this.taskForm = {
        id: task.id ?? null,
        taskName: task.taskName || '',
        description: task.description || '',
        status: task.status || 'OPEN',
        estimatedHours: task.estimatedHours ?? null,
        actualHours: task.actualHours ?? null,
        notes: task.notes || '',
        diagnosisResult: task.diagnosisResult || '',
        actionsTaken: task.actionsTaken || '',
      };
    } else {
      this.taskFormMode = 'create';
      this.taskForm = {
        id: null,
        taskName: '',
        description: '',
        status: 'OPEN',
        estimatedHours: null,
        actualHours: null,
        notes: '',
        diagnosisResult: '',
        actionsTaken: '',
      };
    }
    this.taskModalOpen = true;
  }

  closeTaskModal(): void {
    this.taskModalOpen = false;
  }

  openPartModal(): void {
    this.partModalOpen = true;
  }

  closePartModal(): void {
    this.partModalOpen = false;
    this.resetNewPart();
  }

  openPhotoModal(): void {
    this.photoModalOpen = true;
  }

  onPhotoFileSelected(event: Event): void {
    const target = event.target as HTMLInputElement;
    if (target?.files && target.files.length > 0) {
      this.newPhoto.file = target.files[0];
    }
  }

  closePhotoModal(): void {
    this.photoModalOpen = false;
    this.resetNewPhoto();
  }

  saveTask(): void {
    if (!this.wo?.id) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    const payload: any = {
      workOrderId: this.wo.id,
      taskName: this.taskForm.taskName.trim(),
      description: this.taskForm.description?.trim() || undefined,
      status: this.taskForm.status || 'OPEN',
      estimatedHours:
        this.taskForm.estimatedHours === null || this.taskForm.estimatedHours === undefined
          ? undefined
          : Number(this.taskForm.estimatedHours),
      actualHours:
        this.taskForm.actualHours === null || this.taskForm.actualHours === undefined
          ? undefined
          : Number(this.taskForm.actualHours),
      notes: this.taskForm.notes?.trim() || undefined,
      diagnosisResult: this.taskForm.diagnosisResult?.trim() || undefined,
      actionsTaken: this.taskForm.actionsTaken?.trim() || undefined,
    };

    const request$ =
      this.taskFormMode === 'edit' && this.taskForm.id
        ? this.woService.updateTask(this.wo.id, this.taskForm.id, payload)
        : this.woService.addTask(this.wo.id, payload);

    request$.subscribe({
      next: (res: any) => {
        this.actionLoading = false;
        this.wo = res?.data ?? res;
        this.ensurePaging();
        this.taskModalOpen = false;
        this.success = this.taskFormMode === 'edit' ? 'Task updated.' : 'Task added.';
      },
      error: () => {
        this.actionLoading = false;
        this.error =
          this.taskFormMode === 'edit' ? 'Failed to update task.' : 'Failed to add task.';
      },
    });
  }

  onTaskFilterChange(): void {
    this.taskPage = 0;
  }

  onPartFilterChange(): void {
    this.partPage = 0;
  }

  onPhotoFilterChange(): void {
    this.photoPage = 0;
  }

  prevTaskPage(): void {
    if (this.taskPage > 0) this.taskPage -= 1;
  }

  nextTaskPage(): void {
    if (this.taskPage + 1 < this.taskTotalPages) this.taskPage += 1;
  }

  prevPartPage(): void {
    if (this.partPage > 0) this.partPage -= 1;
  }

  nextPartPage(): void {
    if (this.partPage + 1 < this.partTotalPages) this.partPage += 1;
  }

  prevPhotoPage(): void {
    if (this.photoPage > 0) this.photoPage -= 1;
  }

  nextPhotoPage(): void {
    if (this.photoPage + 1 < this.photoTotalPages) this.photoPage += 1;
  }

  get filteredTasks() {
    const q = this.taskFilterText.trim().toLowerCase();
    return (this.tasks || []).filter((t: any) => {
      const matchesQuery =
        !q ||
        String(t.taskName || '')
          .toLowerCase()
          .includes(q) ||
        String(t.description || '')
          .toLowerCase()
          .includes(q);
      const matchesStatus = !this.taskStatusFilter || t.status === this.taskStatusFilter;
      return matchesQuery && matchesStatus;
    });
  }

  get pmTasks() {
    if (!this.wo?.pmPlanId) return [];
    return (this.tasks || []).filter((t: any) =>
      String(t.notes || '')
        .toLowerCase()
        .includes('pm'),
    );
  }

  get pagedTasks() {
    const start = this.taskPage * this.taskPageSize;
    return this.filteredTasks.slice(start, start + this.taskPageSize);
  }

  get taskTotalPages() {
    return Math.max(1, Math.ceil(this.filteredTasks.length / this.taskPageSize));
  }

  get filteredParts() {
    const q = this.partFilterText.trim().toLowerCase();
    return (this.parts || []).filter((p: any) => {
      if (!q) return true;
      return (
        String(p.partName || '')
          .toLowerCase()
          .includes(q) ||
        String(p.partCode || '')
          .toLowerCase()
          .includes(q) ||
        String(p.notes || '')
          .toLowerCase()
          .includes(q)
      );
    });
  }

  get pagedParts() {
    const start = this.partPage * this.partPageSize;
    return this.filteredParts.slice(start, start + this.partPageSize);
  }

  get partTotalPages() {
    return Math.max(1, Math.ceil(this.filteredParts.length / this.partPageSize));
  }

  get filteredPhotos() {
    const q = this.photoFilterText.trim().toLowerCase();
    return (this.photos || []).filter((p: any) => {
      const matchesQuery =
        !q ||
        String(p.description || '')
          .toLowerCase()
          .includes(q) ||
        String(p.photoType || '')
          .toLowerCase()
          .includes(q);
      const matchesType = !this.photoTypeFilter || p.photoType === this.photoTypeFilter;
      return matchesQuery && matchesType;
    });
  }

  get pagedPhotos() {
    const start = this.photoPage * this.photoPageSize;
    return this.filteredPhotos.slice(start, start + this.photoPageSize);
  }

  get photoTotalPages() {
    return Math.max(1, Math.ceil(this.filteredPhotos.length / this.photoPageSize));
  }

  addPart(): void {
    if (!this.wo?.id || !this.newPart.partId) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    this.woService
      .addPart(this.wo.id, {
        workOrderId: this.wo.id,
        partId: this.newPart.partId,
        quantity: this.newPart.quantity ?? 1,
        unitPrice: this.newPart.unitPrice ?? undefined,
        taskId: this.newPart.taskId ?? undefined,
        notes: this.newPart.notes?.trim() || undefined,
      })
      .subscribe({
        next: (res: any) => {
          this.actionLoading = false;
          this.wo = res?.data ?? res;
          this.ensurePaging();
          this.resetNewPart();
          this.partModalOpen = false;
          this.success = 'Part added successfully.';
        },
        error: () => {
          this.actionLoading = false;
          this.error = 'Failed to add part.';
        },
      });
  }

  deletePart(part: { id?: number | null }): void {
    if (!this.wo?.id || !part?.id) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    this.woService.deletePart(this.wo.id, part.id).subscribe({
      next: (res: any) => {
        this.actionLoading = false;
        this.wo = res?.data ?? res;
        this.ensurePaging();
        this.success = 'Part deleted successfully.';
      },
      error: () => {
        this.actionLoading = false;
        this.error = 'Failed to delete part.';
      },
    });
  }

  addPhoto(): void {
    if (!this.wo?.id) return;
    const hasFile = !!this.newPhoto.file;
    const url = this.newPhoto.photoUrl.trim();
    if (!hasFile && !url) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    const request$ = hasFile
      ? this.woService.uploadPhoto(
          this.wo.id,
          this.newPhoto.file as File,
          this.newPhoto.photoType,
          this.newPhoto.description?.trim() || undefined,
          this.newPhoto.taskId ?? undefined,
        )
      : this.woService.addPhoto(this.wo.id, {
          workOrderId: this.wo.id,
          photoUrl: url,
          photoType: this.newPhoto.photoType,
          description: this.newPhoto.description?.trim() || undefined,
          taskId: this.newPhoto.taskId ?? undefined,
        });

    request$.subscribe({
      next: (res: any) => {
        this.actionLoading = false;
        this.wo = res?.data ?? res;
        this.ensurePaging();
        this.resetNewPhoto();
        this.photoModalOpen = false;
        this.success = 'Photo added successfully.';
      },
      error: () => {
        this.actionLoading = false;
        this.error = 'Failed to add photo.';
      },
    });
  }

  deletePhoto(photo: { id?: number | null }): void {
    if (!this.wo?.id || !photo?.id) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    this.woService.deletePhoto(this.wo.id, photo.id).subscribe({
      next: (res: any) => {
        this.actionLoading = false;
        this.wo = res?.data ?? res;
        this.ensurePaging();
        this.success = 'Photo deleted successfully.';
      },
      error: () => {
        this.actionLoading = false;
        this.error = 'Failed to delete photo.';
      },
    });
  }

  startTask(task: { id?: number | null }): void {
    if (!this.wo?.id || !task?.id) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    this.woService.updateTask(this.wo.id, task.id, { status: 'IN_PROGRESS' }).subscribe({
      next: (res: any) => {
        this.actionLoading = false;
        this.wo = res?.data ?? res;
        this.ensurePaging();
        this.success = 'Task started.';
      },
      error: () => {
        this.actionLoading = false;
        this.error = 'Failed to start task.';
      },
    });
  }

  completeTask(task: { id?: number | null }): void {
    if (!this.wo?.id || !task?.id) return;
    this.actionLoading = true;
    this.error = '';
    this.success = '';
    this.woService.updateTask(this.wo.id, task.id, { status: 'COMPLETED' }).subscribe({
      next: (res: any) => {
        this.actionLoading = false;
        this.wo = res?.data ?? res;
        this.ensurePaging();
        this.success = 'Task completed.';
      },
      error: () => {
        this.actionLoading = false;
        this.error = 'Failed to complete task.';
      },
    });
  }

  resetNewTask(): void {
    this.newTask = {
      taskName: '',
      description: '',
      estimatedHours: null,
      notes: '',
      diagnosisResult: '',
      actionsTaken: '',
    };
  }

  resetNewPart(): void {
    this.newPart = {
      partId: null,
      quantity: 1,
      unitPrice: null,
      taskId: null,
      notes: '',
    };
  }

  resetNewPhoto(): void {
    this.newPhoto = {
      photoUrl: '',
      photoType: 'BEFORE',
      description: '',
      taskId: null,
      file: null,
    };
  }

  statusClass(status?: string | null): string {
    switch (status) {
      case 'COMPLETED':
        return 'bg-green-50 text-green-700 border-green-200';
      case 'IN_PROGRESS':
        return 'bg-blue-50 text-blue-700 border-blue-200';
      case 'WAITING_PARTS':
        return 'bg-yellow-50 text-yellow-700 border-yellow-200';
      case 'CANCELLED':
        return 'bg-red-50 text-red-700 border-red-200';
      case 'OPEN':
        return 'bg-gray-50 text-gray-700 border-gray-200';
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

  formatAmount(value?: number | string | null): string {
    if (value === null || value === undefined || value === '') return '-';
    const num = typeof value === 'string' ? Number(value) : value;
    if (Number.isNaN(num)) return String(value);
    return new Intl.NumberFormat('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(num);
  }

  get tasks() {
    return this.wo?.tasks ?? [];
  }

  get parts() {
    return this.wo?.parts ?? [];
  }

  get photos() {
    return this.wo?.photos ?? [];
  }

  private refreshWorkOrder(id: number): void {
    this.woService.getLegacy(id).subscribe({
      next: (res: any) => {
        this.wo = res?.data ?? res;
        this.ensurePaging();
        if (this.wo) {
          this.edit = {
            title: this.wo.title || '',
            description: this.wo.description || '',
            type: (this.wo.type as any) || 'REPAIR',
            repairType: (this.wo.repairType as any) || 'OWN',
            priority: (this.wo.priority as any) || 'NORMAL',
            scheduledDate: this.toLocalInput(this.wo.scheduledDate),
          };
        }
        if (this.wo?.maintenanceRequestId) {
          this.mrService.get(this.wo.maintenanceRequestId).subscribe({
            next: (mrRes) => (this.mr = mrRes?.data ?? null),
            error: () => {},
          });
        }
        this.loadInvoiceAttachments();
      },
      error: () => {
        this.error = 'Failed to load work order.';
      },
    });
  }

  private loadInvoiceAttachments(): void {
    if (!this.wo?.invoice?.id) {
      this.invoiceAttachments = [];
      return;
    }
    this.woService.listInvoiceAttachments(this.wo.invoice.id).subscribe({
      next: (res) => {
        this.invoiceAttachments = res?.data ?? [];
      },
      error: () => {
        this.invoiceAttachments = [];
      },
    });
  }

  onInvoiceAttachmentSelected(event: Event): void {
    const target = event.target as HTMLInputElement;
    if (target?.files && target.files.length > 0) {
      this.invoiceAttachmentFile = target.files[0];
    }
  }

  uploadInvoiceAttachment(): void {
    if (!this.wo?.invoice?.id || !this.invoiceAttachmentFile) return;
    this.invoiceAttachmentUploading = true;
    this.woService
      .uploadInvoiceAttachment(
        this.wo.invoice.id,
        this.invoiceAttachmentFile,
        this.invoiceAttachmentType,
      )
      .subscribe({
        next: () => {
          this.invoiceAttachmentUploading = false;
          this.invoiceAttachmentFile = null;
          this.loadInvoiceAttachments();
        },
        error: () => {
          this.invoiceAttachmentUploading = false;
        },
      });
  }

  deleteInvoiceAttachment(item: InvoiceAttachmentDto): void {
    if (!this.wo?.invoice?.id || !item?.id) return;
    this.invoiceAttachmentUploading = true;
    this.woService.deleteInvoiceAttachment(this.wo.invoice.id, item.id).subscribe({
      next: () => {
        this.invoiceAttachmentUploading = false;
        this.loadInvoiceAttachments();
      },
      error: () => {
        this.invoiceAttachmentUploading = false;
      },
    });
  }

  private toLocalInput(value?: string | null): string {
    if (!value) return '';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '';
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(
      date.getMinutes(),
    )}`;
  }

  private normalizeLocalDate(value: string): string | undefined {
    const trimmed = value?.trim();
    if (!trimmed) return undefined;
    // Ensure seconds for LocalDateTime parsing
    return trimmed.length === 16 ? `${trimmed}:00` : trimmed;
  }

  private ensurePaging(): void {
    this.taskPage = this.clampPage(this.taskPage, this.taskTotalPages);
    this.partPage = this.clampPage(this.partPage, this.partTotalPages);
    this.photoPage = this.clampPage(this.photoPage, this.photoTotalPages);
  }

  private clampPage(current: number, totalPages: number): number {
    const maxPage = Math.max(0, totalPages - 1);
    return Math.min(current, maxPage);
  }
}
