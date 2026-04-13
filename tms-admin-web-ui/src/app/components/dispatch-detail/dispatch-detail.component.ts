import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterModule } from '@angular/router';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

import { environment } from '../../environments/environment';
import type { DispatchStatusHistory } from '../../models/dispatch-status-history.model';
import type { Dispatch } from '../../models/dispatch.model';
import type {
  DispatchActionMetadata,
  DispatchStatusUpdateResponse,
} from '../../services/dispatch.service';
import { DispatchService } from '../../services/dispatch.service';
import { ImagePreviewModalComponent } from '../../shared/image-preview-modal/image-preview-modal.component';

type StopLike = {
  type?: string;
  address?: {
    name?: string;
    address?: string;
    city?: string;
    province?: string;
    state?: string;
  };
  latitude?: number;
  longitude?: number;
  location?: string;
  stopTime?: string;
  appointmentTime?: string;
  checkInTime?: string;
  checkOutTime?: string;
  actualArrival?: string;
  actualDeparture?: string;
  status?: string;
  notes?: string;
};

@Component({
  selector: 'app-dispatch-detail',
  standalone: true,
  imports: [CommonModule, RouterModule, ImagePreviewModalComponent],
  templateUrl: './dispatch-detail.component.html',
  styleUrls: ['./dispatch-detail.component.css'],
})
export class DispatchDetailComponent implements OnInit {
  readonly baseUrl = `${environment.baseUrl}/uploads/`;
  readonly fallbackImage = 'assets/images/image-placeholder.png';
  readonly fallbackSignature = 'assets/images/signature-placeholder.png';

  private readonly A4_MARGIN_MM = 10;
  private readonly TAILWIND_COLORS = {
    statusColors: {
      PENDING: { rgb: [202, 138, 4] as [number, number, number] },
      DELIVERED: { rgb: [22, 163, 74] as [number, number, number] },
      CANCELLED: { rgb: [220, 38, 38] as [number, number, number] },
      IN_PROGRESS: { rgb: [37, 99, 235] as [number, number, number] },
      COMPLETED: { rgb: [22, 163, 74] as [number, number, number] },
    },
    theme: {
      primary: [37, 99, 235] as [number, number, number],
      text: [31, 41, 55] as [number, number, number],
      textSecondary: [75, 85, 99] as [number, number, number],
      cardBg: [249, 250, 251] as [number, number, number],
      white: [255, 255, 255] as [number, number, number],
    },
  };

  dispatchId = 0;
  dispatch?: Dispatch;
  statusHistory: DispatchStatusHistory[] = [];
  actionPayload: DispatchStatusUpdateResponse | null = null;
  actionLoading = false;

  showModal = false;
  modalImages: string[] = [];
  currentImageIndex = 0;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly dispatchService: DispatchService,
  ) {}

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    this.dispatchId = idParam ? parseInt(idParam, 10) : 0;

    if (this.dispatchId > 0) {
      this.loadDispatch();
      this.loadStatusHistory();
      this.loadAvailableActions();
    } else {
      console.error('Invalid dispatch id');
    }
  }

  loadDispatch(): void {
    this.dispatchService.getDispatchById(this.dispatchId).subscribe({
      next: (res) => {
        this.dispatch = res.data;
      },
      error: (err) => console.error('[DispatchDetail] failed to load:', err),
    });
  }

  loadStatusHistory(): void {
    this.dispatchService.getStatusHistory(this.dispatchId).subscribe({
      next: (res) => {
        this.statusHistory = res.data ?? [];
      },
      error: (err) => console.error('[DispatchDetail] failed to load status history:', err),
    });
  }

  loadAvailableActions(): void {
    this.actionLoading = true;
    this.dispatchService.getAvailableActions(this.dispatchId).subscribe({
      next: (res) => {
        this.actionPayload = res?.data || null;
        this.actionLoading = false;
      },
      error: (err) => {
        console.error('[DispatchDetail] failed to load available actions:', err);
        this.actionPayload = null;
        this.actionLoading = false;
      },
    });
  }

  onImageError(event: Event, isImage = true): void {
    const img = event.target as HTMLImageElement;
    img.src = isImage ? this.fallbackImage : this.fallbackSignature;
  }

  openPreview(images: string[], index = 0): void {
    this.modalImages = images.map((img) => this.buildUploadUrl(img));
    this.currentImageIndex = index;
    this.showModal = true;
  }

  buildUploadUrl(path?: string): string {
    if (!path) return '';
    const cleaned = path
      .replace(/^https?:\/\/[^/]+/i, '')
      .replace(/^\/+/, '')
      .replace(/^uploads\/+/i, '')
      .replace(/^\/+/, '');
    return `${this.baseUrl}${cleaned}`.replace(/([^:]\/)\/+/g, '$1');
  }

  closeModal(): void {
    this.showModal = false;
  }

  toDate(v: unknown): Date | null {
    if (v == null) return null;
    if (v instanceof Date) return v;

    if (typeof v === 'string') {
      if (/^\d{4},\d{1,2},\d{1,2}/.test(v)) {
        v = v.split(',').map((x) => +x);
      } else {
        const d = new Date(v);
        return Number.isNaN(+d) ? null : d;
      }
    }

    if (typeof v === 'number') {
      const ms = v > 1_000_000_000_000 ? v : v > 1_000_000_000 ? v * 1000 : v;
      const d = new Date(ms);
      return Number.isNaN(+d) ? null : d;
    }

    if (Array.isArray(v)) {
      const [y, m, d, hh = 0, mm = 0, ss = 0, nanos = 0] = v;
      const ms = Math.floor((nanos || 0) / 1_000_000);
      return new Date(y, (m ?? 1) - 1, d ?? 1, hh, mm, ss, ms);
    }

    if (typeof v === 'object' && v !== null && 'year' in v && 'month' in v && 'day' in v) {
      const value = v as {
        year: number;
        month: number;
        day: number;
        hour?: number;
        minute?: number;
        second?: number;
        nano?: number;
      };
      const ms = Math.floor((value.nano ?? 0) / 1_000_000);
      return new Date(
        value.year,
        (value.month ?? 1) - 1,
        value.day ?? 1,
        value.hour ?? 0,
        value.minute ?? 0,
        value.second ?? 0,
        ms,
      );
    }

    return null;
  }

  printTripDetails(): void {
    window.print();
  }

  exportTripDetailsToPDF(): void {
    if (!this.dispatch) {
      console.error('[DispatchDetail] cannot export: dispatch is undefined');
      return;
    }

    const pdf = new jsPDF('p', 'mm', 'a4');
    const margin = this.A4_MARGIN_MM;
    let y = margin;

    const toStr = (value: unknown) => {
      const d = this.toDate(value);
      return d ? d.toLocaleString() : '-';
    };

    const getStatusColor = (status?: string): [number, number, number] => {
      if (!status) return this.TAILWIND_COLORS.theme.text;
      const colorObj = (this.TAILWIND_COLORS.statusColors as Record<string, { rgb: [number, number, number] }>)[
        status
      ];
      return colorObj ? colorObj.rgb : this.TAILWIND_COLORS.theme.text;
    };

    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(18);
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.text);
    pdf.text('Dispatch Operations Sheet', margin, y);

    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(11);
    pdf.setTextColor(...getStatusColor(this.dispatch.status));
    pdf.text(this.humanizeStatus(this.dispatch.status), 210 - margin, y, { align: 'right' });

    pdf.setFont('helvetica', 'normal');
    pdf.setFontSize(10);
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.textSecondary);
    pdf.text('Operational overview, stops, proof, and status history', margin, y + 6);
    y += 14;

    const colW = (210 - margin * 2) / 3;
    const t1x = margin;
    const t2x = margin + colW;
    const t3x = margin + colW * 2;

    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(11);
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.text);
    pdf.text('Dispatch', t1x, y);
    pdf.text('Timing', t2x, y);
    pdf.text('Driver & Vehicle', t3x, y);

    pdf.setFont('helvetica', 'normal');
    pdf.setFontSize(9);
    y += 6;

    pdf.text(`Dispatch ID: ${this.dispatch.id ?? '-'}`, t1x, y);
    pdf.text(`Route Code: ${this.dispatch.routeCode ?? '-'}`, t1x, y + 5);
    pdf.text(`Reference: ${this.dispatch.orderReference ?? '-'}`, t1x, y + 10);
    pdf.text(`Trip No: ${this.dispatch.transportOrder?.tripNo ?? '-'}`, t1x, y + 15);

    pdf.text(`Start: ${toStr(this.dispatch.startTime)}`, t2x, y);
    pdf.text(`ETA: ${toStr(this.dispatch.estimatedArrival)}`, t2x, y + 5);
    pdf.text(`Delivery: ${toStr(this.dispatch.expectedDelivery)}`, t2x, y + 10);
    pdf.text(`Updated: ${toStr(this.dispatch.updatedDate)}`, t2x, y + 15);

    pdf.text(`Driver: ${this.dispatch.driverName ?? '-'}`, t3x, y);
    pdf.text(`Phone: ${this.dispatch.driverPhone ?? '-'}`, t3x, y + 5);
    pdf.text(`Plate: ${this.vehicleLabel}`, t3x, y + 10);
    pdf.text(`Customer: ${this.dispatch.customerName ?? '-'}`, t3x, y + 15);

    y += 26;

    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(12);
    pdf.text('Stop Timeline', margin, y);
    y += 6;

    pdf.setFont('helvetica', 'normal');
    pdf.setFontSize(9);
    this.dispatchStops.forEach((stop, index) => {
      const block = `${index + 1}. ${this.stopTypeLabel(stop.type)} | ${this.stopHeadline(stop)} | Appointment: ${toStr(this.stopAppointment(stop))}`;
      pdf.text(block, margin, y, { maxWidth: 190 });
      y += 6;
    });

    y += 2;
    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(12);
    pdf.text('Order Items', margin, y);

    const items = this.itemList;
    const body = items.map((it: any, i: number) => [
      i + 1,
      it.itemCode || '',
      it.itemName || '',
      it.itemType || '',
      it.quantity ?? '',
      it.unitOfMeasurement ?? '',
      it.palletType ?? '',
    ]);

    autoTable(pdf, {
      startY: y + 4,
      head: [['#', 'Code', 'Item', 'Type', 'Qty', 'UOM', 'Pallet']],
      body,
      styles: {
        fontSize: 9,
        cellPadding: 2,
        textColor: this.TAILWIND_COLORS.theme.text,
      },
      headStyles: {
        fillColor: this.TAILWIND_COLORS.theme.primary,
        textColor: this.TAILWIND_COLORS.theme.white,
        fontStyle: 'bold',
      },
      alternateRowStyles: {
        fillColor: this.TAILWIND_COLORS.theme.cardBg,
      },
      didDrawPage: () => {
        const str = `Page ${(pdf as any).internal.getNumberOfPages()}`;
        pdf.setFontSize(9);
        pdf.setTextColor(...this.TAILWIND_COLORS.theme.textSecondary);
        pdf.text(str, 210 - margin, 297 - 8, { align: 'right' });
      },
    });

    autoTable(pdf, {
      startY: (pdf as any).lastAutoTable.finalY + 2,
      theme: 'plain',
      body: [['Totals', '', '', '', this.totalQty(items), '', this.totalPallets(items)]],
      styles: {
        fontStyle: 'bold',
        textColor: this.TAILWIND_COLORS.theme.text,
      },
      columnStyles: {
        4: { halign: 'right' },
        6: { halign: 'right' },
      },
    });

    if (this.statusHistory.length) {
      const sy = (pdf as any).lastAutoTable.finalY + 8;
      pdf.setFont('helvetica', 'bold');
      pdf.setFontSize(12);
      pdf.setTextColor(...this.TAILWIND_COLORS.theme.text);
      pdf.text('Status History', margin, sy);

      const rows = this.statusHistory.map((entry, i) => [
        i + 1,
        this.humanizeStatus(entry.status),
        toStr(entry.updatedAt),
        entry.updatedBy || '-',
        entry.remarks || '',
      ]);

      autoTable(pdf, {
        startY: sy + 4,
        head: [['#', 'Status', 'Time', 'By', 'Remarks']],
        body: rows,
        styles: {
          fontSize: 9,
          cellPadding: 2,
          textColor: this.TAILWIND_COLORS.theme.text,
        },
        headStyles: {
          fillColor: this.TAILWIND_COLORS.theme.primary,
          textColor: this.TAILWIND_COLORS.theme.white,
          fontStyle: 'bold',
        },
      });
    }

    const fileName = `dispatch-${this.dispatch.routeCode || this.dispatch.orderReference || this.dispatch.id}.pdf`;
    pdf.save(fileName);
  }

  copy(value?: string): void {
    if (!value) return;
    void navigator?.clipboard?.writeText?.(value).catch((error: unknown) => {
      console.warn('[DispatchDetail] clipboard write failed', error);
    });
  }

  totalQty(items: any[]): number {
    return Array.isArray(items) ? items.reduce((sum, item) => sum + (Number(item?.quantity) || 0), 0) : 0;
  }

  totalPallets(items: any[]): number {
    return Array.isArray(items) ? items.reduce((sum, item) => sum + (Number(item?.palletType) || 0), 0) : 0;
  }

  get dispatchStops(): StopLike[] {
    const stops = this.dispatch?.transportOrder?.stops;
    if (Array.isArray(stops) && stops.length) return stops;

    const fallback: StopLike[] = [];
    if (this.dispatch?.pickupLocation || this.dispatch?.pickupName) {
      fallback.push({
        type: 'PICKUP',
        location: this.dispatch.pickupName || this.dispatch.pickupLocation,
        address: {
          name: this.dispatch.pickupName,
          address: this.dispatch.pickupLocation,
        },
        latitude: this.dispatch.pickupLat,
        longitude: this.dispatch.pickupLng,
      });
    }
    if (this.dispatch?.dropoffLocation || this.dispatch?.dropoffName) {
      fallback.push({
        type: 'DROPOFF',
        location: this.dispatch.dropoffName || this.dispatch.dropoffLocation,
        address: {
          name: this.dispatch.dropoffName,
          address: this.dispatch.dropoffLocation,
        },
        latitude: this.dispatch.dropoffLat,
        longitude: this.dispatch.dropoffLng,
      });
    }
    return fallback;
  }

  get itemList(): any[] {
    return Array.isArray(this.dispatch?.transportOrder?.items) ? this.dispatch!.transportOrder.items : [];
  }

  get stopCount(): number {
    return this.dispatchStops.length;
  }

  get itemCount(): number {
    return this.itemList.length;
  }

  get proofCount(): number {
    return (this.dispatch?.loadingProofImages?.length || 0) + (this.dispatch?.unloadingProofImages?.length || 0);
  }

  get hasTracking(): boolean {
    return (this.dispatch?.locationLogs?.length || 0) > 0 || !!this.dispatch?.lastLocation;
  }

  get vehicleLabel(): string {
    return this.dispatch?.licensePlate || this.dispatch?.transportOrder?.truckNumber || '-';
  }

  get latestTimelineEvent(): DispatchStatusHistory | null {
    return this.statusHistory.length ? this.statusHistory[0] : null;
  }

  get availableActions(): DispatchActionMetadata[] {
    return [...(this.actionPayload?.availableActions || [])].sort(
      (a, b) => (a.priority ?? 999) - (b.priority ?? 999),
    );
  }

  get primaryAction(): DispatchActionMetadata | null {
    const actions = this.availableActions;
    if (!actions.length) return null;
    const preferredTargets = [
      'DRIVER_CONFIRMED',
      'ARRIVED_LOADING',
      'IN_QUEUE',
      'LOADING',
      'LOADED',
    ];
    return (
      actions.find((action) => preferredTargets.includes(action.targetStatus || '') && !action.isDestructive) ||
      actions.find((action) => !action.isDestructive) ||
      actions[0]
    );
  }

  get alerts(): string[] {
    const alerts: string[] = [];
    if (!this.dispatch?.driverName) alerts.push('Driver is not assigned yet.');
    if (!this.vehicleLabel || this.vehicleLabel === '-') alerts.push('Vehicle or plate number is missing.');
    if (!this.stopCount) alerts.push('No stops are attached to this dispatch.');
    if (!this.dispatch?.estimatedArrival) alerts.push('ETA is missing.');
    if (this.dispatch?.preEntrySafetyRequired && this.dispatch?.preEntrySafetyStatus !== 'PASSED') {
      alerts.push('Pre-entry safety is required but not cleared.');
    }
    if (['DELIVERED', 'COMPLETED'].includes(this.dispatch?.status || '') && !this.hasUnloadProof) {
      alerts.push('Unload proof is missing for a delivered dispatch.');
    }
    if (!this.hasTracking) alerts.push('No tracking history has been received yet.');
    return alerts;
  }

  get hasLoadProof(): boolean {
    return !!(this.dispatch?.loadingProofImages?.length || this.dispatch?.loadingSignature);
  }

  get hasUnloadProof(): boolean {
    return !!(this.dispatch?.unloadingProofImages?.length || this.dispatch?.unloadingSignature);
  }

  get completionScore(): number {
    const checks = [
      !!this.dispatch?.driverName,
      this.vehicleLabel !== '-',
      this.stopCount > 0,
      !!this.dispatch?.estimatedArrival,
      this.hasTracking,
      this.hasLoadProof || this.hasUnloadProof,
    ];
    const completed = checks.filter(Boolean).length;
    return Math.round((completed / checks.length) * 100);
  }

  get documentChecklist(): Array<{ label: string; ready: boolean; note: string }> {
    return [
      {
        label: 'Loading proof',
        ready: this.hasLoadProof,
        note: this.hasLoadProof ? 'Image or signature uploaded' : 'No loading evidence attached',
      },
      {
        label: 'Unloading proof',
        ready: this.hasUnloadProof,
        note: this.hasUnloadProof ? 'Delivery evidence available' : 'No unload evidence attached',
      },
      {
        label: 'Tracking feed',
        ready: this.hasTracking,
        note: this.hasTracking ? 'Location logs or last location received' : 'No tracking signal yet',
      },
      {
        label: 'Safety clearance',
        ready: !this.dispatch?.preEntrySafetyRequired || this.dispatch?.preEntrySafetyStatus === 'PASSED',
        note:
          !this.dispatch?.preEntrySafetyRequired
            ? 'Not required for this dispatch'
            : this.dispatch?.preEntrySafetyStatus || 'Pending safety completion',
      },
    ];
  }

  statusTone(status?: string): string {
    switch ((status || '').toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return 'status-success';
      case 'CANCELLED':
      case 'FAILED':
      case 'PROBLEM':
        return 'status-danger';
      case 'PENDING':
      case 'WAITING':
        return 'status-warning';
      default:
        return 'status-info';
    }
  }

  humanizeStatus(status?: string): string {
    if (!status) return 'Unknown';
    return status
      .toString()
      .toLowerCase()
      .split('_')
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join(' ');
  }

  actionLabel(action: DispatchActionMetadata): string {
    const label = (action.actionLabel || '').trim();
    if (!label) return this.humanizeStatus(action.targetStatus);

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

    return map[shortKey] || this.humanizeStatus(shortKey);
  }

  stopTypeLabel(type?: string): string {
    switch ((type || '').toUpperCase()) {
      case 'PICKUP':
        return 'Pickup';
      case 'DROP':
      case 'DROPOFF':
        return 'Delivery';
      default:
        return this.humanizeStatus(type || 'stop');
    }
  }

  stopHeadline(stop: StopLike): string {
    return stop.address?.name || stop.location || stop.address?.address || 'Location pending';
  }

  stopAddress(stop: StopLike): string {
    const parts = [
      stop.address?.address,
      stop.address?.city,
      stop.address?.province || stop.address?.state,
    ].filter(Boolean);
    return parts.join(', ') || stop.location || '-';
  }

  stopAppointment(stop: StopLike): unknown {
    return (
      stop.appointmentTime ||
      stop.stopTime ||
      stop.checkInTime ||
      stop.actualArrival ||
      this.dispatch?.expectedDelivery ||
      null
    );
  }

  buildMapsUrl(args: { lat?: number; lng?: number; address?: string }): string | null {
    if (args.lat != null && args.lng != null) {
      return `https://maps.google.com/?q=${args.lat},${args.lng}`;
    }
    if (args.address?.trim()) {
      return `https://maps.google.com/?q=${encodeURIComponent(args.address.trim())}`;
    }
    return null;
  }

  proofMeta(kind: 'loading' | 'unloading'): { count: number; uploadedAt: unknown; uploadedBy: string } {
    if (kind === 'loading') {
      return {
        count: this.dispatch?.loadingProofImages?.length || 0,
        uploadedAt: this.dispatch?.loadingUploadedAt,
        uploadedBy: this.dispatch?.loadingUploadedBy || '-',
      };
    }
    return {
      count: this.dispatch?.unloadingProofImages?.length || 0,
      uploadedAt: this.dispatch?.unloadingUploadedAt,
      uploadedBy: this.dispatch?.unloadingUploadedBy || '-',
    };
  }

  metricValue(value: unknown, fallback = '-'): string | number {
    if (value == null || value === '') return fallback;
    return value as string | number;
  }
}
