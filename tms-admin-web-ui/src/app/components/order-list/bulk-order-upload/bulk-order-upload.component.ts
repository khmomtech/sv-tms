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
  rowNumber: number;
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
  toDestination: string;
  totalQty: number;
  invalidRows: number;
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

interface IssueBadge {
  label: string;
  count: number;
}

interface UploadResultSummary {
  fileName: string;
  importedRows: number;
  importedTrips: number;
  importedCustomers: number;
  importedQty: number;
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
  lastUploadSummary: UploadResultSummary | null = null;

  // NEW: server-side error state
  serverErrors: ImportError[] = [];
  serverErrorsByGroup: Record<string, ImportError[]> = {};
  serverMessages: string[] = [];
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
    'TrackingNo',
    'TruckTripCount',
    'TruckNumber',
    'TripNo',
    'FromDestination',
    'ToDestination',
    'ItemCode',
    'ItemName',
    'Qty',
    'UoM',
    'UoMPallet',
    'LoadingPlace',
    'Status',
  ];

  recentUploads: {
    fileName: string;
    uploadedAt: Date;
    status: 'SUCCESS' | 'FAILED';
    message?: string;
  }[] = [];

  // Bulk upload endpoint
  private readonly uploadUrl = `${environment.baseUrl}/api/admin/transportorders/import-bulk`;
  private readonly serverFieldLabels: Record<string, string> = {
    deliveryDate: 'Delivery date',
    customerCode: 'Customer code',
    toDestination: 'Destination',
    tripNo: 'Trip number',
    status: 'Status',
    truckNumber: 'Truck number',
    truckTripCount: 'Truck trip count',
    fromLocation: 'From destination',
    toLocation: 'To destination',
    itemCode: 'Item code',
    quantity: 'Quantity',
    uom: 'Unit of measurement',
    orderReference: 'Order reference',
  };

  constructor(private http: HttpClient) {}

  get canUpload(): boolean {
    return !!this.selectedFile && !this.isUploading && !this.hasValidationErrors;
  }

  get clientIssueBadges(): IssueBadge[] {
    return this.toIssueBadges(this.validationSummary?.issueCounts ?? {});
  }

  get serverIssueBadges(): IssueBadge[] {
    const counts: Record<string, number> = {};
    for (const error of this.serverErrors) {
      const label = this.getServerFieldLabel(error.field);
      counts[label] = (counts[label] || 0) + 1;
    }
    return this.toIssueBadges(counts);
  }

  get guidanceMessages(): string[] {
    if (this.serverErrors.length > 0 || this.serverMessages.length > 0) {
      return [
        'Nothing was saved. Fix the listed rows in the Excel file, then upload the corrected file again.',
        'If the problem mentions customer, vehicle, address, or item not found, update the master data first.',
      ];
    }

    if (this.hasValidationErrors) {
      return [
        'Fix the highlighted rows before upload. The upload button stays disabled until all client-side issues are resolved.',
      ];
    }

    if (this.selectedFile) {
      if (this.validationSummary) {
        return [
          `This file contains ${this.validationSummary.totalRows} row(s) and ${this.validationSummary.totalTrips} grouped batch(es).`,
          'Preview looks valid. Upload will still run a stricter backend validation before saving.',
        ];
      }
      return [
        'Preview looks valid. Upload will still run a stricter backend validation before saving.',
      ];
    }

    return [
      'Use the official template without changing header order. Upload supports .xlsx files up to 5 MB.',
    ];
  }

  get uploadTroubleshootingHints(): string[] {
    if (!this.uploadError) {
      return [];
    }

    if (this.serverErrors.length > 0 || this.serverMessages.length > 0) {
      return [
        'Fix the listed row or master-data issues in the Excel file, then upload again.',
        'Nothing was saved while validation errors are present.',
      ];
    }

    const normalized = this.uploadError.toLowerCase();

    if (normalized.includes('cannot reach') || normalized.includes('network')) {
      return [
        'Check that the frontend proxy, auth API, and core API are all running.',
        'Use the same host consistently in local dev, for example localhost for both browser and APIs or 127.0.0.1 for both.',
      ];
    }

    if (normalized.includes('cors') || normalized.includes('origin') || normalized.includes('blocked')) {
      return [
        'This usually means the browser origin is not allowed by the backend.',
        'Restart the local APIs after CORS changes and use the same host consistently in the browser and proxy target.',
      ];
    }

    if (normalized.includes('permission') || normalized.includes('forbidden')) {
      return [
        'Sign in with an account that has admin order-import access.',
        'If the session is stale, sign out and sign in again before retrying.',
      ];
    }

    return [
      'If the problem keeps happening, check the backend logs for the matching request time.',
      'No data is saved when the import request fails.',
    ];
  }

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

    this.parsedRows = json.map((row, index) => {
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
      if (!truckNumber) errorParts.push('Missing truckNumber');
      if (!truckTripCount || !/^\d+$/.test(truckTripCount))
        errorParts.push('TruckTripCount must be a whole number');
      if (!fromDestination) errorParts.push('Missing fromDestination');
      if (!toDestination) errorParts.push('Missing toDestination');
      if (!itemCode) errorParts.push('Missing itemCode');
      if (!itemName) errorParts.push('Missing itemName');
      if (isNaN(qty) || qty <= 0) errorParts.push('Qty must be > 0');
      if (!uom) errorParts.push('Missing UoM');
      if (!status) errorParts.push('Missing status');

      const error = errorParts.join('; ');

      return {
        rowNumber: index + 2,
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
    this.showPreview = this.hasValidationErrors;
  }

  groupTrips(): void {
    // Align with backend import grouping used by the API.
    const tripMap: Record<string, TripGroup> = {};

    for (const row of this.parsedRows) {
      const key = `${row.deliveryDate}_${row.customerCode}_${row.toDestination}_${row.tripNo}`;

      if (!tripMap[key]) {
        tripMap[key] = {
          key,
          deliveryDate: row.deliveryDate,
          customerCode: row.customerCode,
          trackingNo: row.trackingNo,
          tripNo: row.tripNo,
          truckNumber: row.truckNumber,
          truckTripCount: row.truckTripCount,
          toDestination: row.toDestination,
          totalQty: 0,
          invalidRows: 0,
          rows: [],
        };
      }

      tripMap[key].rows.push(row);
      tripMap[key].totalQty += Number.isFinite(row.qty) ? row.qty : 0;
      if (row.error) {
        tripMap[key].invalidRows += 1;
      }
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
      .post<ApiResponse<unknown>>(this.uploadUrl, formData, {
        reportProgress: true,
        observe: 'events',
      })
      .subscribe({
        next: (event: HttpEvent<ApiResponse<unknown>>) => {
          if (event.type === HttpEventType.UploadProgress && event.total) {
            this.uploadProgress = Math.round((event.loaded / event.total) * 100);
          } else if (event.type === HttpEventType.Response) {
            const body = event.body!;
            if (body.success) {
              const importSnapshot = this.buildUploadResultSummary();
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
              this.serverMessages = [];
              this.lastUploadSummary = importSnapshot;
            } else {
              // Non-422 errors would still land here sometimes; show message
              this.uploadError = body.message || 'Upload failed';
              this.uploadSuccessMessage = '';
            }
          }
        },
        error: (error: HttpErrorResponse) => {
          this.uploadSuccessMessage = '';
          const payload = this.getApiErrorPayload(error);
          const { importErrors, messages } = this.extractServerIssues([
            payload?.data,
            payload?.message,
            error.error,
          ]);

          if (error.status === 422 && error.error) {
            const resp = error.error as ApiResponse<unknown>;
            this.markServerErrors(importErrors);
            this.serverMessages = messages;
            this.uploadError =
              resp.message ||
              `❌ Import blocked. ${importErrors.length || messages.length} issue(s) found. Nothing was saved.`;
          } else {
            this.markServerErrors(importErrors);
            this.serverMessages = messages;
            this.uploadError = this.buildFriendlyUploadError(error, payload, messages);
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
    this.serverMessages = [];
  }

  private getApiErrorPayload(error: HttpErrorResponse): Partial<ApiResponse<unknown>> | null {
    if (!error.error || typeof error.error !== 'object' || Array.isArray(error.error)) {
      return null;
    }

    return error.error as Partial<ApiResponse<unknown>>;
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

  getServerFieldLabel(field: string): string {
    return this.serverFieldLabels[field] || this.humanizeToken(field);
  }

  getReadableServerProblem(error: ImportError): string {
    const label = this.getServerFieldLabel(error.field);
    const suffix = error.value ? ` Value: ${error.value}.` : '';
    return `${label}: ${error.message}.${suffix}`;
  }

  private extractServerIssues(data: unknown): {
    importErrors: ImportError[];
    messages: string[];
  } {
    const importErrors: ImportError[] = [];
    const messages: string[] = [];

    const visit = (value: unknown): void => {
      if (Array.isArray(value)) {
        for (const item of value) {
          visit(item);
        }
        return;
      }

      if (typeof value === 'string') {
        const trimmed = value.trim();
        if (!trimmed) return;

        try {
          visit(JSON.parse(trimmed));
          return;
        } catch {
          messages.push(trimmed);
          return;
        }
      }

      if (!value || typeof value !== 'object') {
        return;
      }

      if (this.isImportError(value)) {
        importErrors.push(value);
        return;
      }

      const maybeErrors = (value as { errors?: unknown }).errors;
      if (maybeErrors !== undefined) {
        visit(maybeErrors);
      }
    };

    visit(data);

    return {
      importErrors,
      messages: Array.from(new Set(messages)),
    };
  }

  private buildFriendlyUploadError(
    error: HttpErrorResponse,
    payload: Partial<ApiResponse<unknown>> | null,
    messages: string[],
  ): string {
    const directMessage = this.pickFirstNonEmptyMessage([
      payload?.message,
      ...messages,
      typeof error.error === 'string' ? error.error : '',
    ]);

    if (error.status === 0) {
      return '❌ Upload failed because the server could not be reached. Check the local frontend proxy and backend services, then try again.';
    }

    if (error.status === 403) {
      if (this.messageLooksLikeCors(directMessage)) {
        return '❌ Upload was blocked by browser/API access rules (CORS or origin mismatch). Use the same local host consistently and restart the local APIs if needed.';
      }
      return '❌ Upload was rejected because this session does not have permission to import orders.';
    }

    if (error.status === 500) {
      if (directMessage) {
        return `❌ Upload failed because the server hit an internal error. ${directMessage}`;
      }
      return '❌ Upload failed because the server hit an internal error. Nothing was saved. Check backend logs and try again.';
    }

    if (directMessage) {
      return `❌ Upload failed. ${directMessage}`;
    }

    return `❌ Upload failed with HTTP ${error.status || 'unknown error'}. Nothing was saved.`;
  }

  private pickFirstNonEmptyMessage(messages: Array<string | null | undefined>): string {
    for (const message of messages) {
      const trimmed = message?.trim();
      if (trimmed) {
        return trimmed;
      }
    }
    return '';
  }

  private messageLooksLikeCors(message: string): boolean {
    const normalized = message.toLowerCase();
    return normalized.includes('cors') || normalized.includes('origin');
  }

  private isImportError(value: unknown): value is ImportError {
    if (!value || typeof value !== 'object') {
      return false;
    }

    const candidate = value as Partial<ImportError>;
    return (
      typeof candidate.row === 'number' &&
      typeof candidate.groupKey === 'string' &&
      typeof candidate.field === 'string' &&
      typeof candidate.message === 'string'
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
      const normalizedHeaders = headers.filter(Boolean);
      const missingHeaders = this.requiredHeaders.filter(
        (required) => !normalizedHeaders.includes(required),
      );
      const hasExpectedHeaderOrder = this.requiredHeaders.every(
        (header, index) => normalizedHeaders[index] === header,
      );
      if (missingHeaders.length > 0 || !hasExpectedHeaderOrder) {
        this.uploadError = missingHeaders.length
          ? `⚠️ Missing required columns: ${missingHeaders.join(', ')}. Please use the official template.`
          : '⚠️ Invalid column order. Please use the official template without changing the header layout.';
        this.selectedFile = null;
        this.selectedFileName = '';
        return null;
      }

      worksheet.eachRow((row, rowNumber) => {
        if (rowNumber === 1) return;
        const obj: Record<string, string | number> = {};
        let hasNonEmptyValue = false;
        for (let c = 1; c <= this.requiredHeaders.length; c++) {
          const key = this.requiredHeaders[c - 1];
          const normalizedValue = this.normalizeExcelCellValue(row.getCell(c).value, key);
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
        (row) =>
          `${row.deliveryDate}_${row.customerCode}_${row.toDestination}_${row.tripNo}`,
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

  private toIssueBadges(issueCounts: Record<string, number>): IssueBadge[] {
    return Object.entries(issueCounts)
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
      .map(([label, count]) => ({ label, count }));
  }

  private buildUploadResultSummary(): UploadResultSummary | null {
    if (!this.validationSummary || !this.selectedFile) {
      return null;
    }

    return {
      fileName: this.selectedFile.name,
      importedRows: this.validationSummary.validRows,
      importedTrips: this.validationSummary.totalTrips,
      importedCustomers: this.validationSummary.uniqueCustomers,
      importedQty: this.validationSummary.totalQty,
    };
  }

  private humanizeToken(value: string): string {
    return value
      .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
      .replace(/[_-]+/g, ' ')
      .replace(/\s+/g, ' ')
      .trim()
      .replace(/^\w/, (char) => char.toUpperCase());
  }

  private normalizeExcelCellValue(value: unknown, header = ''): string | number {
    if (value == null) return '';
    if (value instanceof Date) {
      return header === 'DeliveryDate' ? this.formatDateDdMmYyyy(value) : value.toISOString();
    }
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      return value.trim();
    }
    if (typeof value === 'object') {
      const obj = value as Record<string, unknown>;
      const text = obj['text'];
      if (typeof text === 'string' && text.trim()) return text.trim();

      const result = obj['result'];
      if (result instanceof Date) {
        return header === 'DeliveryDate' ? this.formatDateDdMmYyyy(result) : result.toISOString();
      }

      if (typeof result === 'number' || typeof result === 'string') {
        return this.normalizeExcelCellValue(result, header);
      }

      const richText = obj['richText'];
      if (Array.isArray(richText)) {
        return richText
          .map((rt) => String((rt as Record<string, unknown>)['text'] ?? ''))
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
