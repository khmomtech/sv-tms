// @ts-nocheck
// Angular core & common
/* eslint-disable import/order */
/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, HostListener, type OnDestroy, type OnInit } from '@angular/core';
import {
  FormsModule,
  ReactiveFormsModule,
  Validators,
  FormBuilder,
  type FormGroup,
} from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
// @ts-ignore: IDE/TS server may not resolve workspace node_modules in editor
import { finalize, forkJoin } from 'rxjs';
// @ts-ignore: IDE/TS server may not resolve workspace node_modules in editor
import Swal from 'sweetalert2';

import { DispatchStatus } from '../../models/dispatch-status.enum';
import type { Dispatch } from '../../models/dispatch.model';
import type { Driver } from '../../models/driver.model';
import type { Vehicle } from '../../models/vehicle.model';
import type { TransportOrder } from '../../models/transport-order.model';
import type { LoadingQueue } from '../../models/loading-queue.model';
import type { LoadingSession } from '../../models/loading-session.model';
import {
  DispatchService,
  type DispatchActionMetadata,
  type DispatchStatusUpdateResponse,
} from '../../services/dispatch.service';
import { DriverService } from '../../services/driver.service';
import { VehicleService } from '../../services/vehicle.service';
import { ConfirmService } from '@services/confirm.service';
import { TransportOrderService } from '../../services/transport-order.service';
import { LoadingOpsService } from '../../services/loading-ops.service';
import { SafetyCheckService } from '../../services/safety-check.service';
import { AssignDriverModalComponent } from '../assign-driver-modal/assign-driver-modal.component';
import { AssignTruckModalComponent } from '../assign-truck-modal/assign-truck-modal.component';
import { ChangeDriverModalComponent } from '../change-driver-modal/change-driver-modal.component';
import { SvSafeDatePipe } from '../../pipes/sv-safe-date.pipe';
import { SafetyChecklistComponent } from '../safety-checklist/safety-checklist.component';

@Component({
  selector: 'app-dispatch-list',
  templateUrl: './dispatch-list.component.html',
  styleUrls: ['./dispatch-list.component.css'],
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterModule,
    ChangeDriverModalComponent,
    AssignDriverModalComponent,
    AssignTruckModalComponent,
    SvSafeDatePipe,
    SafetyChecklistComponent,
  ],
})
export class DispatchListComponent implements OnInit, OnDestroy {
  // ==== enum export for template ====
  DispatchStatus = DispatchStatus;

  // ==== data ====
  dispatches: Dispatch[] = [];
  filteredDispatches: Dispatch[] = [];
  drivers: Driver[] = [];
  vehicles: Vehicle[] = [];
  transportOrders: TransportOrder[] = [];

  // ==== filters (existing) ====
  searchQuery = '';
  mySelectedDriver = '';
  searchRouteCode = '';
  selectedDriver: Driver | null = null;
  selectedStatus: DispatchStatus | '' = '';
  startDate = '';
  endDate = '';

  // ==== new filters ====
  customerName = '';
  destinationTo = '';
  truckPlate = '';
  tripNo = '';

  // ==== ui state ====
  dispatchForm!: FormGroup;
  isModalOpen = false;
  isEditing = false;
  selectedDispatch: Dispatch | null = null;
  dropdownOpen: number | null = null;

  // ==== load/unload proofs ====
  selectedDispatchForLoadProof: any = null;
  loadProofImages: string[] = [];
  loadProofRemarks = '';
  selectedLoadImages: File[] = [];
  selectedSignature: File | null = null;
  loadProofSignature = '';

  selectedDispatchForUnloadProof: any = null;
  unloadProofRemarks = '';
  unloadProofImages: string[] = [];
  unloadProofImageFiles: File[] = [];
  unloadProofSignature: string | null = null;
  unloadProofSignatureFile: File | null = null;
  unloadAddress = '';
  unloadLatitude: number | null = null;
  unloadLongitude: number | null = null;

  // ==== driver/truck changes ====
  selectedDispatchForDriverChange: any = null;
  selectedDispatchForTruckChange: any = null;
  selectedDispatchForDriverAssign: any | null = null;
  selectedDispatchForTruckAssign: any | null = null;
  selectedNewVehicleId: number | null = null;

  // ==== safety & loading ====
  safetyChecklistDispatch: Dispatch | null = null;

  queueModalDispatch: Dispatch | null = null;
  queueWarehouse: 'KHB' | 'W2' | 'W3' = 'KHB';
  queueRemarks = '';
  queueBusy = false;

  loadingModalDispatch: Dispatch | null = null;
  loadingWarehouse: 'KHB' | 'W2' | 'W3' = 'KHB';
  loadingBay = '';
  loadingBusy = false;
  activeQueue?: LoadingQueue | null;
  activeSession?: LoadingSession | null;

  // ---- pagination state ----
  pageIndex = 0; // 0-based
  pageSize = 20;
  pageSizes = [10, 20, 50, 100];
  totalElements = 0;
  totalPages = 1;
  loading = false;

  // ---- bulk selection state ----
  selectedIds = new Set<number>();
  bulkBusy = false;
  private filterDebounceTimer: ReturnType<typeof setTimeout> | null = null;
  flowActionByDispatchId: Record<
    number,
    {
      loading: boolean;
      label: string;
      targetStatus?: string;
      disabled: boolean;
      reason?: string | null;
      buttonColor?: string;
    }
  > = {};

  Math = Math;

  constructor(
    private dispatchService: DispatchService,
    private driverService: DriverService,
    private vehicleService: VehicleService,
    private transportOrderService: TransportOrderService,
    private loadingOpsService: LoadingOpsService,
    private safetyCheckService: SafetyCheckService,
    private toastr: ToastrService,
    private fb: FormBuilder,
    private confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.fetchDrivers();
    this.fetchVehicles();
    this.fetchTransportOrders();
    this.initializeForm();
    this.loadPage(0); // initial load using paging
  }

  ngOnDestroy(): void {
    if (this.filterDebounceTimer) {
      clearTimeout(this.filterDebounceTimer);
      this.filterDebounceTimer = null;
    }
  }

  // ====== filters trigger ======
  onFilterChange(): void {
    if (this.filterDebounceTimer) {
      clearTimeout(this.filterDebounceTimer);
    }
    this.filterDebounceTimer = setTimeout(() => {
      this.loadPage(0); // server-side filtering only
    }, 350);
  }

  // Get driver name from ID
  getDriverName(driverId: number | undefined | null): string {
    if (!driverId) return 'Not assigned';
    const driver = this.drivers.find((d) => d.id === driverId);
    return driver ? driver.name : `Driver #${driverId}`;
  }

  formatDispatchStatus(status: string | null | undefined): string {
    if (!status) return '-';
    return String(status)
      .replace(/_/g, ' ')
      .toLowerCase()
      .replace(/\b\w/g, (ch) => ch.toUpperCase());
  }

  // Get vehicle license plate from ID
  getVehicleLicensePlate(vehicleId: number | undefined | null): string {
    if (!vehicleId) return 'Not assigned';
    const vehicle = this.vehicles.find((v) => v.id === vehicleId);
    return vehicle ? vehicle.licensePlate : `Vehicle #${vehicleId}`;
  }

  initializeForm(): void {
    this.dispatchForm = this.fb.group({
      id: [null],
      routeCode: [''],
      startTime: ['', Validators.required],
      estimatedArrival: ['', Validators.required],
      status: ['PENDING', Validators.required],
      transportOrderId: ['', Validators.required],
      driverId: ['', Validators.required],
      vehicleId: ['', Validators.required],
    });
    this.applyDefaultTimes();
  }

  // ========== PAGING ==========
  loadPage(index: number): void {
    if (index < 0) index = 0;
    this.pageIndex = index;
    this.loading = true;

    const start = this.startDate ? `${this.startDate}T00:00:00` : undefined;
    const end = this.endDate ? `${this.endDate}T23:59:59` : undefined;

    const driverName = (this.mySelectedDriver ?? '').trim() || undefined;
    const routeCode = (this.searchRouteCode ?? '').trim() || undefined;
    const qInput = (this.searchQuery ?? '').trim() || undefined;
    const status = this.selectedStatus || undefined;

    // New fields folded into q (so no service type changes are required)
    const customerName = (this.customerName ?? '').trim() || undefined;
    const toLocation = (this.destinationTo ?? '').trim() || undefined;
    const truckPlate = (this.truckPlate ?? '').trim() || undefined;
    const tripNo = (this.tripNo ?? '').trim() || undefined;

    // Expand free-text query with new filters so backend can match them with `q`
    const qExpanded =
      [qInput, customerName, toLocation, truckPlate, tripNo].filter(Boolean).join(' ') || undefined;

    const hasFilter = !!(driverName || status || routeCode || start || end || qExpanded);

    const obs = hasFilter
      ? this.dispatchService.filterDispatches({
          driverName,
          status,
          routeCode,
          customerName,
          toLocation,
          truckPlate,
          tripNo,
          q: qExpanded,
          start,
          end,
          page: this.pageIndex,
          size: this.pageSize,
        })
      : this.dispatchService.getAllDispatches(this.pageIndex, this.pageSize);

    obs.pipe(finalize(() => (this.loading = false))).subscribe({
      next: (res: any) => {
        const payload = res?.data ?? res;

        let content: any[] = [];
        let totalElements = 0;
        let totalPages = 1;

        if (payload?.content && Array.isArray(payload.content)) {
          content = payload.content;
          totalElements =
            typeof payload.totalElements === 'number' ? payload.totalElements : content.length;
          totalPages =
            typeof payload.totalPages === 'number'
              ? payload.totalPages
              : Math.max(1, Math.ceil(totalElements / this.pageSize));
        } else if (Array.isArray(payload?.content)) {
          content = payload.content;
          totalElements = content.length;
          totalPages = Math.max(1, Math.ceil(totalElements / this.pageSize));
        } else if (Array.isArray(payload)) {
          content = payload;
          totalElements = content.length;
          totalPages = Math.max(1, Math.ceil(totalElements / this.pageSize));
        } else {
          content = [];
          totalElements = 0;
          totalPages = 1;
        }

        this.filteredDispatches = content.map((d) => {
          const from =
            d.from || (d.transportOrder?.stops?.find((s: any) => s?.type === 'PICKUP') ?? null);
          const to =
            d.to || (d.transportOrder?.stops?.find((s: any) => s?.type === 'DROP') ?? null);

          const delivery =
            d.deliveryDate ||
            d.estimatedArrival ||
            d.expectedDelivery ||
            d.transportOrder?.deliveryDate ||
            null;

          return {
            ...d,
            from,
            to,
            deliveryDate: delivery,
            transportOrder: d.transportOrder
              ? {
                  ...d.transportOrder,
                  stops: Array.isArray(d.transportOrder.stops) ? d.transportOrder.stops : [],
                }
              : { stops: [] },
          };
        });
        this.dispatches = [...this.filteredDispatches];
        this.totalElements = totalElements;
        this.totalPages = totalPages;

        // keep selection state in sync with current page
        this.syncSelectionWithPage();
        this.loadFlowActionsForCurrentPage(this.filteredDispatches);
      },
      error: (err: any) => {
        console.error('Error fetching (paged):', err);
        this.toastr.error('Failed to load dispatches');
      },
    });
  }

  onPageSizeChange(size: number | string): void {
    this.pageSize = Number(size) || 20;
    this.loadPage(0);
  }
  firstPage(): void {
    if (this.pageIndex > 0) this.loadPage(0);
  }
  prevPage(): void {
    if (this.pageIndex > 0) this.loadPage(this.pageIndex - 1);
  }
  nextPage(): void {
    if (this.pageIndex + 1 < this.totalPages) this.loadPage(this.pageIndex + 1);
  }
  lastPage(): void {
    if (this.pageIndex + 1 < this.totalPages) this.loadPage(this.totalPages - 1);
  }

  // ========== EXISTING HOOKS ==========
  refreshDispatches(): void {
    this.loadPage(this.pageIndex);
  }

  private preSafetyStatuses = [
    DispatchStatus.PENDING,
    DispatchStatus.ASSIGNED,
    DispatchStatus.SCHEDULED,
    DispatchStatus.ARRIVED_LOADING,
    // allow reassignments after safety check has passed
    DispatchStatus.SAFETY_PASSED,
  ];

  canReassign(dispatch: Dispatch): boolean {
    return this.preSafetyStatuses.includes(dispatch.status);
  }

  canAddToQueue(dispatch: Dispatch): boolean {
    return dispatch.status === DispatchStatus.ARRIVED_LOADING;
  }

  canStartLoading(dispatch: Dispatch): boolean {
    return dispatch.status === DispatchStatus.IN_QUEUE;
  }

  filterDispatches(): void {
    if (this.filterDebounceTimer) {
      clearTimeout(this.filterDebounceTimer);
      this.filterDebounceTimer = null;
    }
    this.loadPage(0);
  }

  resetFilters(): void {
    this.selectedStatus = '';
    this.startDate = '';
    this.endDate = '';
    this.selectedDriver = null;
    this.mySelectedDriver = '';
    this.searchQuery = '';
    this.searchRouteCode = '';

    // clear new fields
    this.customerName = '';
    this.destinationTo = '';
    this.truckPlate = '';
    this.tripNo = '';

    this.loadPage(0);
  }

  get activeFilterCount(): number {
    const filterValues = [
      this.selectedStatus,
      this.mySelectedDriver,
      this.searchRouteCode,
      this.searchQuery,
      this.customerName,
      this.destinationTo,
      this.truckPlate,
      this.tripNo,
      this.startDate,
      this.endDate,
    ];
    return filterValues.filter((v) => !!String(v ?? '').trim()).length;
  }

  applyDatePreset(preset: 'TODAY' | 'LAST_7_DAYS' | 'LAST_30_DAYS' | 'CLEAR'): void {
    const today = new Date();
    const toYmd = (d: Date) => d.toISOString().slice(0, 10);

    if (preset === 'CLEAR') {
      this.startDate = '';
      this.endDate = '';
      this.onFilterChange();
      return;
    }

    const from = new Date(today);
    if (preset === 'LAST_7_DAYS') {
      from.setDate(today.getDate() - 6);
    } else if (preset === 'LAST_30_DAYS') {
      from.setDate(today.getDate() - 29);
    }

    this.startDate = toYmd(from);
    this.endDate = toYmd(today);
    this.onFilterChange();
  }

  getFlowStageLabel(dispatch: Dispatch): string {
    switch (dispatch.status) {
      case DispatchStatus.ASSIGNED:
        return 'Awaiting Driver Confirm';
      case DispatchStatus.DRIVER_CONFIRMED:
        return 'Awaiting Arrival';
      case DispatchStatus.ARRIVED_LOADING:
        return 'Awaiting Safety / Queue';
      case DispatchStatus.IN_QUEUE:
        return 'Queued';
      case DispatchStatus.LOADING:
        return 'Loading';
      case DispatchStatus.LOADED:
        return 'Loaded';
      default:
        return 'In Progress';
    }
  }

  getFlowStageClass(dispatch: Dispatch): string {
    switch (dispatch.status) {
      case DispatchStatus.ASSIGNED:
      case DispatchStatus.DRIVER_CONFIRMED:
        return 'bg-amber-100 text-amber-800';
      case DispatchStatus.ARRIVED_LOADING:
        return 'bg-orange-100 text-orange-800';
      case DispatchStatus.IN_QUEUE:
        return 'bg-indigo-100 text-indigo-800';
      case DispatchStatus.LOADING:
        return 'bg-blue-100 text-blue-800';
      case DispatchStatus.LOADED:
        return 'bg-emerald-100 text-emerald-800';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  }

  private loadFlowActionsForCurrentPage(rows: Dispatch[]): void {
    const ids = (rows || []).map((r) => r.id).filter((id): id is number => typeof id === 'number');
    if (!ids.length) return;

    const requests = ids.map((id) =>
      this.dispatchService.getAvailableActions(id).pipe(
        finalize(() => {
          const existing = this.flowActionByDispatchId[id];
          if (existing) {
            this.flowActionByDispatchId[id] = { ...existing, loading: false };
          }
        }),
      ),
    );

    ids.forEach((id) => {
      this.flowActionByDispatchId[id] = {
        loading: true,
        label: 'Loading...',
        disabled: true,
      };
    });

    forkJoin(requests).subscribe({
      next: (responses) => {
        responses.forEach((res, idx) => {
          const id = ids[idx];
          const payload = (res?.data || null) as DispatchStatusUpdateResponse | null;
          const action = this.pickPrimaryFlowAction(payload);
          if (!action) {
            this.flowActionByDispatchId[id] = {
              loading: false,
              label: 'No next action',
              disabled: true,
              reason: payload?.actionRestrictionMessage || null,
            };
            return;
          }

          const disabled =
            !!action.requiresAdminApproval ||
            !!(action.validationMessage && action.validationMessage.trim().length > 0);

          this.flowActionByDispatchId[id] = {
            loading: false,
            label: this.resolveActionLabel(action.actionLabel),
            targetStatus: action.targetStatus,
            disabled,
            reason: action.validationMessage || null,
            buttonColor: action.buttonColor || '#2563EB',
          };
        });
      },
      error: (err) => {
        console.error('Unable to load flow actions', err);
      },
    });
  }

  private pickPrimaryFlowAction(
    payload: DispatchStatusUpdateResponse | null,
  ): DispatchActionMetadata | null {
    const actions = [...(payload?.availableActions || [])];
    if (!actions.length) return null;

    actions.sort((a, b) => (a.priority ?? 999) - (b.priority ?? 999));
    const preferredTargets = [
      DispatchStatus.DRIVER_CONFIRMED,
      DispatchStatus.ARRIVED_LOADING,
      DispatchStatus.IN_QUEUE,
      DispatchStatus.LOADING,
      DispatchStatus.LOADED,
    ];
    const preferred = actions.find(
      (a) =>
        preferredTargets.includes((a.targetStatus || '') as DispatchStatus) && !a.isDestructive,
    );
    if (preferred) return preferred;
    return actions.find((a) => !a.isDestructive) || actions[0];
  }

  private resolveActionLabel(raw?: string | null): string {
    const label = (raw || '').trim();
    if (!label) return 'Next Action';

    const shortKey = label.replace(/^dispatch\.action\./, '').replace(/^action\./, '');

    const map: Record<string, string> = {
      confirm_pickup: 'Confirm Pickup',
      arrive_at_loading: 'Arrive At Loading',
      get_ticket: 'Get Ticket',
      enter_queue: 'Add To Queue',
      start_loading: 'Start Loading',
      finish_loading: 'Mark Loaded',
      depart_for_delivery: 'Depart For Delivery',
    };

    return map[shortKey] || shortKey.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  }

  private resolveWarehouseCode(dispatch: Dispatch): 'KHB' | 'W2' | 'W3' {
    const candidate =
      (dispatch as any)?.warehouseCode ||
      (dispatch as any)?.warehouse ||
      (dispatch as any)?.transportOrder?.warehouseCode ||
      (dispatch as any)?.transportOrder?.warehouse ||
      (dispatch as any)?.transportOrder?.items?.[0]?.warehouse ||
      (dispatch as any)?.items?.[0]?.warehouse;

    const normalized = String(candidate || '')
      .trim()
      .toUpperCase();
    if (normalized === 'W2' || normalized === 'W3') {
      return normalized;
    }
    return 'KHB';
  }

  onFlowActionClick(dispatch: Dispatch): void {
    if (!dispatch?.id) return;
    const action = this.flowActionByDispatchId[dispatch.id];
    if (!action || action.disabled || !action.targetStatus) return;

    if (action.targetStatus === DispatchStatus.IN_QUEUE) {
      this.openQueueModal(dispatch);
      return;
    }
    if (action.targetStatus === DispatchStatus.LOADING) {
      this.openStartLoading(dispatch);
      return;
    }

    this.dispatchService.updateDispatchStatus(dispatch.id, action.targetStatus).subscribe({
      next: () => {
        this.toastr.success(`Dispatch updated to ${action.targetStatus}.`);
        this.refreshDispatches();
      },
      error: (err) => {
        console.error('Flow action failed', err);
        this.toastr.error(err?.error?.message || 'Unable to update dispatch stage');
      },
    });
  }

  safetyStatus(dispatch: Dispatch): 'PASSED' | 'FAILED' | 'PENDING' {
    if (dispatch.status === DispatchStatus.SAFETY_FAILED) return 'FAILED';
    if (
      dispatch.status === DispatchStatus.SAFETY_PASSED ||
      dispatch.status === DispatchStatus.IN_QUEUE ||
      dispatch.status === DispatchStatus.ARRIVED_LOADING ||
      dispatch.status === DispatchStatus.LOADING ||
      dispatch.status === DispatchStatus.LOADED ||
      dispatch.status === DispatchStatus.IN_TRANSIT ||
      dispatch.status === DispatchStatus.ARRIVED_UNLOADING ||
      dispatch.status === DispatchStatus.UNLOADING ||
      dispatch.status === DispatchStatus.UNLOADED ||
      dispatch.status === DispatchStatus.DELIVERED ||
      dispatch.status === DispatchStatus.COMPLETED
    ) {
      return 'PASSED';
    }
    return 'PENDING';
  }

  openSafetyChecklist(dispatch: Dispatch): void {
    this.safetyChecklistDispatch = dispatch;
  }

  onSafetySaved(): void {
    this.safetyChecklistDispatch = null;
    this.refreshDispatches();
  }

  downloadSafetyPdf(dispatch: Dispatch): void {
    if (!dispatch.id) return;
    this.safetyCheckService.downloadPdf(dispatch.id).subscribe({
      next: (blob: any) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `safety-check-${dispatch.id}.pdf`;
        a.click();
        window.URL.revokeObjectURL(url);
      },
      error: (err: any) => {
        console.error(err);
        this.toastr.error(err?.error?.message || 'Unable to download safety checklist');
      },
    });
  }

  openQueueModal(dispatch: Dispatch): void {
    if (!this.canAddToQueue(dispatch)) {
      this.toastr.error('Dispatch must be ARRIVED_LOADING before adding to queue.');
      return;
    }
    this.queueModalDispatch = dispatch;
    this.queueWarehouse = this.resolveWarehouseCode(dispatch);
    this.queueRemarks = '';
  }

  submitQueue(): void {
    if (!this.queueModalDispatch?.id) return;
    this.queueBusy = true;
    this.loadingOpsService
      .enqueue({
        dispatchId: this.queueModalDispatch.id,
        warehouseCode: this.queueWarehouse,
        remarks: this.queueRemarks || null,
      })
      .pipe(finalize(() => (this.queueBusy = false)))
      .subscribe({
        next: () => {
          this.toastr.success('Dispatch added to queue.');
          this.queueModalDispatch = null;
          this.refreshDispatches();
        },
        error: (err: any) => {
          console.error('Queue error', err);
          this.toastr.error(err?.error?.message || 'Unable to add to queue');
        },
      });
  }

  openStartLoading(dispatch: Dispatch): void {
    if (!this.canStartLoading(dispatch)) {
      this.toastr.error('Dispatch must be IN_QUEUE before starting loading.');
      return;
    }
    this.loadingModalDispatch = dispatch;
    this.loadingWarehouse = this.resolveWarehouseCode(dispatch);
    this.loadingBay = '';
  }

  submitStartLoading(): void {
    if (!this.loadingModalDispatch?.id) return;
    this.loadingBusy = true;
    this.loadingOpsService
      .startLoading({
        dispatchId: this.loadingModalDispatch.id,
        warehouseCode: this.loadingWarehouse,
        bay: this.loadingBay || null,
      })
      .pipe(finalize(() => (this.loadingBusy = false)))
      .subscribe({
        next: () => {
          this.toastr.success('Loading started.');
          this.loadingModalDispatch = null;
          this.refreshDispatches();
        },
        error: (err: any) => {
          console.error('Start loading failed', err);
          this.toastr.error(err?.error?.message || 'Unable to start loading');
        },
      });
  }

  // ========== ORIGINAL FETCHES (not used by table anymore) ==========
  fetchDispatches(): void {
    this.dispatchService.getAllDispatches(0, 50).subscribe({
      next: (response: any) => {
        this.dispatches = response.data?.content ?? [];
        this.filteredDispatches = this.dispatches;
      },
      error: (err: any) => console.error(' Error fetching dispatches:', err),
    });
  }

  fetchDrivers(): void {
    this.driverService.getAllDrivers().subscribe({
      next: (response: any) => {
        this.drivers = response.data?.content || [];
      },
      error: (err: any) => console.error(' Error fetching drivers:', err),
    });
  }

  fetchVehicles(): void {
    this.vehicleService.getAllVehicles().subscribe({
      next: (response: any) => {
        this.vehicles = response.data;
      },
      error: (err: any) => console.error(' Error fetching vehicles:', err),
    });
  }

  fetchTransportOrders(): void {
    this.transportOrderService.getOrders().subscribe({
      next: (response: any) => {
        this.transportOrders = response.data?.content ?? [];
      },
      error: (err: any) => console.error(' Error fetching transport orders:', err),
    });
  }

  // ========== MODAL + CRUD ==========
  openModal(dispatch?: Dispatch): void {
    this.isEditing = !!dispatch;
    this.selectedDispatch = dispatch || null;

    if (dispatch) {
      this.dispatchForm.patchValue({
        id: dispatch.id,
        routeCode: dispatch.routeCode,
        startTime: this.formatDatetime(dispatch.startTime),
        estimatedArrival: this.formatDatetime(dispatch.estimatedArrival),
        status: dispatch.status,
        transportOrderId: dispatch.transportOrderId,
        driverId: dispatch.driverId,
        vehicleId: dispatch.vehicleId,
      });
    } else {
      this.dispatchForm.reset();
      this.applyDefaultTimes();
      this.dispatchForm.patchValue({ status: 'PENDING' });
    }

    this.isModalOpen = true;
  }

  closeModal(): void {
    this.isModalOpen = false;
    this.selectedDispatch = null;
  }

  formatDatetime(datetime: string | Date): string {
    if (!datetime) return '';
    const date = typeof datetime === 'string' ? new Date(datetime) : datetime;
    return date.toISOString().substring(0, 16);
  }

  submitForm(): void {
    if (this.dispatchForm.valid) {
      if (this.isEditing) {
        this.dispatchService
          .updateDispatch(this.dispatchForm.value.id, this.dispatchForm.value)
          .subscribe(() => {
            this.handleSuccess('Dispatch updated successfully.');
          });
      } else {
        this.dispatchService.createDispatch(this.dispatchForm.value).subscribe({
          next: () => {
            this.handleSuccess('Dispatch created successfully.');
          },
          error: (error: any) => {
            const message =
              error?.error?.message ||
              error?.message ||
              'Unable to create dispatch. Please check the form and try again.';
            if (error?.status === 409) {
              Swal.fire({
                icon: 'warning',
                title: 'មិនអាចចាប់ផ្តើម Trip បានទេ',
                text: message,
                confirmButtonText: 'យល់ព្រម',
              });
              return;
            }
            this.toastr.error(message, 'Create Dispatch');
          },
        });
      }
    }
  }

  async deleteDispatch(id: number): Promise<void> {
    if (await this.confirm.confirm('Are you sure you want to delete this dispatch?')) {
      this.dispatchService.deleteDispatch(id).subscribe(() => {
        this.toastr.success('Dispatch deleted successfully.');
        const lastOnPage = this.filteredDispatches.length === 1 && this.pageIndex > 0;
        this.loadPage(lastOnPage ? this.pageIndex - 1 : this.pageIndex);
      });
    }
  }

  handleSuccess(message: string): void {
    console.log(message);
    this.toastr.success(message);
    this.loadPage(this.pageIndex);
    this.closeModal();
  }

  toggleActionMenu(dispatch: any): void {
    this.filteredDispatches.forEach((d) => {
      if (d !== dispatch) d.showMenu = false;
    });
    dispatch.showMenu = !dispatch.showMenu;
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    const clickedInsideActionMenu = target.closest('.dispatch-action-menu');
    if (clickedInsideActionMenu) return;
    this.filteredDispatches.forEach((d) => (d.showMenu = false));
  }

  // ===== load proof =====
  markAsLoaded(dispatch: any): void {
    this.selectedDispatchForLoadProof = dispatch;
  }

  handleLoadImages(event: any): void {
    const files = event.target.files;
    this.loadProofImages = [];
    this.selectedLoadImages = [];

    for (let file of files) {
      this.selectedLoadImages.push(file);
      const reader = new FileReader();
      reader.onload = (e: any) => {
        this.loadProofImages.push(e.target.result);
      };
      reader.readAsDataURL(file);
    }
  }

  handleSignature(event: any): void {
    const file = event.target.files[0];
    this.selectedSignature = file;

    if (file) {
      const reader = new FileReader();
      reader.onload = (e: any) => {
        this.loadProofSignature = e.target.result;
      };
      reader.readAsDataURL(file);
    }
  }

  submitLoadProof(): void {
    this.dispatchService
      .submitLoadProof(
        this.selectedDispatchForLoadProof.id,
        this.loadProofRemarks,
        this.selectedLoadImages,
        this.selectedSignature ?? undefined,
      )
      .subscribe({
        next: () => {
          this.toastr.success('Load proof submitted!');
          this.cancelLoadProof();
          this.refreshDispatches?.();
        },
        error: () => this.toastr.error('Failed to submit load proof.'),
      });
  }

  cancelLoadProof(): void {
    this.selectedDispatchForLoadProof = null;
    this.loadProofImages = [];
    this.selectedLoadImages = [];
    this.selectedSignature = null;
    this.loadProofSignature = '';
    this.loadProofRemarks = '';
  }

  // ===== unload proof =====
  markAsDelivered(dispatch: any): void {
    this.dispatchService.markAsDelivered(dispatch.id).subscribe({
      next: () => {
        this.toastr.success('Dispatch marked as delivered.');
        this.refreshDispatches?.();
      },
      error: () => this.toastr.error('Failed to mark dispatch as delivered.'),
    });
  }

  markAsUnloaded(dispatch: any): void {
    this.selectedDispatchForUnloadProof = dispatch;
    this.unloadProofRemarks = '';
    this.unloadProofImages = [];
    this.unloadProofImageFiles = [];
    this.unloadProofSignature = null;
    this.unloadProofSignatureFile = null;
    this.unloadAddress = '';
    this.unloadLatitude = null;
    this.unloadLongitude = null;
  }

  handleUnloadImages(event: any): void {
    const files = Array.from(event.target.files) as File[];
    this.unloadProofImageFiles = files;
    this.unloadProofImages = files.map((file) => URL.createObjectURL(file));
  }

  handleUnloadSignature(event: any): void {
    const file = event.target.files[0];
    this.unloadProofSignatureFile = file;
    this.unloadProofSignature = URL.createObjectURL(file);
  }

  cancelUnloadProof(): void {
    this.selectedDispatchForUnloadProof = null;
  }

  submitUnloadProof(): void {
    if (!this.selectedDispatchForUnloadProof) return;

    const formData = new FormData();
    formData.append('remarks', this.unloadProofRemarks);
    formData.append('address', this.unloadAddress);
    formData.append('latitude', this.unloadLatitude?.toString() ?? '');
    const lng = this.unloadLongitude?.toString() ?? '';
    formData.append('longitude', lng);

    this.unloadProofImageFiles.forEach((img) => {
      formData.append('images', img);
    });

    if (this.unloadProofSignatureFile) {
      formData.append('signature', this.unloadProofSignatureFile);
    }

    this.dispatchService
      .markAsUnloaded(this.selectedDispatchForUnloadProof.id, formData)
      .subscribe({
        next: () => {
          this.cancelUnloadProof();
          this.refreshDispatches();
        },
        error: (err: any) => {
          console.error('Unload failed:', err);
        },
      });
  }

  // ===== driver/truck actions =====
  notifyAssignedDriver(dispatch: any): void {
    this.dispatchService.notifyAssignedDriver(dispatch.id).subscribe({
      next: (res: any) => {
        if (res.success) {
          Swal.fire({
            icon: 'success',
            title: 'ជោគជ័យ',
            text: res.message,
            confirmButtonText: 'OK',
          }).then(() => {
            this.refreshDispatches(); // refresh current page
          });
        } else {
          Swal.fire({
            icon: 'warning',
            title: 'ការព្រមាន',
            text: res.message,
            confirmButtonText: 'OK',
          });
        }
      },
      error: () => {
        Swal.fire({
          icon: 'error',
          title: 'កំហុស',
          text: 'មិនអាចជូនដំណឹងអ្នកបើកបាបានទេ។',
          confirmButtonText: 'OK',
        });
      },
    });
  }

  onAssignDriver(dispatchId: number, driverId: number): void {
    if (dispatchId == null || driverId == null) {
      console.error('onAssignDriver called with invalid ids', { dispatchId, driverId });
      return;
    }
    if (
      this.selectedDispatchForDriverAssign &&
      !this.canReassign(this.selectedDispatchForDriverAssign)
    ) {
      this.toastr.error('Cannot reassign driver after safety submission.');
      this.selectedDispatchForDriverAssign = null;
      return;
    }
    this.dispatchService.assignDriverOnly(dispatchId, driverId).subscribe({
      next: () => {
        this.selectedDispatchForDriverAssign = null;
        this.toastr.success('Driver assigned.');
        this.refreshDispatches?.();
      },
      error: (err: any) => {
        console.error('Failed to assign driver:', err);
        this.toastr.error(err?.error?.message || 'Failed to assign driver.');
      },
    });
  }

  confirmTruckChange(): void {
    if (!this.selectedDispatchForTruckChange || !this.selectedNewVehicleId) return;
    if (!this.canReassign(this.selectedDispatchForTruckChange)) {
      this.toastr.error('Cannot change truck after safety submission.');
      this.selectedDispatchForTruckChange = null;
      return;
    }

    const dispatchId = this.selectedDispatchForTruckChange.id;
    const vehicleId = Number(this.selectedNewVehicleId);
    if (Number.isNaN(vehicleId)) {
      this.toastr.error('Please select a valid truck.');
      return;
    }

    this.dispatchService.changeTruck(dispatchId, vehicleId).subscribe({
      next: (res: any) => {
        this.toastr.success('Truck changed.');
        this.selectedDispatchForTruckChange = null;
        this.selectedNewVehicleId = null;
        this.refreshDispatches();
      },
      error: (err: any) => {
        console.error('Truck change failed:', err);
        this.toastr.error(err?.error?.message || 'Truck change failed.');
      },
    });
  }

  messageDriver(dispatch: Dispatch): void {
    if (!dispatch.id) return;
    Swal.fire({
      title: 'Message to driver',
      input: 'textarea',
      inputLabel: `Send message to ${dispatch.driverName || 'driver'}`,
      inputPlaceholder: 'Type your message here...',
      showCancelButton: true,
      confirmButtonText: 'Send',
    }).then((result: any) => {
      if (!result.isConfirmed) return;
      const message = result.value as string;
      if (!message || message.trim().length === 0) {
        this.toastr.info('Message is empty.');
        return;
      }

      this.dispatchService.messageDriver(dispatch.id!, message).subscribe({
        next: (res: any) => {
          if (res?.success) {
            this.toastr.success(res.message || 'Message sent to driver.');
            this.refreshDispatches();
          } else {
            this.toastr.warning(res?.message || 'Driver message not delivered.');
          }
        },
        error: (err: any) => {
          console.error('Message driver failed:', err);
          this.toastr.error(err?.error?.message || 'Failed to send message to driver.');
        },
      });
    });
  }

  // ===== helpers for UI =====
  getLocationLabel(
    loc: any,
    fallbackName?: string | null,
    fallbackAddress?: string | null,
  ): string {
    if (!loc) return fallbackName || fallbackAddress || '—';
    if (typeof loc === 'string') return loc;

    const name = loc.name ?? loc.locationName ?? fallbackName;
    const address = loc.address ?? fallbackAddress;

    if (name && address) return `${name}`;
    return name ?? address ?? '—';
  }

  getLocationCoords(loc: any): { lat: number; lng: number } | null {
    if (!loc) return null;

    if (typeof loc === 'string') {
      if (!loc.includes(',')) return null;
      const [latStr, lngStr] = loc.split(',').map((s) => s.trim());
      const lat = Number(latStr);
      const lng = Number(lngStr);
      return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null;
    }

    const lat =
      loc.latitude ??
      loc.lat ??
      (typeof loc.coordinates === 'string' ? Number(loc.coordinates.split(',')[0]) : undefined);
    const lng =
      loc.longitude ??
      loc.lng ??
      (typeof loc.coordinates === 'string' ? Number(loc.coordinates.split(',')[1]) : undefined);

    return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null;
  }

  hasLoadProof(dispatch: Dispatch): boolean {
    return (dispatch.loadingProofImages?.length ?? 0) > 0 || !!dispatch.loadingSignature;
  }

  hasUnloadProof(dispatch: Dispatch): boolean {
    return (dispatch.unloadingProofImages?.length ?? 0) > 0 || !!dispatch.unloadingSignature;
  }

  getProofThumbnails(images: string[] | undefined): string[] {
    return images?.slice(0, 3) ?? [];
  }

  assignDriver(dispatch: Dispatch): void {
    if (!this.canReassign(dispatch)) {
      this.toastr.error('Cannot reassign driver after safety submission.');
      return;
    }
    console.log('🧑‍✈️ Assigning driver:', dispatch.routeCode);
    this.selectedDispatchForDriverAssign = dispatch;
  }

  changeDriver(dispatch: Dispatch): void {
    if (!this.canReassign(dispatch)) {
      this.toastr.error('Cannot change driver after safety submission.');
      return;
    }
    console.log(' Changing driver:', dispatch.routeCode);
    this.selectedDispatchForDriverChange = dispatch;
  }

  assignTruck(dispatch: Dispatch): void {
    if (!this.canReassign(dispatch)) {
      this.toastr.error('Cannot reassign truck after safety submission.');
      return;
    }
    console.log(' Assigning truck:', dispatch.routeCode);
    this.selectedDispatchForTruckAssign = dispatch;
  }

  changeTruck(dispatch: Dispatch): void {
    if (!this.canReassign(dispatch)) {
      this.toastr.error('Cannot change truck after safety submission.');
      return;
    }
    console.log(' Changing truck:', dispatch.routeCode);
    this.selectedDispatchForTruckChange = dispatch;
    // pre-select current vehicle if available
    this.selectedNewVehicleId = (dispatch as any).vehicleId ?? null;
  }
  sendMessageToDriver(): void {
    console.log('Sending message to driver...');
  }

  updateDispatchStatus(dispatch: Dispatch): void {
    console.log('Update dispatch status:', dispatch);
  }

  viewDriverLocation(dispatch: Dispatch): void {
    if (!dispatch.driverId) {
      this.toastr.warning('No driver assigned to this trip', 'Driver Location');
      return;
    }
    // Navigate to driver location tracking page
    window.open(`/live/map?driverId=${dispatch.driverId}`, '_blank');
  }

  viewTimeline(dispatch: Dispatch): void {
    if (!dispatch.id) {
      this.toastr.error('Invalid dispatch ID', 'Timeline');
      return;
    }
    // Navigate to dispatch detail page to view timeline/status history
    window.open(`/dispatch/${dispatch.id}`, '_blank');
  }

  // =========================
  // ===== Bulk selection ====
  // =========================

  get anySelected(): boolean {
    return this.selectedIds.size > 0;
  }

  get allOnPageSelected(): boolean {
    if (!this.filteredDispatches?.length) return false;
    return this.filteredDispatches.every((d) => d.id != null && this.selectedIds.has(d.id));
  }

  get someOnPageSelected(): boolean {
    return this.anySelected && !this.allOnPageSelected;
  }

  toggleRowSelection(id: number, checked: boolean): void {
    if (id == null) return;
    if (checked) this.selectedIds.add(id);
    else this.selectedIds.delete(id);
  }

  toggleSelectAllOnPage(checked: boolean): void {
    if (!this.filteredDispatches?.length) return;
    if (checked) {
      this.filteredDispatches.forEach((d) => d.id != null && this.selectedIds.add(d.id));
    } else {
      this.filteredDispatches.forEach((d) => d.id != null && this.selectedIds.delete(d.id));
    }
  }

  private syncSelectionWithPage(): void {
    const idsOnPage = new Set<number>(
      this.filteredDispatches.filter((d) => d.id != null).map((d) => d.id!),
    );
    // selection persists across pages; prune if you want by iterating selectedIds
  }

  trackById = (_: number, d: { id?: number }) => d.id ?? _;

  trackByStopIndex = (index: number) => index;

  private applyDefaultTimes(): void {
    const { start, eta } = this.buildDefaultTimes();
    this.dispatchForm.patchValue({ startTime: start, estimatedArrival: eta }, { emitEvent: false });
  }

  private buildDefaultTimes(): { start: string; eta: string } {
    const start = new Date();
    const eta = new Date(start.getTime() + 2 * 60 * 60 * 1000);
    return {
      start: this.toDateTimeLocalInput(start),
      eta: this.toDateTimeLocalInput(eta),
    };
  }

  private toDateTimeLocalInput(date: Date): string {
    const offsetMinutes = date.getTimezoneOffset();
    const localDate = new Date(date.getTime() - offsetMinutes * 60 * 1000);
    return localDate.toISOString().slice(0, 16);
  }

  bulkDeleteSelectedDispatches(): void {
    if (this.bulkBusy) {
      return;
    }

    const selected = Array.from(this.selectedIds);
    if (selected.length === 0) {
      this.toastr.info('Please select at least one dispatch.');
      return;
    }

    Swal.fire({
      icon: 'warning',
      title: 'Delete selected dispatches?',
      text: 'This action cannot be undone.',
      showCancelButton: true,
      confirmButtonText: 'Delete',
      confirmButtonColor: '#dc2626',
      cancelButtonText: 'Cancel',
    }).then((result: any) => {
      if (!result.isConfirmed) {
        return;
      }

      this.bulkBusy = true;
      this.dispatchService
        .bulkDeleteDispatches(selected)
        .pipe(finalize(() => (this.bulkBusy = false)))
        .subscribe({
          next: () => {
            this.toastr.success('Deleted selected dispatches.');
            this.selectedIds.clear();
            this.loadPage(this.pageIndex);
          },
          error: (err: any) => {
            console.error('Bulk delete failed:', err);
            this.toastr.error('Failed to delete selected dispatches.');
          },
        });
    });
  }

  bulkNotifyAssignedDrivers(): void {
    if (this.bulkBusy) {
      return;
    }

    const selected = Array.from(this.selectedIds);
    if (selected.length === 0) {
      this.toastr.info('Please select at least one dispatch.');
      return;
    }

    const pageMap = new Map<number, Dispatch>(
      this.filteredDispatches.filter((d) => d.id != null).map((d) => [d.id!, d]),
    );

    const targets = selected
      .map((id) => pageMap.get(id))
      .filter((d): d is Dispatch => !!d && !!(d as any).driverId);

    if (targets.length === 0) {
      this.toastr.info('No selected rows on this page have an assigned driver.');
      return;
    }

    this.bulkBusy = true;
    console.log(
      '[BulkNotify] IDs:',
      selected,
      'Targets:',
      targets.map((t) => t.id),
    );

    forkJoin(targets.map((d) => this.dispatchService.notifyAssignedDriver(d.id!)))
      .pipe(finalize(() => (this.bulkBusy = false)))
      .subscribe({
        next: (results: any[]) => {
          const ok = results.filter((r) => r?.success).length;
          const fail = results.length - ok;
          if (ok) this.toastr.success(`Notified ${ok} driver(s).`);
          if (fail) this.toastr.warning(`${fail} notification(s) failed.`);
          targets.forEach((t) => this.selectedIds.delete(t.id!));
          this.refreshDispatches();
        },
        error: (err: any) => {
          console.error('[BulkNotify] error:', err);
          this.toastr.error('Bulk notify failed.');
        },
      });
  }
}
