import { CommonModule } from '@angular/common';
import type { ElementRef, OnInit } from '@angular/core';
import { Component, ViewChild } from '@angular/core';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ActivatedRoute } from '@angular/router';
import { RouterModule } from '@angular/router';
import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

import { environment } from '../../environments/environment';
import type { DispatchStatusHistory } from '../../models/dispatch-status-history.model';
import type { Dispatch } from '../../models/dispatch.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DispatchService } from '../../services/dispatch.service';
import { ImagePreviewModalComponent } from '../../shared/image-preview-modal/image-preview-modal.component';

@Component({
  selector: 'app-dispatch-detail',
  standalone: true,
  imports: [CommonModule, RouterModule, ImagePreviewModalComponent],
  templateUrl: './dispatch-detail.component.html',
  styleUrls: ['./dispatch-detail.component.css'],
})
export class DispatchDetailComponent implements OnInit {
  @ViewChild('tripDetailsContent', { static: false }) tripDetailsContent!: ElementRef;

  readonly baseUrl = `${environment.baseUrl}/uploads/`;
  readonly fallbackImage = 'assets/images/image-placeholder.png';
  readonly fallbackSignature = 'assets/images/signature-placeholder.png';

  // A4 Paper dimensions: 210mm x 297mm
  private readonly A4_MARGIN_MM = 10; // Consistent with print CSS
  private readonly TAILWIND_COLORS = {
    // Status badge colors (must match print CSS)
    statusColors: {
      PENDING: { rgb: [202, 138, 4] as [number, number, number], hex: '#ca8a04', label: 'Yellow' },
      DELIVERED: { rgb: [22, 163, 74] as [number, number, number], hex: '#16a34a', label: 'Green' },
      CANCELLED: { rgb: [220, 38, 38] as [number, number, number], hex: '#dc2626', label: 'Red' },
      IN_PROGRESS: {
        rgb: [37, 99, 235] as [number, number, number],
        hex: '#2563eb',
        label: 'Blue',
      },
      COMPLETED: { rgb: [22, 163, 74] as [number, number, number], hex: '#16a34a', label: 'Green' },
    },
    // Theme colors (must match Tailwind colors)
    theme: {
      primary: [37, 99, 235] as [number, number, number], // blue-600
      success: [22, 163, 74] as [number, number, number], // green-600
      warning: [202, 138, 4] as [number, number, number], // yellow-600
      error: [220, 38, 38] as [number, number, number], // red-600
      cardBg: [249, 250, 251] as [number, number, number], // gray-50
      text: [31, 41, 55] as [number, number, number], // gray-800
      textSecondary: [75, 85, 99] as [number, number, number], // gray-600
      border: [209, 213, 219] as [number, number, number], // gray-300
      white: [255, 255, 255] as [number, number, number], // white
    },
  };

  dispatchId!: number;
  dispatch?: Dispatch;
  statusHistory: DispatchStatusHistory[] = [];

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
    } else {
      console.error('Invalid Trip ID');
    }
  }

  loadDispatch(): void {
    this.dispatchService.getDispatchById(this.dispatchId).subscribe({
      next: (res) => {
        this.dispatch = res.data;
        console.log('[Trip] loaded', this.dispatch);
      },
      error: (err) => console.error('[Trip] failed to load:', err),
    });
  }

  loadStatusHistory(): void {
    this.dispatchService.getStatusHistory(this.dispatchId).subscribe({
      next: (res) => {
        this.statusHistory = res.data;
        console.log('[Trip] status history', this.statusHistory);
      },
      error: (err) => console.error('[Trip] failed to load status history:', err),
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

  nextImage(): void {
    if (this.currentImageIndex < this.modalImages.length - 1) {
      this.currentImageIndex++;
    }
  }

  prevImage(): void {
    if (this.currentImageIndex > 0) {
      this.currentImageIndex--;
    }
  }

  /**
   * Normalize various backend date shapes (Jackson arrays, comma-joined strings, ISO strings, Date, or {year,...})
   * into a real JS Date for Angular DatePipe.
   */
  public toDate(v: any): Date | null {
    if (v == null) return null;

    // Already a Date
    if (v instanceof Date) return v;

    // String handling
    if (typeof v === 'string') {
      // Comma-joined Jackson array like "2025,9,6,0,0,0,278382000"
      if (/^\d{4},\d{1,2},\d{1,2}/.test(v)) {
        v = v.split(',').map((x) => +x);
      } else {
        const d = new Date(v);
        return isNaN(+d) ? null : d;
      }
    }

    // Number handling (epoch seconds/ms)
    if (typeof v === 'number') {
      // Heuristic: treat > 10^12 as ms, > 10^9 as seconds
      const ms = v > 1_000_000_000_000 ? v : v > 1_000_000_000 ? v * 1000 : v;
      const d = new Date(ms);
      return isNaN(+d) ? null : d;
    }

    // Array handling: [year, month(1-12), day, hour?, minute?, second?, nanos?]
    if (Array.isArray(v)) {
      const [y, m, d, hh = 0, mm = 0, ss = 0, nanos = 0] = v;
      const ms = Math.floor((nanos || 0) / 1_000_000); // ns → ms
      return new Date(y, (m ?? 1) - 1, d ?? 1, hh, mm, ss, ms); // JS months are 0-based
    }

    // Object fallback (e.g., {year,month,day,hour,minute,second,nano})
    if (typeof v === 'object' && 'year' in v && 'month' in v && 'day' in v) {
      const y = (v as any).year;
      const m = ((v as any).month ?? 1) - 1;
      const d = (v as any).day ?? 1;
      const hh = (v as any).hour ?? 0;
      const mm = (v as any).minute ?? 0;
      const ss = (v as any).second ?? 0;
      const ms = Math.floor(((v as any).nano ?? 0) / 1_000_000);
      return new Date(y, m, d, hh, mm, ss, ms);
    }

    return null;
  }

  printTripDetails(): void {
    // Use browser's native print - simpler, more reliable
    window.print();
  }

  exportTripDetailsToPDF(): void {
    if (!this.dispatch) {
      console.error('[Trip] cannot export: dispatch is undefined');
      return;
    }

    const pdf = new jsPDF('p', 'mm', 'a4');
    const margin = this.A4_MARGIN_MM; // 10mm - consistent with print CSS
    let y = margin;

    // Helper: Convert date value to formatted string
    const toStr = (v: any) => {
      const d = this.toDate(v);
      return d ? d.toLocaleString() : '-';
    };

    // Helper: Get status color
    const getStatusColor = (status?: string): [number, number, number] => {
      if (!status) return this.TAILWIND_COLORS.theme.text;
      const colorObj = (this.TAILWIND_COLORS.statusColors as any)[status];
      return colorObj ? colorObj.rgb : this.TAILWIND_COLORS.theme.text;
    };

    // ==== HEADER ====
    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(18);
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.text); // gray-800
    pdf.text('Delivery Note', margin, y);

    // Status badge with dynamic color
    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(11);
    const statusColor = getStatusColor(this.dispatch.status);
    pdf.setTextColor(...statusColor);
    pdf.text(this.dispatch.status || '-', 210 - margin, y, { align: 'right' });

    // Subtitle
    pdf.setFont('helvetica', 'normal');
    pdf.setFontSize(10);
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.textSecondary); // gray-600
    pdf.text('Full delivery journey and status details', margin, y + 6);
    y += 14;

    // ==== TRIP INFO / TIMING / DRIVER COLUMNS ====
    const colW = (210 - margin * 2) / 3;

    pdf.setFontSize(11);
    pdf.setFont('helvetica', 'bold');
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.text); // gray-800
    pdf.text('Trip Info', margin, y);
    pdf.text('Timing', margin + colW, y);
    pdf.text('Driver & Vehicle', margin + colW * 2, y);

    pdf.setFont('helvetica', 'normal');
    pdf.setFontSize(9);
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.text); // gray-800

    const t1x = margin;
    const t2x = margin + colW;
    const t3x = margin + colW * 2;
    y += 6;

    // Column 1: Trip Info
    pdf.text(`Trip ID: ${this.dispatch.id ?? '-'}`, t1x, y);
    pdf.text(`Route Code: ${this.dispatch.routeCode ?? '-'}`, t1x, y + 5);
    pdf.text(`Ref: ${this.dispatch.orderReference ?? '-'}`, t1x, y + 10);
    pdf.text(`Trip No: ${this.dispatch.transportOrder?.tripNo ?? '-'}`, t1x, y + 15);

    // Column 2: Timing
    pdf.text(`Start: ${toStr(this.dispatch.startTime)}`, t2x, y);
    pdf.text(`ETA: ${toStr(this.dispatch.estimatedArrival)}`, t2x, y + 5);
    pdf.text(`Delivery: ${toStr(this.dispatch.transportOrder?.deliveryDate)}`, t2x, y + 10);
    pdf.text(`TZ: ${Intl.DateTimeFormat().resolvedOptions().timeZone}`, t2x, y + 15);

    // Column 3: Driver & Vehicle
    pdf.text(`Name: ${this.dispatch.driverName ?? '-'}`, t3x, y);
    pdf.text(`Phone: ${this.dispatch.driverPhone ?? '-'}`, t3x, y + 5);
    pdf.text(
      `Plate: ${this.dispatch.licensePlate || this.dispatch.transportOrder?.truckNumber || '-'}`,
      t3x,
      y + 10,
    );

    y += 24;

    // ==== LOCATIONS ====
    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(12);
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.text); // gray-800
    pdf.text('Locations', margin, y);
    y += 6;

    pdf.setFont('helvetica', 'normal');
    pdf.setFontSize(9);
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.text); // gray-800

    const stops = this.dispatch.transportOrder?.stops || [];
    const loading = stops.find((s: any) => s.type === 'PICKUP');
    const unloading = stops.find((s: any) => s.type === 'DROP');
    const addrLine = (a: any) =>
      a ? `${a?.name || ''}${a?.city ? ' - ' + a.city : ''}`.trim() : '-';

    pdf.text(`Loading: ${addrLine(loading?.address)}`, margin, y);
    y += 5;
    pdf.text(`Unloading: ${addrLine(unloading?.address)}`, margin, y);
    y += 6;

    // ==== ORDER ITEMS TABLE ====
    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(12);
    pdf.setTextColor(...this.TAILWIND_COLORS.theme.text); // gray-800
    pdf.text('Order Items', margin, y);
    y += 2;

    const items = this.dispatch.transportOrder?.items || [];
    const body = items.map((it: any, i: number) => [
      i + 1,
      it.itemCode || '',
      it.itemName || '',
      it.itemType || '',
      it.quantity ?? '',
      it.unitOfMeasurement ?? '',
      it.palletType ?? '',
      it.fromDestination ?? '',
      it.toDestination ?? '',
      it.warehouse ?? '',
    ]);

    autoTable(pdf, {
      startY: y + 4,
      head: [
        ['#', 'Item Code', 'Item Name', 'Type', 'Qty', 'UOM', 'Pallet', 'From', 'To', 'Warehouse'],
      ],
      body,
      styles: {
        fontSize: 9,
        cellPadding: 2,
        textColor: this.TAILWIND_COLORS.theme.text, // gray-800
      },
      headStyles: {
        fillColor: this.TAILWIND_COLORS.theme.primary, // blue-600
        textColor: this.TAILWIND_COLORS.theme.white, // white text
        fontStyle: 'bold',
      },
      alternateRowStyles: {
        fillColor: this.TAILWIND_COLORS.theme.cardBg, // gray-50 for alternating rows
      },
      columnStyles: {
        0: { cellWidth: 8 }, // #
        1: { cellWidth: 24 }, // Item Code
        2: { cellWidth: 56 }, // Item Name
        3: { cellWidth: 26 }, // Type
        4: { cellWidth: 14, halign: 'right' }, // Qty
        5: { cellWidth: 16 }, // UOM
        6: { cellWidth: 16, halign: 'right' }, // Pallet
        7: { cellWidth: 16 }, // From
        8: { cellWidth: 16 }, // To
        9: { cellWidth: 22 }, // Warehouse
      },
      didDrawPage: (data) => {
        // Footer page number
        const str = `Page ${(pdf as any).internal.getNumberOfPages()}`;
        pdf.setFontSize(9);
        pdf.setTextColor(...this.TAILWIND_COLORS.theme.textSecondary); // gray-600
        pdf.text(str, 210 - margin, 297 - 8, { align: 'right' });
      },
    });

    // ==== TOTALS ROW ====
    const totalQty = this.totalQty(items);
    const totalPallets = this.totalPallets(items);
    autoTable(pdf, {
      startY: (pdf as any).lastAutoTable.finalY + 2,
      theme: 'plain',
      body: [['Totals', '', '', '', totalQty, '', totalPallets, '', '', '']],
      styles: {
        fontStyle: 'bold',
        textColor: this.TAILWIND_COLORS.theme.text, // gray-800
      },
      columnStyles: {
        4: { halign: 'right' },
        6: { halign: 'right' },
      },
    });

    // ==== DISPATCH STATUS HISTORY ====
    if (this.statusHistory?.length) {
      const sy = (pdf as any).lastAutoTable ? (pdf as any).lastAutoTable.finalY + 8 : y + 60;
      pdf.setFont('helvetica', 'bold');
      pdf.setFontSize(12);
      pdf.setTextColor(...this.TAILWIND_COLORS.theme.text); // gray-800
      pdf.text('Dispatch Status History', margin, sy);

      const rows = this.statusHistory.map((s: any, i: number) => [
        i + 1,
        s.status,
        toStr(s.changedAt),
        s.remark || '',
      ]);
      autoTable(pdf, {
        startY: sy + 4,
        head: [['#', 'Status', 'Time', 'Remark']],
        body: rows,
        styles: {
          fontSize: 9,
          cellPadding: 2,
          textColor: this.TAILWIND_COLORS.theme.text, // gray-800
        },
        headStyles: {
          fillColor: this.TAILWIND_COLORS.theme.primary, // blue-600
          textColor: this.TAILWIND_COLORS.theme.white, // white text
          fontStyle: 'bold',
        },
        columnStyles: {
          0: { cellWidth: 8 },
          1: { cellWidth: 28 },
          2: { cellWidth: 40 },
          3: { cellWidth: 116 },
        },
      });
    }

    // ==== SAVE FILE ====
    const fileName = `trip-details-${this.dispatch.routeCode || this.dispatch.orderReference || 'trip'}.pdf`;
    pdf.save(fileName);
  }

  // Copy helper for code chips / phone
  copy(v: string) {
    try {
      (navigator as any)?.clipboard?.writeText?.(v);
    } catch (e) {
      console.warn('[Trip] clipboard write failed', e);
    }
  }

  // Totals for items table
  totalQty(items: any[]): number {
    return Array.isArray(items) ? items.reduce((s, it) => s + (Number(it?.quantity) || 0), 0) : 0;
  }

  totalPallets(items: any[]): number {
    return Array.isArray(items) ? items.reduce((s, it) => s + (Number(it?.palletType) || 0), 0) : 0;
  }
}
