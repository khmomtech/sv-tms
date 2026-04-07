import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  standalone: true,
  selector: 'app-driver-detail-header',
  imports: [CommonModule],
  template: `
    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <div class="flex items-center gap-4">
        <div class="flex h-16 w-16 items-center justify-center rounded-full bg-blue-100">
          <svg class="h-8 w-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            ></path>
          </svg>
        </div>
        <div>
          <p class="text-sm font-medium text-blue-600">Driver Management</p>
          <h2 class="text-3xl font-bold text-gray-900">{{ title }}</h2>
          <p class="mt-1 text-sm text-gray-500">{{ subtitle }}</p>
        </div>
      </div>
      <div class="flex items-center gap-3">
        <div
          class="hidden items-center gap-2 rounded-lg border border-gray-200 bg-white px-3 py-2 text-xs text-gray-500 shadow-sm lg:flex"
          *ngIf="showSaveHint"
        >
          <kbd class="rounded border bg-gray-50 px-2 py-0.5 shadow-sm">Ctrl</kbd>
          <span>+</span>
          <kbd class="rounded border bg-gray-50 px-2 py-0.5 shadow-sm">S</kbd>
          <span>Save changes</span>
        </div>
        <button
          type="button"
          (click)="back.emit()"
          class="flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-5 py-3 text-sm font-semibold text-gray-700 shadow-sm transition hover:border-blue-300 hover:text-blue-600"
        >
          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M10 19l-7-7m0 0l7-7m-7 7h18"
            ></path>
          </svg>
          Back to Drivers
        </button>
      </div>
    </div>

    <section class="mb-6 rounded-2xl border border-gray-200 bg-white p-4 shadow-sm">
      <div class="flex flex-wrap gap-2">
        <button
          *ngFor="let tab of firstRowTabs"
          type="button"
          class="rounded-full px-3 py-2 text-sm font-semibold transition"
          [ngClass]="{
            'bg-blue-50 text-blue-600 shadow-sm': activeTab === tab.key,
            'border border-gray-200 text-gray-700 hover:border-blue-300': activeTab !== tab.key,
          }"
          (click)="tabChange.emit(tab.key)"
        >
          {{ tab.label }}
        </button>
      </div>
      <div *ngIf="secondRowTabs.length" class="mt-3 flex flex-wrap gap-2 border-t border-gray-100 pt-3">
        <button
          *ngFor="let tab of secondRowTabs"
          type="button"
          class="rounded-full px-3 py-2 text-sm font-semibold transition"
          [ngClass]="{
            'bg-blue-50 text-blue-600 shadow-sm': activeTab === tab.key,
            'border border-gray-200 text-gray-700 hover:border-blue-300': activeTab !== tab.key,
          }"
          (click)="tabChange.emit(tab.key)"
        >
          {{ tab.label }}
        </button>
      </div>
    </section>
  `,
})
export class DriverDetailHeaderComponent {
  @Input() title = '';
  @Input() subtitle = '';
  @Input() showSaveHint = false;
  @Input() activeTab = 'overview';
  @Input() firstRowTabs: Array<{ key: string; label: string }> = [];
  @Input() secondRowTabs: Array<{ key: string; label: string }> = [];

  @Output() back = new EventEmitter<void>();
  @Output() tabChange = new EventEmitter<string>();
}
