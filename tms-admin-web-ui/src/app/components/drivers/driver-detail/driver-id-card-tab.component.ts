import { CommonModule } from '@angular/common';
import { Component, ElementRef, EventEmitter, Input, Output, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';

import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';

@Component({
  standalone: true,
  selector: 'app-driver-id-card-tab',
  imports: [CommonModule, FormsModule],
  template: `
    <div class="bg-white rounded-lg shadow-sm p-8 space-y-6">
      <div class="flex items-center justify-between">
        <h3 class="text-2xl font-semibold text-gray-900">Issue ID Card</h3>
        <div class="flex items-center gap-2">
          <button
            type="button"
            (click)="openPreview()"
            [disabled]="previewLoading"
            class="px-3 py-1.5 text-xs font-semibold rounded-full bg-white border border-blue-200 text-blue-700 hover:bg-blue-50 shadow-sm"
          >
            {{ previewLoading ? 'Preparing...' : 'Preview' }}
          </button>
          <button
            type="button"
            (click)="print.emit()"
            class="px-3 py-1.5 text-xs font-semibold rounded-full bg-white border border-blue-200 text-blue-700 hover:bg-blue-50 shadow-sm no-print"
          >
            Print
          </button>
          <button
            type="button"
            (click)="saveLayout()"
            [disabled]="savingLayout"
            class="px-3 py-1.5 text-xs font-semibold rounded-full bg-blue-600 text-white hover:bg-blue-700 shadow-sm"
          >
            {{ savingLayout ? 'Saving...' : 'Save Layout' }}
          </button>
        </div>
      </div>

      <div class="border border-gray-200 rounded-xl overflow-x-auto">
        <table class="min-w-full text-sm">
          <thead class="bg-gray-50 text-gray-600">
            <tr>
              <th class="px-4 py-3 text-left font-semibold">ID Card</th>
              <th class="px-4 py-3 text-left font-semibold">Issued Date</th>
              <th class="px-4 py-3 text-left font-semibold">Expired Date</th>
              <th class="px-4 py-3 text-left font-semibold">Status</th>
            </tr>
          </thead>
          <tbody>
            <tr class="border-t border-gray-100">
              <td class="px-4 py-3 font-semibold text-gray-900">{{ idCardInfo.code || '—' }}</td>
              <td class="px-4 py-3 text-gray-700">{{ issuedDisplayLabel }}</td>
              <td class="px-4 py-3 text-gray-700">{{ expiryLabel }}</td>
              <td class="px-4 py-3">
                <span class="px-2.5 py-1 rounded-full text-xs font-semibold" [ngClass]="statusClass">
                  {{ statusLabel }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 bg-blue-50 border border-blue-100 rounded-xl p-4">
        <div>
          <label class="block text-xs font-semibold text-gray-600 uppercase mb-1">ID Card Number</label>
          <input
            type="text"
            [ngModel]="idCardNumber"
            (ngModelChange)="idCardNumberChange.emit($event || null)"
            class="w-full px-3 py-2 border border-gray-300 rounded-md bg-white text-sm"
            placeholder="CARD-30211"
          />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-600 uppercase mb-1">Issued Date</label>
          <input
            type="date"
            [ngModel]="idCardIssuedDate"
            (ngModelChange)="idCardIssuedDateChange.emit($event || null)"
            class="w-full px-3 py-2 border border-gray-300 rounded-md bg-white text-sm"
          />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-600 uppercase mb-1">Expired Date</label>
          <input
            type="date"
            [ngModel]="idCardExpiry"
            (ngModelChange)="idCardExpiryChange.emit($event || null)"
            class="w-full px-3 py-2 border border-gray-300 rounded-md bg-white text-sm"
          />
        </div>
        <div class="flex items-end">
          <button
            type="button"
            (click)="save.emit()"
            [disabled]="isSubmitting"
            class="w-full px-4 py-2 text-sm font-semibold text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-50"
          >
            {{ isSubmitting ? 'Saving...' : idCardRecordExists ? 'Update ID Card' : 'Create ID Card' }}
          </button>
        </div>
        <div class="flex items-end">
          <button
            type="button"
            (click)="delete.emit()"
            [disabled]="isSubmitting || !idCardRecordExists"
            class="w-full px-4 py-2 text-sm font-semibold text-red-700 bg-white border border-red-300 rounded-md hover:bg-red-50 disabled:opacity-50"
          >
            Delete ID Card
          </button>
        </div>
      </div>

      <div class="id-card-print-area print-area">
        <div class="max-w-3xl mx-auto">
          <div
            #idCardLayout
            class="bg-gradient-to-b from-blue-50 via-white to-white border border-blue-100 rounded-2xl shadow-sm p-6 id-card-surface"
          >
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center gap-3">
                <div class="h-10 w-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold text-sm shadow-sm">
                  SV
                </div>
                <div>
                  <p class="text-xs font-semibold text-blue-700 tracking-widest uppercase">SV Trucking Co., Ltd</p>
                  <p class="text-[11px] text-gray-500 uppercase">Driver Identification Card</p>
                </div>
              </div>
              <div class="flex items-center gap-2">
                <span class="px-3 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-700">ID Card</span>
              </div>
            </div>

            <div class="mb-2 text-center">
              <h3 class="text-2xl font-bold text-gray-900">{{ driverName || 'Driver' }}</h3>
              <p class="text-sm text-gray-500">Share this card to verify driver identity</p>
            </div>

            <div class="flex flex-col items-center text-center gap-4 py-4">
              <div class="w-28 h-28 rounded-2xl border-4 border-blue-200 bg-gray-100 flex items-center justify-center overflow-hidden shadow-sm">
                <ng-container *ngIf="profilePreviewUrl; else initialsBadge">
                  <img [src]="profilePreviewUrl" alt="Driver photo" class="w-full h-full object-cover" />
                </ng-container>
                <ng-template #initialsBadge>
                  <span class="text-2xl font-bold text-gray-700">{{ driverInitials }}</span>
                </ng-template>
              </div>
              <div class="mt-2 inline-flex items-center px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-xs font-semibold">
                Driver
              </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-4">
              <div class="flex items-center justify-between px-3 py-2 rounded-lg bg-gray-50">
                <span class="text-sm text-gray-600">ID</span>
                <span class="text-sm font-semibold text-gray-900">{{ idCardInfo.code || '—' }}</span>
              </div>
              <div class="flex items-center justify-between px-3 py-2 rounded-lg bg-gray-50">
                <span class="text-sm text-gray-600">Phone</span>
                <span class="text-sm font-semibold text-gray-900">{{ idCardInfo.phone || '—' }}</span>
              </div>
              <div class="flex items-center justify-between px-3 py-2 rounded-lg bg-gray-50">
                <span class="text-sm text-gray-600">Group</span>
                <span class="text-sm font-semibold text-gray-900">{{ driverGroupName }}</span>
              </div>
              <div class="flex items-center justify-between px-3 py-2 rounded-lg bg-gray-50">
                <span class="text-sm text-gray-600">Vehicle</span>
                <span class="text-sm font-semibold text-gray-900">{{ idCardInfo.vehicle || '—' }}</span>
              </div>
            </div>

            <div class="mt-6 flex flex-col items-center gap-3">
              <div class="p-4 bg-white border border-gray-200 rounded-2xl shadow-sm">
                <ng-container *ngIf="idCardQrDataUrl; else qrPlaceholder">
                  <img
                    [src]="idCardQrDataUrl"
                    alt="Driver QR"
                    class="w-48 qr-code h-48 object-contain rounded-2xl border border-gray-200 shadow-sm"
                  />
                </ng-container>
                <ng-template #qrPlaceholder>
                  <div class="w-48 h-48 flex items-center justify-center text-gray-400 bg-gray-50 rounded-xl border border-dashed border-gray-300">
                    Generating QR...
                  </div>
                </ng-template>
              </div>
              <div class="text-center">
                <p class="text-xs text-gray-500">Scan to verify driver information</p>
                <p class="text-sm font-semibold text-gray-900 mt-2">ID Card Expiry: {{ idCardInfo.licenseValid || 'Not set' }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        *ngIf="showPreview"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
        (click)="closePreview()"
      >
        <div class="bg-white rounded-2xl shadow-2xl max-w-4xl w-full p-4" (click)="$event.stopPropagation()">
          <div class="flex items-center justify-between mb-3">
            <p class="text-lg font-semibold text-gray-900">ID Card Preview</p>
            <button
              type="button"
              (click)="closePreview()"
              class="px-3 py-1 text-xs font-semibold rounded-full border border-gray-300 text-gray-600 hover:bg-gray-100"
            >
              Close
            </button>
          </div>
          <div class="flex justify-center overflow-auto bg-gray-50 rounded-lg border border-gray-200 p-4">
            <img
              *ngIf="previewImageUrl"
              [src]="previewImageUrl"
              alt="ID card preview"
              class="max-w-full h-auto border border-gray-200 rounded-lg shadow"
            />
          </div>
        </div>
      </div>
    </div>
  `,
})
export class DriverIdCardTabComponent {
  @Input() driverId!: number;
  @Input() driverName = '';
  @Input() profilePreviewUrl: string | null = null;
  @Input() driverInitials = '';
  @Input() driverGroupName = '—';
  @Input() idCardInfo!: { code: string; phone: string; vehicle: string; licenseValid: string };
  @Input() idCardQrDataUrl: string | null = null;
  @Input() idCardNumber: string | null = null;
  @Input() idCardIssuedDate: string | null = null;
  @Input() idCardExpiry: string | null = null;
  @Input() idCardRecordExists = false;
  @Input() isSubmitting = false;
  @Input() issuedDisplayLabel = '—';
  @Input() expiryLabel = '—';
  @Input() statusLabel = 'NO_EXPIRY';
  @Input() statusClass = 'bg-gray-100 text-gray-600';

  @Output() idCardNumberChange = new EventEmitter<string | null>();
  @Output() idCardIssuedDateChange = new EventEmitter<string | null>();
  @Output() idCardExpiryChange = new EventEmitter<string | null>();
  @Output() save = new EventEmitter<void>();
  @Output() delete = new EventEmitter<void>();
  @Output() print = new EventEmitter<void>();

  @ViewChild('idCardLayout') idCardLayoutRef?: ElementRef<HTMLElement>;

  previewLoading = false;
  savingLayout = false;
  showPreview = false;
  previewImageUrl: string | null = null;

  async openPreview(): Promise<void> {
    if (this.previewLoading) return;
    this.previewLoading = true;
    try {
      this.previewImageUrl = await this.generateIdCardImageDataUrl(2);
      this.showPreview = true;
    } finally {
      this.previewLoading = false;
    }
  }

  closePreview(): void {
    this.showPreview = false;
  }

  async saveLayout(): Promise<void> {
    if (this.savingLayout) return;
    this.savingLayout = true;
    try {
      const imageData = await this.generateIdCardImageDataUrl(3);
      const pdf = new jsPDF({
        orientation: 'landscape',
        unit: 'mm',
        format: [85.6, 54],
      });
      const pageW = pdf.internal.pageSize.getWidth();
      const pageH = pdf.internal.pageSize.getHeight();
      pdf.addImage(imageData, 'PNG', 0, 0, pageW, pageH);
      pdf.save(`driver-id-card-${this.driverId || 'new'}.pdf`);
    } finally {
      this.savingLayout = false;
    }
  }

  private async generateIdCardImageDataUrl(scale: number): Promise<string> {
    const node = this.idCardLayoutRef?.nativeElement;
    if (!node) {
      throw new Error('ID card layout not ready');
    }
    const canvas = await html2canvas(node, {
      backgroundColor: '#ffffff',
      scale,
      useCORS: true,
      logging: false,
    });
    return canvas.toDataURL('image/png');
  }
}
