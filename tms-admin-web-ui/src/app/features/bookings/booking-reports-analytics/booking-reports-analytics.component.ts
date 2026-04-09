import { CommonModule } from '@angular/common';
import { Component, type OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import type { BookingAnalytics } from '@services/booking-report.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { BookingReportService } from '@services/booking-report.service';
import { finalize } from 'rxjs/operators';

@Component({
  selector: 'app-booking-reports-analytics',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="analytics-container">
      <div class="analytics-header">
        <h1>Booking Analytics</h1>
        <div class="filter-section">
          <input type="date" [(ngModel)]="startDate" placeholder="Start Date" class="date-input" />
          <input type="date" [(ngModel)]="endDate" placeholder="End Date" class="date-input" />
          <button (click)="loadAnalytics()" class="btn btn-primary" [disabled]="loading">
            {{ loading ? 'Loading...' : 'Apply Filters' }}
          </button>
        </div>
      </div>

      <div *ngIf="error" class="alert alert-error">{{ error }}</div>

      <div *ngIf="loading" class="loading-spinner">Loading analytics...</div>

      <div *ngIf="!loading" class="analytics-grid">
        <div class="analytics-section">
          <h2>By Customer</h2>
          <div *ngIf="customerAnalytics.length === 0" class="empty-message">No data available</div>
          <div *ngFor="let item of customerAnalytics" class="analytics-row">
            <div class="analytics-name">{{ item.name }}</div>
            <div class="analytics-stats">
              <span class="stat">
                <span class="label">Bookings:</span>
                <span class="value">{{ item.count }}</span>
              </span>
              <span class="stat">
                <span class="label">Revenue:</span>
                <span class="value">{{ item.revenue | currency }}</span>
              </span>
              <span class="stat">
                <span class="label">Confirmed:</span>
                <span class="value">{{ (item.confirmationRate * 100).toFixed(1) }}%</span>
              </span>
            </div>
          </div>
        </div>

        <div class="analytics-section">
          <h2>By Service Type</h2>
          <div *ngIf="serviceTypeAnalytics.length === 0" class="empty-message">
            No data available
          </div>
          <div *ngFor="let item of serviceTypeAnalytics" class="analytics-row">
            <div class="analytics-name">{{ item.name }}</div>
            <div class="analytics-stats">
              <span class="stat">
                <span class="label">Bookings:</span>
                <span class="value">{{ item.count }}</span>
              </span>
              <span class="stat">
                <span class="label">Revenue:</span>
                <span class="value">{{ item.revenue | currency }}</span>
              </span>
              <span class="stat">
                <span class="label">Confirmed:</span>
                <span class="value">{{ (item.confirmationRate * 100).toFixed(1) }}%</span>
              </span>
            </div>
          </div>
        </div>

        <div class="analytics-section">
          <h2>By Truck Type</h2>
          <div *ngIf="truckTypeAnalytics.length === 0" class="empty-message">No data available</div>
          <div *ngFor="let item of truckTypeAnalytics" class="analytics-row">
            <div class="analytics-name">{{ item.name }}</div>
            <div class="analytics-stats">
              <span class="stat">
                <span class="label">Bookings:</span>
                <span class="value">{{ item.count }}</span>
              </span>
              <span class="stat">
                <span class="label">Revenue:</span>
                <span class="value">{{ item.revenue | currency }}</span>
              </span>
              <span class="stat">
                <span class="label">Confirmed:</span>
                <span class="value">{{ (item.confirmationRate * 100).toFixed(1) }}%</span>
              </span>
            </div>
          </div>
        </div>
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
      .analytics-container {
        padding: 20px;
        max-width: 1400px;
        margin: 0 auto;
      }

      .analytics-header {
        margin-bottom: 30px;
      }

      .analytics-header h1 {
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

      .date-input {
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

      .btn-secondary {
        background: #6c757d;
        color: white;
        margin-top: 20px;
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

      .analytics-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
        gap: 20px;
        margin-bottom: 30px;
      }

      .analytics-section {
        background: white;
        border-radius: 8px;
        padding: 20px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
      }

      .analytics-section h2 {
        margin: 0 0 15px 0;
        font-size: 18px;
        font-weight: 600;
        color: #333;
        border-bottom: 2px solid #007bff;
        padding-bottom: 10px;
      }

      .analytics-row {
        padding: 12px;
        border-bottom: 1px solid #eee;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      .analytics-row:last-child {
        border-bottom: none;
      }

      .analytics-name {
        font-weight: 500;
        color: #333;
        min-width: 100px;
      }

      .analytics-stats {
        display: flex;
        gap: 15px;
        flex-wrap: wrap;
        justify-content: flex-end;
      }

      .stat {
        display: flex;
        flex-direction: column;
        text-align: right;
        font-size: 13px;
      }

      .stat .label {
        color: #999;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.3px;
      }

      .stat .value {
        color: #333;
        font-weight: 600;
        font-size: 14px;
      }

      .empty-message {
        text-align: center;
        color: #999;
        padding: 30px;
        font-size: 14px;
      }

      .navigation {
        display: flex;
        gap: 10px;
        margin-top: 20px;
      }
    `,
  ],
})
export class BookingReportsAnalyticsComponent implements OnInit {
  customerAnalytics: BookingAnalytics[] = [];
  serviceTypeAnalytics: BookingAnalytics[] = [];
  truckTypeAnalytics: BookingAnalytics[] = [];

  loading = false;
  error: string | null = null;

  startDate: string = '';
  endDate: string = '';

  constructor(private readonly bookingReportService: BookingReportService) {}

  ngOnInit(): void {
    this.loadAnalytics();
  }

  loadAnalytics(): void {
    this.loading = true;
    this.error = null;

    const requests = [
      this.bookingReportService.getAnalyticsByCustomer(this.startDate, this.endDate),
      this.bookingReportService.getAnalyticsByServiceType(this.startDate, this.endDate),
      this.bookingReportService.getAnalyticsByTruckType(this.startDate, this.endDate),
    ];

    Promise.all(
      requests.map((req) =>
        req.toPromise().catch((err) => {
          console.error('Error loading analytics:', err);
          return null;
        }),
      ),
    ).then((results) => {
      this.loading = false;
      if (results[0]) this.customerAnalytics = results[0].data || [];
      if (results[1]) this.serviceTypeAnalytics = results[1].data || [];
      if (results[2]) this.truckTypeAnalytics = results[2].data || [];
    });
  }
}
