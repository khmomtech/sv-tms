import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';

import {
  PmRunService,
  type PmRunDto,
  type PmRunChecklistResultDto,
} from '../../../services/pm-run.service';

@Component({
  selector: 'app-pm-run-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="p-6" *ngIf="run">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">PM Run #{{ run.pmRunId }}</h1>
          <p class="text-gray-600">{{ run.itemName || run.planName }} · {{ run.vehiclePlate }}</p>
        </div>
        <button class="px-4 py-2 bg-gray-100 rounded" type="button" (click)="back()">Back</button>
      </div>

      <div *ngIf="error" class="mb-4 p-3 rounded border border-red-200 bg-red-50 text-red-700">
        {{ error }}
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-6">
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Due</div>
          <div class="text-lg font-semibold">
            {{ run.triggerExplanation || run.dueDate || run.dueKm + ' km' }}
          </div>
        </div>
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Status</div>
          <div class="text-lg font-semibold">{{ run.status }}</div>
        </div>
        <div class="bg-white rounded-lg border p-4">
          <div class="text-sm text-gray-500">Work Order</div>
          <div class="text-lg font-semibold">{{ run.relatedWoNumber || '-' }}</div>
        </div>
      </div>

      <div class="flex flex-wrap gap-3 mb-6">
        <button
          class="px-4 py-2 bg-blue-600 text-white rounded"
          (click)="start()"
          [disabled]="run.status !== 'DUE' && run.status !== 'RESCHEDULED'"
        >
          Start
        </button>
        <button class="px-4 py-2 bg-emerald-600 text-white rounded" (click)="complete()">
          Complete
        </button>
        <button class="px-4 py-2 bg-amber-500 text-white rounded" (click)="skip()">Skip</button>
        <button class="px-4 py-2 bg-gray-800 text-white rounded" (click)="reschedule()">
          Reschedule
        </button>
        <button
          class="px-4 py-2 bg-indigo-600 text-white rounded"
          (click)="createWo()"
          [disabled]="run.relatedWoId"
        >
          Create WO
        </button>
      </div>

      <div class="bg-white rounded-lg border mb-6">
        <div class="p-4 border-b font-semibold text-gray-900">Checklist</div>
        <div class="p-4" *ngIf="!run.checklistItems || run.checklistItems.length === 0">
          <p class="text-sm text-gray-500">No checklist configured.</p>
        </div>
        <div class="p-4 space-y-4" *ngIf="run.checklistItems && run.checklistItems.length">
          <div *ngFor="let item of run.checklistItems" class="border rounded p-3">
            <div class="font-medium text-gray-900">{{ item.label }}</div>
            <div class="text-xs text-gray-500">
              {{ item.inputType }} · {{ item.required ? 'Required' : 'Optional' }}
            </div>
            <div class="mt-2" [ngSwitch]="item.inputType">
              <div *ngSwitchCase="'CHECK'">
                <label class="inline-flex items-center gap-2">
                  <input
                    type="checkbox"
                    [(ngModel)]="completion[item.checklistItemId].checkedBool"
                  />
                  <span>Checked</span>
                </label>
              </div>
              <div *ngSwitchCase="'TEXT'">
                <input
                  class="border rounded px-3 py-2 w-full"
                  [(ngModel)]="completion[item.checklistItemId].valueText"
                />
              </div>
              <div *ngSwitchCase="'NUMBER'">
                <input
                  class="border rounded px-3 py-2 w-full"
                  type="number"
                  [(ngModel)]="completion[item.checklistItemId].valueNumber"
                />
              </div>
              <div *ngSwitchCase="'PHOTO'">
                <input
                  class="border rounded px-3 py-2 w-full"
                  placeholder="Photo URL"
                  [(ngModel)]="completion[item.checklistItemId].photoUrl"
                />
              </div>
              <div *ngSwitchDefault>Unsupported input type</div>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-lg border mb-6">
        <div class="p-4 border-b font-semibold text-gray-900">Notes</div>
        <div class="p-4">
          <textarea class="border rounded px-3 py-2 w-full" rows="3" [(ngModel)]="notes"></textarea>
        </div>
      </div>

      <div class="bg-white rounded-lg border">
        <div class="p-4 border-b font-semibold text-gray-900">Attachments</div>
        <div class="p-4 space-y-2">
          <input type="file" (change)="upload($event)" />
          <div *ngIf="run.attachments && run.attachments.length">
            <div *ngFor="let att of run.attachments" class="text-sm text-gray-700">
              {{ att.fileUrl }}
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-lg border mt-6" *ngIf="run.statusLogs && run.statusLogs.length">
        <div class="p-4 border-b font-semibold text-gray-900">Timeline</div>
        <div class="p-4 space-y-2 text-sm">
          <div *ngFor="let log of run.statusLogs" class="border rounded p-3">
            <div class="font-medium">{{ log.newStatus }}</div>
            <div class="text-xs text-gray-500">
              {{ log.changedAt }} · {{ log.changedByName || 'system' }}
            </div>
            <div class="text-gray-700">{{ log.note }}</div>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class PmRunDetailComponent implements OnInit {
  run?: PmRunDto;
  completion: Record<number, PmRunChecklistResultDto> = {};
  notes = '';
  error = '';
  private id = 0;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly runService: PmRunService,
  ) {}

  ngOnInit(): void {
    this.id = Number(this.route.snapshot.paramMap.get('id'));
    this.load();
  }

  load(): void {
    this.error = '';
    this.runService.get(this.id).subscribe({
      next: (res) => {
        this.run = res.data || undefined;
        this.notes = this.run?.notes || '';
        if (this.run?.checklistItems) {
          for (const item of this.run.checklistItems) {
            this.completion[item.checklistItemId] = { checklistItemId: item.checklistItemId };
          }
        }
      },
      error: () => (this.error = 'Failed to load PM run.'),
    });
  }

  start(): void {
    this.runService.start(this.id).subscribe({
      next: (res) => (this.run = res.data || this.run),
      error: () => (this.error = 'Failed to start run.'),
    });
  }

  complete(): void {
    const checklistResults = Object.values(this.completion);
    this.runService.complete(this.id, { notes: this.notes, checklistResults }).subscribe({
      next: (res) => (this.run = res.data || this.run),
      error: (err) => (this.error = err?.error?.message || 'Failed to complete run.'),
    });
  }

  skip(): void {
    const reason = prompt('Skip reason?');
    if (!reason) return;
    this.runService.skip(this.id, { skipReason: reason }).subscribe({
      next: (res) => (this.run = res.data || this.run),
      error: () => (this.error = 'Failed to skip run.'),
    });
  }

  reschedule(): void {
    const date = prompt('Reschedule to date (YYYY-MM-DD)?');
    if (!date) return;
    this.runService.reschedule(this.id, { rescheduledToDate: date }).subscribe({
      next: (res) => (this.run = res.data || this.run),
      error: () => (this.error = 'Failed to reschedule run.'),
    });
  }

  createWo(): void {
    this.runService.createWorkOrder(this.id).subscribe({
      next: (res) => (this.run = res.data || this.run),
      error: () => (this.error = 'Failed to create work order.'),
    });
  }

  upload(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.runService.uploadAttachment(this.id, file).subscribe({
      next: () => this.load(),
      error: () => (this.error = 'Failed to upload attachment.'),
    });
  }

  back(): void {
    this.router.navigate(['/fleet/maintenance/pm-runs']);
  }
}
