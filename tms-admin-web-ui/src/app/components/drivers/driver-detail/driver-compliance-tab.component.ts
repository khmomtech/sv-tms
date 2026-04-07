import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import type { DriverDocument } from '../../../models/driver-document.model';

@Component({
  standalone: true,
  selector: 'app-driver-compliance-tab',
  imports: [CommonModule, MatProgressSpinnerModule],
  template: `
    <div class="space-y-6">
      <div class="grid gap-6 md:grid-cols-2">
        <div class="bg-white rounded-2xl border border-blue-100 shadow-sm p-6 space-y-4">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900">License</h3>
            <button
              type="button"
              class="px-3 py-1 text-sm font-semibold text-blue-600 border border-blue-200 rounded-full hover:bg-blue-50"
              (click)="uploadLicense.emit()"
            >
              Upload New
            </button>
          </div>
          <div class="text-sm text-gray-600 space-y-2">
            <p><span class="font-semibold text-gray-900">License No:</span> {{ license.number }}</p>
            <p><span class="font-semibold text-gray-900">Class:</span> {{ license.clazz }}</p>
            <p><span class="font-semibold text-gray-900">Expires:</span> {{ license.expires }}</p>
            <p>
              <span class="font-semibold text-gray-900">Status:</span>
              <span
                [ngClass]="{
                  'text-green-700 bg-green-100 px-2 py-0.5 rounded-full': license.tone === 'success',
                  'text-yellow-700 bg-yellow-100 px-2 py-0.5 rounded-full': license.tone === 'warning',
                  'text-red-700 bg-red-100 px-2 py-0.5 rounded-full': license.tone === 'danger',
                  'text-gray-600 bg-gray-100 px-2 py-0.5 rounded-full': license.tone === 'neutral',
                }"
              >
                {{ license.status }}
              </span>
            </p>
          </div>
        </div>

        <div class="bg-white rounded-2xl border border-blue-100 shadow-sm p-6 space-y-4">
          <h3 class="text-lg font-semibold text-gray-900">Document Compliance</h3>
          <div class="grid grid-cols-2 gap-4 text-sm text-gray-600">
            <div>
              <p class="text-xs uppercase text-gray-400">Submitted</p>
              <p class="font-semibold text-gray-900">{{ documentSummary.approved }}/{{ documentSummary.total }}</p>
            </div>
            <div>
              <p class="text-xs uppercase text-gray-400">Dispatch Eligible</p>
              <p class="font-semibold text-gray-900">{{ complianceSummary.dispatchEligible }}</p>
            </div>
            <div>
              <p class="text-xs uppercase text-gray-400">Background</p>
              <p class="font-semibold text-gray-900">{{ complianceSummary.backgroundCheck }}</p>
            </div>
            <div>
              <p class="text-xs uppercase text-gray-400">Documents</p>
              <p class="font-semibold text-gray-900">{{ complianceSummary.documents }}</p>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl border border-blue-100 shadow-sm p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-gray-900">Documents</h3>
          <span class="text-sm text-gray-500">Auto marked non-compliant if expired</span>
        </div>

        <div *ngIf="isDocumentUploadInProgress" class="mb-3 flex items-center gap-2 text-sm text-green-700">
          <mat-progress-spinner diameter="20" mode="indeterminate"></mat-progress-spinner>
          <span>Replacing {{ documentUploadTarget?.name || 'document' }}...</span>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full text-sm text-left border-collapse">
            <thead>
              <tr class="text-xs uppercase text-gray-400 border-b border-gray-200">
                <th class="px-3 py-2">Document</th>
                <th class="px-3 py-2">Status</th>
                <th class="px-3 py-2">Expiry</th>
                <th class="px-3 py-2">Verified By</th>
                <th class="px-3 py-2 text-right">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr
                *ngFor="let doc of documentsList"
                class="border-b border-gray-100 hover:bg-blue-50/40 cursor-pointer"
                (click)="previewDocument.emit(doc)"
                tabindex="0"
                role="button"
                [attr.aria-label]="'Open preview for ' + (doc.name || 'document')"
                (keydown.enter)="previewDocument.emit(doc)"
                (keydown.space)="previewDocument.emit(doc)"
                [attr.title]="'Open document preview for ' + (doc.name || 'document')"
              >
                <td class="px-3 py-3 font-medium text-gray-900">{{ doc.name }}</td>
                <td class="px-3 py-3">
                  <span [ngClass]="documentStatusClass(doc)" class="px-2 py-0.5 rounded-full text-xs">
                    {{ documentStatusLabel(doc) }}
                  </span>
                </td>
                <td class="px-3 py-3 text-gray-700">{{ formatDocumentExpiry(doc) }}</td>
                <td class="px-3 py-3 text-gray-700">{{ doc.uploadedBy || doc.updatedBy || '—' }}</td>
                <td class="px-3 py-3 text-right">
                  <div class="flex justify-end gap-2">
                    <button
                      type="button"
                      class="px-3 py-1 text-xs font-semibold rounded-full border border-gray-300 text-gray-600 hover:border-blue-500 hover:text-blue-600"
                      (click)="editDocument.emit(doc); $event.stopPropagation()"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      class="px-3 py-1 text-xs font-semibold rounded-full border border-gray-300 hover:border-blue-500 text-blue-600"
                      (click)="documentAction.emit(doc); $event.stopPropagation()"
                    >
                      {{ documentActionLabel(doc) }}
                    </button>
                  </div>
                </td>
              </tr>
              <tr *ngIf="documentsList.length === 0">
                <td colspan="5" class="px-3 py-6 text-center text-gray-500">No documents uploaded yet.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `,
})
export class DriverComplianceTabComponent {
  @Input() driverId: number | null = null;
  @Input() license!: {
    number: string;
    clazz: string;
    expires: string;
    status: string;
    tone: 'neutral' | 'success' | 'warning' | 'danger';
  };
  @Input() documentSummary!: { total: number; approved: number };
  @Input() complianceSummary!: {
    license: string;
    documents: string;
    backgroundCheck: string;
    dispatchEligible: string;
  };
  @Input() documentsList: DriverDocument[] = [];
  @Input() isDocumentUploadInProgress = false;
  @Input() documentUploadTarget: DriverDocument | null = null;
  @Input() documentStatusClass!: (doc: DriverDocument) => string;
  @Input() documentStatusLabel!: (doc: DriverDocument) => string;
  @Input() formatDocumentExpiry!: (doc: DriverDocument) => string;
  @Input() documentActionLabel!: (doc: DriverDocument) => string;

  @Output() uploadLicense = new EventEmitter<void>();
  @Output() previewDocument = new EventEmitter<DriverDocument>();
  @Output() editDocument = new EventEmitter<DriverDocument>();
  @Output() documentAction = new EventEmitter<DriverDocument>();
}
