import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { SafetyCheckService } from '../services/safety-check.service';
import type { SafetyCheck } from '../models/safety-check.model';

@Component({
  selector: 'app-safety-check-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <!-- Loading skeleton -->
    <div *ngIf="!safetyCheck && !loadError" class="p-4 space-y-4 animate-pulse">
      <div class="h-6 w-48 rounded bg-gray-200"></div>
      <div class="h-32 rounded-lg bg-gray-100"></div>
      <div class="h-48 rounded-lg bg-gray-100"></div>
    </div>

    <!-- Load error -->
    <div *ngIf="loadError" class="p-4">
      <div class="rounded-lg bg-red-50 p-4 text-sm text-red-700">
        មានបញ្ហាក្នុងការផ្ទុកទិន្នន័យ។ សូមព្យាយាមម្ដងទៀត។
      </div>
    </div>

    <div *ngIf="safetyCheck" class="p-4 space-y-4">
      <!-- Header -->
      <div class="flex items-start justify-between">
        <div>
          <h1 class="text-xl font-semibold text-gray-900">លម្អិតត្រួតពិនិត្យសុវត្ថិភាព</h1>
          <p class="text-sm text-gray-500 mt-0.5">ពិនិត្យព័ត៌មាន និងអនុម័ត/បដិសេធការត្រួតពិនិត្យ</p>
        </div>
        <a
          routerLink="/safety"
          class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M15 19l-7-7 7-7"
            />
          </svg>
          ត្រឡប់
        </a>
      </div>

      <!-- Action feedback banners -->
      <div
        *ngIf="actionSuccess"
        class="flex items-center gap-2 rounded-lg bg-green-50 p-3 text-sm text-green-800 ring-1 ring-green-200"
      >
        <svg class="h-4 w-4 flex-shrink-0 text-green-500" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
            clip-rule="evenodd"
          />
        </svg>
        {{ actionSuccess }}
      </div>
      <div
        *ngIf="actionError"
        class="flex items-center gap-2 rounded-lg bg-red-50 p-3 text-sm text-red-800 ring-1 ring-red-200"
      >
        <svg class="h-4 w-4 flex-shrink-0 text-red-500" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
            clip-rule="evenodd"
          />
        </svg>
        {{ actionError }}
      </div>

      <!-- Summary card -->
      <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-gray-200">
        <div class="grid grid-cols-2 gap-4 sm:grid-cols-3">
          <div>
            <p class="text-xs text-gray-500">កាលបរិច្ឆេទ</p>
            <p class="mt-0.5 text-sm font-medium text-gray-900">
              {{ safetyCheck.checkDate || '–' }}
            </p>
          </div>
          <div>
            <p class="text-xs text-gray-500">វេន</p>
            <p class="mt-0.5 text-sm font-medium text-gray-900">{{ safetyCheck.shift || '–' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500">អ្នកបើកបរ</p>
            <p class="mt-0.5 text-sm font-medium text-gray-900">
              {{ safetyCheck.driverName || '–' }}
            </p>
          </div>
          <div>
            <p class="text-xs text-gray-500">យានយន្ត</p>
            <p class="mt-0.5 text-sm font-medium text-gray-900">
              {{ safetyCheck.vehiclePlate || '–' }}
            </p>
          </div>
          <div>
            <p class="text-xs text-gray-500">ស្ថានភាព</p>
            <span
              class="mt-0.5 inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
              [ngClass]="statusClass(safetyCheck.status)"
            >
              {{ statusLabel(safetyCheck.status) }}
            </span>
          </div>
          <div>
            <p class="text-xs text-gray-500">ហានិភ័យ</p>
            <span
              class="mt-0.5 inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
              [ngClass]="riskClass(safetyCheck.riskOverride || safetyCheck.riskLevel)"
            >
              {{ safetyCheck.riskOverride || safetyCheck.riskLevel || '–' }}
            </span>
          </div>
          <div *ngIf="safetyCheck.approvedByName">
            <p class="text-xs text-gray-500">
              {{ isRejected() ? 'ត្រូវបានបដិសេធដោយ' : 'បានអនុម័តដោយ' }}
            </p>
            <p class="mt-0.5 text-sm font-medium text-gray-900">{{ safetyCheck.approvedByName }}</p>
          </div>
          <div *ngIf="safetyCheck.rejectReason" class="col-span-2 sm:col-span-3">
            <p class="text-xs text-gray-500">មូលហេតុបដិសេធ</p>
            <p class="mt-0.5 text-sm font-medium text-red-700">{{ safetyCheck.rejectReason }}</p>
          </div>
          <div *ngIf="safetyCheck.gpsLat && safetyCheck.gpsLng" class="col-span-2 sm:col-span-3">
            <p class="text-xs text-gray-500">ទីតាំង GPS</p>
            <a
              class="mt-0.5 text-sm text-blue-600 hover:underline"
              [href]="
                'https://www.google.com/maps?q=' + safetyCheck.gpsLat + ',' + safetyCheck.gpsLng
              "
              target="_blank"
              rel="noopener"
            >
              {{ safetyCheck.gpsLat }}, {{ safetyCheck.gpsLng }}
            </a>
          </div>
        </div>
      </div>

      <!-- Action panel — only visible for WAITING_APPROVAL -->
      <div
        *ngIf="canDecide()"
        class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-gray-200 space-y-4"
      >
        <h3 class="text-sm font-semibold text-gray-900">ការសម្រេចចិត្ត</h3>

        <!-- Confirm overlay (inline) -->
        <div
          *ngIf="pendingAction"
          class="rounded-lg border border-amber-200 bg-amber-50 p-4 space-y-3"
        >
          <p class="text-sm font-medium text-amber-900">
            {{ pendingAction === 'approve' ? 'បញ្ជាក់ការអនុម័ត?' : 'បញ្ជាក់ការបដិសេធ?' }}
          </p>
          <p *ngIf="pendingAction === 'approve' && riskOverride" class="text-xs text-amber-800">
            ហានិភ័យនឹងត្រូវបានកំណត់ជា <strong>{{ riskOverride }}</strong>
          </p>
          <p *ngIf="pendingAction === 'reject'" class="text-xs text-amber-800">
            មូលហេតុ: <strong>"{{ rejectReason }}"</strong>
          </p>
          <div class="flex gap-2">
            <button
              class="rounded-md px-3 py-1.5 text-sm font-medium text-white disabled:opacity-50"
              [ngClass]="
                pendingAction === 'approve'
                  ? 'bg-green-600 hover:bg-green-700'
                  : 'bg-red-600 hover:bg-red-700'
              "
              (click)="confirmAction()"
              [disabled]="acting"
            >
              <span *ngIf="!acting">{{
                pendingAction === 'approve' ? 'បញ្ជាក់អនុម័ត' : 'បញ្ជាក់បដិសេធ'
              }}</span>
              <span *ngIf="acting" class="inline-flex items-center gap-1">
                <svg class="h-3 w-3 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  ></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"></path>
                </svg>
                រង់ចាំ...
              </span>
            </button>
            <button
              class="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              (click)="cancelAction()"
              [disabled]="acting"
            >
              បោះបង់
            </button>
          </div>
        </div>

        <!-- Approve row -->
        <div *ngIf="!pendingAction" class="flex items-end gap-3 flex-wrap">
          <div class="flex-1 min-w-[160px]">
            <label class="block text-xs font-medium text-gray-700 mb-1">
              កែសម្រួលហានិភ័យ <span class="font-normal text-gray-400">(ស្រេចចិត្ត)</span>
            </label>
            <select
              class="block w-full rounded-md border-gray-300 text-sm shadow-sm"
              [(ngModel)]="riskOverride"
            >
              <option value="">មិនកំណត់</option>
              <option value="LOW">LOW</option>
              <option value="MEDIUM">MEDIUM</option>
              <option value="HIGH">HIGH</option>
            </select>
          </div>
          <button
            class="rounded-md bg-green-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-green-700"
            (click)="requestApprove()"
          >
            អនុម័ត
          </button>
        </div>

        <!-- Reject row -->
        <div *ngIf="!pendingAction" class="flex items-end gap-3 flex-wrap">
          <div class="flex-1 min-w-[200px]">
            <label class="block text-xs font-medium text-gray-700 mb-1">មូលហេតុបដិសេធ</label>
            <input
              type="text"
              class="block w-full rounded-md border-gray-300 text-sm shadow-sm"
              placeholder="សូមបញ្ចូលមូលហេតុ..."
              [(ngModel)]="rejectReason"
            />
          </div>
          <button
            class="rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-red-700 disabled:opacity-50"
            (click)="requestReject()"
            [disabled]="!rejectReason.trim()"
          >
            បដិសេធ
          </button>
        </div>
      </div>

      <!-- Checklist items -->
      <div class="rounded-lg bg-white shadow-sm ring-1 ring-gray-200 overflow-hidden">
        <div class="border-b border-gray-200 px-4 py-3">
          <h3 class="text-sm font-semibold text-gray-900">បញ្ជីការត្រួតពិនិត្យ</h3>
        </div>
        <table class="min-w-full divide-y divide-gray-100 text-sm">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-4 py-2 text-left text-xs font-medium text-gray-500">ធាតុ</th>
              <th class="px-4 py-2 text-left text-xs font-medium text-gray-500">លទ្ធផល</th>
              <th class="px-4 py-2 text-left text-xs font-medium text-gray-500">កម្រិត</th>
              <th class="px-4 py-2 text-left text-xs font-medium text-gray-500">សេចក្ដីពន្យល់</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr
              *ngFor="let item of safetyCheck.items || []"
              [ngClass]="item.result && item.result !== 'OK' ? 'bg-red-50' : 'hover:bg-gray-50'"
            >
              <td class="px-4 py-2.5 text-gray-900">{{ item.itemLabelKm || item.itemKey }}</td>
              <td class="px-4 py-2.5">
                <span
                  class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium"
                  [ngClass]="
                    item.result === 'OK' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  "
                >
                  {{ item.result || '–' }}
                </span>
              </td>
              <td class="px-4 py-2.5 text-xs text-gray-600">{{ item.severity || '–' }}</td>
              <td class="px-4 py-2.5 text-xs text-gray-600">{{ item.remark || '–' }}</td>
            </tr>
            <tr *ngIf="!safetyCheck.items || safetyCheck.items.length === 0">
              <td colspan="4" class="px-4 py-6 text-center text-xs text-gray-400">គ្មានទិន្នន័យ</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Attachments -->
      <div
        *ngIf="safetyCheck.attachments && safetyCheck.attachments.length"
        class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-gray-200"
      >
        <h3 class="text-sm font-semibold text-gray-900 mb-3">រូបភាព / ឯកសារភ្ជាប់</h3>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          <a
            *ngFor="let att of safetyCheck.attachments"
            [href]="att.fileUrl"
            target="_blank"
            rel="noopener"
            class="block overflow-hidden rounded-lg border border-gray-200 hover:ring-2 hover:ring-blue-300 transition-shadow"
          >
            <img
              *ngIf="isImage(att.fileUrl)"
              [src]="att.fileUrl"
              [alt]="att.fileName"
              class="h-28 w-full object-cover"
            />
            <div
              *ngIf="!isImage(att.fileUrl)"
              class="flex h-28 flex-col items-center justify-center bg-gray-50 text-xs text-gray-500 p-2 text-center"
            >
              <svg
                class="mb-1 h-8 w-8 text-gray-300"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="1.5"
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
              {{ att.fileName || 'ឯកសារ' }}
            </div>
          </a>
        </div>
      </div>

      <!-- Audit log -->
      <div
        *ngIf="safetyCheck.audits && safetyCheck.audits.length"
        class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-gray-200"
      >
        <h3 class="text-sm font-semibold text-gray-900 mb-3">Audit Log</h3>
        <ol class="space-y-2">
          <li
            *ngFor="let log of safetyCheck.audits"
            class="flex items-start gap-3 text-xs text-gray-600"
          >
            <span class="mt-1.5 h-1.5 w-1.5 flex-shrink-0 rounded-full bg-gray-400"></span>
            <span>
              <span class="font-semibold text-gray-800">{{ log.action }}</span>
              <span *ngIf="log.actorRole" class="text-gray-500"> · {{ log.actorRole }}</span>
              <span *ngIf="log.message"> — {{ log.message }}</span>
              <span class="ml-2 text-gray-400">{{ log.createdAt }}</span>
            </span>
          </li>
        </ol>
      </div>
    </div>
  `,
})
export class SafetyCheckDetailComponent implements OnInit {
  safetyCheck?: SafetyCheck;
  loadError = false;

  riskOverride = '';
  rejectReason = '';

  /** Pending confirmation: set when user clicks Approve/Reject to show the confirm UI */
  pendingAction: 'approve' | 'reject' | null = null;
  acting = false;

  actionSuccess = '';
  actionError = '';

  constructor(
    private route: ActivatedRoute,
    private safetyService: SafetyCheckService,
  ) {}

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (id) this.fetch(id);
  }

  fetch(id: number): void {
    this.loadError = false;
    this.safetyService.getById(id).subscribe({
      next: (res) => {
        this.safetyCheck = res.data;
        this.riskOverride = this.safetyCheck?.riskOverride || '';
      },
      error: () => {
        this.loadError = true;
      },
    });
  }

  canDecide(): boolean {
    return (this.safetyCheck?.status || '').toUpperCase() === 'WAITING_APPROVAL';
  }

  isRejected(): boolean {
    return (this.safetyCheck?.status || '').toUpperCase() === 'REJECTED';
  }

  requestApprove(): void {
    this.actionSuccess = '';
    this.actionError = '';
    this.pendingAction = 'approve';
  }

  requestReject(): void {
    if (!this.rejectReason.trim()) return;
    this.actionSuccess = '';
    this.actionError = '';
    this.pendingAction = 'reject';
  }

  cancelAction(): void {
    this.pendingAction = null;
  }

  confirmAction(): void {
    if (!this.safetyCheck?.id) return;
    this.acting = true;

    if (this.pendingAction === 'approve') {
      this.safetyService.approve(this.safetyCheck.id, this.riskOverride || undefined).subscribe({
        next: (res) => {
          this.safetyCheck = res.data;
          this.actionSuccess = 'ការអនុម័តបានជោគជ័យ';
          this.pendingAction = null;
          this.acting = false;
        },
        error: () => {
          this.actionError = 'មានបញ្ហាក្នុងការអនុម័ត។ សូមព្យាយាមម្ដងទៀត។';
          this.pendingAction = null;
          this.acting = false;
        },
      });
    } else if (this.pendingAction === 'reject') {
      this.safetyService.reject(this.safetyCheck.id, this.rejectReason.trim()).subscribe({
        next: (res) => {
          this.safetyCheck = res.data;
          this.actionSuccess = 'ការបដិសេធបានជោគជ័យ';
          this.rejectReason = '';
          this.pendingAction = null;
          this.acting = false;
        },
        error: () => {
          this.actionError = 'មានបញ្ហាក្នុងការបដិសេធ។ សូមព្យាយាមម្ដងទៀត។';
          this.pendingAction = null;
          this.acting = false;
        },
      });
    }
  }

  statusLabel(status?: string): string {
    switch ((status || '').toUpperCase()) {
      case 'DRAFT':
        return 'កំពុងបំពេញ';
      case 'WAITING_APPROVAL':
        return 'រង់ចាំអនុម័ត';
      case 'APPROVED':
        return 'បានអនុម័ត';
      case 'REJECTED':
        return 'ត្រូវបានបដិសេធ';
      default:
        return 'មិនទាន់ចាប់ផ្តើម';
    }
  }

  statusClass(status?: string): string {
    switch ((status || '').toUpperCase()) {
      case 'DRAFT':
        return 'bg-blue-100 text-blue-800';
      case 'WAITING_APPROVAL':
        return 'bg-amber-100 text-amber-800';
      case 'APPROVED':
        return 'bg-green-100 text-green-800';
      case 'REJECTED':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  }

  riskClass(risk?: string): string {
    switch ((risk || '').toUpperCase()) {
      case 'HIGH':
        return 'bg-red-100 text-red-800';
      case 'MEDIUM':
        return 'bg-amber-100 text-amber-800';
      case 'LOW':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-600';
    }
  }

  isImage(url?: string): boolean {
    return /\.(jpg|jpeg|png|gif|webp)$/i.test(url || '');
  }
}
