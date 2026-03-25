import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import type { DriverAlert } from '../../models/driver-alert.model';

@Component({
  selector: 'app-driver-alert-toast',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div
      class="fixed top-4 right-4 max-w-sm p-4 rounded shadow-lg z-50 animate-slideInRight"
      [ngClass]="{
        'bg-red-100 border-l-4 border-red-500': alert.severity === 'critical',
        'bg-yellow-100 border-l-4 border-yellow-500': alert.severity === 'warning',
        'bg-blue-100 border-l-4 border-blue-500': alert.severity === 'info',
      }"
    >
      <div class="flex justify-between items-start">
        <div>
          <h3
            class="font-semibold"
            [ngClass]="{
              'text-red-800': alert.severity === 'critical',
              'text-yellow-800': alert.severity === 'warning',
              'text-blue-800': alert.severity === 'info',
            }"
          >
            {{ alert.type | titlecase }}
          </h3>
          <p class="text-sm mt-1">{{ alert.message }}</p>
          <p class="text-xs mt-2 opacity-70">
            {{ alert.timestamp | date: 'short' }}
          </p>
        </div>
        <div class="flex gap-2 ml-4">
          <button (click)="onSnooze()" class="text-sm px-2 py-1 bg-white rounded hover:bg-gray-100">
            Snooze
          </button>
          <button
            (click)="onDismiss()"
            class="text-sm px-2 py-1 bg-white rounded hover:bg-gray-100"
          >
            ✕
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      @keyframes slideInRight {
        from {
          transform: translateX(400px);
          opacity: 0;
        }
        to {
          transform: translateX(0);
          opacity: 1;
        }
      }
      .animate-slideInRight {
        animation: slideInRight 0.3s ease-out;
      }
    `,
  ],
})
export class DriverAlertToastComponent {
  @Input() alert!: DriverAlert;
  @Output() snoozed = new EventEmitter<string>();
  @Output() dismissed = new EventEmitter<string>();

  onSnooze(): void {
    this.snoozed.emit(this.alert.id);
  }

  onDismiss(): void {
    this.dismissed.emit(this.alert.id);
  }
}
