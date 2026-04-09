import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';

import { PmRunService, type PmRunDto } from '../../../services/pm-run.service';
import {
  MaintenanceWorkOrderService,
  type WorkOrderDto,
} from '../../../services/maintenance-work-order.service';

type TabKey = 'pm_due' | 'wo_assigned' | 'waiting_parts' | 'completed';

@Component({
  selector: 'app-pm-workshop-queue',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="p-6">
      <div class="mb-6 flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Workshop Queue</h1>
          <p class="text-gray-600">Fast execution for PM and WO</p>
        </div>
        <button
          class="px-3 py-2 border rounded-lg text-sm hover:bg-gray-50"
          type="button"
          (click)="load()"
        >
          Refresh
        </button>
      </div>

      <div class="flex flex-wrap gap-2 mb-4">
        <button
          class="px-3 py-2 rounded"
          [ngClass]="tabClass('pm_due')"
          (click)="activeTab = 'pm_due'"
        >
          PM Due ({{ pmDue.length }})
        </button>
        <button
          class="px-3 py-2 rounded"
          [ngClass]="tabClass('wo_assigned')"
          (click)="activeTab = 'wo_assigned'"
        >
          WO Assigned ({{ woAssigned.length }})
        </button>
        <button
          class="px-3 py-2 rounded"
          [ngClass]="tabClass('waiting_parts')"
          (click)="activeTab = 'waiting_parts'"
        >
          Waiting Parts ({{ woWaiting.length }})
        </button>
        <button
          class="px-3 py-2 rounded"
          [ngClass]="tabClass('completed')"
          (click)="activeTab = 'completed'"
        >
          Completed ({{ pmCompleted.length }})
        </button>
        <a
          class="ml-auto text-sm text-blue-600 hover:underline"
          routerLink="/fleet/maintenance/work-orders"
        >
          Open Work Orders
        </a>
      </div>

      <div *ngIf="activeTab === 'pm_due'">
        <div class="bg-white rounded-lg border p-4">
          <div *ngIf="pmDue.length === 0" class="text-sm text-gray-500">No PM due.</div>
          <div
            *ngFor="let run of pmDue"
            class="border rounded p-3 mb-2 flex items-center justify-between"
          >
            <div>
              <div class="font-medium">{{ run.itemName || run.planName }}</div>
              <div class="text-xs text-gray-500">{{ run.vehiclePlate }}</div>
            </div>
            <a
              class="text-blue-600 hover:underline"
              [routerLink]="['/fleet/maintenance/pm-runs', run.pmRunId]"
              >Start</a
            >
          </div>
        </div>
      </div>

      <div *ngIf="activeTab === 'wo_assigned'">
        <div class="bg-white rounded-lg border p-4">
          <div *ngIf="woAssigned.length === 0" class="text-sm text-gray-500">
            No assigned work orders.
          </div>
          <div
            *ngFor="let wo of woAssigned"
            class="border rounded p-3 mb-2 flex items-center justify-between"
          >
            <div>
              <div class="font-medium">{{ wo.title || wo.woNumber }}</div>
              <div class="text-xs text-gray-500">{{ wo.vehiclePlate || 'ID ' + wo.vehicleId }}</div>
            </div>
            <a
              class="text-blue-600 hover:underline"
              [routerLink]="['/fleet/maintenance/work-orders', wo.id]"
              >Open</a
            >
          </div>
        </div>
      </div>

      <div *ngIf="activeTab === 'waiting_parts'">
        <div class="bg-white rounded-lg border p-4">
          <div *ngIf="woWaiting.length === 0" class="text-sm text-gray-500">No waiting parts.</div>
          <div
            *ngFor="let wo of woWaiting"
            class="border rounded p-3 mb-2 flex items-center justify-between"
          >
            <div>
              <div class="font-medium">{{ wo.title || wo.woNumber }}</div>
              <div class="text-xs text-gray-500">{{ wo.vehiclePlate || 'ID ' + wo.vehicleId }}</div>
            </div>
            <a
              class="text-blue-600 hover:underline"
              [routerLink]="['/fleet/maintenance/work-orders', wo.id]"
              >Open</a
            >
          </div>
        </div>
      </div>

      <div *ngIf="activeTab === 'completed'">
        <div class="bg-white rounded-lg border p-4">
          <div *ngIf="pmCompleted.length === 0" class="text-sm text-gray-500">
            No completed runs.
          </div>
          <div *ngFor="let run of pmCompleted" class="border rounded p-3 mb-2">
            <div class="font-medium">{{ run.itemName || run.planName }}</div>
            <div class="text-xs text-gray-500">{{ run.vehiclePlate }}</div>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class PmWorkshopQueueComponent implements OnInit {
  activeTab: TabKey = 'pm_due';
  pmDue: PmRunDto[] = [];
  pmCompleted: PmRunDto[] = [];
  woAssigned: WorkOrderDto[] = [];
  woWaiting: WorkOrderDto[] = [];

  constructor(
    private readonly pmRunService: PmRunService,
    private readonly workOrderService: MaintenanceWorkOrderService,
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.pmRunService.list({ status: 'DUE', page: 0, size: 50 }).subscribe({
      next: (res) => (this.pmDue = res.data?.content || []),
    });
    this.pmRunService.list({ status: 'COMPLETED', page: 0, size: 50 }).subscribe({
      next: (res) => (this.pmCompleted = res.data?.content || []),
    });

    this.workOrderService.listLegacy({ status: 'IN_PROGRESS', page: 0, size: 50 }).subscribe({
      next: (res) => (this.woAssigned = res?.data?.content || res?.content || []),
    });
    this.workOrderService.listLegacy({ status: 'WAITING_PARTS', page: 0, size: 50 }).subscribe({
      next: (res) => (this.woWaiting = res?.data?.content || res?.content || []),
    });
  }

  tabClass(tab: TabKey): string {
    return this.activeTab === tab ? 'bg-gray-900 text-white' : 'bg-gray-100 text-gray-700';
  }
}
