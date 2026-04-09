import { CommonModule } from '@angular/common';
import type { HttpEvent, HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpEventType, HttpHeaders } from '@angular/common/http';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { Workbook } from 'exceljs';

import { environment } from '../../environments/environment';

interface ParsedRow {
  deliveryDate: string;
  customerCode: string;
  trackingNo: string;
  truckNumber: string;
  truckTripCount: string;
  fromDestination: string;
  toDestination: string;
  item: string;
  qty: number;
  uom: string;
  uoMPallet: string;
  loadingPlace: string;
  status: string;
  error?: string;
}

interface TripGroup {
  key: string;
  deliveryDate: string;
  customerCode: string;
  trackingNo: string;
  truckNumber: string;
  truckTripCount: string;
  rows: ParsedRow[];
}

@Component({
  selector: 'app-bulk-dispatch-upload',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslateModule],
  templateUrl: './bulk-dispatch-upload.component.html',
  styleUrl: './bulk-dispatch-upload.component.scss',
})
export class BulkDispatchUploadComponent {
  selectedFile: File | null = null;
  parsedRows: ParsedRow[] = [];
  groupedTrips: TripGroup[] = [];
  uploadProgress = 0;
  uploadError = '';
  uploadSuccess = false;
  isUploading = false;
  hasValidationErrors = false;

  recentUploads: {
    fileName: string;
    uploadedAt: Date;
    status: 'SUCCESS' | 'FAILED';
    message?: string;
  }[] = [];

  private readonly uploadUrl = `${environment.baseUrl}/api/admin/dispatches/import-bulk`;

  constructor(
    private http: HttpClient,
    private translate: TranslateService,
  ) {}

  async onFileSelected(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    if (!input.files?.length) return;

    const file = input.files[0];
    const isExcel = file.name.endsWith('.xlsx') || file.type.includes('spreadsheetml');
    const fileSizeMB = file.size / (1024 * 1024);

    this.uploadError = '';
    this.parsedRows = [];
    this.groupedTrips = [];
    this.hasValidationErrors = false;

    if (!isExcel) {
      this.uploadError = this.translate.instant('bulkDispatchUpload.invalid_file');
      return;
    }

    if (fileSizeMB > 5) {
      this.uploadError = this.translate.instant('bulkDispatchUpload.file_too_large');
      return;
    }

    this.selectedFile = file;

    // Parse using ExcelJS
    const buffer = await file.arrayBuffer();
    const workbook = new Workbook();
    await workbook.xlsx.load(buffer);
    const worksheet = workbook.worksheets[0];
    if (!worksheet) {
      this.uploadError = this.translate.instant('bulkDispatchUpload.no_worksheet');
      return;
    }

    // Build headers from first row
    const headerVals =
      (worksheet.getRow(1).values as Array<string | number | null | undefined>) || [];
    const headers: string[] = headerVals.map((h) =>
      typeof h === 'string' ? h.trim() : h != null ? String(h).trim() : '',
    );

    const json: any[] = [];
    worksheet.eachRow((row, rowNumber) => {
      if (rowNumber === 1) return; // skip header
      const obj: any = {};
      for (let c = 1; c < headers.length; c++) {
        const key = headers[c];
        if (!key) continue;
        const cellVal: any = row.getCell(c).value;
        const normalized =
          cellVal?.text ??
          cellVal?.result ??
          (Array.isArray(cellVal?.richText)
            ? cellVal.richText.map((rt: any) => rt.text).join('')
            : cellVal);
        obj[key] = typeof normalized === 'string' ? normalized.trim() : (normalized ?? '');
      }
      json.push(obj);
    });

    this.parsedRows = json.map((row) => {
      const deliveryDate = row['DeliveryDate']?.toString().trim() || '';
      const customerCode = row['CustomerCode']?.toString().trim() || '';
      const trackingNo = row['TrackingNo']?.toString().trim() || '';
      const truckNumber = row['TruckNumber']?.toString().trim() || '';
      const truckTripCount = row['TruckTripCount']?.toString().trim() || '';
      const fromDestination = row['FromDestination']?.toString().trim() || '';
      const toDestination = row['ToDestination']?.toString().trim() || '';
      const item = row['Item']?.toString().trim() || '';
      const qty = Number(row['Qty']) || 0;
      const uom = row['UoM']?.toString().trim() || '';
      const uoMPallet = row['UoMPallet']?.toString().trim() || '';
      const loadingPlace = row['LoadingPlace']?.toString().trim() || '';
      const status = row['Status']?.toString().trim() || '';

      let error = '';
      if (!deliveryDate || !customerCode || !trackingNo || isNaN(qty) || qty <= 0) {
        error = this.translate.instant('bulkDispatchUpload.invalid_qty');
        this.hasValidationErrors = true;
      }

      return {
        deliveryDate,
        customerCode,
        trackingNo,
        truckNumber,
        truckTripCount,
        fromDestination,
        toDestination,
        item,
        qty,
        uom,
        uoMPallet,
        loadingPlace,
        status,
        error,
      };
    });

    this.groupTrips();
  }

  groupTrips(): void {
    const tripMap: Record<string, TripGroup> = {};

    for (const row of this.parsedRows) {
      const key = `${row.deliveryDate}_${row.customerCode}_${row.trackingNo}_${row.truckNumber}_${row.truckTripCount}`;

      if (!tripMap[key]) {
        tripMap[key] = {
          key,
          deliveryDate: row.deliveryDate,
          customerCode: row.customerCode,
          trackingNo: row.trackingNo,
          truckNumber: row.truckNumber,
          truckTripCount: row.truckTripCount,
          rows: [],
        };
      }

      tripMap[key].rows.push(row);
    }

    this.groupedTrips = Object.values(tripMap);
  }

  uploadExcel(): void {
    if (!this.selectedFile || this.hasValidationErrors) return;

    const formData = new FormData();
    formData.append('file', this.selectedFile);

    const token = localStorage.getItem('token') || '';
    const headers = new HttpHeaders({ Authorization: `Bearer ${token}` });

    this.uploadProgress = 0;
    this.isUploading = true;
    this.uploadError = '';
    this.uploadSuccess = false;

    this.http
      .post(this.uploadUrl, formData, {
        headers,
        reportProgress: true,
        observe: 'events',
      })
      .subscribe({
        next: (event: HttpEvent<any>) => {
          if (event.type === HttpEventType.UploadProgress && event.total) {
            this.uploadProgress = Math.round((event.loaded / event.total) * 100);
          } else if (event.type === HttpEventType.Response) {
            this.uploadSuccess = true;
            this.recentUploads.unshift({
              fileName:
                this.selectedFile?.name ||
                this.translate.instant('bulkDispatchUpload.unknown_file'),
              uploadedAt: new Date(),
              status: 'SUCCESS',
              message: this.translate.instant('bulkDispatchUpload.upload_complete'),
            });
            this.selectedFile = null;
            this.parsedRows = [];
            this.groupedTrips = [];
          }
        },
        error: (error: HttpErrorResponse) => {
          this.uploadError = this.translate.instant('bulkDispatchUpload.upload_failed', {
            message: error.error?.message || error.message,
          });
          this.recentUploads.unshift({
            fileName:
              this.selectedFile?.name || this.translate.instant('bulkDispatchUpload.unknown_file'),
            uploadedAt: new Date(),
            status: 'FAILED',
            message: error.error?.message || error.message,
          });
        },
        complete: () => {
          this.isUploading = false;
        },
      });
  }
}
