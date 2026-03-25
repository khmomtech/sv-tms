import { CommonModule } from '@angular/common';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpClientModule, HttpHeaders } from '@angular/common/http';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { environment } from '../../environments/environment';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../../services/auth.service';
import { NotificationService } from '../../services/notification.service';

@Component({
  selector: 'app-khb-so-upload',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './khb-so-upload.component.html',
  styleUrls: ['./khb-so-upload.component.css'],
})
export class KhbSoUploadComponent {
  private notification = inject(NotificationService);
  selectedFile: File | null = null;
  previewData: any[] = [];
  summary: { totalRows: number; skipped: number; errors: number } | null = null;
  errorMsg: string = '';
  loading: boolean = false;

  errorRows: Set<number> = new Set();
  errorMessages: { [key: number]: string[] } = {};

  input = {
    smallVanOwn11: { pallets: 0, trucks: 0 },
    smallVanOwn8: { pallets: 0, trucks: 0 },
    smallVanSub11: { pallets: 0, trucks: 0 },
    smallVanSub8: { pallets: 0, trucks: 0 },
  };

  private readonly BASE_URL = `${environment.baseUrl}/api/khb-so-upload`;

  columnOrder: string[] = [
    'docNo',
    'distributorCode',
    'docDate',
    'transportVendorName',
    'soldToParty',
    'name1',
    'shipToParty',
    'shipToPartyName',
    'description',
    'pallet',
    'wh',
    'purchasingDoc',
    'qty',
    'qtyPerPallet',
    'remark',
  ];

  columnHeaders: { [key: string]: string } = {
    docNo: 'Doc No',
    distributorCode: 'Distributor',
    docDate: 'Date',
    transportVendorName: 'Vendor',
    soldToParty: 'Sold To',
    name1: 'Sold To Name',
    shipToParty: 'Ship To',
    shipToPartyName: 'Ship To Name',
    description: 'Product',
    pallet: 'Pallet Type',
    wh: 'Warehouse',
    purchasingDoc: 'PO No',
    qty: 'Qty',
    qtyPerPallet: 'Qty/Pallet',
    remark: 'Remark',
  };

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  private getAuthHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      Authorization: token ? `Bearer ${token}` : '',
    });
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files?.length) {
      this.selectedFile = input.files[0];
      this.previewData = [];
      this.summary = null;
      this.errorRows.clear();
      this.errorMessages = {};
      this.errorMsg = '';
    }
  }

  previewUpload(): void {
    if (!this.selectedFile) {
      this.errorMsg = 'Please select a file.';
      return;
    }

    const formData = new FormData();
    formData.append('file', this.selectedFile);

    this.loading = true;
    this.http
      .post(`${this.BASE_URL}/preview`, formData, {
        headers: this.getAuthHeaders(),
      })
      .subscribe({
        next: (res: any) => {
          this.previewData = res.valid || [];
          this.summary = {
            totalRows: res.totalRows || 0,
            skipped: res.skipped || 0,
            errors: res.errors?.length || 0,
          };

          this.errorRows = new Set(res.errors?.map((e: any) => parseInt(e.row) - 1));
          this.errorMessages =
            res.errors?.reduce((acc: any, e: any) => {
              const rowIndex = parseInt(e.row) - 1;
              acc[rowIndex] = e.reason.split(';').map((msg: string) => msg.trim());
              return acc;
            }, {}) || {};

          this.errorMsg = '';
          this.loading = false;
        },
        error: (err) => {
          console.error(' Preview Error:', err);
          this.errorMsg = err.error?.error || 'Preview failed.';
          this.previewData = [];
          this.summary = null;
          this.loading = false;
        },
      });
  }

  commitUpload(): void {
    if (!this.previewData.length) {
      this.notification.simulateNotification('Notice', '⚠️ No valid preview data to commit.');
      return;
    }

    const payload = {
      rows: this.previewData,
      truckInput: this.input, // Optional: Send to backend if needed
    };

    this.loading = true;
    this.http
      .post(`${this.BASE_URL}/commit`, payload, {
        headers: this.getAuthHeaders(),
      })
      .subscribe({
        next: () => {
          this.notification.simulateNotification('Success', 'Upload committed successfully.');
          this.previewData = [];
          this.summary = null;
          this.selectedFile = null;
          this.errorRows.clear();
          this.errorMessages = {};
          this.loading = false;
        },
        error: (err) => {
          console.error(' Commit Error:', err);
          this.notification.simulateNotification(
            'Error',
            `Commit failed: ${err.error?.error || 'Unknown error.'}`,
          );
          this.loading = false;
        },
      });
  }

  get hasErrorMessages(): boolean {
    return Object.keys(this.errorMessages).length > 0;
  }
}
