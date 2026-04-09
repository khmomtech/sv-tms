import { HttpClient, HttpEvent, HttpEventType, HttpHeaders } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Observable } from 'rxjs';
import { catchError, tap, map, throwError, of, filter } from 'rxjs';

import { environment } from '../../environments/environment';
import { ApiResponse } from '../models/api-response.model';
import { DriverDocument } from '../models/driver-document.model';

import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class DriverDocumentService {
  private readonly documentUrl = `${environment.apiBaseUrl}/admin/driver-documents`;
  private readonly driverApiUrl = `${environment.apiBaseUrl}/admin/drivers`;

  private readonly http = inject(HttpClient);
  private readonly authService = inject(AuthService);
  private readonly snackBar = inject(MatSnackBar);

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    });
  }

  private getUploadHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    });
  }

  private handleError(operation: string, error: any): Observable<never> {
    const message = this.getDetailedErrorMessage(error);
    this.showToast(`${operation} failed: ${message}`);
    console.error(`DriverDocumentService ${operation} error:`, { status: error.status, error });
    return throwError(() => error);
  }

  private showToast(message: string, action = 'Close', duration = 3000): void {
    this.snackBar.open(message, action, {
      duration,
      horizontalPosition: 'right',
      verticalPosition: 'top',
    });
  }

  private getDetailedErrorMessage(error: any): string {
    if (!error) {
      return 'An unexpected error occurred. Please try again.';
    }

    const status = error.status || error.statusCode || 0;
    const errorMsg = error.error?.message || error.message || '';

    switch (status) {
      case 400:
        return `Validation error: ${errorMsg || 'Please check your input and try again.'}`;
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The document was not found. It may have been deleted by another user.';
      case 409:
        return `Conflict: ${errorMsg || 'This document may already exist.'}`;
      case 413:
        return 'File is too large. Maximum file size is 10MB.';
      case 422:
        return `Invalid data: ${errorMsg || 'Please check your input and try again.'}`;
      case 500:
        return 'Server error. Please try again later.';
      case 0:
        return 'Network error. Please check your connection and try again.';
      default:
        return errorMsg || `Error (${status}). Please try again.`;
    }
  }

  buildDocumentFileUrl(raw: string | undefined | null): string {
    if (!raw) return '';
    const token = this.authService.getToken();
    const hasProtocol = /^https?:\/\//i.test(raw);
    let url = raw.trim();

    if (hasProtocol) {
      if (token && !/[?&]token=/.test(url)) {
        const sep = url.includes('?') ? '&' : '?';
        url = `${url}${sep}token=${encodeURIComponent(token)}`;
      }
      return url;
    }

    url = url.replace(/^\.\//, '');
    url = url.startsWith('/') ? url.substring(1) : url;

    let full = `${environment.apiBaseUrl.replace(/\/+$/, '')}/${url}`;
    if (token && !/[?&]token=/.test(full)) {
      const sep = full.includes('?') ? '&' : '?';
      full = `${full}${sep}token=${encodeURIComponent(token)}`;
    }
    return full;
  }

  getDocumentsByCategory(
    driverId: number,
    category: string,
  ): Observable<ApiResponse<DriverDocument[]>> {
    const url = `${this.documentUrl}?driverId=${driverId}&category=${encodeURIComponent(category)}`;
    return this.http.get<ApiResponse<DriverDocument[]>>(url, { headers: this.getHeaders() }).pipe(
      tap((res) =>
        console.log(
          `[DriverDocumentService] Documents for driver ${driverId}, category ${category}:`,
          res,
        ),
      ),
      catchError((error) => this.handleError('Fetching driver documents by category', error)),
    );
  }

  addDocument(
    driverId: number,
    doc: Partial<DriverDocument>,
  ): Observable<ApiResponse<DriverDocument>> {
    const payload = { ...doc, driverId };
    return this.http
      .post<ApiResponse<DriverDocument>>(this.documentUrl, payload, { headers: this.getHeaders() })
      .pipe(
        tap((res) => this.showToast('Document added')),
        catchError((error) => this.handleError('Adding driver document', error)),
      );
  }

  updateDocument(
    docId: number,
    doc: Partial<DriverDocument>,
  ): Observable<ApiResponse<DriverDocument>> {
    const url = `${this.documentUrl}/${docId}`;
    return this.http
      .put<ApiResponse<DriverDocument>>(url, doc, { headers: this.getHeaders() })
      .pipe(
        tap((res) => this.showToast('Document updated')),
        catchError((error) => this.handleError('Updating driver document', error)),
      );
  }

  deleteDocument(docId: number): Observable<ApiResponse<string>> {
    const url = `${this.documentUrl}/${docId}`;
    return this.http.delete<ApiResponse<string>>(url, { headers: this.getHeaders() }).pipe(
      tap((res) => this.showToast('Document deleted')),
      catchError((error) => this.handleError('Deleting driver document', error)),
    );
  }

  getDriverDocuments(driverId: number): Observable<ApiResponse<DriverDocument[]>> {
    const url = `${this.driverApiUrl}/${driverId}/documents`;
    return this.http
      .get<ApiResponse<DriverDocument[]>>(url, {
        headers: this.getHeaders(),
        observe: 'body',
        responseType: 'json',
      })
      .pipe(
        tap((response) => console.log(`📄 Documents response for driver ${driverId}:`, response)),
        catchError((error) => {
          console.error('❌ Error fetching driver documents:', error);
          return this.handleError('Fetching driver documents', error);
        }),
      );
  }

  uploadDriverDocument(
    driverId: number,
    file: File,
    options: {
      documentType?: string;
      name?: string;
      category?: string;
      description?: string;
      expiryDate?: string;
      isRequired?: boolean;
    },
  ): Observable<ApiResponse<DriverDocument>> {
    return this.uploadDriverDocumentWithProgress(driverId, file, options).pipe(
      filter((event) => event.type === HttpEventType.Response),
      map((event) => event.body as ApiResponse<DriverDocument>),
    );
  }

  uploadDriverDocumentWithProgress(
    driverId: number,
    file: File,
    options: {
      documentType?: string;
      name?: string;
      category?: string;
      description?: string;
      expiryDate?: string;
      isRequired?: boolean;
    },
  ): Observable<HttpEvent<ApiResponse<DriverDocument>>> {
    const formData = new FormData();
    formData.append('file', file);

    if (options.documentType) formData.append('documentType', options.documentType);
    if (options.name) formData.append('name', options.name);
    if (options.category) formData.append('category', options.category);
    if (options.description) formData.append('description', options.description);
    if (options.expiryDate) formData.append('expiryDate', options.expiryDate);
    if (options.isRequired !== undefined) formData.append('isRequired', String(options.isRequired));

    const url = `${this.driverApiUrl}/${driverId}/documents/upload`;
    return this.http
      .post<ApiResponse<DriverDocument>>(url, formData, {
        headers: this.getUploadHeaders(),
        reportProgress: true,
        observe: 'events',
      })
      .pipe(
        tap((event) => {
          if (event.type === HttpEventType.Response) {
            this.showToast('Document uploaded successfully!');
            console.log('📎 Document uploaded:', event.body);
          }
        }),
        catchError((error) => this.handleError('Uploading driver document', error)),
      );
  }

  deleteDriverDocument(driverId: number, documentId: number): Observable<ApiResponse<string>> {
    const url = `${this.driverApiUrl}/${driverId}/documents/${documentId}`;
    return this.http.delete<ApiResponse<string>>(url, { headers: this.getHeaders() }).pipe(
      tap(() => this.showToast('Document deleted successfully')),
      catchError((error) => this.handleError('Deleting document', error)),
    );
  }

  downloadDriverDocument(driverId: number, documentId: number): Observable<Blob> {
    const url = `${this.driverApiUrl}/${driverId}/documents/${documentId}/download`;
    return this.http
      .get(url, {
        headers: this.getHeaders(),
        responseType: 'blob',
      })
      .pipe(
        tap(() => console.log(`📥 Downloading document ${documentId} for driver ${driverId}`)),
        catchError((error) => this.handleError('Downloading document', error)),
      );
  }

  downloadDriverDocumentUrl(driverId: number, documentId: number): Observable<string> {
    return this.downloadDriverDocument(driverId, documentId).pipe(
      map((blob: Blob) => URL.createObjectURL(blob)),
      tap((objectUrl: string) =>
        console.log(`🔗 Object URL created for document ${documentId}:`, objectUrl),
      ),
      catchError((err) => this.handleError('Creating object URL for document', err)),
    );
  }

  addDriverDocument(document: DriverDocument): Observable<ApiResponse<DriverDocument>> {
    const url = `${this.driverApiUrl}/${document.driverId}/documents`;
    return this.http
      .post<ApiResponse<DriverDocument>>(url, document, { headers: this.getHeaders() })
      .pipe(
        tap((res) => {
          this.showToast('📄 Document added successfully');
          console.log('📄 Document added:', res);
        }),
        catchError((error) => this.handleError('Adding driver document', error)),
      );
  }

  updateDriverDocument(
    driverId: number,
    documentId: number,
    updateDto: {
      name: string;
      category: string;
      expiryDate?: string;
      description?: string;
      isRequired?: boolean;
    },
  ): Observable<ApiResponse<DriverDocument>> {
    const url = `${this.driverApiUrl}/${driverId}/documents/${documentId}`;
    return this.http
      .put<ApiResponse<DriverDocument>>(url, updateDto, { headers: this.getHeaders() })
      .pipe(
        tap((res) => {
          this.showToast('📝 Document updated successfully');
          console.log('📝 Document updated:', res);
        }),
        catchError((error) => this.handleError('Updating driver document', error)),
      );
  }

  updateDriverDocumentFile(
    driverId: number,
    documentId: number,
    file: File,
    metadata: {
      name: string;
      category: string;
      expiryDate?: string;
      description?: string;
      isRequired?: boolean;
    },
  ): Observable<ApiResponse<DriverDocument>> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('name', metadata.name);
    formData.append('category', metadata.category);
    if (metadata.expiryDate) {
      formData.append('expiryDate', metadata.expiryDate);
    }
    if (metadata.description) {
      formData.append('description', metadata.description);
    }
    formData.append('isRequired', String(metadata.isRequired ?? false));

    const url = `${this.driverApiUrl}/${driverId}/documents/${documentId}/file`;
    return this.http
      .put<ApiResponse<DriverDocument>>(url, formData, { headers: this.getUploadHeaders() })
      .pipe(
        tap((res) => {
          this.showToast('📝 Document file updated successfully');
          console.log('📝 Document file updated:', res);
        }),
        catchError((error) => this.handleError('Updating driver document file', error)),
      );
  }
}
