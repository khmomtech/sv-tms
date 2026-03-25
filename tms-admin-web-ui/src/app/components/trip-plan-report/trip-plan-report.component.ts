/* eslint-disable @typescript-eslint/consistent-type-imports */
import { formatDate } from '@angular/common';
import { Component } from '@angular/core';

import { KhbSoUploadService } from '../../services/khb-so-upload.service';

@Component({
  selector: 'app-trip-plan-report',
  templateUrl: './trip-plan-report.component.html',
  styleUrls: ['./trip-plan-report.component.css'],
})
export class TripPlanReportComponent {
  uploadDate: string = formatDate(new Date(), 'yyyy-MM-dd', 'en');
  zone: string = '';
  distributorCode: string = '';
  tripPlans: any[] = [];
  isLoading = false;
  errorMsg = '';

  constructor(private khbService: KhbSoUploadService) {}

  fetchTripPlans(): void {
    this.isLoading = true;
    this.khbService.planTrip(this.uploadDate, this.zone, this.distributorCode).subscribe({
      next: (res) => {
        this.tripPlans = res.content || [];
        this.isLoading = false;
      },
      error: (err) => {
        this.errorMsg = err.error?.error || 'Failed to load trip plans.';
        this.isLoading = false;
      },
    });
  }

  downloadTripPlan(): void {
    this.khbService.exportTripPlan(this.uploadDate).subscribe((blob) => {
      this.downloadFile(blob, `trip-plan-${this.uploadDate}.xlsx`);
    });
  }

  downloadFinalSummary(): void {
    this.khbService.exportFinalSummary(this.uploadDate).subscribe((blob) => {
      this.downloadFile(blob, `Final_Summary_Report_${this.uploadDate}.xlsx`);
    });
  }

  private downloadFile(blob: Blob, filename: string): void {
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    window.URL.revokeObjectURL(url);
  }
}
