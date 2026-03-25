import { CommonModule } from '@angular/common';
import { Component, inject, type OnDestroy, type OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';

import type { Dispatch } from '../../models/dispatch.model';
import type { LoadingQueue, WarehouseCode } from '../../models/loading-queue.model';
import { DispatchService } from '../../services/dispatch.service';
import { LoadingOpsService } from '../../services/loading-ops.service';
import { ConfirmService } from '../../services/confirm.service';
import { SafetyChecklistComponent } from '../safety-checklist/safety-checklist.component';

@Component({
  selector: 'app-loading-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, SafetyChecklistComponent],
  templateUrl: './loading-dashboard.component.html',
  styleUrls: ['./loading-dashboard.component.css'],
})
export class LoadingDashboardComponent implements OnInit, OnDestroy {
  private confirm = inject(ConfirmService);
  warehouses: WarehouseCode[] = ['KHB', 'W2', 'W3'];
  selectedWarehouse: WarehouseCode = 'KHB';
  loading = false;
  statusFilter: 'ALL' | 'WAITING' | 'CALLED' | 'LOADING' | 'LOADED' = 'ALL';
  searchTerm = '';
  driverSearchTerm = '';
  deliveryFrom = '';
  deliveryTo = '';
  pageIndex = 0;
  pageSize = 20;
  totalPages = 1;
  // simple split control
  topHeight = 320;
  leftWidthPx = 960;
  // vertical splitter
  private dragStartY = 0;
  private dragStartHeight = 0;

  queue: LoadingQueue[] = [];
  selectedEntry: LoadingQueue | null = null;
  metrics = {
    waiting: 0,
    called: 0,
    loading: 0,
    loaded: 0,
  };

  // Template-aligned state (orders/drivers)
  searchOrders = '';
  ordersError = '';
  assignedError = '';
  selectedOrderIds = new Set<number>();
  selectedDispatchIds = new Set<number>();
  driverPage = 0;
  driverPageSize = 8;
  driverPageCount = 1;
  searchDrivers = '';
  filteredDrivers: any[] = [];
  selectedDriver: any = null;
  dragging = false;
  // removed unused dragSub (was unused)
  topSectionHeightPx = 340;
  private dragStartX = 0;
  private dragStartWidth = 0;

  // Packing Note Modal
  showPackingNote = false;
  packingNoteOrder: LoadingQueue | null = null;
  packingNoteText = '';

  // Status Update Modal
  showStatusUpdateModal = false;
  statusUpdateEntry: LoadingQueue | null = null;
  selectedStatus: 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED' = 'PENDING';
  statusUpdateReason = '';
  isSubmittingStatus = false;

  // Safety Checklist Modal
  safetyChecklistEntry: LoadingQueue | null = null;

  constructor(
    private readonly loadingOpsService: LoadingOpsService,
    private readonly dispatchService: DispatchService,
    private readonly toastr: ToastrService,
    private readonly router: Router,
  ) {}

  ngOnInit(): void {
    this.load();
  }

  ngOnDestroy(): void {
    // Ensure any global listeners are removed when component is destroyed
    try {
      window.removeEventListener('mousemove', this.onDrag);
      window.removeEventListener('mouseup', this.stopDrag);
      window.removeEventListener('mousemove', this.onVerticalDrag);
      window.removeEventListener('mouseup', this.stopVerticalDrag);
    } catch (e) {
      // ignore
    }
  }

  load(): void {
    this.loading = true;
    this.loadPreLoadingDispatches();
  }

  private loadPreLoadingDispatches(): void {
    const params = {
      page: this.pageIndex,
      size: this.pageSize,
      q: this.searchTerm || undefined,
      start: this.deliveryFrom ? new Date(this.deliveryFrom).toISOString() : undefined,
      end: this.deliveryTo ? new Date(this.deliveryTo).toISOString() : undefined,
    };
    const preStatuses = [
      'ARRIVED_LOADING',
      'SCHEDULED',
      'ASSIGNED',
      'DRIVER_CONFIRMED',
      'SAFETY_PASSED',
      'IN_QUEUE',
      'LOADING',
    ];
    this.dispatchService.filterDispatchesByDriverName(params).subscribe({
      next: (res) => this.handleDispatchResponse(res, preStatuses),
      error: (err) => {
        console.error('Dispatch load failed', err);
        this.toastr.error(err?.error?.message || 'Unable to load dispatches');
        this.loading = false;
      },
    });
  }
  private loadLoadedDispatches(): void {
    const params = {
      page: this.pageIndex,
      size: this.pageSize,
      q: this.searchTerm || undefined,
      start: this.deliveryFrom ? new Date(this.deliveryFrom).toISOString() : undefined,
      end: this.deliveryTo ? new Date(this.deliveryTo).toISOString() : undefined,
    };
    const loadedStatuses = ['LOADED'];
    this.dispatchService.filterDispatchesByDriverName(params).subscribe({
      next: (res) => this.handleDispatchResponse(res, loadedStatuses),
      error: (err) => {
        console.error('Dispatch load failed', err);
        this.toastr.error(err?.error?.message || 'Unable to load dispatches');
        this.loading = false;
      },
    });
  }

  private handleDispatchResponse(res: any, allowStatuses?: string[]): void {
    const preSet = new Set((allowStatuses ?? []).map((s) => s.toUpperCase()));
    const content = res.data?.content ?? [];
    const mapped = content.map((d: Dispatch) => this.mapDispatchToQueue(d));
    this.queue = allowStatuses?.length
      ? mapped.filter((m: LoadingQueue) =>
          preSet.has((m.dispatchStatusRaw ?? m.status ?? '').toUpperCase()),
        )
      : mapped;
    this.totalPages = res.data?.totalPages ?? 1;
    this.computeMetrics();
    this.recomputeDrivers();
    this.loading = false;
  }

  onPreloadAction(entry: LoadingQueue, action: string): void {
    if (!action) return;
    if (action === 'view') {
      this.viewDispatch(entry);
    } else if (action === 'safety') {
      this.openSafetyChecklist(entry);
    } else if (action === 'pickingList') {
      this.openPickingList(entry);
    } else if (action === 'select') {
      this.selectPreload(entry);
      this.toastr.info('Dispatch selected, pick a driver on the right');
    } else if (action === 'assign') {
      this.toastr.info('Assign action placeholder. Wire to backend assign endpoint.');
    } else if (action === 'packing') {
      this.packingNoteOrder = entry;
      this.packingNoteText = '';
      this.showPackingNote = true;
    } else if (action === 'status') {
      this.openStatusUpdateModal(entry);
    } else if (action === 'quickConfirm') {
      this.quickConfirmDispatch(entry);
    } else if (action === 'quickStart') {
      this.quickStartLoading(entry);
    } else if (action === 'quickComplete') {
      this.quickCompleteDispatch(entry);
    }
  }

  private viewDispatch(entry: LoadingQueue): void {
    if (entry?.dispatchId) {
      try {
        this.router.navigate(['/dispatch', entry.dispatchId], {
          queryParamsHandling: 'merge',
        });
      } catch (e) {
        window.open(`/dispatch/${entry.dispatchId}`, '_blank');
      }
    } else {
      this.toastr.info(`View dispatch ${entry.routeCode ?? 'unknown'}`, 'Open');
    }
  }

  private openSafetyChecklist(entry: LoadingQueue): void {
    if (!entry?.dispatchId) {
      this.toastr.error('Dispatch id missing for safety check');
      return;
    }
    this.safetyChecklistEntry = entry;
  }

  onSafetyCheckSaved(): void {
    this.safetyChecklistEntry = null;
    this.load();
  }

  private openPickingList(entry: LoadingQueue): void {
    if (!entry?.dispatchId) {
      this.toastr.error('Dispatch id missing for picking list');
      return;
    }
    // Try to resolve the related order id; fall back to dispatch tab if unavailable
    this.dispatchService.getDispatchById(entry.dispatchId).subscribe({
      next: (res) => {
        const data: any = (res as any).data ?? res;
        const orderId = data?.transportOrderId ?? data?.transportOrder?.id;
        if (orderId) {
          window.open(`/orders/${orderId}/picking-list`, '_blank');
        } else {
          window.open(`/dispatch/${entry.dispatchId}?tab=picking-list`, '_blank');
        }
      },
      error: () => {
        this.toastr.error('Unable to open picking list');
        window.open(`/dispatch/${entry.dispatchId}?tab=picking-list`, '_blank');
      },
    });
  }

  closePackingNote(): void {
    this.showPackingNote = false;
    this.packingNoteOrder = null;
    this.packingNoteText = '';
  }

  savePackingNote(): void {
    if (!this.packingNoteOrder) return;
    const dispatchId = this.packingNoteOrder.dispatchId;
    const text = this.packingNoteText || '';
    this.toastr.info('Saving packing note...');

    // Try attach to an active loading session first
    this.loadingOpsService.sessionForDispatch(dispatchId).subscribe({
      next: (session) => {
        try {
          const blob = new Blob([text], { type: 'text/plain' });
          const file = new File([blob], `packing-note-${dispatchId}.txt`, { type: 'text/plain' });
          this.loadingOpsService.uploadDocument(session.id, 'PACKING_LIST', file).subscribe({
            next: () => {
              this.toastr.success('Packing note uploaded to session.');
              // open printable view
              this.openPackingNoteInNewWindow(text, this.packingNoteOrder);
              this.closePackingNote();
              this.load();
            },
            error: (err) => {
              console.error(err);
              this.toastr.error(err?.error?.message || 'Failed to upload packing note');
            },
          });
        } catch (e) {
          console.error(e);
          this.toastr.error('Unable to create packing note file');
        }
      },
      error: () => {
        // No session found — save as queue remarks via enqueue (will update existing queue if present)
        const payload = {
          dispatchId,
          warehouseCode: this.packingNoteOrder?.warehouseCode ?? this.selectedWarehouse,
          remarks: text,
        };
        this.loadingOpsService.enqueue(payload).subscribe({
          next: () => {
            this.toastr.success('Packing note saved to queue remarks.');
            // open printable view (remarks saved to queue)
            this.openPackingNoteInNewWindow(text, this.packingNoteOrder);
            this.closePackingNote();
            this.load();
          },
          error: (err) => {
            console.error(err);
            this.toastr.error(err?.error?.message || 'Failed to save packing note');
          },
        });
      },
    });
  }

  openPackingNoteInNewWindow(text: string, entry: LoadingQueue | null): void {
    const dispatchId = entry?.dispatchId ?? entry?.id ?? null;
    const title = `Packing Note - ${entry?.routeCode ?? (dispatchId ? 'DSP-' + dispatchId : 'Packing Note')}`;

    const renderHtml = (itemsHtml: string) => {
      const html = `
      <!doctype html>
      <html>
      <head>
        <meta charset="utf-8" />
        <title>${title}</title>
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial; margin:24px; color:#111827 }
          .card { max-width:900px; margin:0 auto; border:1px solid #e5e7eb; padding:20px; border-radius:8px }
          h1 { font-size:18px; margin-bottom:6px }
          .meta { color:#374151; font-size:13px; margin-bottom:12px }
          pre { white-space:pre-wrap; word-break:break-word; background:#f8fafc; padding:12px; border-radius:6px; border:1px solid #e6eef6 }
          .footer { margin-top:18px; font-size:12px; color:#6b7280 }
          @media print { button#print-btn { display:none } }
          .row { display:flex; gap:12px; margin-bottom:6px }
          .label { width:110px; color:#374151; font-weight:600 }
          table { width:100%; border-collapse:collapse; margin-top:12px }
          th, td { border:1px solid #e5e7eb; padding:8px; text-align:left }
          th { background:#f3f4f6; font-weight:700 }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>${title}</h1>
          <div class="meta">
            <div class="row"><div class="label">Delivery Date</div><div>${entry?.deliveryDate ? new Date(entry.deliveryDate).toLocaleDateString() : '—'}</div></div>
            <div class="row"><div class="label">From</div><div>${entry?.from ?? '—'}</div></div>
            <div class="row"><div class="label">To</div><div>${entry?.to ?? '—'}</div></div>
            <div class="row"><div class="label">Truck</div><div>${entry?.truckPlate ?? '—'}</div></div>
            <div class="row"><div class="label">Driver</div><div>${entry?.driverName ?? '—'}</div></div>
          </div>
          ${itemsHtml}
          <div style="margin-top:12px">
            <h3>Packing Note</h3>
            <pre>${this.escapeHtml(text || '')}</pre>
          </div>
          <div class="footer">Generated on ${new Date().toLocaleString()}</div>
          <div style="margin-top:12px; text-align:right"><button id="print-btn" onclick="window.print()" style="padding:8px 14px; background:#2563eb;color:#fff;border:none;border-radius:6px;cursor:pointer">Print</button></div>
        </div>
      </body>
      </html>
    `;

      const win = window.open('', '_blank');
      if (!win) {
        this.toastr.error('Unable to open print window (popup blocked).');
        return;
      }
      win.document.open();
      win.document.write(html);
      win.document.close();
      setTimeout(() => {
        try {
          win.focus();
        } catch (e) {}
      }, 200);
    };

    // If we have a dispatch id, fetch full dispatch to get order items; otherwise render text-only
    if (dispatchId && typeof dispatchId === 'number') {
      this.dispatchService.getDispatchById(dispatchId).subscribe({
        next: (res) => {
          const d = (res as any).data ?? res;
          const transportOrder = d?.transportOrder ?? d?.order ?? null;
          const items = transportOrder?.items ?? transportOrder?.orderItems ?? [];
          let itemsHtml = '';
          if (items && items.length) {
            const rows = items
              .map((it: any, idx: number) => {
                const name = this.escapeHtml(
                  String(it.itemName ?? it.itemNameKh ?? it.itemCode ?? ''),
                );
                const qty = this.escapeHtml(String(it.quantity ?? it.qty ?? ''));
                const unit = this.escapeHtml(String(it.unitOfMeasurement ?? it.uom ?? ''));
                return `<tr><td>${idx + 1}</td><td>${name}</td><td>${qty}</td><td>${unit}</td></tr>`;
              })
              .join('\n');
            itemsHtml = `<div><h3>Order Items</h3><table><thead><tr><th>#</th><th>Description</th><th>Qty</th><th>Unit</th></tr></thead><tbody>${rows}</tbody></table></div>`;
          } else {
            itemsHtml = `<div><h3>Order Items</h3><div style="color:#6b7280">No line items available</div></div>`;
          }
          renderHtml(itemsHtml);
        },
        error: () => {
          // fallback to text-only rendering
          renderHtml(
            `<div><h3>Order Items</h3><div style="color:#6b7280">Unable to load items</div></div>`,
          );
        },
      });
    } else {
      renderHtml(
        `<div><h3>Order Items</h3><div style="color:#6b7280">No dispatch selected</div></div>`,
      );
    }
  }

  private escapeHtml(s: string): string {
    return (s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  selectPreload(entry: LoadingQueue): void {
    this.selectedEntry = entry;
    if (entry.driverName) {
      this.driverSearchTerm = entry.driverName;
      this.recomputeDrivers();
    }
  }

  isSelected(entry: LoadingQueue): boolean {
    return (
      !!this.selectedEntry &&
      (this.selectedEntry.dispatchId === entry.dispatchId ||
        this.selectedEntry.routeCode === entry.routeCode)
    );
  }

  private mapDispatchToQueue(d: Dispatch): LoadingQueue {
    const status = (d as any).status ?? (d as any).dispatchStatus ?? 'PENDING';
    const transportOrder: any = (d as any).transportOrder;
    const stops: any[] = transportOrder?.stops ?? (d as any).stops ?? [];
    const pickup = stops.find((s) => (s.type ?? '').toUpperCase() === 'PICKUP') ?? stops[0];
    const drop =
      stops.find((s) => (s.type ?? '').toUpperCase() === 'DROP') ?? stops[stops.length - 1];

    const pickupName =
      pickup?.address?.name ??
      pickup?.locationName ??
      pickup?.address ??
      (pickup?.addressId ? `Stop ${pickup.addressId}` : undefined);
    const dropName =
      drop?.address?.name ??
      drop?.locationName ??
      drop?.address ??
      (drop?.addressId ? `Stop ${drop.addressId}` : undefined);

    const deliveryDateValue =
      (d as any).deliveryDate ??
      transportOrder?.deliveryDate ??
      (d as any).estimatedArrival ??
      transportOrder?.estimatedArrival ??
      (d as any).startTime;

    return {
      id: d.id ?? 0,
      dispatchId: d.id ?? 0,
      routeCode: d.routeCode,
      deliveryDate: this.normalizeDate(deliveryDateValue),
      customerName: d.customerName ?? transportOrder?.customerName,
      from: d.pickupName ?? d.pickupLocation ?? (d as any).from_location ?? pickupName,
      to: d.dropoffName ?? d.dropoffLocation ?? (d as any).to_location ?? dropName,
      driverName: d.driverName,
      driverPhone: (d as any).driverPhone,
      driverLicense: (d as any).driverLicense,
      truckPlate: d.licensePlate,
      warehouseCode: this.selectedWarehouse,
      status: status as any,
      safetyStatus:
        status === 'SAFETY_PASSED' ? 'PASSED' : status === 'SAFETY_FAILED' ? 'FAILED' : 'PENDING',
    };
  }

  private normalizeDate(value: any): any {
    if (!value) return undefined;
    // handle LocalDate or LocalDateTime arrays: [yyyy, MM, dd, hh?, mm?, ss?]
    if (Array.isArray(value)) {
      const [y, m = 1, d = 1, hh = 0, mm = 0, ss = 0] = value;
      return new Date(y, m - 1, d, hh, mm, ss);
    }
    return value;
  }

  // ===== Orders/Drivers helpers for template alignment =====
  get filteredUnassignedOrders(): LoadingQueue[] {
    return this.unassignedOrders.filter((o) => {
      const term = this.searchOrders.trim().toLowerCase();
      if (
        term &&
        !`${o.routeCode ?? ''} ${o.customerName ?? ''} ${o.from ?? ''} ${o.to ?? ''}`
          .toLowerCase()
          .includes(term)
      ) {
        return false;
      }
      if (
        this.deliveryFrom &&
        o.deliveryDate &&
        new Date(o.deliveryDate) < new Date(this.deliveryFrom)
      )
        return false;
      if (this.deliveryTo && o.deliveryDate && new Date(o.deliveryDate) > new Date(this.deliveryTo))
        return false;
      return true;
    });
  }

  get filteredAssignedOrders(): LoadingQueue[] {
    return this.assignedOrders;
  }

  toggleOrderSelection(id: number, checked: boolean): void {
    if (checked) this.selectedOrderIds.add(id);
    else this.selectedOrderIds.delete(id);
  }

  toggleSelectAllOrders(list: LoadingQueue[], checked: boolean): void {
    list.forEach((o) => {
      if (o.dispatchId) {
        checked
          ? this.selectedOrderIds.add(o.dispatchId)
          : this.selectedOrderIds.delete(o.dispatchId);
      }
    });
  }

  toggleDispatchSelection(id: number, checked: boolean): void {
    if (checked) this.selectedDispatchIds.add(id);
    else this.selectedDispatchIds.delete(id);
  }

  toggleSelectAllDispatches(list: LoadingQueue[], checked: boolean): void {
    list.forEach((o) => {
      if (o.dispatchId) {
        checked
          ? this.selectedDispatchIds.add(o.dispatchId)
          : this.selectedDispatchIds.delete(o.dispatchId);
      }
    });
  }

  get pagedDrivers(): any[] {
    const start = this.driverPage * this.driverPageSize;
    return this.filteredDrivers.slice(start, start + this.driverPageSize);
  }

  get allDriversSelected(): boolean {
    return this.selectedDriver && this.filteredDrivers.some((d) => d.id === this.selectedDriver.id);
  }

  selectDriver(driver: any): void {
    this.selectedDriver = driver;
    const match = this.queue.find(
      (q) => q.driverName === driver.name || q.driverName === driver.fullName,
    );
    if (match) {
      this.selectedEntry = match;
    }
  }

  selectFirstFilteredDriver(): void {
    if (this.filteredDrivers.length) {
      this.selectDriver(this.filteredDrivers[0]);
    }
  }

  quickPickDriver(): void {
    this.selectFirstFilteredDriver();
  }

  onDriverSearchChange(term: string): void {
    this.searchDrivers = term;
    this.recomputeDrivers();
  }

  private recomputeDrivers(): void {
    const seen = new Set<string>();
    const drivers = this.queue
      .filter((q) => q.driverName)
      .map((q) => ({
        id: q.driverName,
        name: q.driverName,
        fullName: q.driverName,
        phone: q.driverPhone,
        status: 'ONLINE',
        assignedVehicle: { licensePlate: q.truckPlate },
      }))
      .filter((d) => {
        if (!d.name) return false;
        if (seen.has(d.name)) return false;
        seen.add(d.name);
        return true;
      });
    const term = this.searchDrivers.trim().toLowerCase();
    this.filteredDrivers = term
      ? drivers.filter(
          (d) =>
            (d.name ?? '').toLowerCase().includes(term) ||
            (d.phone ?? '').toLowerCase().includes(term),
        )
      : drivers;
    this.driverPageCount = Math.max(
      1,
      Math.ceil(this.filteredDrivers.length / this.driverPageSize),
    );
    if (this.driverPage >= this.driverPageCount)
      this.driverPage = Math.max(0, this.driverPageCount - 1);
  }

  // Drag handling (horizontal resize is native via CSS; vertical splitter not used)
  startDrag(event: MouseEvent): void {
    event.preventDefault();
    this.dragging = true;
    this.dragStartX = event.clientX;
    this.dragStartWidth = this.leftWidthPx;
    window.addEventListener('mousemove', this.onDrag);
    window.addEventListener('mouseup', this.stopDrag);
  }

  onDrag = (event: MouseEvent): void => {
    if (!this.dragging) return;
    const delta = event.clientX - this.dragStartX;
    const next = this.dragStartWidth + delta;
    this.leftWidthPx = Math.max(480, Math.min(next, 1100));
  };

  stopDrag = (): void => {
    if (!this.dragging) return;
    this.dragging = false;
    window.removeEventListener('mousemove', this.onDrag);
    window.removeEventListener('mouseup', this.stopDrag);
  };

  startVerticalDrag(event: MouseEvent): void {
    event.preventDefault();
    this.dragStartY = event.clientY;
    this.dragStartHeight = this.topSectionHeightPx;
    window.addEventListener('mousemove', this.onVerticalDrag);
    window.addEventListener('mouseup', this.stopVerticalDrag);
  }

  onVerticalDrag = (event: MouseEvent): void => {
    const delta = event.clientY - this.dragStartY;
    const next = this.dragStartHeight + delta;
    this.topSectionHeightPx = Math.max(180, Math.min(next, 800));
  };

  // explicit field type needed because this variable is referenced in its own initializer
  stopVerticalDrag: () => void = () => {
    window.removeEventListener('mousemove', this.onVerticalDrag);
    window.removeEventListener('mouseup', this.stopVerticalDrag);
  };

  assignSelected(): void {
    this.toastr.info('Assign action placeholder. Wire to backend assign endpoint.');
  }

  private computeMetrics(): void {
    const totals = { waiting: 0, called: 0, loading: 0, loaded: 0 };
    this.queue.forEach((q) => {
      if (q.status === 'WAITING') totals.waiting += 1;
      else if (q.status === 'CALLED') totals.called += 1;
      else if (q.status === 'LOADING') totals.loading += 1;
      else if (q.status === 'LOADED') totals.loaded += 1;
    });
    this.metrics = totals;
  }

  get filteredQueue(): LoadingQueue[] {
    return this.queue
      .filter((q) => {
        if (this.statusFilter !== 'ALL' && q.status !== this.statusFilter) return false;
        if (
          this.deliveryFrom &&
          q.deliveryDate &&
          new Date(q.deliveryDate) < new Date(this.deliveryFrom)
        ) {
          return false;
        }
        if (
          this.deliveryTo &&
          q.deliveryDate &&
          new Date(q.deliveryDate) > new Date(this.deliveryTo)
        ) {
          return false;
        }
        if (!this.searchTerm) return true;
        const term = this.searchTerm.toLowerCase();
        return (
          q.routeCode?.toLowerCase().includes(term) ||
          q.dispatchId?.toString().includes(term) ||
          q.driverName?.toLowerCase().includes(term) ||
          q.truckPlate?.toLowerCase().includes(term) ||
          q.customerName?.toLowerCase().includes(term) ||
          q.from?.toLowerCase().includes(term) ||
          q.to?.toLowerCase().includes(term)
        );
      })
      .sort((a, b) => (a.queuePosition ?? 0) - (b.queuePosition ?? 0));
  }

  get unloadedQueue(): LoadingQueue[] {
    return this.filteredQueue.filter((q) => q.status !== 'LOADED');
  }

  get loadedQueue(): LoadingQueue[] {
    return this.filteredQueue.filter((q) => q.status === 'LOADED');
  }

  get unassignedOrders(): LoadingQueue[] {
    return this.unloadedQueue;
  }

  get assignedOrders(): LoadingQueue[] {
    return this.loadedQueue;
  }

  get driverOptions(): LoadingQueue[] {
    const seen = new Set<string>();
    return this.queue.filter((q) => {
      if (!q.driverName) return false;
      if (this.driverSearchTerm) {
        const term = this.driverSearchTerm.toLowerCase();
        if (
          !q.driverName.toLowerCase().includes(term) &&
          !(q.truckPlate ?? '').toLowerCase().includes(term)
        ) {
          return false;
        }
      }
      const key = `${q.driverName}|${q.truckPlate ?? ''}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }

  selectEntry(entry: LoadingQueue): void {
    this.selectedEntry = entry;
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.deliveryFrom = '';
    this.deliveryTo = '';
    this.pageIndex = 0;
    this.load();
  }

  goPage(page: number): void {
    if (page < 0 || page >= this.totalPages) return;
    this.pageIndex = page;
    this.load();
  }

  startLoading(entry: LoadingQueue): void {
    this.toastr.info('Assign/Loading action placeholder. Wire to backend assign endpoint.');
  }

  // ===== Status Update Methods =====

  /**
   * Open status update modal for a dispatch
   */
  openStatusUpdateModal(entry: LoadingQueue): void {
    if (!entry || !entry.dispatchId) {
      this.toastr.error('Invalid dispatch entry');
      return;
    }
    this.statusUpdateEntry = entry;
    this.selectedStatus = (entry.status as any) || 'PENDING';
    this.statusUpdateReason = '';
    this.showStatusUpdateModal = true;
  }

  /**
   * Close status update modal
   */
  closeStatusUpdateModal(): void {
    this.showStatusUpdateModal = false;
    this.statusUpdateEntry = null;
    this.selectedStatus = 'PENDING';
    this.statusUpdateReason = '';
    this.isSubmittingStatus = false;
  }

  /**
   * Submit status update to backend with validation and confirmation
   */
  async submitStatusUpdate(): Promise<void> {
    if (!this.statusUpdateEntry || !this.statusUpdateEntry.dispatchId) {
      this.toastr.error('No dispatch selected');
      return;
    }

    const dispatchId = this.statusUpdateEntry.dispatchId;
    const newStatus = this.selectedStatus;
    const currentStatus = this.statusUpdateEntry.status || 'PENDING';
    const reason = this.statusUpdateReason.trim();

    // Validation: require reason for CANCELLED status
    if (newStatus === 'CANCELLED' && !reason) {
      this.toastr.warning('Please provide a reason for cancellation');
      return;
    }

    // Check if status actually changed
    if (newStatus === currentStatus) {
      this.toastr.info('Status is already ' + this.getStatusLabel(newStatus));
      return;
    }

    // Validate status transition
    if (!this.isValidStatusTransition(currentStatus, newStatus)) {
      this.toastr.warning(
        `Cannot change status from ${this.getStatusLabel(currentStatus)} to ${this.getStatusLabel(newStatus)}`,
        'Invalid Transition',
      );
      return;
    }

    // Show confirmation for critical status changes
    if (newStatus === 'CANCELLED' || newStatus === 'COMPLETED') {
      const action = newStatus === 'CANCELLED' ? 'cancel' : 'complete';
      const confirmed = await this.confirm.confirm(
        `Are you sure you want to ${action} this dispatch?\n\nOrder: ${this.statusUpdateEntry.routeCode || 'DSP-' + dispatchId}\nFrom: ${this.statusUpdateEntry.from || 'N/A'}\nTo: ${this.statusUpdateEntry.to || 'N/A'}${reason ? '\n\nReason: ' + reason : ''}`,
      );
      if (!confirmed) return;
    }

    this.isSubmittingStatus = true;
    this.loading = true;
    this.toastr.info('Updating dispatch status...');

    // Call backend to update dispatch status
    this.dispatchService.updateDispatchStatus(dispatchId, newStatus, reason).subscribe({
      next: () => {
        this.toastr.success(`Status updated to ${this.getStatusLabel(newStatus)}`, 'Success');
        this.closeStatusUpdateModal();
        this.load(); // Reload data to reflect changes
      },
      error: (err) => {
        console.error('Status update failed:', err);
        const errorMsg = err?.error?.message || err?.message || 'Failed to update status';
        this.toastr.error(errorMsg, 'Update Failed');
        this.isSubmittingStatus = false;
        this.loading = false;
      },
    });
  }

  /**
   * Validate if status transition is allowed
   */
  private isValidStatusTransition(currentStatus: string, newStatus: string): boolean {
    const current = currentStatus.toUpperCase();
    const next = newStatus.toUpperCase();

    // Allow same status (no-op)
    if (current === next) return true;

    // CANCELLED can be set from any status
    if (next === 'CANCELLED') return true;

    // Can't change from COMPLETED or CANCELLED to other statuses
    if (current === 'COMPLETED' || current === 'CANCELLED') {
      return false;
    }

    // Valid forward transitions
    const validTransitions: Record<string, string[]> = {
      PENDING: ['CONFIRMED', 'IN_PROGRESS', 'CANCELLED'],
      CONFIRMED: ['IN_PROGRESS', 'COMPLETED', 'CANCELLED'],
      IN_PROGRESS: ['COMPLETED', 'CANCELLED'],
      LOADING: ['LOADED', 'COMPLETED', 'CANCELLED'],
      WAITING: ['CALLED', 'LOADING', 'CANCELLED'],
      CALLED: ['LOADING', 'CANCELLED'],
    };

    return validTransitions[current]?.includes(next) ?? true;
  }

  /**
   * Quick status update - Confirm dispatch
   */
  async quickConfirmDispatch(entry: LoadingQueue): Promise<void> {
    if (!entry || !entry.dispatchId) return;

    const confirmed = await this.confirm.confirm(
      `Confirm this dispatch?\n\nOrder: ${entry.routeCode || 'DSP-' + entry.dispatchId}\nDriver: ${entry.driverName || 'N/A'}`,
    );
    if (!confirmed) return;

    this.loading = true;
    this.dispatchService.updateDispatchStatus(entry.dispatchId, 'CONFIRMED').subscribe({
      next: () => {
        this.toastr.success('Dispatch confirmed');
        this.load();
      },
      error: (err) => {
        console.error('Confirm failed:', err);
        this.toastr.error(err?.error?.message || 'Failed to confirm dispatch');
        this.loading = false;
      },
    });
  }

  /**
   * Quick status update - Start loading
   */
  quickStartLoading(entry: LoadingQueue): void {
    if (!entry || !entry.dispatchId) return;

    this.loading = true;
    this.dispatchService.updateDispatchStatus(entry.dispatchId, 'IN_PROGRESS').subscribe({
      next: () => {
        this.toastr.success('Loading started');
        this.load();
      },
      error: (err) => {
        console.error('Start loading failed:', err);
        this.toastr.error(err?.error?.message || 'Failed to start loading');
        this.loading = false;
      },
    });
  }

  /**
   * Quick status update - Complete dispatch
   */
  async quickCompleteDispatch(entry: LoadingQueue): Promise<void> {
    if (!entry || !entry.dispatchId) return;

    const confirmed = await this.confirm.confirm(
      `Mark this dispatch as completed?\n\nOrder: ${entry.routeCode || 'DSP-' + entry.dispatchId}`,
    );
    if (!confirmed) return;

    this.loading = true;
    this.dispatchService.updateDispatchStatus(entry.dispatchId, 'COMPLETED').subscribe({
      next: () => {
        this.toastr.success('Dispatch completed');
        this.load();
      },
      error: (err) => {
        console.error('Complete failed:', err);
        this.toastr.error(err?.error?.message || 'Failed to complete dispatch');
        this.loading = false;
      },
    });
  }

  /**
   * Get status badge CSS class for styling
   */
  getStatusBadgeClass(status?: string): string {
    if (!status) return 'badge-default';
    const s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
        return 'badge-pending';
      case 'CONFIRMED':
        return 'badge-confirmed';
      case 'IN_PROGRESS':
      case 'LOADING':
        return 'badge-in-progress';
      case 'COMPLETED':
      case 'LOADED':
        return 'badge-completed';
      case 'CANCELLED':
        return 'badge-cancelled';
      default:
        return 'badge-default';
    }
  }

  /**
   * Get user-friendly status label
   */
  getStatusLabel(status?: string): string {
    if (!status) return 'Unknown';
    const s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'LOADING':
        return 'Loading';
      case 'COMPLETED':
        return 'Completed';
      case 'LOADED':
        return 'Loaded';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
