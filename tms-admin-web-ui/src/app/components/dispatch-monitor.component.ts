import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy } from '@angular/core';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { NgZone } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Router } from '@angular/router';
import { RouterModule } from '@angular/router';
import { ConfirmService } from '@services/confirm.service';
import Swal from 'sweetalert2';

import { environment } from '../environments/environment';
import { DispatchStatus } from '../models/dispatch-status.enum';
import type { Dispatch } from '../models/dispatch.model';
import type { WarehouseCode } from '../models/loading-queue.model';
import { SvSafeDatePipe } from '../pipes/sv-safe-date.pipe';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import {
  DispatchService,
  type DispatchActionMetadata,
  type DispatchStatusUpdateResponse,
} from '../services/dispatch.service';
import { LoadingOpsService } from '../services/loading-ops.service';
import { ImagePreviewModalComponent } from '../shared/image-preview-modal/image-preview-modal.component';

@Component({
  selector: 'app-dispatch-monitor',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterModule,
    ImagePreviewModalComponent,
    SvSafeDatePipe,
    MatIconModule,
  ],
  templateUrl: './dispatch-monitor.component.html',
  styleUrls: ['./dispatch-monitor.component.css'],
})
export class DispatchMonitorComponent implements OnInit, OnDestroy {
  // expose enum + stable list for template
  DispatchStatus = DispatchStatus;
  statusList: string[] = Object.values(DispatchStatus);

  dispatches: Dispatch[] = [];
  filteredDispatches: Dispatch[] = [];

  baseUrl = `${environment.baseUrl}/uploads`;
  modalImages: string[] = [];
  currentImageIndex = 0;
  showModal = false;

  selectedStatus = '';

  /** Legacy field that might be referenced elsewhere; keep it. */
  selectedDriver = '';

  /** Preferred string-based driver filter for the template. */
  mySelectedDriver = '';

  searchRouteCode = '';
  customerName = '';
  destinationTo = '';
  truckPlate = '';
  tripNo = '';
  startDate: string = new Date().toISOString().slice(0, 10);
  endDate: string = new Date().toISOString().slice(0, 10);

  autoRefresh = true;
  refreshInterval = 15000;
  intervalId: ReturnType<typeof setInterval> | null = null;
  lastRefreshedAt = '';

  refreshOptions = [
    { value: 2000, label: '2 seconds' },
    { value: 5000, label: '5 seconds' },
    { value: 10000, label: '10 seconds' },
    { value: 15000, label: '15 seconds' },
    { value: 30000, label: '30 seconds' },
    { value: 60000, label: '1 minute' },
    { value: 120000, label: '2 minutes' },
    { value: 300000, label: '5 minutes' },
    { value: 600000, label: '10 minutes' },
    { value: 900000, label: '15 minutes' },
  ];

  /** Small debounce timer for text inputs */
  private filterDebounce: any = null;

  /** Used by assign-driver flow referenced in onAssignDriver */
  selectedDispatchForDriverAssign: any | null = null;

  p: any;
  flowActionByDispatchId: Record<
    number,
    {
      loading: boolean;
      label: string;
      targetStatus?: string;
      disabled: boolean;
      reason?: string | null;
    }
  > = {};

  constructor(
    private dispatchService: DispatchService,
    private loadingOps: LoadingOpsService,
    private router: Router,
    private zone: NgZone,
    private confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.loadDispatches();
    if (this.autoRefresh) this.setupAutoRefresh();
  }

  ngOnDestroy(): void {
    this.clearAutoRefresh();
    if (this.filterDebounce) {
      clearTimeout(this.filterDebounce);
      this.filterDebounce = null;
    }
  }

  /** Normalize any backend date shape into a JS Date (or null) */
  private toDate(input: unknown): Date | null {
    if (!input && input !== 0) return null;

    if (input instanceof Date) return isNaN(input.getTime()) ? null : input;

    if (typeof input === 'number') {
      const d = new Date(input);
      return isNaN(d.getTime()) ? null : d;
    }

    if (Array.isArray(input)) {
      const [y, m, d, hh = 0, mm = 0, ss = 0] = (input as any[]).map(Number);
      const dt = new Date(y, m - 1, d, hh, mm, ss);
      return isNaN(dt.getTime()) ? null : dt;
    }

    if (typeof input === 'string') {
      if (input.includes(',')) {
        const parts = input.split(',').map((p) => Number(p.trim()));
        const [y, m, d, hh = 0, mm = 0, ss = 0] = parts;
        const dt = new Date(y, (m as number) - 1, d, hh, mm, ss);
        return isNaN(dt.getTime()) ? null : dt;
      }
      const dt = new Date(input); // ISO or parseable
      return isNaN(dt.getTime()) ? null : dt;
    }

    return null;
  }

  private isAnyFilterActive(): boolean {
    return !!(
      this.selectedStatus ||
      this.mySelectedDriver ||
      this.selectedDriver ||
      this.searchRouteCode ||
      this.customerName ||
      this.destinationTo ||
      this.truckPlate ||
      this.tripNo ||
      this.startDate ||
      this.endDate
    );
  }

  loadDispatches(): void {
    this.dispatchService.getAllDispatches(0, 100).subscribe({
      next: (res: any) => {
        this.dispatches = res?.data?.content ?? [];
        // Re-apply current filters (or mirror list if none active)
        this.applyFilters();
        this.loadFlowActionsForCurrentRows(this.dispatches);
        this.lastRefreshedAt = new Date().toLocaleTimeString();
        console.log(
          ' Data refreshed at',
          this.lastRefreshedAt,
          '=>',
          this.dispatches.length,
          'records',
        );
      },
      error: (err: any) => console.error('Failed to fetch dispatches:', err),
    });
  }

  applyFilters(): void {
    // If no filters are active, mirror cached list and don't hit the API
    if (!this.isAnyFilterActive()) {
      this.filteredDispatches = [...this.dispatches];
      return;
    }

    // Build ISO strings (leave undefined so params are omitted when empty)
    const startIso = this.startDate
      ? new Date(this.startDate + 'T00:00:00').toISOString()
      : undefined;
    const endIso = this.endDate ? new Date(this.endDate + 'T23:59:59').toISOString() : undefined;

    const driverName = (this.mySelectedDriver || this.selectedDriver || '').trim() || undefined;
    const status = this.selectedStatus || undefined;
    const routeCode = this.searchRouteCode.trim() || undefined;

    const customerName = (this.customerName ?? '').trim() || undefined;
    const destinationTo = (this.destinationTo ?? '').trim() || undefined;
    const truckPlate = (this.truckPlate ?? '').trim() || undefined;
    const tripNo = (this.tripNo ?? '').trim() || undefined;

    // Combine additional filters into free-text 'q' so backend can match if supported
    const qParts = [customerName, destinationTo, truckPlate, tripNo].filter(Boolean) as string[];
    const q = qParts.length ? qParts.join(' ') : undefined;

    this.dispatchService
      .filterDispatches({
        driverName,
        status,
        routeCode,
        customerName,
        toLocation: destinationTo,
        truckPlate,
        tripNo,
        q,
        start: startIso,
        end: endIso,
        page: 0,
        size: 100,
      })
      .subscribe({
        next: (res: any) => {
          const serverContent = res?.data?.content ?? [];
          this.filteredDispatches = Array.isArray(serverContent) ? serverContent : [];
          this.loadFlowActionsForCurrentRows(this.filteredDispatches);

          // Safety net: if server returns empty unexpectedly, apply client-side filter on cached page
          if (!this.filteredDispatches.length && this.dispatches.length) {
            const driverQuery = (driverName ?? '').toLowerCase();
            const routeQuery = (routeCode ?? '').toLowerCase();
            const customerQuery = (this.customerName ?? '').toLowerCase();
            const toQuery = (this.destinationTo ?? '').toLowerCase();
            const truckQuery = (this.truckPlate ?? '').toLowerCase();
            const tripQuery = (this.tripNo ?? '').toLowerCase();

            this.filteredDispatches = this.dispatches.filter((d) => {
              const matchesStatus = status ? d.status === status : true;

              const dn = (d as any).driverName as string | undefined;
              const matchesDriver = driverQuery
                ? (dn ?? '').toLowerCase().includes(driverQuery)
                : true;

              const matchesRoute = routeQuery
                ? (d.routeCode ?? '').toLowerCase().includes(routeQuery)
                : true;

              const cust = ((d as any).customerName ?? (d as any).customer ?? '').toString();
              const toField = (
                (d as any).to ??
                (d as any).destination ??
                (d as any).destinationTo ??
                ''
              ).toString();
              const plate = (
                (d as any).truckPlate ??
                (d as any).vehiclePlate ??
                (d as any).truckNumber ??
                ''
              ).toString();
              const trip = ((d as any).tripNo ?? (d as any).tripNumber ?? '').toString();

              const matchesCustomer = customerQuery
                ? cust.toLowerCase().includes(customerQuery)
                : true;
              const matchesTo = toQuery ? toField.toLowerCase().includes(toQuery) : true;
              const matchesTruck = truckQuery ? plate.toLowerCase().includes(truckQuery) : true;
              const matchesTrip = tripQuery ? trip.toLowerCase().includes(tripQuery) : true;

              const startTime = this.toDate((d as any).startTime);
              const matchesStartDate = startIso
                ? !!startTime && startTime.getTime() >= new Date(startIso).getTime()
                : true;
              const matchesEndDate = endIso
                ? !!startTime && startTime.getTime() <= new Date(endIso).getTime()
                : true;

              return (
                matchesStatus &&
                matchesDriver &&
                matchesRoute &&
                matchesCustomer &&
                matchesTo &&
                matchesTruck &&
                matchesTrip &&
                matchesStartDate &&
                matchesEndDate
              );
            });
            this.loadFlowActionsForCurrentRows(this.filteredDispatches);
          }
        },
        error: (err: any) => {
          console.error('Server filter failed, using client-side fallback:', err);
          const driverQuery = (driverName ?? '').toLowerCase();
          const routeQuery = (routeCode ?? '').toLowerCase();
          const customerQuery = (this.customerName ?? '').toLowerCase();
          const toQuery = (this.destinationTo ?? '').toLowerCase();
          const truckQuery = (this.truckPlate ?? '').toLowerCase();
          const tripQuery = (this.tripNo ?? '').toLowerCase();

          this.filteredDispatches = this.dispatches.filter((d) => {
            const matchesStatus = status ? d.status === status : true;

            const dn = (d as any).driverName as string | undefined;
            const matchesDriver = driverQuery
              ? (dn ?? '').toLowerCase().includes(driverQuery)
              : true;

            const matchesRoute = routeQuery
              ? (d.routeCode ?? '').toLowerCase().includes(routeQuery)
              : true;

            const cust = ((d as any).customerName ?? (d as any).customer ?? '').toString();
            const toField = (
              (d as any).to ??
              (d as any).destination ??
              (d as any).destinationTo ??
              ''
            ).toString();
            const plate = (
              (d as any).truckPlate ??
              (d as any).vehiclePlate ??
              (d as any).truckNumber ??
              ''
            ).toString();
            const trip = ((d as any).tripNo ?? (d as any).tripNumber ?? '').toString();

            const matchesCustomer = customerQuery
              ? cust.toLowerCase().includes(customerQuery)
              : true;
            const matchesTo = toQuery ? toField.toLowerCase().includes(toQuery) : true;
            const matchesTruck = truckQuery ? plate.toLowerCase().includes(truckQuery) : true;
            const matchesTrip = tripQuery ? trip.toLowerCase().includes(tripQuery) : true;

            const startTime = this.toDate((d as any).startTime);
            const matchesStartDate = startIso
              ? !!startTime && startTime.getTime() >= new Date(startIso).getTime()
              : true;
            const matchesEndDate = endIso
              ? !!startTime && startTime.getTime() <= new Date(endIso).getTime()
              : true;

            return (
              matchesStatus &&
              matchesDriver &&
              matchesRoute &&
              matchesCustomer &&
              matchesTo &&
              matchesTruck &&
              matchesTrip &&
              matchesStartDate &&
              matchesEndDate
            );
          });
          this.loadFlowActionsForCurrentRows(this.filteredDispatches);
        },
      });
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
        return dispatch.status || 'Unknown';
    }
  }

  private loadFlowActionsForCurrentRows(rows: Dispatch[]): void {
    const ids = (rows || []).map((r) => r.id).filter((id): id is number => typeof id === 'number');
    if (!ids.length) return;

    ids.forEach((id) => {
      this.flowActionByDispatchId[id] = { loading: true, label: 'Loading...', disabled: true };
      this.dispatchService.getAvailableActions(id).subscribe({
        next: (res) => {
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
          this.flowActionByDispatchId[id] = {
            loading: false,
            label: this.resolveActionLabel(action.actionLabel),
            targetStatus: action.targetStatus,
            disabled:
              !!action.requiresAdminApproval ||
              !!(action.validationMessage && action.validationMessage.trim().length > 0),
            reason: action.validationMessage || null,
          };
        },
        error: () => {
          this.flowActionByDispatchId[id] = {
            loading: false,
            label: 'No next action',
            disabled: true,
          };
        },
      });
    });
  }

  private pickPrimaryFlowAction(
    payload: DispatchStatusUpdateResponse | null,
  ): DispatchActionMetadata | null {
    const actions = [...(payload?.availableActions || [])].sort(
      (a, b) => (a.priority ?? 999) - (b.priority ?? 999),
    );
    if (!actions.length) return null;
    const preferredTargets = [
      DispatchStatus.DRIVER_CONFIRMED,
      DispatchStatus.ARRIVED_LOADING,
      DispatchStatus.IN_QUEUE,
      DispatchStatus.LOADING,
      DispatchStatus.LOADED,
    ];
    return (
      actions.find(
        (a) =>
          preferredTargets.includes((a.targetStatus || '') as DispatchStatus) && !a.isDestructive,
      ) ||
      actions.find((a) => !a.isDestructive) ||
      actions[0]
    );
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
    };
    return map[shortKey] || shortKey.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  }

  private resolveWarehouseCode(dispatch: Dispatch): WarehouseCode {
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
      return normalized as WarehouseCode;
    }
    return 'KHB';
  }

  onFlowActionClick(dispatch: Dispatch): void {
    if (!dispatch?.id) return;
    const action = this.flowActionByDispatchId[dispatch.id];
    if (!action || action.disabled || !action.targetStatus) return;

    if (action.targetStatus === DispatchStatus.IN_QUEUE) {
      const warehouseCode = this.resolveWarehouseCode(dispatch);
      this.loadingOps
        .enqueue({
          dispatchId: dispatch.id,
          warehouseCode,
          remarks: 'Queued via G-Management Monitor',
        })
        .subscribe({
          next: () => this.loadDispatches(),
          error: (err) => console.error('Queue action failed', err),
        });
      return;
    }

    if (action.targetStatus === DispatchStatus.LOADING) {
      const warehouseCode = this.resolveWarehouseCode(dispatch);
      this.loadingOps
        .startLoading({
          dispatchId: dispatch.id,
          warehouseCode,
          remarks: 'Started via G-Management Monitor',
        })
        .subscribe({
          next: () => this.loadDispatches(),
          error: (err) => console.error('Start loading action failed', err),
        });
      return;
    }

    this.dispatchService.updateDispatchStatus(dispatch.id, action.targetStatus).subscribe({
      next: () => this.loadDispatches(),
      error: (err) => console.error('Flow action failed', err),
    });
  }

  // Debounced filter hook for text inputs (driver name / route code)
  onFilterChangeDebounced(_val?: any): void {
    if (this.filterDebounce) clearTimeout(this.filterDebounce);
    this.filterDebounce = setTimeout(() => {
      this.applyFilters();
    }, 300);
  }

  setupAutoRefresh(): void {
    this.clearAutoRefresh();
    this.intervalId = setInterval(() => {
      this.zone.run(() => {
        if (this.isAnyFilterActive()) {
          this.applyFilters();
        } else {
          this.loadDispatches();
        }
      });
    }, this.refreshInterval);
  }

  clearAutoRefresh(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  toggleAutoRefresh(): void {
    if (this.autoRefresh) this.setupAutoRefresh();
    else this.clearAutoRefresh();
  }

  changeRefreshInterval(interval: number): void {
    this.refreshInterval = interval;
    if (this.autoRefresh) this.setupAutoRefresh();
  }

  onFilterChange(): void {
    this.applyFilters();
  }

  resetFilters(): void {
    this.selectedStatus = '';
    this.selectedDriver = ''; // legacy
    this.mySelectedDriver = ''; // preferred
    this.searchRouteCode = '';
    this.customerName = '';
    this.destinationTo = '';
    this.truckPlate = '';
    this.tripNo = '';
    this.startDate = '';
    this.endDate = '';
    this.loadDispatches();
  }

  toggleMenu(dispatch: Dispatch): void {
    this.filteredDispatches.forEach((d) => ((d as any)['showMenu'] = false));
    (dispatch as any)['showMenu'] = !(dispatch as any)['showMenu'];
  }

  viewDispatch(id: number): void {
    this.router.navigate(['/dispatch', id]);
  }

  viewLoading(id: number): void {
    console.log('👁 View loading for dispatch:', id);
  }

  viewUnloading(id: number): void {
    console.log(' View unloading for dispatch:', id);
  }

  editDispatch(dispatch: Dispatch): void {
    console.log('✏️ Edit dispatch:', dispatch);
  }

  async deleteDispatch(id: number): Promise<void> {
    if (await this.confirm.confirm('Are you sure?')) {
      console.log('🗑 Delete dispatch:', id);
    }
  }

  // Safe method to prepend base URL for proof images
  prependBaseUrl(images?: string[]): string[] {
    if (!images || images.length === 0) return [];
    return images.map((img) => this.buildUploadUrl(img));
  }

  hasLoadingProofImages(dispatch: Dispatch): boolean {
    const imgs = (dispatch as any).loadingProofImages as string[] | undefined;
    return !!imgs && imgs.length > 0;
  }

  hasUnLoadingProofImages(dispatch: Dispatch): boolean {
    const imgs = (dispatch as any).unloadingProofImages as string[] | undefined;
    return !!imgs && imgs.length > 0;
  }

  // Optional: wrap signature in array for uniform preview logic
  wrapSignatureWithBaseUrl(signature?: string): string[] {
    return signature ? [this.buildUploadUrl(signature)] : [];
  }

  buildUploadUrl(path?: string): string {
    if (!path) return '';
    const cleaned = path
      .replace(/^https?:\/\/[^/]+/i, '')
      .replace(/^\/+/, '')
      .replace(/^uploads\/+/i, '')
      .replace(/^\/+/, '');
    return `${this.baseUrl}/${cleaned}`.replace(/([^:]\/)\/+/g, '$1');
  }

  openPreview(images: string[], index: number) {
    this.modalImages = images;
    this.currentImageIndex = index;
    this.showModal = true;
  }

  closeModal() {
    this.showModal = false;
  }

  nextImage() {
    if (this.currentImageIndex < this.modalImages.length - 1) {
      this.currentImageIndex++;
    }
  }

  prevImage() {
    if (this.currentImageIndex > 0) {
      this.currentImageIndex--;
    }
  }

  // ===== driver/truck actions =====
  notifyAssignedDriver(dispatch: any): void {
    this.dispatchService.notifyAssignedDriver(dispatch.id).subscribe({
      next: (res) => {
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
    this.dispatchService.assignDriverOnly(dispatchId, driverId).subscribe({
      next: () => {
        this.selectedDispatchForDriverAssign = null;
        this.refreshDispatches?.();
      },
      error: (err) => {
        console.error('Failed to assign driver:', err);
      },
    });
  }

  /** Wrapper used after SweetAlert confirmations */
  refreshDispatches(): void {
    this.loadDispatches();
  }
}
