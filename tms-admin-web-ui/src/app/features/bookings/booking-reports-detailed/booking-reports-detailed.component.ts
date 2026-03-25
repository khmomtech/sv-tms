import { CommonModule } from '@angular/common';
import { Component, inject, type OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import type { Booking } from '@models/booking.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { BookingReportService } from '@services/booking-report.service';
import { finalize } from 'rxjs/operators';
import { NotificationService } from '@services/notification.service';

@Component({
  selector: 'app-booking-reports-detailed',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="detailed-reports-container">
      <div class="reports-header">
        <h1>Detailed Booking List</h1>
        <div class="filter-section">
          <input type="date" [(ngModel)]="startDate" placeholder="Start Date" class="date-input" />
          <input type="date" [(ngModel)]="endDate" placeholder="End Date" class="date-input" />
          <select [(ngModel)]="selectedStatus" class="select-input">
            <option value="">All Status</option>
            <option value="NEW">New</option>
            <option value="CONFIRMED">Confirmed</option>
            <option value="CANCELLED">Cancelled</option>
            <option value="CONVERTED_TO_ORDER">Converted to Order</option>
          </select>
          <select [(ngModel)]="selectedServiceType" class="select-input">
            <option value="">All Service Types</option>
            <option value="FTL">FTL</option>
            <option value="LTL">LTL</option>
          </select>
          <button (click)="loadReports()" class="btn btn-primary" [disabled]="loading">
            {{ loading ? 'Loading...' : 'Apply Filters' }}
          </button>
          <button (click)="exportCsv()" class="btn btn-success" [disabled]="loading">
            📥 Export CSV
          </button>
        </div>
      </div>

      <div *ngIf="error" class="alert alert-error">{{ error }}</div>

      <div *ngIf="loading" class="loading-spinner">Loading bookings...</div>

      <div *ngIf="!loading && bookings.length > 0" class="table-container">
        <table class="bookings-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Customer</th>
              <th>Service Type</th>
              <th>Status</th>
              <th>Pickup Date</th>
              <th>Delivery Date</th>
              <th>Truck Type</th>
              <th>Cost</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              *ngFor="let booking of bookings"
              [ngClass]="'status-' + getStatusClass(booking.status)"
            >
              <td class="id-cell">
                <a [routerLink]="['/bookings', booking.id]"> #{{ booking.id }} </a>
              </td>
              <td>{{ booking.customerName || 'N/A' }}</td>
              <td>{{ booking.serviceType || 'N/A' }}</td>
              <td>
                <span class="status-badge" [ngClass]="'status-' + getStatusClass(booking.status)">
                  {{ getStatusLabel(booking.status) }}
                </span>
              </td>
              <td>{{ formatDate(booking.pickupDate) }}</td>
              <td>{{ formatDate(booking.deliveryDate) }}</td>
              <td>{{ booking.truckType || 'N/A' }}</td>
              <td class="cost-cell">{{ booking.estimatedCost | currency }}</td>
              <td>
                <a
                  class="action-link"
                  [routerLink]="['/bookings', booking.id]"
                  title="View Details"
                >
                  View
                </a>
              </td>
            </tr>
          </tbody>
        </table>

        <div class="pagination">
          <button (click)="previousPage()" [disabled]="!canPreviousPage" class="btn btn-pagination">
            ← Previous
          </button>
          <span class="page-info"> Page {{ currentPage + 1 }} of {{ totalPages }} </span>
          <button (click)="nextPage()" [disabled]="!canNextPage" class="btn btn-pagination">
            Next →
          </button>
        </div>
      </div>

      <div *ngIf="!loading && bookings.length === 0" class="empty-message">
        No bookings found matching the filters.
      </div>

      <div class="navigation">
        <button class="btn btn-secondary" [routerLink]="['/bookings/reports']">
          ← Back to Summary
        </button>
      </div>
    </div>
  `,
  styles: [
    `
      .detailed-reports-container {
        padding: 20px;
        max-width: 1400px;
        margin: 0 auto;
      }

      .reports-header {
        margin-bottom: 30px;
      }

      .reports-header h1 {
        margin: 0 0 20px 0;
        font-size: 28px;
        font-weight: 600;
      }

      .filter-section {
        display: flex;
        gap: 10px;
        flex-wrap: wrap;
        padding: 15px;
        background: #f5f5f5;
        border-radius: 8px;
        align-items: center;
      }

      .date-input,
      .select-input {
        padding: 8px 12px;
        border: 1px solid #ddd;
        border-radius: 4px;
        font-size: 14px;
      }

      .btn {
        padding: 8px 16px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 14px;
        font-weight: 500;
        transition: all 0.3s ease;
      }

      .btn:disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }

      .btn-primary {
        background: #007bff;
        color: white;
      }

      .btn-primary:hover:not(:disabled) {
        background: #0056b3;
      }

      .btn-success {
        background: #28a745;
        color: white;
      }

      .btn-success:hover:not(:disabled) {
        background: #218838;
      }

      .btn-secondary {
        background: #6c757d;
        color: white;
        margin-top: 20px;
      }

      .btn-secondary:hover:not(:disabled) {
        background: #5a6268;
      }

      .btn-pagination {
        background: #e9ecef;
        color: #333;
        padding: 6px 12px;
      }

      .btn-pagination:hover:not(:disabled) {
        background: #dee2e6;
      }

      .alert-error {
        background: #f8d7da;
        color: #721c24;
        padding: 12px;
        border-radius: 4px;
        margin-bottom: 20px;
      }

      .loading-spinner {
        text-align: center;
        padding: 40px;
        font-size: 16px;
        color: #666;
      }

      .table-container {
        background: white;
        border-radius: 8px;
        overflow: hidden;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        margin-bottom: 20px;
      }

      .bookings-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 14px;
      }

      .bookings-table thead {
        background: #f8f9fa;
        border-bottom: 2px solid #dee2e6;
      }

      .bookings-table th {
        padding: 12px;
        text-align: left;
        font-weight: 600;
        color: #333;
        white-space: nowrap;
      }

      .bookings-table td {
        padding: 12px;
        border-bottom: 1px solid #eee;
      }

      .bookings-table tbody tr:hover {
        background: #f9f9f9;
      }

      .id-cell {
        font-weight: 600;
      }

      .id-cell a {
        color: #007bff;
        text-decoration: none;
      }

      .id-cell a:hover {
        text-decoration: underline;
      }

      .cost-cell {
        font-weight: 600;
        color: #28a745;
      }

      .status-badge {
        display: inline-block;
        padding: 4px 8px;
        border-radius: 4px;
        font-size: 12px;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.3px;
      }

      .status-badge.status-new {
        background: #e2e3e5;
        color: #383d41;
      }

      .status-badge.status-confirmed {
        background: #d4edda;
        color: #155724;
      }

      .status-badge.status-cancelled {
        background: #f8d7da;
        color: #721c24;
      }

      .status-badge.status-converted {
        background: #d1ecf1;
        color: #0c5460;
      }

      .action-link {
        color: #007bff;
        text-decoration: none;
        font-weight: 500;
      }

      .action-link:hover {
        text-decoration: underline;
      }

      .pagination {
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 15px;
        padding: 20px;
        background: #f9f9f9;
        border-top: 1px solid #eee;
      }

      .page-info {
        font-size: 14px;
        color: #666;
      }

      .empty-message {
        text-align: center;
        padding: 60px 20px;
        color: #999;
        font-size: 16px;
        background: white;
        border-radius: 8px;
        margin-bottom: 20px;
      }

      .navigation {
        display: flex;
        gap: 10px;
        margin-top: 20px;
      }
    `,
  ],
})
export class BookingReportsDetailedComponent implements OnInit {
  private notification = inject(NotificationService);
  bookings: Booking[] = [];
  loading = false;
  error: string | null = null;

  startDate: string = '';
  endDate: string = '';
  selectedStatus: string = '';
  selectedServiceType: string = '';

  currentPage = 0;
  pageSize = 20;
  totalPages = 0;

  get canPreviousPage(): boolean {
    return this.currentPage > 0;
  }

  get canNextPage(): boolean {
    return this.currentPage < this.totalPages - 1;
  }

  constructor(private readonly bookingReportService: BookingReportService) {}

  ngOnInit(): void {
    this.loadReports();
  }

  loadReports(): void {
    this.loading = true;
    this.error = null;

    this.bookingReportService
      .getDetailedList(
        this.currentPage,
        this.pageSize,
        this.startDate,
        this.endDate,
        this.selectedStatus || undefined,
        this.selectedServiceType || undefined,
      )
      .pipe(finalize(() => (this.loading = false)))
      .subscribe({
        next: (response) => {
          this.bookings = response.data.content || [];
          this.totalPages = response.data.totalPages || 0;
        },
        error: (err) => {
          this.error = 'Failed to load bookings.';
          console.error('Error loading bookings:', err);
        },
      });
  }

  previousPage(): void {
    if (this.canPreviousPage) {
      this.currentPage--;
      this.loadReports();
    }
  }

  nextPage(): void {
    if (this.canNextPage) {
      this.currentPage++;
      this.loadReports();
    }
  }

  formatDate(date: any): string {
    if (!date) return 'N/A';
    return new Date(date).toLocaleDateString('en-US', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  }

  getStatusLabel(status: string): string {
    const labels: { [key: string]: string } = {
      NEW: 'New',
      CONFIRMED: 'Confirmed',
      CANCELLED: 'Cancelled',
      CONVERTED_TO_ORDER: 'Converted',
    };
    return labels[status] || status;
  }

  getStatusClass(status: string): string {
    return status.toLowerCase().replace('_', '');
  }

  exportCsv(): void {
    this.loading = true;
    this.bookingReportService
      .exportCsv(
        this.startDate,
        this.endDate,
        this.selectedStatus || undefined,
        this.selectedServiceType || undefined,
      )
      .pipe(finalize(() => (this.loading = false)))
      .subscribe({
        next: (blob) => {
          const url = window.URL.createObjectURL(blob);
          const link = document.createElement('a');
          link.href = url;
          link.download = `bookings_report_${new Date().toISOString().split('T')[0]}.csv`;
          link.click();
          window.URL.revokeObjectURL(url);
        },
        error: (err) => {
          this.notification.simulateNotification('Error', 'Failed to export CSV');
          console.error('Error exporting CSV:', err);
        },
      });
  }
}
