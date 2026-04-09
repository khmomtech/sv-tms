import { CommonModule } from '@angular/common';
import { Component, inject, type OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import type { BookingReportSummary } from '@services/booking-report.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { BookingReportService } from '@services/booking-report.service';
import { finalize } from 'rxjs/operators';
import { NotificationService } from '@services/notification.service';

@Component({
  selector: 'app-booking-reports-summary',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="reports-container">
      <div class="reports-header">
        <h1>Booking Reports & Analytics</h1>
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
          <button (click)="loadReports()" class="btn btn-primary" [disabled]="loading">
            {{ loading ? 'Loading...' : 'Apply Filters' }}
          </button>
          <button (click)="exportCsv()" class="btn btn-success" [disabled]="loading">
            📥 Export CSV
          </button>
        </div>
      </div>

      <div *ngIf="error" class="alert alert-error">{{ error }}</div>

      <div *ngIf="loading" class="loading-spinner">Loading reports...</div>

      <div *ngIf="!loading && summary" class="summary-cards">
        <div class="summary-card">
          <div class="card-title">Total Bookings</div>
          <div class="card-value">{{ summary.totalBookings }}</div>
        </div>
        <div class="summary-card success">
          <div class="card-title">Confirmed</div>
          <div class="card-value">{{ summary.confirmedBookings }}</div>
          <div class="card-rate">{{ (summary.confirmationRate * 100).toFixed(1) }}%</div>
        </div>
        <div class="summary-card warning">
          <div class="card-title">New/Pending</div>
          <div class="card-value">{{ summary.newBookings }}</div>
        </div>
        <div class="summary-card danger">
          <div class="card-title">Cancelled</div>
          <div class="card-value">{{ summary.cancelledBookings }}</div>
          <div class="card-rate">{{ (summary.cancellationRate * 100).toFixed(1) }}%</div>
        </div>
        <div class="summary-card info">
          <div class="card-title">Converted to Orders</div>
          <div class="card-value">{{ summary.convertedToOrderBookings }}</div>
          <div class="card-rate">{{ (summary.conversionRate * 100).toFixed(1) }}%</div>
        </div>
      </div>

      <div *ngIf="!loading && summary" class="revenue-cards">
        <div class="revenue-card">
          <div class="card-title">Total Revenue</div>
          <div class="card-value">{{ summary.totalRevenue | currency }}</div>
        </div>
        <div class="revenue-card">
          <div class="card-title">Average Cost per Booking</div>
          <div class="card-value">{{ summary.averageCost | currency }}</div>
        </div>
      </div>

      <div class="navigation">
        <button class="btn btn-secondary" [routerLink]="['/bookings/reports/detailed']">
          View Detailed List
        </button>
        <button class="btn btn-secondary" [routerLink]="['/bookings/reports/analytics']">
          View Analytics
        </button>
      </div>
    </div>
  `,
  styles: [
    `
      .reports-container {
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
        margin-right: 10px;
      }

      .btn-secondary:hover:not(:disabled) {
        background: #5a6268;
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

      .summary-cards {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 15px;
        margin-bottom: 30px;
      }

      .summary-card {
        background: white;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        border-left: 4px solid #007bff;
      }

      .summary-card.success {
        border-left-color: #28a745;
      }

      .summary-card.warning {
        border-left-color: #ffc107;
      }

      .summary-card.danger {
        border-left-color: #dc3545;
      }

      .summary-card.info {
        border-left-color: #17a2b8;
      }

      .card-title {
        font-size: 12px;
        color: #666;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        margin-bottom: 8px;
        font-weight: 600;
      }

      .card-value {
        font-size: 28px;
        font-weight: 700;
        color: #333;
      }

      .card-rate {
        font-size: 12px;
        color: #999;
        margin-top: 8px;
      }

      .revenue-cards {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 15px;
        margin-bottom: 30px;
      }

      .revenue-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 25px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
      }

      .revenue-card .card-title {
        color: rgba(255, 255, 255, 0.9);
      }

      .revenue-card .card-value {
        color: white;
      }

      .navigation {
        display: flex;
        gap: 10px;
        margin-top: 20px;
      }
    `,
  ],
})
export class BookingReportsSummaryComponent implements OnInit {
  private notification = inject(NotificationService);
  summary: BookingReportSummary | null = null;
  loading = false;
  error: string | null = null;

  startDate: string = '';
  endDate: string = '';
  selectedStatus: string = '';

  constructor(private readonly bookingReportService: BookingReportService) {}

  ngOnInit(): void {
    this.loadReports();
  }

  loadReports(): void {
    this.loading = true;
    this.error = null;

    this.bookingReportService
      .getSummary(this.startDate, this.endDate, this.selectedStatus || undefined)
      .pipe(finalize(() => (this.loading = false)))
      .subscribe({
        next: (response) => {
          this.summary = response.data;
        },
        error: (err) => {
          this.error = 'Failed to load reports.';
          console.error('Error loading reports:', err);
        },
      });
  }

  exportCsv(): void {
    this.loading = true;
    this.bookingReportService
      .exportCsv(this.startDate, this.endDate, this.selectedStatus || undefined)
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
