import { CommonModule } from '@angular/common';
import type { HttpEvent, HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpEventType } from '@angular/common/http';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
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
  imports: [CommonModule, FormsModule, TranslateModule],
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

  get selectedFileSizeLabel(): string {
    if (!this.selectedFile) return '0 KB';
    const bytes = this.selectedFile.size;
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
  }

  get expectedColumns(): string[] {
    return this.requiredHeaders;
  }

  get uploadStatusKey(): string {
    if (this.isUploading) return 'bulkOrderUpload.status.processing';
    if (!this.selectedFile) return 'bulkOrderUpload.status.no_file_selected';
    if (this.serverErrors.length > 0 || this.serverMessages.length > 0 || this.uploadError) {
      return 'bulkOrderUpload.status.needs_attention';
    }
    if (this.hasValidationErrors) return 'bulkOrderUpload.status.needs_attention';
    return 'bulkOrderUpload.status.ready_to_upload';
  }

  get uploadStatusToneClasses(): string {
    if (this.isUploading) return 'bg-blue-50 text-blue-700 border-blue-200';
    if (!this.selectedFile) return 'bg-slate-50 text-slate-700 border-slate-200';
    if (this.serverErrors.length > 0 || this.serverMessages.length > 0 || this.uploadError || this.hasValidationErrors) {
      return 'bg-amber-50 text-amber-800 border-amber-200';
    }
    return 'bg-emerald-50 text-emerald-700 border-emerald-200';
  }

  get uploadActionHint(): string {
    if (this.isUploading) return this.t('bulkOrderUpload.action_hint.uploading');
    if (!this.selectedFile) return this.t('bulkOrderUpload.action_hint.choose_file_first');
    if (this.hasValidationErrors) return this.t('bulkOrderUpload.action_hint.fix_rows_first');
    if (this.serverErrors.length > 0 || this.serverMessages.length > 0) {
      return this.t('bulkOrderUpload.action_hint.fix_backend_issues');
    }
    return this.t('bulkOrderUpload.action_hint.ready');
  }

  get submitLabel(): string {
    if (this.isUploading) return this.t('bulkDispatchUpload.uploading');
    if (!this.selectedFile) return this.t('bulkOrderUpload.submit.choose_file');
    if (this.hasValidationErrors) return this.t('bulkOrderUpload.submit.review_rows');
    return this.t('bulkOrderUpload.submit.upload_now');
  }

  private normalizeImportStatus(value: unknown): string {
    const normalized = (value ?? '').toString().trim().toUpperCase();
    if (!normalized || normalized === 'PENDDING') {
      return 'PENDING';
    }
    return normalized;
  }

  private buildHeaderIndexMap(headers: string[]): Map<string, number> {
    const indexMap = new Map<string, number>();
    headers.forEach((header, index) => {
      if (header && !indexMap.has(header)) {
        indexMap.set(header, index + 1);
      }
    });
    return indexMap;
  }

  recentUploads: {
    fileName: string;
    uploadedAt: Date;
    status: 'SUCCESS' | 'FAILED';
    message?: string;
  }[] = [];

  // Bulk upload endpoint
  private readonly uploadUrl = `${environment.baseUrl}/api/admin/transportorders/import-bulk`;
  private readonly serverFieldLabels: Record<string, string> = {
    deliveryDate: 'bulkOrderUpload.field_labels.delivery_date',
    customerCode: 'bulkOrderUpload.field_labels.customer_code',
    toDestination: 'bulkOrderUpload.field_labels.destination',
    tripNo: 'bulkOrderUpload.field_labels.trip_number',
    status: 'bulkOrderUpload.field_labels.status',
    truckNumber: 'bulkOrderUpload.field_labels.truck_number',
    truckTripCount: 'bulkOrderUpload.field_labels.truck_trip_count',
    fromLocation: 'bulkOrderUpload.field_labels.from_destination',
    toLocation: 'bulkOrderUpload.field_labels.to_destination',
    itemCode: 'bulkOrderUpload.field_labels.item_code',
    quantity: 'bulkOrderUpload.field_labels.quantity',
    uom: 'bulkOrderUpload.field_labels.unit_of_measurement',
    orderReference: 'bulkOrderUpload.field_labels.order_reference',
  };

  constructor(
    private http: HttpClient,
    private translate: TranslateService,
  ) {}

  t(key: string, params?: Record<string, unknown>): string {
    return this.translate.instant(key, params);
  }

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

  get filteredServerMessages(): string[] {
    return this.serverMessages.filter((message) => !this.isGenericServerMessage(message));
  }

  get hasStructuredServerFeedback(): boolean {
    return this.serverErrors.length > 0 || this.filteredServerMessages.length > 0;
  }

  get guidanceMessages(): string[] {
    if (this.hasStructuredServerFeedback) {
      return [
        this.t('bulkOrderUpload.guidance.nothing_saved'),
        this.t('bulkOrderUpload.guidance.master_data_first'),
      ];
    }

    if (this.hasValidationErrors) {
      return [
        this.t('bulkOrderUpload.guidance.fix_highlighted_rows'),
      ];
    }

    if (this.selectedFile) {
      if (this.validationSummary) {
        return [
          this.t('bulkOrderUpload.guidance.file_contains', {
            rows: this.validationSummary.totalRows,
            groups: this.validationSummary.totalTrips,
          }),
          this.t('bulkOrderUpload.guidance.preview_valid'),
        ];
      }
      return [
        this.t('bulkOrderUpload.guidance.preview_valid'),
      ];
    }

    return [
      this.t('bulkOrderUpload.guidance.template_support'),
    ];
  }

  get uploadTroubleshootingHints(): string[] {
    if (!this.uploadError) {
      return [];
    }

    if (this.hasStructuredServerFeedback) {
      return [
        this.t('bulkOrderUpload.hints.fix_row_or_master_data'),
        this.t('bulkOrderUpload.hints.nothing_saved_validation'),
      ];
    }

    const normalized = this.uploadError.toLowerCase();

    if (normalized.includes('cannot reach') || normalized.includes('network')) {
      return [
        this.t('bulkOrderUpload.hints.check_services'),
        this.t('bulkOrderUpload.hints.use_same_host'),
      ];
    }

    if (normalized.includes('cors') || normalized.includes('origin') || normalized.includes('blocked')) {
      return [
        this.t('bulkOrderUpload.hints.cors_origin'),
        this.t('bulkOrderUpload.hints.restart_after_cors'),
      ];
    }

    if (normalized.includes('permission') || normalized.includes('forbidden')) {
      return [
        this.t('bulkOrderUpload.hints.admin_access'),
        this.t('bulkOrderUpload.hints.sign_in_again'),
      ];
    }

    return [
      this.t('bulkOrderUpload.hints.check_backend_logs'),
      this.t('bulkOrderUpload.hints.no_data_saved'),
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

  clearSelectedFile(): void {
    this.selectedFile = null;
    this.selectedFileName = '';
    this.resetClientState();
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
      const status = this.normalizeImportStatus(row['Status']);

      // client-side validation
      let errorParts: string[] = [];
      if (!deliveryDate || !datePattern.test(deliveryDate))
        errorParts.push(this.t('bulkOrderUpload.errors.invalid_date'));
      if (!customerCode) errorParts.push(this.t('bulkOrderUpload.errors.missing_customer_code'));
      if (!tripNo) errorParts.push(this.t('bulkOrderUpload.errors.missing_trip_no'));
      if (!truckNumber) errorParts.push(this.t('bulkOrderUpload.errors.missing_truck_number'));
      if (!truckTripCount || !/^\d+$/.test(truckTripCount))
        errorParts.push(this.t('bulkOrderUpload.errors.invalid_truck_trip_count'));
      if (!fromDestination) errorParts.push(this.t('bulkOrderUpload.errors.missing_from_destination'));
      if (!toDestination) errorParts.push(this.t('bulkOrderUpload.errors.missing_to_destination'));
      if (!itemCode) errorParts.push(this.t('bulkOrderUpload.errors.missing_item_code'));
      if (!itemName) errorParts.push(this.t('bulkOrderUpload.errors.missing_item_name'));
      if (isNaN(qty) || qty <= 0) errorParts.push(this.t('bulkOrderUpload.errors.invalid_qty'));
      if (!uom) errorParts.push(this.t('bulkOrderUpload.errors.missing_uom'));

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
      const key = `${row.deliveryDate}_${row.customerCode}_${row.toDestination}_${row.truckTripCount}`;

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
              this.uploadSuccessMessage =
                body.message || this.t('bulkOrderUpload.messages.upload_completed');
              this.autoSuffixMap =
                body.data && !Array.isArray(body.data) && typeof body.data === 'object'
                  ? (body.data as Record<string, string>)
                  : {};
              this.recentUploads.unshift({
                fileName: this.selectedFile?.name || this.t('bulkOrderUpload.common.unknown'),
                uploadedAt: new Date(),
                status: 'SUCCESS',
                message: body.message || this.t('bulkOrderUpload.messages.upload_complete'),
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
              this.uploadError = body.message || this.t('bulkOrderUpload.messages.upload_failed');
              this.uploadSuccessMessage = '';
            }
          }
        },
        error: (error: HttpErrorResponse) => {
          this.isUploading = false;
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
            const normalizedMessage = this.normalizeServerMessage(resp.message || '');
            this.uploadError = this.hasStructuredServerFeedback
              ? this.buildValidationStyleFailureMessage(normalizedMessage)
              : normalizedMessage ||
                this.t('bulkOrderUpload.messages.import_blocked', {
                  count: importErrors.length || messages.length,
                });
          } else {
            this.markServerErrors(importErrors);
            this.serverMessages = messages;
            this.uploadError = this.buildFriendlyUploadError(error, payload, messages);
          }

          this.recentUploads.unshift({
            fileName: this.selectedFile?.name || this.t('bulkOrderUpload.common.unknown'),
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
    if (errs.length > 0) {
      this.showPreview = false;
      setTimeout(() => {
        document.getElementById('orders-upload-server-errors')?.scrollIntoView({
          behavior: 'smooth',
          block: 'start',
        });
      }, 0);
    }
  }

  getServerFieldLabel(field: string): string {
    const translationKey = this.serverFieldLabels[field];
    if (translationKey) {
      return this.t(translationKey);
    }
    return this.humanizeToken(field);
  }

  getReadableServerProblem(error: ImportError): string {
    const label = this.getServerFieldLabel(error.field);
    const suffix = error.value
      ? ` ${this.t('bulkOrderUpload.value_label', { value: error.value })}`
      : '';
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
    const normalizedMessage = this.normalizeServerMessage(directMessage);

    if (this.looksLikeValidationOrMasterDataIssue(normalizedMessage, messages)) {
      return this.buildValidationStyleFailureMessage(normalizedMessage);
    }

    if (error.status === 0) {
      return this.t('bulkOrderUpload.messages.server_unreachable');
    }

    if (error.status === 403) {
      if (this.messageLooksLikeCors(directMessage)) {
        return this.t('bulkOrderUpload.messages.cors_blocked');
      }
      return this.t('bulkOrderUpload.messages.permission_denied');
    }

    if (error.status === 500) {
      if (normalizedMessage) {
        return this.t('bulkOrderUpload.messages.internal_error_with_detail', {
          message: normalizedMessage,
        });
      }
      return this.t('bulkOrderUpload.messages.internal_error');
    }

    if (normalizedMessage) {
      return this.t('bulkOrderUpload.messages.upload_failed_with_message', {
        message: normalizedMessage,
      });
    }

    return this.t('bulkOrderUpload.messages.http_error', {
      status: error.status || this.t('bulkOrderUpload.common.unknown_error'),
    });
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

  private normalizeServerMessage(message: string): string {
    const trimmed = message.trim();
    if (!trimmed) {
      return '';
    }

    const genericMessages = new Set([
      'An unexpected error occurred',
      'Bulk import failed',
      'Upload failed',
    ]);

    return genericMessages.has(trimmed) ? '' : trimmed;
  }

  private isGenericServerMessage(message: string): boolean {
    return this.normalizeServerMessage(message) === '';
  }

  private looksLikeValidationOrMasterDataIssue(
    directMessage: string,
    messages: string[],
  ): boolean {
    const pool = [directMessage, ...messages]
      .map((value) => value.trim())
      .filter(Boolean);

    return pool.some((value) =>
      /(not found|missing required headers|invalid template headers|invalid status|required|quantity must|order already exists|customer|vehicle|item|address|destination|template)/i.test(
        value,
      ),
    );
  }

  private buildValidationStyleFailureMessage(detail: string): string {
    if (!detail) {
      return this.t('bulkOrderUpload.messages.validation_issue_fallback');
    }

    return this.t('bulkOrderUpload.messages.validation_issue_with_detail', {
      message: detail,
    });
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
    if (!isExcel) return this.t('bulkOrderUpload.messages.invalid_excel');

    const fileSizeMB = file.size / (1024 * 1024);
    if (fileSizeMB > 5) return this.t('bulkOrderUpload.messages.file_too_large');

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
        this.uploadError = this.t('bulkOrderUpload.messages.no_worksheet');
        this.selectedFile = null;
        this.selectedFileName = '';
        return null;
      }

      const headerVals =
        ((worksheet.getRow(1).values as Array<string | number | null | undefined>) || []).slice(1);
      const headers: string[] = headerVals.map((h) =>
        typeof h === 'string' ? h.trim() : h != null ? String(h).trim() : '',
      );
      const normalizedHeaders = headers.filter(Boolean);
      const missingHeaders = this.requiredHeaders.filter((required) => !normalizedHeaders.includes(required));
      if (missingHeaders.length > 0) {
        this.uploadError = missingHeaders.length
          ? this.t('bulkOrderUpload.messages.missing_columns', {
              columns: missingHeaders.join(', '),
            })
          : this.t('bulkOrderUpload.messages.invalid_column_order');
        this.selectedFile = null;
        this.selectedFileName = '';
        return null;
      }

      const headerIndexMap = this.buildHeaderIndexMap(headers);

      worksheet.eachRow((row, rowNumber) => {
        if (rowNumber === 1) return;
        const obj: Record<string, string | number> = {};
        let hasNonEmptyValue = false;
        for (const key of this.requiredHeaders) {
          const columnIndex = headerIndexMap.get(key);
          const normalizedValue = this.normalizeExcelCellValue(
            columnIndex ? row.getCell(columnIndex).value : null,
            key,
          );
          if (normalizedValue !== '') {
            hasNonEmptyValue = true;
          }
          obj[key] = normalizedValue;
        }
        if (hasNonEmptyValue) json.push(obj);
      });
    } catch {
      this.uploadError = this.t('bulkOrderUpload.messages.failed_to_read');
      this.selectedFile = null;
      this.selectedFileName = '';
      return null;
    }

    if (json.length === 0) {
      this.uploadError = this.t('bulkOrderUpload.messages.no_data_rows');
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
          `${row.deliveryDate}_${row.customerCode}_${row.toDestination}_${row.truckTripCount}`,
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
    const header = [
      this.t('bulkOrderUpload.row'),
      this.t('bulkOrderUpload.group_key'),
      this.t('bulkOrderUpload.field'),
      this.t('bulkOrderUpload.value'),
      this.t('bulkOrderUpload.message'),
    ];
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
