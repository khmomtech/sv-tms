import { CommonModule } from '@angular/common';
import { Component, HostListener, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';

import type { PagedResponse } from '../../../models/api-response-page.model';
import { PartnerService } from '../../../services/partner.service';
import type { PartnerCompany } from '../../../models/partner.model';
import { MechanicService } from '../../../services/mechanic.service';
import type { MechanicDto } from '../../../services/mechanic.service';
import { MaintenanceRequestService } from '../../../services/maintenance-request.service';
import type { MaintenanceRequestDto } from '../../../services/maintenance-request.service';
import { VehicleService } from '../../../services/vehicle.service';
import type { Vehicle } from '../../../models/vehicle.model';
import { MaintenanceWorkOrderService } from '../../../services/maintenance-work-order.service';
import type {
  InvoiceDto,
  PaymentDto,
  RepairType,
  VendorQuotationDto,
  WorkOrderDto,
  WorkOrderStatus,
  WorkOrderType,
  Priority,
} from '../../../services/maintenance-work-order.service';
import { getWorkOrderStatusClass } from '../maintenance-status.utils';

@Component({
  selector: 'app-work-orders',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
            <i class="text-2xl text-blue-600 fas fa-clipboard-list"></i>
          </div>
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Work Orders</h1>
            <p class="text-gray-600">SV Standard flow: MR → WO with OWN / VENDOR</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <a
            routerLink="/admin/employees"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
            >Employees</a
          >
          <button
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            (click)="openCreateFromMr()"
            type="button"
          >
            <i class="fas fa-plus mr-2"></i>Create from MR
          </button>
        </div>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Open</div>
          <div class="text-xl font-bold text-indigo-700">{{ kpis.open }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">In Progress</div>
          <div class="text-xl font-bold text-blue-700">{{ kpis.inProgress }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Waiting Parts</div>
          <div class="text-xl font-bold text-amber-700">{{ kpis.waitingParts }}</div>
        </div>
        <div class="bg-white border rounded-lg p-3">
          <div class="text-xs text-gray-500">Completed</div>
          <div class="text-xl font-bold text-emerald-700">{{ kpis.completed }}</div>
        </div>
      </div>

      <div class="bg-white border rounded-lg shadow-sm mb-4">
        <div class="p-4 grid grid-cols-1 md:grid-cols-6 gap-3">
          <input
            class="px-3 py-2 border rounded-lg"
            [(ngModel)]="filters.search"
            (keyup.enter)="apply()"
            placeholder="Search WO #, MR #, plate, title"
          />
          <select class="px-3 py-2 border rounded-lg" [(ngModel)]="filters.status">
            <option value="">All Status</option>
            <option *ngFor="let s of statuses" [value]="s">{{ s }}</option>
          </select>
          <select class="px-3 py-2 border rounded-lg" [(ngModel)]="filters.type">
            <option value="">All Type</option>
            <option *ngFor="let t of types" [value]="t">{{ t }}</option>
          </select>
          <select class="px-3 py-2 border rounded-lg" [(ngModel)]="filters.priority">
            <option value="">All Priority</option>
            <option *ngFor="let p of priorities" [value]="p">{{ p }}</option>
          </select>
          <select class="px-3 py-2 border rounded-lg" [(ngModel)]="filters.vehicleId">
            <option value="">All Vehicles</option>
            <option *ngFor="let v of vehicles" [value]="v.id">{{ v.licensePlate }}</option>
          </select>
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
        Loading work orders...
      </div>

      <div class="bg-white border rounded-lg shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">WO #</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Vehicle</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Type</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Repair</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Status</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Planned</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">Actual</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-600">MR</th>
                <th class="px-4 py-3 text-right text-xs font-semibold text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let wo of filteredRows" class="border-t">
                <td class="px-4 py-3 text-sm font-medium text-gray-900">{{ wo.woNumber }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ wo.vehiclePlate }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ wo.type }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ wo.repairType || '-' }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  <span
                    class="px-2 py-1 text-xs rounded-full border font-semibold"
                    [ngClass]="getStatusClass(wo.status)"
                  >
                    {{ wo.status }}
                  </span>
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ formatDate(wo.scheduledDate) }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{{ formatDate(wo.completedAt) }}</td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ wo.maintenanceRequestNumber || '-' }}
                </td>
                <td class="px-4 py-3 text-right relative">
                  <button
                    class="px-3 py-1 mr-2 text-xs text-blue-700 border border-blue-200 rounded-lg hover:bg-blue-50"
                    (click)="openDetails(wo)"
                    type="button"
                  >
                    Open Details
                  </button>
                  <button
                    class="w-9 h-9 border rounded-lg hover:bg-gray-50 inline-flex items-center justify-center"
                    (click)="$event.stopPropagation(); toggleActionMenu(wo.id)"
                    type="button"
                    aria-label="Options"
                    [attr.aria-expanded]="actionMenuOpenId === wo.id"
                  >
                    <i class="fas fa-ellipsis-h"></i>
                    <span class="sr-only">Options</span>
                  </button>
                  <div
                    *ngIf="actionMenuOpenId === wo.id"
                    class="absolute right-0 mt-2 w-52 bg-white border rounded-lg shadow-lg z-20 text-left"
                    (click)="$event.stopPropagation()"
                  >
                    <button
                      class="w-full px-3 py-2 text-sm hover:bg-gray-50 flex items-center gap-2"
                      (click)="goToDetails(wo)"
                      type="button"
                    >
                      <i class="fas fa-external-link-alt text-xs"></i>
                      Open Details Page
                    </button>
                    <button
                      class="w-full px-3 py-2 text-sm hover:bg-gray-50 flex items-center gap-2"
                      (click)="openDetails(wo); closeActionMenu()"
                      type="button"
                    >
                      <i class="fas fa-eye text-xs"></i>
                      Quick View
                    </button>
                    <div class="my-1 border-t"></div>
                    <button
                      class="w-full px-3 py-2 text-sm hover:bg-gray-50 disabled:text-gray-400 flex items-center gap-2"
                      [disabled]="!wo.maintenanceRequestId"
                      (click)="goToMr(wo)"
                      type="button"
                    >
                      <i class="fas fa-file-alt text-xs"></i>
                      View MR
                    </button>
                    <button
                      class="w-full px-3 py-2 text-sm hover:bg-gray-50 disabled:text-gray-400 flex items-center gap-2"
                      [disabled]="!wo.vehicleId"
                      (click)="goToVehicle(wo)"
                      type="button"
                    >
                      <i class="fas fa-truck text-xs"></i>
                      View Vehicle
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
            Showing <span class="font-medium">{{ startItem }}</span> to
            <span class="font-medium">{{ endItem }}</span> of
            <span class="font-medium">{{ page?.totalElements || 0 }}</span>
          </div>
          <div class="flex items-center gap-2">
            <button
              class="px-3 py-1 border rounded"
              (click)="prev()"
              [disabled]="pageIndex <= 0 || isLoading"
              type="button"
            >
              Prev
            </button>
            <button
              class="px-3 py-1 border rounded"
              (click)="next()"
              [disabled]="(page && pageIndex >= (page.totalPages || 1) - 1) || isLoading"
              type="button"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      <!-- Create from MR modal -->
      <div
        *ngIf="createOpen"
        class="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50"
      >
        <div class="bg-white rounded-lg w-full max-w-2xl shadow-lg">
          <div class="px-5 py-4 border-b flex items-center justify-between">
            <h3 class="font-semibold text-gray-900">Create Work Order from Approved MR</h3>
            <button
              class="text-gray-500 hover:text-gray-700"
              (click)="createOpen = false"
              type="button"
            >
              <i class="fas fa-times"></i>
            </button>
          </div>
          <div
            *ngIf="createError"
            class="mx-5 mt-3 p-2 text-sm rounded border border-red-200 bg-red-50 text-red-700"
          >
            {{ createError }}
          </div>
          <div class="p-5 grid grid-cols-1 md:grid-cols-2 gap-3">
            <div class="md:col-span-2">
              <label class="block text-xs font-medium text-gray-700 mb-1"
                >Approved Maintenance Request</label
              >
              <select
                class="w-full px-3 py-2 border rounded-lg"
                [(ngModel)]="create.mrId"
                (change)="onMrSelectionChange()"
              >
                <option value="">Select MR</option>
                <option *ngFor="let mr of approvedMrs" [value]="mr.id">
                  {{ mr.mrNumber }} - {{ mr.vehiclePlate }} - {{ mr.title }}
                </option>
              </select>
              <div
                *ngIf="selectedMrForCreate"
                class="mt-2 p-2 text-xs border rounded bg-gray-50 text-gray-700"
              >
                {{ selectedMrForCreate.vehiclePlate }} · {{ selectedMrForCreate.requestType }} ·
                {{ selectedMrForCreate.priority }}
              </div>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Repair Type</label>
              <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="create.repairType">
                <option value="OWN">OWN</option>
                <option value="VENDOR">VENDOR</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Priority</label>
              <select class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="create.priority">
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
                [(ngModel)]="create.scheduledDate"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-xs font-medium text-gray-700 mb-1">Title</label>
              <input class="w-full px-3 py-2 border rounded-lg" [(ngModel)]="create.title" />
              <p *ngIf="createError && !create.title" class="mt-1 text-xs text-red-600">
                Title is required.
              </p>
            </div>
            <div class="md:col-span-2">
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
              class="px-4 py-2 bg-blue-600 text-white rounded-lg"
              (click)="submitCreateFromMr()"
              [disabled]="isCreateSubmitting"
              type="button"
            >
              {{ isCreateSubmitting ? 'Creating...' : 'Create Work Order' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Details modal -->
      <div
        *ngIf="detailsOpen"
        class="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50"
      >
        <div class="bg-white rounded-lg w-full max-w-4xl shadow-lg max-h-[90vh] overflow-auto">
          <div class="px-5 py-4 border-b flex items-center justify-between">
            <div>
              <h3 class="font-semibold text-gray-900">Work Order {{ selected?.woNumber }}</h3>
              <p class="text-sm text-gray-600">
                {{ selected?.vehiclePlate }} • {{ selected?.type }} •
                {{ selected?.repairType || '-' }} •
                {{ selected?.status }}
              </p>
            </div>
            <button
              class="text-gray-500 hover:text-gray-700"
              (click)="closeDetails()"
              type="button"
            >
              <i class="fas fa-times"></i>
            </button>
          </div>

          <div
            *ngIf="detailsLoading"
            class="p-5 text-sm text-blue-700 bg-blue-50 border-b border-blue-100"
          >
            Loading work order details...
          </div>
          <div class="p-5 space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="border rounded-lg p-4">
                <p class="text-xs font-semibold text-gray-600 mb-1">MR</p>
                <p class="text-sm text-gray-900">{{ selected?.maintenanceRequestNumber || '-' }}</p>
                <p class="text-xs text-gray-500 mt-2">{{ selected?.title }}</p>
                <p class="text-sm text-gray-700 mt-2 whitespace-pre-wrap">
                  {{ selected?.description }}
                </p>
              </div>

              <div class="border rounded-lg p-4">
                <p class="text-xs font-semibold text-gray-600 mb-1">Timeline</p>
                <div class="text-sm text-gray-700">
                  <div>
                    Planned date:
                    <span class="font-medium">{{ formatDate(selected?.scheduledDate) }}</span>
                  </div>
                  <div class="mt-1">
                    Actual completion:
                    <span class="font-medium">{{ formatDate(selected?.completedAt) }}</span>
                  </div>
                </div>
              </div>

              <div class="border rounded-lg p-4">
                <p class="text-xs font-semibold text-gray-600 mb-1">Vendor / Invoice</p>
                <div *ngIf="selected?.repairType === 'VENDOR'">
                  <div class="text-sm text-gray-700 mb-2">
                    Quotation:
                    <span class="font-medium">{{
                      selected?.vendorQuotation?.status || 'Not created'
                    }}</span>
                  </div>
                  <div class="text-sm text-gray-700 mb-2">
                    Invoice:
                    <span class="font-medium">{{
                      selected?.invoice?.paymentStatus || 'Not created'
                    }}</span>
                  </div>
                </div>
                <div *ngIf="selected?.repairType !== 'VENDOR'" class="text-sm text-gray-600">
                  OWN repair: no vendor invoice required.
                </div>
              </div>
            </div>

            <!-- OWN -->
            <div *ngIf="selected?.repairType === 'OWN'" class="border rounded-lg p-4">
              <div class="flex items-center justify-between mb-3">
                <h4 class="font-semibold text-gray-900">OWN Repair</h4>
                <button
                  class="px-3 py-1 bg-green-600 text-white rounded-lg"
                  (click)="saveMechanics()"
                  [disabled]="actionSaving"
                  type="button"
                >
                  Save Mechanics
                </button>
              </div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Assigned mechanics</label>
              <select
                class="w-full px-3 py-2 border rounded-lg"
                multiple
                [(ngModel)]="ownMechanicIds"
              >
                <option *ngFor="let m of mechanics" [value]="m.id">{{ m.fullName }}</option>
              </select>
              <p class="text-xs text-gray-500 mt-2">
                Parts usage is available via Work Order parts (existing module).
              </p>
            </div>

            <!-- VENDOR -->
            <div *ngIf="selected?.repairType === 'VENDOR'" class="border rounded-lg p-4 space-y-4">
              <h4 class="font-semibold text-gray-900">VENDOR Repair</h4>

              <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Vendor</label>
                  <select
                    class="w-full px-3 py-2 border rounded-lg"
                    [(ngModel)]="vendorQuote.vendorId"
                  >
                    <option value="">Select vendor</option>
                    <option *ngFor="let v of vendors" [value]="v.id">{{ v.companyName }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Quotation #</label>
                  <input
                    class="w-full px-3 py-2 border rounded-lg"
                    [(ngModel)]="vendorQuote.quotationNumber"
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Amount</label>
                  <input
                    class="w-full px-3 py-2 border rounded-lg"
                    [(ngModel)]="vendorQuote.amount"
                  />
                </div>
              </div>
              <div class="flex gap-2">
                <button
                  class="px-3 py-2 bg-blue-600 text-white rounded-lg"
                  (click)="saveQuotation()"
                  [disabled]="actionSaving"
                  type="button"
                >
                  Save Quotation
                </button>
                <button
                  class="px-3 py-2 bg-green-600 text-white rounded-lg"
                  (click)="approveQuotation()"
                  [disabled]="actionSaving"
                  type="button"
                >
                  Approve Quotation
                </button>
              </div>

              <div class="border-t pt-4">
                <h5 class="font-semibold text-gray-900 mb-2">Invoice</h5>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1"
                      >Invoice Date (YYYY-MM-DD)</label
                    >
                    <input
                      class="w-full px-3 py-2 border rounded-lg"
                      [(ngModel)]="invoice.invoiceDate"
                    />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Total Amount</label>
                    <input
                      class="w-full px-3 py-2 border rounded-lg"
                      [(ngModel)]="invoice.totalAmount"
                    />
                  </div>
                  <div class="flex items-end">
                    <button
                      class="px-3 py-2 bg-blue-600 text-white rounded-lg"
                      (click)="createInvoice()"
                      [disabled]="actionSaving"
                      type="button"
                    >
                      Create Invoice
                    </button>
                  </div>
                </div>

                <div class="mt-4 grid grid-cols-1 md:grid-cols-4 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1"
                      >Payment Amount</label
                    >
                    <input
                      class="w-full px-3 py-2 border rounded-lg"
                      [(ngModel)]="payment.amount"
                    />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Method</label>
                    <input
                      class="w-full px-3 py-2 border rounded-lg"
                      [(ngModel)]="payment.method"
                    />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Reference</label>
                    <input
                      class="w-full px-3 py-2 border rounded-lg"
                      [(ngModel)]="payment.referenceNo"
                    />
                  </div>
                  <div class="flex items-end">
                    <button
                      class="px-3 py-2 bg-green-600 text-white rounded-lg"
                      (click)="recordPayment()"
                      [disabled]="actionSaving"
                      type="button"
                    >
                      Record Payment
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="flex items-center justify-end gap-2">
              <button class="px-4 py-2 border rounded-lg" (click)="closeDetails()" type="button">
                Close
              </button>
              <button
                class="px-4 py-2 bg-green-600 text-white rounded-lg"
                (click)="complete()"
                [disabled]="actionSaving"
                type="button"
              >
                Complete Work Order
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class WorkOrdersComponent implements OnInit {
  error = '';
  isLoading = false;
  detailsLoading = false;
  actionSaving = false;
  isCreateSubmitting = false;
  createError = '';

  page: PagedResponse<WorkOrderDto> | null = null;
  pageIndex = 0;
  pageSize = 10;
  vehicles: Vehicle[] = [];

  statuses: WorkOrderStatus[] = ['OPEN', 'IN_PROGRESS', 'WAITING_PARTS', 'COMPLETED', 'CANCELLED'];
  types: WorkOrderType[] = ['PREVENTIVE', 'REPAIR', 'EMERGENCY', 'INSPECTION'];
  priorities: Priority[] = ['URGENT', 'HIGH', 'NORMAL', 'LOW'];

  filters: {
    search: string;
    status: '' | WorkOrderStatus;
    type: '' | WorkOrderType;
    priority: '' | Priority;
    vehicleId: number | '';
  } = {
    search: '',
    status: '',
    type: '',
    priority: '',
    vehicleId: '',
  };

  // Create
  createOpen = false;
  approvedMrs: MaintenanceRequestDto[] = [];
  create: {
    mrId: number | '';
    repairType: RepairType;
    priority: Priority;
    title: string;
    description: string;
    scheduledDate: string;
  } = {
    mrId: '',
    repairType: 'OWN',
    priority: 'NORMAL',
    title: '',
    description: '',
    scheduledDate: '',
  };

  // Details
  detailsOpen = false;
  selected: WorkOrderDto | null = null;
  actionMenuOpenId: number | null = null;

  mechanics: MechanicDto[] = [];
  ownMechanicIds: number[] = [];

  vendors: PartnerCompany[] = [];
  vendorQuote: VendorQuotationDto = { vendorId: 0 as any, quotationNumber: '', amount: '' };
  invoice: InvoiceDto = { invoiceDate: '', totalAmount: '' };
  payment: PaymentDto = { amount: '', method: '', referenceNo: '' };

  get filteredRows(): WorkOrderDto[] {
    const rows = this.page?.content || [];
    const q = this.filters.search.trim().toLowerCase();
    if (!q) return rows;
    return rows.filter((wo) => {
      const haystack = [wo.woNumber, wo.maintenanceRequestNumber, wo.vehiclePlate, wo.title]
        .map((v) => (v || '').toString().toLowerCase())
        .join(' ');
      return haystack.includes(q);
    });
  }

  get kpis(): { open: number; inProgress: number; waitingParts: number; completed: number } {
    const rows = this.page?.content || [];
    return {
      open: rows.filter((x) => x.status === 'OPEN').length,
      inProgress: rows.filter((x) => x.status === 'IN_PROGRESS').length,
      waitingParts: rows.filter((x) => x.status === 'WAITING_PARTS').length,
      completed: rows.filter((x) => x.status === 'COMPLETED').length,
    };
  }

  get startItem(): number {
    const total = this.page?.totalElements || 0;
    if (total === 0) return 0;
    return (this.page?.number || 0) * (this.page?.size || 0) + 1;
  }

  get endItem(): number {
    const total = this.page?.totalElements || 0;
    return Math.min(((this.page?.number || 0) + 1) * (this.page?.size || 0), total);
  }

  get selectedMrForCreate(): MaintenanceRequestDto | null {
    if (!this.create.mrId) return null;
    return this.approvedMrs.find((mr) => mr.id === Number(this.create.mrId)) || null;
  }

  constructor(
    private readonly woService: MaintenanceWorkOrderService,
    private readonly mrService: MaintenanceRequestService,
    private readonly mechanicService: MechanicService,
    private readonly partnerService: PartnerService,
    private readonly vehicleService: VehicleService,
    private readonly route: ActivatedRoute,
    private readonly router: Router,
  ) {}

  @HostListener('document:click')
  onDocumentClick(): void {
    this.closeActionMenu();
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    this.closeActionMenu();
  }

  ngOnInit(): void {
    this.vehicleService.getVehicles(0, 200, {}).subscribe({
      next: (res: any) => (this.vehicles = res?.data?.content ?? []),
      error: () => {},
    });
    this.route.queryParamMap.subscribe((params) => {
      const vehicleId = params.get('vehicleId');
      const status = params.get('status') as WorkOrderStatus | null;
      const type = params.get('type') as WorkOrderType | null;
      const openId = params.get('openId');
      if (vehicleId) this.filters.vehicleId = Number(vehicleId);
      if (status) this.filters.status = status;
      if (type) this.filters.type = type;
      this.load();
      if (openId) {
        const id = Number(openId);
        if (!Number.isNaN(id)) {
          this.openDetails({ id } as WorkOrderDto);
        }
      }
    });
  }

  load(): void {
    this.error = '';
    this.isLoading = true;
    this.woService
      .listLegacy({
        status: this.filters.status || undefined,
        type: this.filters.type || undefined,
        priority: this.filters.priority || undefined,
        vehicleId: (this.filters.vehicleId as any) || undefined,
        page: this.pageIndex,
        size: this.pageSize,
      })
      .subscribe({
        next: (res: any) => {
          this.page = res?.data ?? res; // legacy endpoints may not wrap
        },
        error: (err) => {
          console.error(err);
          this.error = 'Failed to load work orders.';
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
    this.filters = { search: '', status: '', type: '', priority: '', vehicleId: '' };
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

  openCreateFromMr(): void {
    this.createError = '';
    this.create = {
      mrId: '',
      repairType: 'OWN',
      priority: 'NORMAL',
      title: '',
      description: '',
      scheduledDate: '',
    };
    this.createOpen = true;
    this.mrService
      .list({ status: 'APPROVED', page: 0, size: 100 })
      .subscribe({ next: (res) => (this.approvedMrs = res.data.content || []), error: () => {} });
  }

  onMrSelectionChange(): void {
    const selectedMr = this.approvedMrs.find((mr) => mr.id === Number(this.create.mrId));
    if (!selectedMr) return;
    this.create.title = selectedMr.title || this.create.title;
    this.create.description = selectedMr.description || this.create.description;
    this.create.priority = (selectedMr.priority as any) || this.create.priority;
  }

  toggleActionMenu(id?: number): void {
    if (!id) return;
    this.actionMenuOpenId = this.actionMenuOpenId === id ? null : id;
  }

  closeActionMenu(): void {
    this.actionMenuOpenId = null;
  }

  goToDetails(wo: WorkOrderDto): void {
    if (!wo.id) return;
    this.closeActionMenu();
    this.router.navigate(['/fleet/maintenance/work-orders', wo.id], {
      queryParams: { group: 'overview' },
    });
  }

  goToMr(wo: WorkOrderDto): void {
    if (!wo.maintenanceRequestId) return;
    this.closeActionMenu();
    this.router.navigate(['/fleet/maintenance/requests', wo.maintenanceRequestId], {
      queryParams: { group: 'overview' },
    });
  }

  goToVehicle(wo: WorkOrderDto): void {
    if (!wo.vehicleId) return;
    this.closeActionMenu();
    this.router.navigate(['/fleet/vehicles', wo.vehicleId]);
  }

  submitCreateFromMr(): void {
    this.createError = '';
    if (!this.create.mrId) {
      this.createError = 'Select an approved MR.';
      return;
    }
    if (!this.create.title) {
      this.createError = 'Title is required.';
      return;
    }
    const selectedMr = this.approvedMrs.find((mr) => mr.id === Number(this.create.mrId));
    const dto: WorkOrderDto = {
      type: selectedMr?.requestType === 'PM' ? 'PREVENTIVE' : 'REPAIR',
      priority: this.create.priority,
      title: this.create.title,
      description: this.create.description,
      repairType: this.create.repairType,
      scheduledDate: this.create.scheduledDate || undefined,
    };
    this.isCreateSubmitting = true;
    this.woService.createFromMaintenanceRequest(Number(this.create.mrId), dto).subscribe({
      next: () => {
        this.createOpen = false;
        this.apply();
      },
      error: (err) => {
        console.error(err);
        this.error = 'Failed to create work order from MR.';
      },
      complete: () => {
        this.isCreateSubmitting = false;
      },
    });
  }

  openDetails(wo: WorkOrderDto): void {
    if (!wo.id) return;
    this.error = '';
    this.detailsOpen = true;
    this.selected = null;
    this.detailsLoading = true;

    this.mechanicService.list({ active: true, page: 0, size: 200 }).subscribe({
      next: (res) => (this.mechanics = res.data.content || []),
      error: () => {},
    });
    this.partnerService.getAllPartners().subscribe({
      next: (res: any) => (this.vendors = res?.data ?? res ?? []),
      error: () => {},
    });

    this.woService.getLegacy(wo.id).subscribe({
      next: (res: any) => {
        const dto: WorkOrderDto = res?.data ?? res;
        this.selected = dto;
        this.ownMechanicIds = [];
        this.vendorQuote = {
          vendorId: dto.vendorQuotation?.vendorId || (0 as any),
          quotationNumber: dto.vendorQuotation?.quotationNumber || '',
          amount: (dto.vendorQuotation as any)?.amount || '',
          notes: dto.vendorQuotation?.notes || '',
        };
        this.invoice = {
          invoiceDate: dto.invoice?.invoiceDate || '',
          totalAmount: (dto.invoice as any)?.totalAmount || '',
        };
        this.payment = { amount: '', method: '', referenceNo: '' };
      },
      error: (err) => {
        console.error(err);
        this.error = 'Failed to load work order details.';
      },
      complete: () => {
        this.detailsLoading = false;
      },
    });
  }

  closeDetails(): void {
    this.detailsOpen = false;
    this.selected = null;
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

  saveMechanics(): void {
    if (!this.selected?.id) return;
    this.actionSaving = true;
    this.woService.assignMechanics(this.selected.id, this.ownMechanicIds).subscribe({
      next: (res) => {
        this.selected = res.data;
      },
      error: () => (this.error = 'Failed to assign mechanics.'),
      complete: () => {
        this.actionSaving = false;
      },
    });
  }

  saveQuotation(): void {
    if (!this.selected?.id) return;
    if (!this.vendorQuote.vendorId) {
      this.error = 'Vendor is required.';
      return;
    }
    this.actionSaving = true;
    this.woService.upsertVendorQuotation(this.selected.id, this.vendorQuote).subscribe({
      next: (res) => {
        if (!this.selected) return;
        this.selected.vendorQuotation = res.data;
      },
      error: () => (this.error = 'Failed to save vendor quotation.'),
      complete: () => {
        this.actionSaving = false;
      },
    });
  }

  approveQuotation(): void {
    if (!this.selected?.id) return;
    this.actionSaving = true;
    this.woService.approveVendorQuotation(this.selected.id).subscribe({
      next: (res) => {
        if (!this.selected) return;
        this.selected.vendorQuotation = res.data;
      },
      error: () => (this.error = 'Failed to approve vendor quotation.'),
      complete: () => {
        this.actionSaving = false;
      },
    });
  }

  createInvoice(): void {
    if (!this.selected?.id) return;
    this.actionSaving = true;
    this.woService.createInvoice(this.selected.id, this.invoice).subscribe({
      next: (res) => {
        if (!this.selected) return;
        this.selected.invoice = res.data;
      },
      error: () => (this.error = 'Failed to create invoice.'),
      complete: () => {
        this.actionSaving = false;
      },
    });
  }

  recordPayment(): void {
    const invId = this.selected?.invoice?.id;
    if (!invId) {
      this.error = 'Create invoice first.';
      return;
    }
    if (!this.payment.amount) {
      this.error = 'Payment amount is required.';
      return;
    }
    this.actionSaving = true;
    this.woService.recordPayment(invId, this.payment).subscribe({
      next: () => {
        // reload details from backend for paymentStatus
        if (this.selected?.id) this.openDetails({ id: this.selected.id } as any);
      },
      error: () => (this.error = 'Failed to record payment.'),
      complete: () => {
        this.actionSaving = false;
      },
    });
  }

  complete(): void {
    if (!this.selected?.id) return;
    if (!window.confirm('Complete this work order now?')) return;
    this.actionSaving = true;
    this.woService.complete(this.selected.id).subscribe({
      next: (res) => {
        this.selected = res.data;
        this.apply();
      },
      error: (err) => {
        console.error(err);
        this.error = err?.error?.message || 'Failed to complete work order.';
      },
      complete: () => {
        this.actionSaving = false;
      },
    });
  }

  getStatusClass(status?: WorkOrderStatus): string {
    return getWorkOrderStatusClass(status);
  }
}
