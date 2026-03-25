import { CommonModule } from '@angular/common';
import type { HttpEvent, HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpEventType } from '@angular/common/http';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Workbook } from 'exceljs';

import { environment } from '../../../environments/environment';

interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T | null;
  timestamp?: string;
}

interface ImportError {
  row: number;
  groupKey: string;
  field: string;
  value: string;
  message: string;
}

interface ParsedRow {
  deliveryDate: string;
  customerCode: string;
  trackingNo: string;
  tripNo: string;
  truckNumber: string;
  truckTripCount: string;
  fromDestination: string;
  toDestination: string;
  itemCode: string;
  itemName: string;
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
  tripNo: string;
  truckNumber: string;
  truckTripCount: string;
  rows: ParsedRow[];
}

interface ValidationSummary {
  totalRows: number;
  validRows: number;
  invalidRows: number;
  totalTrips: number;
  uniqueCustomers: number;
  totalQty: number;
  issueCounts: Record<string, number>;
}

@Component({
  selector: 'app-bulk-order-upload',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './bulk-order-upload.component.html',
  styleUrls: ['./bulk-order-upload.component.scss'],
})
export class BulkOrderUploadComponent {
  selectedFile: File | null = null;
  selectedFileName = '';
  parsedRows: ParsedRow[] = [];
  groupedTrips: TripGroup[] = [];
  validationSummary: ValidationSummary | null = null;
  showPreview = false;
  uploadProgress = 0;
  uploadError = '';
  uploadSuccessMessage = '';
  uploadSuccess = false;
  isUploading = false;
  hasValidationErrors = false;
  isDragOver = false;

  // NEW: server-side error state
  serverErrors: ImportError[] = [];
  serverErrorsByGroup: Record<string, ImportError[]> = {};
  autoSuffixMap: Record<string, string> = {};
  private readonly acceptedExtensions = ['.xlsx'];
  private readonly acceptedMimeTypes = [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel',
    'application/octet-stream',
  ];
  private readonly requiredHeaders = [
    'DeliveryDate',
    'CustomerCode',
    'TripNo',
    'ToDestination',
    'ItemCode',
    'ItemName',
    'Qty',
  ];

  recentUploads: {
    fileName: string;
    uploadedAt: Date;
    status: 'SUCCESS' | 'FAILED';
    message?: string;
  }[] = [];

  // Bulk upload endpoint
  private readonly uploadUrl = `${environment.baseUrl}/api/admin/transportorders/import-bulk`;

  constructor(private http: HttpClient) {}

  async onFileSelected(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    await this.handleSelectedFile(file);
    // Allow selecting the same file again after fixing data
    input.value = '';
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = false;
  }

  async onFileDropped(event: DragEvent): Promise<void> {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = false;
    const file = event.dataTransfer?.files?.[0];
    if (!file) return;
    await this.handleSelectedFile(file);
  }

  openFilePicker(fileInput: HTMLInputElement): void {
    fileInput.click();
  }

  private async handleSelectedFile(file: File): Promise<void> {
    const validationError = this.validateFile(file);
    this.resetClientState();
    if (validationError) {
      this.uploadError = validationError;
      return;
    }

    this.selectedFile = file;
    this.selectedFileName = file.name;

    const json = await this.extractRowsFromFile(file);
    if (!json) return;

    const datePattern = /^\d{2}\.\d{2}\.\d{4}$/;

    this.parsedRows = json.map((row) => {
      const deliveryDate = (row['DeliveryDate'] ?? '').toString().trim();
      const customerCode = (row['CustomerCode'] ?? '').toString().trim();
      const trackingNo = (row['TrackingNo'] ?? '').toString().trim();
      const tripNo = (row['TripNo'] ?? '').toString().trim();
      const truckNumber = (row['TruckNumber'] ?? '').toString().trim();
      const truckTripCount = (row['TruckTripCount'] ?? '').toString().trim();
      const fromDestination = (row['FromDestination'] ?? '').toString().trim();
      const toDestination = (row['ToDestination'] ?? '').toString().trim();
      const itemCode = (row['ItemCode'] ?? '').toString().trim();
      const itemName = (row['ItemName'] ?? '').toString().trim();
      const qty = this.parseQty(row['Qty']);
      const uom = (row['UoM'] ?? '').toString().trim();
      const uoMPallet = (row['UoMPallet'] ?? '').toString().trim();
      const loadingPlace = (row['LoadingPlace'] ?? '').toString().trim();
      const status = (row['Status'] ?? '').toString().trim();

      // client-side validation
      let errorParts: string[] = [];
      if (!deliveryDate || !datePattern.test(deliveryDate))
        errorParts.push('Invalid date (dd.MM.yyyy)');
      if (!customerCode) errorParts.push('Missing customerCode');
      if (!tripNo) errorParts.push('Missing tripNo');
      if (!toDestination) errorParts.push('Missing toDestination');
      if (!itemCode) errorParts.push('Missing itemCode');
      if (!itemName) errorParts.push('Missing itemName');
      if (isNaN(qty) || qty <= 0) errorParts.push('Qty must be > 0');

      const error = errorParts.join('; ');

      return {
        deliveryDate,
        customerCode,
        trackingNo,
        tripNo,
        truckNumber,
        truckTripCount,
        fromDestination,
        toDestination,
        itemCode,
        itemName,
        qty,
        uom,
        uoMPallet,
        loadingPlace,
        status,
        error,
      };
    });

    this.hasValidationErrors = this.parsedRows.some((row) => !!row.error);
    this.groupTrips();
    this.validationSummary = this.buildValidationSummary();
  }

  groupTrips(): void {
    // Align with backend grouping:
    // deliveryDate + customerCode + toDestination + tripNo
    const tripMap: Record<string, TripGroup> = {};

    for (const row of this.parsedRows) {
      const key = `${row.deliveryDate}_${row.customerCode}_${row.toDestination}_${row.tripNo}`;

      if (!tripMap[key]) {
        tripMap[key] = {
          key,
          deliveryDate: row.deliveryDate,
          customerCode: row.customerCode,
          trackingNo: row.trackingNo, // optional, just for display
          tripNo: row.tripNo,
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

    this.uploadProgress = 0;
    this.isUploading = true;
    this.uploadError = '';
    this.uploadSuccess = false;
    this.clearServerErrors();

    this.http
      .post<ApiResponse<null | ImportError[]>>(this.uploadUrl, formData, {
        reportProgress: true,
        observe: 'events',
      })
      .subscribe({
        next: (event: HttpEvent<ApiResponse<null | ImportError[]>>) => {
          if (event.type === HttpEventType.UploadProgress && event.total) {
            this.uploadProgress = Math.round((event.loaded / event.total) * 100);
          } else if (event.type === HttpEventType.Response) {
            const body = event.body!;
            if (body.success) {
              this.uploadSuccess = true;
              this.uploadSuccessMessage = body.message || '✅ Upload completed successfully.';
              this.autoSuffixMap =
                body.data && !Array.isArray(body.data) && typeof body.data === 'object'
                  ? (body.data as Record<string, string>)
                  : {};
              this.recentUploads.unshift({
                fileName: this.selectedFile?.name || 'Unknown',
                uploadedAt: new Date(),
                status: 'SUCCESS',
                message: body.message || 'Upload complete',
              });
              this.uploadError = '';
              // reset
              this.selectedFile = null;
              this.selectedFileName = '';
              this.parsedRows = [];
              this.groupedTrips = [];
              this.hasValidationErrors = false;
              this.validationSummary = null;
            } else {
              // Non-422 errors would still land here sometimes; show message
              this.uploadError = body.message || 'Upload failed';
              this.uploadSuccessMessage = '';
            }
          }
        },
        error: (error: HttpErrorResponse) => {
          this.uploadSuccessMessage = '';
          if (error.status === 422 && error.error) {
            const resp = error.error as ApiResponse<ImportError[]>;
            const errs = resp.data || [];
            this.markServerErrors(errs);
            this.uploadError =
              resp.message ||
              `❌ Import blocked. ${errs.length} issue(s) found. Nothing was saved.`;
          } else {
            // Try to extract server-side validation errors in any shape
            const payload = error?.error as Partial<ApiResponse<any>> | undefined;
            const raw = payload?.data;

            let errs: ImportError[] = [];

            if (Array.isArray(raw)) {
              errs = raw as ImportError[];
            } else if (typeof raw === 'string') {
              // Sometimes servers send a JSON string; try to parse it
              try {
                const maybe = JSON.parse(raw);
                if (Array.isArray(maybe)) errs = maybe as ImportError[];
              } catch {
                // Not JSON, ignore; server likely sent a toString() of the list
              }
            } else if (raw && typeof raw === 'object') {
              // Some servers send { errors: [...] }
              if (Array.isArray((raw as any).errors)) errs = (raw as any).errors;
            }

            if (errs.length) {
              this.markServerErrors(errs);
            } else {
              this.clearServerErrors();
            }

            this.uploadError = payload?.message || `❌ Upload failed: ${error.message}`;
          }

          this.recentUploads.unshift({
            fileName: this.selectedFile?.name || 'Unknown',
            uploadedAt: new Date(),
            status: 'FAILED',
            message: this.uploadError,
          });
        },
        complete: () => {
          this.isUploading = false;
        },
      });
  }

  // ---- helpers ----
  private resetClientState(): void {
    this.uploadError = '';
    this.uploadSuccessMessage = '';
    this.uploadSuccess = false;
    this.parsedRows = [];
    this.groupedTrips = [];
    this.hasValidationErrors = false;
    this.validationSummary = null;
    this.showPreview = false;
    this.isDragOver = false;
    this.autoSuffixMap = {};
    this.clearServerErrors();
  }

  private clearServerErrors(): void {
    this.serverErrors = [];
    this.serverErrorsByGroup = {};
  }

  downloadSuffixMapCsv(): void {
    if (!this.autoSuffixMap || Object.keys(this.autoSuffixMap).length === 0) return;
    const rows = [['original_order_reference', 'new_order_reference']];
    for (const [original, updated] of Object.entries(this.autoSuffixMap)) {
      rows.push([original, updated]);
    }
    const csv = rows
      .map((r) => r.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','))
      .join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `order-reference-aliases-${new Date().toISOString().slice(0, 19)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  private markServerErrors(errs: ImportError[] = []): void {
    this.serverErrors = errs;
    this.serverErrorsByGroup = errs.reduce(
      (acc, e) => {
        (acc[e.groupKey] ??= []).push(e);
        return acc;
      },
      {} as Record<string, ImportError[]>,
    );
  }

  private parseQty(value: unknown): number {
    if (typeof value === 'number') return Number.isFinite(value) ? value : 0;
    if (value == null) return 0;
    const raw = String(value).trim().replace(/,/g, '');
    const parsed = Number(raw);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  private validateFile(file: File): string {
    const lowerName = file.name.toLowerCase();
    const hasValidExtension = this.acceptedExtensions.some((ext) => lowerName.endsWith(ext));
    const hasExcelMime =
      !file.type ||
      this.acceptedMimeTypes.includes(file.type) ||
      file.type.includes('spreadsheetml');
    const isExcel = hasValidExtension && hasExcelMime;
    if (!isExcel) return '⚠️ Please upload a valid .xlsx Excel file.';

    const fileSizeMB = file.size / (1024 * 1024);
    if (fileSizeMB > 5) return '⚠️ File size exceeds 5MB limit (max 5MB).';

    return '';
  }

  private async extractRowsFromFile(file: File): Promise<Record<string, string | number>[] | null> {
    let json: Record<string, string | number>[] = [];
    try {
      const buffer = await file.arrayBuffer();
      const workbook = new Workbook();
      await workbook.xlsx.load(buffer);
      const worksheet = workbook.worksheets[0];
      if (!worksheet) {
        this.uploadError = '⚠️ No worksheet found in the uploaded file.';
        this.selectedFile = null;
        this.selectedFileName = '';
        return null;
      }

      const headerVals =
        (worksheet.getRow(1).values as Array<string | number | null | undefined>) || [];
      const headers: string[] = headerVals.map((h) =>
        typeof h === 'string' ? h.trim() : h != null ? String(h).trim() : '',
      );
      const missingHeaders = this.requiredHeaders.filter((required) => !headers.includes(required));
      if (missingHeaders.length > 0) {
        this.uploadError = `⚠️ Missing required columns: ${missingHeaders.join(', ')}. Please use the official template.`;
        this.selectedFile = null;
        this.selectedFileName = '';
        return null;
      }

      worksheet.eachRow((row, rowNumber) => {
        if (rowNumber === 1) return;
        const obj: Record<string, string | number> = {};
        let hasNonEmptyValue = false;
        for (let c = 1; c < headers.length; c++) {
          const key = headers[c];
          if (!key) continue;
          const normalizedValue = this.normalizeExcelCellValue(row.getCell(c).value);
          if (normalizedValue !== '') {
            hasNonEmptyValue = true;
          }
          obj[key] = normalizedValue;
        }
        if (hasNonEmptyValue) json.push(obj);
      });
    } catch {
      this.uploadError = '⚠️ Failed to read Excel file. Please verify it is a valid .xlsx file.';
      this.selectedFile = null;
      this.selectedFileName = '';
      return null;
    }

    if (json.length === 0) {
      this.uploadError = '⚠️ No data rows found. Please fill at least one row in the template.';
      this.selectedFile = null;
      this.selectedFileName = '';
      return null;
    }
    return json;
  }

  private buildValidationSummary(): ValidationSummary {
    const totalRows = this.parsedRows.length;
    const validRowsOnly = this.parsedRows.filter((row) => !row.error);
    const invalidRows = totalRows - validRowsOnly.length;
    const validRows = totalRows - invalidRows;
    const uniqueCustomers = new Set(
      validRowsOnly.map((r) => r.customerCode).filter((code) => !!code),
    ).size;
    const totalQty = validRowsOnly.reduce(
      (sum, row) => sum + (Number.isFinite(row.qty) ? row.qty : 0),
      0,
    );
    const totalTrips = new Set(
      validRowsOnly.map(
        (row) => `${row.deliveryDate}_${row.customerCode}_${row.toDestination}_${row.tripNo}`,
      ),
    ).size;

    const issueCounts: Record<string, number> = {};
    for (const row of this.parsedRows) {
      if (!row.error) continue;
      const issues = row.error
        .split(';')
        .map((s) => s.trim())
        .filter(Boolean);
      for (const issue of issues) {
        issueCounts[issue] = (issueCounts[issue] || 0) + 1;
      }
    }

    return {
      totalRows,
      validRows,
      invalidRows,
      totalTrips,
      uniqueCustomers,
      totalQty,
      issueCounts,
    };
  }

  private normalizeExcelCellValue(value: unknown): string | number {
    if (value == null) return '';
    if (value instanceof Date) {
      return this.formatDateDdMmYyyy(value);
    }
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      return value.trim();
    }
    if (typeof value === 'object') {
      const obj = value as Record<string, unknown>;
      if (typeof obj.text === 'string' && obj.text.trim()) return obj.text.trim();
      if (obj.result instanceof Date) return this.formatDateDdMmYyyy(obj.result);
      if (typeof obj.result === 'number' || typeof obj.result === 'string') {
        return this.normalizeExcelCellValue(obj.result);
      }
      if (Array.isArray(obj.richText)) {
        return obj.richText
          .map((rt) => String((rt as Record<string, unknown>).text ?? ''))
          .join('')
          .trim();
      }
    }
    return String(value).trim();
  }

  private formatDateDdMmYyyy(date: Date): string {
    const dd = String(date.getDate()).padStart(2, '0');
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const yyyy = String(date.getFullYear());
    return `${dd}.${mm}.${yyyy}`;
  }

  // Download server errors as CSV for quick fixing
  downloadErrorsCSV(): void {
    if (!this.serverErrors.length) return;
    const header = ['Row', 'GroupKey', 'Field', 'Value', 'Message'];
    const rows = this.serverErrors.map((e) => [
      e.row,
      `"${(e.groupKey ?? '').replace(/"/g, '""')}"`,
      e.field,
      `"${(e.value ?? '').toString().replace(/"/g, '""')}"`,
      `"${(e.message ?? '').replace(/"/g, '""')}"`,
    ]);
    const csv = [header, ...rows].map((r) => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `import-errors-${new Date().toISOString().slice(0, 19)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }
}
