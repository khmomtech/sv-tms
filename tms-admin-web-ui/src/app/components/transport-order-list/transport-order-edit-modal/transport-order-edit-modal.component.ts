import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output, type OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import type { TransportOrder } from '../../../models/transport-order.model';
import { OrderStatus } from '../../../models/order-status.enum';

@Component({
  selector: 'app-transport-order-edit-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="modal-overlay" role="presentation" (click)="onBackdropClick()">
      <div
        class="modal-content"
        role="dialog"
        aria-labelledby="modalTitle"
        aria-modal="true"
        (click)="$event.stopPropagation()"
      >
        <!-- Modal Header -->
        <div class="modal-header">
          <h2 id="modalTitle" class="modal-title">Edit Order</h2>
          <button
            (click)="onClose()"
            aria-label="Close modal"
            class="modal-close-btn"
            type="button"
          >
            ✕
          </button>
        </div>

        <!-- Modal Body -->
        <div class="modal-body">
          <div class="form-group">
            <label for="orderRef" class="form-label">Order Reference</label>
            <input
              id="orderRef"
              type="text"
              [(ngModel)]="order!.orderReference"
              class="form-input"
              readonly
              aria-readonly="true"
            />
          </div>

          <div class="form-group">
            <label for="customer" class="form-label">Customer</label>
            <input
              id="customer"
              type="text"
              [(ngModel)]="order!.customerName"
              class="form-input"
              readonly
              aria-readonly="true"
            />
          </div>

          <div class="form-group">
            <label for="status" class="form-label">Status</label>
            <select
              id="status"
              [(ngModel)]="order!.status"
              class="form-input"
              aria-label="Order status"
            >
              <option *ngFor="let status of availableStatuses" [value]="status">
                {{ formatStatus(status) }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label for="origin" class="form-label">Origin</label>
            <input
              id="origin"
              type="text"
              [(ngModel)]="order!.origin"
              class="form-input"
              readonly
              aria-readonly="true"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Requires Driver</label>
            <div>
              <label class="inline-flex items-center">
                <input type="checkbox" [(ngModel)]="order!.requiresDriver" class="mr-2" />
                <span>{{ order?.requiresDriver ? 'Yes' : 'No' }}</span>
              </label>
            </div>
          </div>
        </div>

        <!-- Modal Footer -->
        <div class="modal-footer">
          <button
            (click)="onClose()"
            class="btn btn-secondary"
            type="button"
            aria-label="Cancel and close modal"
          >
            Cancel
          </button>
          <button
            (click)="onSave()"
            class="btn btn-primary"
            type="button"
            [disabled]="!isValid()"
            [attr.aria-label]="'Save order status changes'"
          >
            Save Changes
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 50;
      }

      .modal-content {
        background: white;
        border-radius: 8px;
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
        width: 100%;
        max-width: 500px;
        max-height: 90vh;
        overflow-y: auto;
      }

      .modal-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 20px;
        border-bottom: 1px solid #e5e7eb;
      }

      .modal-title {
        margin: 0;
        font-size: 20px;
        font-weight: 600;
        color: #1f2937;
      }

      .modal-close-btn {
        background: none;
        border: none;
        font-size: 24px;
        cursor: pointer;
        padding: 0;
        width: 32px;
        height: 32px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 4px;
        transition: background-color 0.2s;
      }

      .modal-close-btn:hover {
        background-color: #f3f4f6;
      }

      .modal-close-btn:focus {
        outline: 2px solid #3b82f6;
        outline-offset: 2px;
      }

      .modal-body {
        padding: 20px;
      }

      .form-group {
        margin-bottom: 20px;
      }

      .form-label {
        display: block;
        font-weight: 500;
        color: #374151;
        margin-bottom: 8px;
        font-size: 14px;
      }

      .form-input {
        width: 100%;
        padding: 8px 12px;
        border: 1px solid #d1d5db;
        border-radius: 4px;
        font-size: 14px;
        transition: border-color 0.2s;
      }

      .form-input:focus {
        outline: none;
        border-color: #3b82f6;
        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
      }

      .form-input[readonly] {
        background-color: #f3f4f6;
        cursor: not-allowed;
      }

      .modal-footer {
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        padding: 20px;
        border-top: 1px solid #e5e7eb;
        background-color: #f9fafb;
      }

      .btn {
        padding: 8px 16px;
        border: none;
        border-radius: 4px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
      }

      .btn:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      .btn-primary {
        background-color: #3b82f6;
        color: white;
      }

      .btn-primary:hover:not(:disabled) {
        background-color: #2563eb;
      }

      .btn-secondary {
        background-color: #9ca3af;
        color: white;
      }

      .btn-secondary:hover:not(:disabled) {
        background-color: #6b7280;
      }

      /* Responsive */
      @media (max-width: 640px) {
        .modal-content {
          max-width: 90%;
          margin: 10px;
        }

        .modal-footer {
          flex-direction: column-reverse;
        }

        .btn {
          width: 100%;
        }
      }
    `,
  ],
})
export class TransportOrderEditModalComponent implements OnInit {
  @Input() order: TransportOrder | null = null;
  @Output() save = new EventEmitter<TransportOrder>();
  @Output() close = new EventEmitter<void>();

  availableStatuses = Object.values(OrderStatus);

  ngOnInit(): void {
    // Focus close button on open for keyboard accessibility
    setTimeout(() => {
      const closeBtn = document.querySelector('.modal-close-btn') as HTMLButtonElement;
      closeBtn?.focus();
    }, 100);
  }

  isValid(): boolean {
    return this.order?.status ? true : false;
  }

  formatStatus(status: string): string {
    return status
      .split('_')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(' ');
  }

  onSave(): void {
    if (this.order && this.isValid()) {
      this.save.emit(this.order);
    }
  }

  onClose(): void {
    this.close.emit();
  }

  onBackdropClick(): void {
    this.close.emit();
  }
}
