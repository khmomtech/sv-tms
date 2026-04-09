import { CommonModule } from '@angular/common';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { environment } from '../../environments/environment';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-khb-final-summary',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './khb-final-summary.component.html',
  styleUrls: ['./khb-final-summary.component.css'],
})
export class KhbFinalSummaryComponent {
  date: string = '';
  loading: boolean = false;
  errorMsg: string = '';
  summaryData: any[] = [];

  private readonly BASE_URL = `${environment.baseUrl}/api/khb-so-upload`; // 'http://localhost:8080/api/khb-so-upload';

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  /** 🔐 Auth Headers */
  private getAuthHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      Authorization: token ? `Bearer ${token}` : '',
    });
  }

  /**  Fetch JSON preview */
  fetchPreviewTable(): void {
    if (!this.date) {
      this.errorMsg = '⚠️ Please select a date.';
      return;
    }

    this.loading = true;
    this.errorMsg = '';
    this.summaryData = [];

    this.http
      .get<any[]>(`${this.BASE_URL}/report/final-summary`, {
        params: { uploadDate: this.date },
        headers: this.getAuthHeaders(),
      })
      .subscribe({
        next: (data) => {
          this.summaryData = data;
          this.loading = false;
        },
        error: (err) => {
          console.error(' Preview Error:', err);
          this.errorMsg = err.error?.message || 'Failed to load summary.';
          this.loading = false;
        },
      });
  }

  /** 📥 Download Final Summary Excel */
  downloadFinalSummary(): void {
    if (!this.date) {
      this.errorMsg = '⚠️ Please select a date.';
      return;
    }

    this.loading = true;
    this.errorMsg = '';

    this.http
      .get(`${this.BASE_URL}/khb/final-summary/excel`, {
        params: { date: this.date },
        headers: this.getAuthHeaders(),
        responseType: 'blob',
      })
      .subscribe({
        next: (blob) => {
          const url = window.URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = `Final_Summary_${this.date}.xlsx`;
          a.click();
          window.URL.revokeObjectURL(url);
          this.loading = false;
        },
        error: (err) => {
          console.error(' Download Error:', err);
          this.errorMsg = err.error?.message || 'Download failed.';
          this.loading = false;
        },
      });
  }

  /** ➕ Get total pallet quantity */
  getTotalPallets(): number {
    return this.summaryData.reduce((sum, row) => sum + (row.palletQty || 0), 0);
  }

  /** ➕ Get total weight */
  getTotalWeight(): number {
    return this.summaryData.reduce((sum, row) => sum + (row.weightInKg || 0), 0);
  }
}
