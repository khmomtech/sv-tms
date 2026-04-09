// ... existing imports
import { HttpClient, HttpEvent, HttpEventType } from '@angular/common/http';
import { HttpHeaders, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import type { Observable } from 'rxjs';
import { catchError, throwError, tap, of, map, filter } from 'rxjs';

import { environment } from '../environments/environment';
import type { PagedResponse } from '../models/api-response-page.model';
import type { DriverDocument } from '../models/driver-document.model';
import type { DriverLicense } from '../models/driver-license.model';
import type { Driver, DriverCreateDto } from '../models/driver.model';
import { mapToDriverCreateDto } from '../models/driver.model';
import type { Vehicle } from '../models/vehicle.model';

import type { ApiResponse } from './../models/api-response.model';
import { AuthService } from './auth.service';

export interface DriverExistencePayload {
  phone: string;
}

export interface DriverFilter {
  query?: string;
  isActive?: boolean;
  minRating?: number;
  maxRating?: number;
  zone?: string;
  vehicleType?: string;
  status?: string;
  isPartner?: boolean;
}

export interface DriverAccount {
  id: number;
  username: string;
  email: string;
  enabled: boolean;
  roles: string[];
  driverId: number | null;
}

export interface DriverGroup {
  id: number;
  name: string;
  code?: string;
  description?: string;
  active?: boolean;
}

export interface DriverLifecycleActionPayload {
  action: 'Suspend' | 'Exit';
  reason?: string;
}

export interface DriverIdCardPayload {
  idCardNumber?: string | null;
  idCardIssuedDate?: string | null;
  idCardExpiry?: string | null;
}

export interface DriverIdCardRecord {
  driverId: number;
  idCardNumber?: string | null;
  issuedDate?: string | null;
  expiryDate?: string | null;
  status?: string | null;
}

@Injectable({ providedIn: 'root' })
export class DriverService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/drivers`;
  private readonly assignmentApiUrl = `${environment.apiBaseUrl}/admin/assignments/permanent`;
  private readonly licenseUrl = `${environment.apiBaseUrl}/admin/driver-licenses`;

  private readonly http = inject(HttpClient);
  private readonly authService = inject(AuthService);
  private readonly snackBar = inject(MatSnackBar);

  // ===== HTTP CONFIGURATION METHODS =====

  /**
   * Get standardized HTTP headers with authentication
   */
  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    });
  }

  /**
   * Get headers for file upload (FormData) requests
   */
  private getUploadHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      // Note: Content-Type is omitted for FormData
    });
  }

  /**
   * Build a full file URL for driver document preview/download.
   * Handles:
   *  - Absolute URLs (http/https) -> returned unchanged (token appended if missing)
   *  - Relative URLs with or without leading slash
   *  - Ensures /api base prefix when backend serves from /api
   *  - Appends JWT token as query param (backend supports token=? pattern) when Authorization header not usable (e.g. iframe/img)
   */
  buildDocumentFileUrl(raw: string | undefined | null): string {
    if (!raw) return '';
    const token = this.authService.getToken();
    const hasProtocol = /^https?:\/\//i.test(raw);
    let url = raw.trim();

    // If already absolute, just append token if not present
    if (hasProtocol) {
      if (token && !/[?&]token=/.test(url)) {
        const sep = url.includes('?') ? '&' : '?';
        url = `${url}${sep}token=${encodeURIComponent(token)}`;
      }
      return url;
    }

    // Remove any leading "./" and normalize leading slash
    url = url.replace(/^\.\//, '');
    url = url.startsWith('/') ? url.substring(1) : url;

    // Construct relative URL against apiBaseUrl without duplicating slashes.
    // NOTE: Passing JWT as query param can leak via referrer logs; consider migrating to short-lived signed URLs.
    let full = `${environment.apiBaseUrl.replace(/\/+$/, '')}/${url}`;
    // Append token for direct resource access (images, pdf, etc.)
    if (token && !/[?&]token=/.test(full)) {
      const sep = full.includes('?') ? '&' : '?';
      full = `${full}${sep}token=${encodeURIComponent(token)}`;
    }
    return full;
  }

  /**
   * Build filter parameters for driver list endpoints
   */
  private buildFilterParams(filters?: DriverFilter): HttpParams {
    let params = new HttpParams();
    if (!filters) return params;
    if (filters.query) params = params.set('query', filters.query);
    if (filters.status && filters.status !== 'all') params = params.set('status', filters.status);
    if (filters.vehicleType && filters.vehicleType !== 'all')
      params = params.set('vehicleType', filters.vehicleType);
    if (filters.zone) params = params.set('zone', filters.zone);
    if (filters.isActive !== undefined) params = params.set('isActive', String(filters.isActive));
    if (filters.isPartner !== undefined)
      params = params.set('isPartner', String(filters.isPartner));
    if (filters.minRating !== undefined)
      params = params.set('minRating', String(filters.minRating));
    if (filters.maxRating !== undefined)
      params = params.set('maxRating', String(filters.maxRating));
    return params;
  }

  /**
   * Handle HTTP errors with user-friendly messages
   */
  private handleError(operation: string, error: any): Observable<never> {
    const message = this.getDetailedErrorMessage(error);
    this.showToast(`${operation} failed: ${message}`);
    console.error(`DriverService ${operation} error:`, { status: error.status, error });
    return throwError(() => error);
  }

  /**
   * Show toast notification
   */
  showToast(message: string, action = 'Close', duration = 3000): void {
    this.snackBar.open(message, action, {
      duration,
      horizontalPosition: 'right',
      verticalPosition: 'top',
    });
  }

  /**
   * Extract detailed error message from HTTP error response
   * Maps HTTP status codes to user-friendly messages
   */
  private getDetailedErrorMessage(error: any): string {
    if (!error) {
      return 'An unexpected error occurred. Please try again.';
    }

    const status = error.status || error.statusCode || 0;
    const errorMsg = error.error?.message || error.message || '';
    const requestId =
      error.error?.requestId ||
      (typeof error.headers?.get === 'function' ? error.headers.get('X-Request-ID') : undefined);

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
        return requestId
          ? `${errorMsg || 'Server error. Please try again later.'} (Request ID: ${requestId})`
          : errorMsg || 'Server error. Please try again later.';
      case 0:
        return 'Network error. Please check your connection and try again.';
      default:
        return requestId
          ? `${errorMsg || `Error (${status}). Please try again.`} (Request ID: ${requestId})`
          : errorMsg || `Error (${status}). Please try again.`;
    }
  }

  /**
   * Check if a phone number already exists in the driver directory.
   */
  checkDriverExists(phone: string): Observable<boolean> {
    const trimmedPhone = phone?.trim() ?? '';
    if (!trimmedPhone) {
      return of(false);
    }
    const params = new HttpParams().set('phone', trimmedPhone);
    return this.http
      .get<ApiResponse<boolean>>(`${this.apiUrl}/exists`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(map((res) => res.data));
  }

  updateDriverLifecycleStatus(
    driverId: number,
    payload: DriverLifecycleActionPayload,
  ): Observable<ApiResponse<Driver>> {
    return this.http.post<ApiResponse<Driver>>(`${this.apiUrl}/${driverId}/lifecycle`, payload, {
      headers: this.getHeaders(),
    });
  }

  // ===== DRIVER CRUD OPERATIONS =====

  /**
   * Get all drivers with optional filtering and pagination
   * @param filters Optional filter criteria for drivers
   * @returns Observable of paginated driver list
   */
  getAllDrivers(filters?: DriverFilter): Observable<ApiResponse<PagedResponse<Driver>>> {
    let params = this.buildFilterParams(filters);
    // Ensure page and size parameters are always included for pagination
    if (!params.has('page')) {
      params = params.set('page', '0');
    }
    if (!params.has('size')) {
      params = params.set('size', '10');
    }

    return this.http
      .get<ApiResponse<PagedResponse<Driver>>>(`${this.apiUrl}/alllists`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(
        tap((res) => console.log(' All Drivers (Filtered):', res)),
        catchError((error) => this.handleError('Fetching drivers', error)),
      );
  }

  /**
   * Get all drivers for modal selection (unpaginated)
   * @param filters Optional filter criteria
   * @returns Observable of driver array
   */
  getAllDriversModal(filters?: DriverFilter): Observable<ApiResponse<Driver[]>> {
    const params = this.buildFilterParams(filters);
    // Use the /all endpoint for unpaginated results
    return this.http
      .get<ApiResponse<Driver[]>>(`${this.apiUrl}/all`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(
        tap((res) => console.log(' All Drivers (Modal):', res)),
        catchError((error) => this.handleError('Fetching drivers for modal', error)),
      );
  }

  /**
   * Get paginated list of drivers (alias for getAllDrivers)
   * @param page Page number (0-based)
   * @param size Page size
   * @returns Observable of paginated drivers with proper PageResponse structure
   */
  getDrivers(page: number, size: number): Observable<ApiResponse<PagedResponse<any>>> {
    const url = `${this.apiUrl}/alllists?page=${page}&size=${size}`;
    return this.http.get<ApiResponse<PagedResponse<any>>>(url, { headers: this.getHeaders() }).pipe(
      tap((res) => console.log('📋 Paginated Drivers:', res)),
      catchError((error) => this.handleError('Fetching paginated drivers', error)),
    );
  }

  /**
   * Get drivers with advanced filtering
   * @param page Page number (0-based)
   * @param size Page size
   * @param filters Driver filter criteria
   * @returns Observable of filtered drivers
   */
  // Flexible signature: can be called as (page, size, filters) or (filters)
  getAdvancedDrivers(
    pageOrFilters?: number | DriverFilter,
    size?: number | DriverFilter,
    maybeFilters?: DriverFilter,
  ): Observable<ApiResponse<any>> {
    let page = 0;
    let pageSize = 10;
    let filters: DriverFilter = {};

    if (typeof pageOrFilters === 'number') {
      page = pageOrFilters;
      pageSize = typeof size === 'number' ? (size as number) : 10;
      filters = (maybeFilters as DriverFilter) || {};
    } else if (pageOrFilters && typeof pageOrFilters === 'object') {
      filters = pageOrFilters as DriverFilter;
    }

    const url = `${this.apiUrl}/advanced-search`;

    // If called with a single filters object (no pagination), use GET with params
    if (
      pageOrFilters &&
      typeof pageOrFilters === 'object' &&
      typeof pageOrFilters !== 'number' &&
      !maybeFilters &&
      !size
    ) {
      const params = this.buildFilterParams(filters || {});
      return this.http.get<ApiResponse<any>>(url, { params, headers: this.getHeaders() }).pipe(
        tap((res) => console.log(' Advanced Filtered Drivers (GET):', res)),
        catchError((error) => this.handleError('Fetching filtered drivers', error)),
      );
    }

    return this.http
      .post<ApiResponse<any>>(`${url}?page=${page}&size=${pageSize}`, filters, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => console.log(' Advanced Filtered Drivers:', res)),
        catchError((error) => this.handleError('Fetching filtered drivers', error)),
      );
  }

  /**
   * Search drivers by query string
   * @param searchTerm Search query
   * @returns Observable of driver array
   */
  searchDrivers(searchTerm: string): Observable<ApiResponse<Driver[]>> {
    const url = `${this.apiUrl}/search`;
    const params = new HttpParams().set('query', searchTerm);
    return this.http.get<ApiResponse<Driver[]>>(url, { headers: this.getHeaders(), params }).pipe(
      tap((res) => console.log(' Search Results:', res)),
      catchError((error) => this.handleError('Searching drivers', error)),
    );
  }

  /**
   * Get driver by ID
   * @param id Driver ID
   * @returns Observable of single driver
   */
  getDriverById(id: number): Observable<ApiResponse<Driver>> {
    return this.http
      .get<ApiResponse<Driver>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => console.log(` Driver [${id}]`, res)),
        catchError((error) => this.handleError(`Fetching driver ${id}`, error)),
      );
  }

  /**
   * Create a new driver
   * @param input Driver data (partial or create DTO)
   * @returns Observable of created driver
   */
  addDriver(input: Partial<Driver> | DriverCreateDto): Observable<ApiResponse<Driver>> {
    const payload: DriverCreateDto = mapToDriverCreateDto(input as any);
    return this.http
      .post<ApiResponse<Driver>>(`${this.apiUrl}/add`, payload, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => {
          this.showToast('Driver added successfully!');
          console.log(' Driver added:', res);
        }),
        catchError((error) => this.handleError('Adding driver', error)),
      );
  }

  /**
   * Update an existing driver
   * @param id Driver ID
   * @param driver Updated driver data
   * @returns Observable of updated driver
   */
  updateDriver(id: number, driver: Partial<Driver>): Observable<ApiResponse<Driver>> {
    const payload: any = { ...driver };
    // do not send `id` in body; it's provided in the URL path
    if ('id' in payload) {
      delete payload.id;
    }

    return this.http
      .put<ApiResponse<Driver>>(`${this.apiUrl}/update/${id}`, payload, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => {
          this.showToast('Driver updated successfully!');
          console.log(' Driver updated:', res);
        }),
        catchError((error) => this.handleError('Updating driver', error)),
      );
  }

  getDriverIdCard(id: number): Observable<ApiResponse<DriverIdCardRecord>> {
    return this.http
      .get<ApiResponse<DriverIdCardRecord>>(`${this.apiUrl}/${id}/id-card`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError((error) => this.handleError('Fetching driver ID card', error)));
  }

  createDriverIdCard(
    id: number,
    payload: DriverIdCardPayload,
  ): Observable<ApiResponse<DriverIdCardRecord>> {
    return this.http
      .post<ApiResponse<DriverIdCardRecord>>(`${this.apiUrl}/${id}/id-card`, payload, {
        headers: this.getHeaders(),
      })
      .pipe(catchError((error) => this.handleError('Creating driver ID card', error)));
  }

  updateDriverIdCard(
    id: number,
    payload: DriverIdCardPayload,
  ): Observable<ApiResponse<DriverIdCardRecord>> {
    return this.http
      .put<ApiResponse<DriverIdCardRecord>>(`${this.apiUrl}/${id}/id-card`, payload, {
        headers: this.getHeaders(),
      })
      .pipe(catchError((error) => this.handleError('Updating driver ID card', error)));
  }

  deleteDriverIdCard(id: number): Observable<ApiResponse<string>> {
    return this.http
      .delete<ApiResponse<string>>(`${this.apiUrl}/${id}/id-card`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError((error) => this.handleError('Deleting driver ID card', error)));
  }

  /**
   * Upload or replace driver profile picture
   * @param driverId Driver ID
   * @param file Image file
   */
  uploadDriverProfilePicture(driverId: number, file: File): Observable<ApiResponse<string>> {
    const formData = new FormData();
    formData.append('profilePicture', file);

    return this.http
      .post<ApiResponse<string>>(`${this.apiUrl}/${driverId}/upload-profile`, formData, {
        headers: this.getUploadHeaders(),
      })
      .pipe(
        tap((res) => {
          this.showToast(' Profile photo updated');
          console.log(' Profile photo uploaded:', res);
        }),
        catchError((error) => this.handleError('Uploading profile photo', error)),
      );
  }

  /**
   * Fetch active driver groups
   */
  getDriverGroups(): Observable<ApiResponse<DriverGroup[]>> {
    return this.http
      .get<ApiResponse<DriverGroup[]>>(`${environment.apiBaseUrl}/admin/driver-groups`, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => console.log(' Driver groups:', res)),
        catchError((error) => this.handleError('Fetching driver groups', error)),
      );
  }

  createDriverGroup(payload: Partial<DriverGroup>): Observable<ApiResponse<DriverGroup>> {
    return this.http
      .post<ApiResponse<DriverGroup>>(`${environment.apiBaseUrl}/admin/driver-groups`, payload, {
        headers: this.getHeaders(),
      })
      .pipe(catchError((error) => this.handleError('Creating driver group', error)));
  }

  updateDriverGroup(
    id: number,
    payload: Partial<DriverGroup>,
  ): Observable<ApiResponse<DriverGroup>> {
    return this.http
      .put<ApiResponse<DriverGroup>>(
        `${environment.apiBaseUrl}/admin/driver-groups/${id}`,
        payload,
        {
          headers: this.getHeaders(),
        },
      )
      .pipe(catchError((error) => this.handleError('Updating driver group', error)));
  }

  deleteDriverGroup(id: number): Observable<ApiResponse<string>> {
    return this.http
      .delete<ApiResponse<string>>(`${environment.apiBaseUrl}/admin/driver-groups/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError((error) => this.handleError('Deleting driver group', error)));
  }

  /**
   * Delete a driver
   * @param id Driver ID
   * @returns Observable of deletion result
   */
  deleteDriver(id: number): Observable<ApiResponse<string>> {
    return this.http
      .delete<ApiResponse<string>>(`${this.apiUrl}/delete/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => {
          this.showToast('Driver deleted successfully!');
          console.log(' Driver deleted:', res);
        }),
        catchError((error) => this.handleError('Deleting driver', error)),
      );
  }

  // ===== DRIVER ACCOUNT MANAGEMENT =====

  /**
   * Create driver account and associate with driver
   * @param user Account data
   * @param driverId Driver ID to associate
   * @returns Observable of account creation result
   */
  addDriverAccount(user: any, driverId: number): Observable<ApiResponse<any>> {
    if (!Array.isArray(user.roles)) user.roles = ['DRIVER'];
    return this.http
      .post<ApiResponse<any>>(
        `${this.licenseUrl}/users/registerdriver?driverId=${driverId}`,
        user,
        {
          headers: this.getHeaders(),
        },
      )
      .pipe(
        tap((res) => {
          this.showToast('Driver account created successfully!');
          console.log(' Driver account created:', res);
        }),
        catchError((error) => this.handleError('Creating driver account', error)),
      );
  }

  /**
   * Get driver login account by driver ID
   * @param driverId Driver ID
   * @returns Observable of driver account or null
   */
  getDriverAccountById(driverId: number): Observable<DriverAccount | null> {
    const url = `${environment.apiBaseUrl}/admin/users/driver-account/${driverId}`;
    return this.http
      .get<DriverAccount>(url, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => {
          console.log('👤 Driver login account loaded:', res);
        }),
        catchError((error) => {
          if (error.status === 404 || error.status === 403) {
            console.warn('[DriverService] Login account fetch returned', error.status);
            return of(null);
          }
          return this.handleError('Fetching driver account', error);
        }),
      );
  }

  /**
   * Save or update login account for driver
   * @param driverId Driver ID
   * @param account Account data
   * @returns Observable of account update result
   */
  saveDriverAccount(
    driverId: number,
    account: { username: string; email: string; password?: string; enabled?: boolean },
  ): Observable<ApiResponse<any>> {
    const url = `${environment.apiBaseUrl}/admin/users/registerdriver?driverId=${driverId}`;
    const body = {
      ...account,
      roles: ['DRIVER'],
    };
    return this.http
      .post<ApiResponse<any>>(url, body, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => {
          this.showToast('Login account saved');
          console.log('Login saved:', res);
        }),
        catchError((error) => this.handleError('Saving driver account', error)),
      );
  }

  /**
   * Delete driver login account
   * @param driverId Driver ID
   * @returns Observable of deletion result
   */
  deleteDriverAccount(driverId: number): Observable<ApiResponse<any>> {
    const url = `${environment.apiBaseUrl}/admin/users/driver-account/${driverId}`;
    return this.http
      .delete<ApiResponse<any>>(url, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap(() => this.showToast(' Login account deleted')),
        catchError((error) => this.handleError('Deleting driver account', error)),
      );
  }
  /**  Get all documents for a driver */
  // ===== DRIVER LICENSE MANAGEMENT =====

  /**
   * Get driver license by driver ID
   * @param driverId Driver ID
   * @returns Observable of driver license
   */
  getDriverLicense(driverId: number): Observable<ApiResponse<DriverLicense>> {
    // Build URL and append JWT as query param when available. This provides a
    // fallback authentication mechanism for contexts where Authorization headers
    // may not be propagated (e.g. certain generated clients or iframe/img loads).
    let url = `${this.licenseUrl}/${driverId}`;
    const token = this.authService.getToken();
    if (token) {
      const sep = url.includes('?') ? '&' : '?';
      url = `${url}${sep}token=${encodeURIComponent(token)}`;
    }

    return this.http.get<ApiResponse<DriverLicense>>(url, { headers: this.getHeaders() }).pipe(
      tap((res) => console.log('📄 License Fetched:', res)),
      catchError((error) => {
        // If license not found, return a null payload so callers can handle absence gracefully
        if (error && error.status === 404) {
          console.warn(`[DriverService] License for driver ${driverId} not found (404)`);
          const notFound: ApiResponse<DriverLicense> = {
            success: false,
            message: 'Driver license not found',
            data: null as any,
          };
          return of(notFound);
        }
        return this.handleError('Fetching driver license', error);
      }),
    );
  }

  /**
   * Add new driver license
   * @param driverId Driver ID
   * @param license License data
   * @returns Observable of created license
   */
  addDriverLicense(
    driverId: number,
    license: DriverLicense,
  ): Observable<ApiResponse<DriverLicense>> {
    const url = `${this.licenseUrl}/${driverId}`;
    return this.http
      .post<ApiResponse<DriverLicense>>(url, license, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => {
          this.showToast(' Driver license added');
          console.log(' License added:', res);
        }),
        catchError((error) => this.handleError('Adding driver license', error)),
      );
  }

  /**
   * Update existing driver license
   * @param driverId Driver ID
   * @param license Updated license data
   * @returns Observable of updated license
   */
  updateDriverLicense(
    driverId: number,
    license: DriverLicense,
  ): Observable<ApiResponse<DriverLicense>> {
    const url = `${this.licenseUrl}/${driverId}`;
    return this.http
      .put<ApiResponse<DriverLicense>>(url, license, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => {
          this.showToast('📝 Driver license updated');
          console.log('📝 License updated:', res);
        }),
        catchError((error) => this.handleError('Updating driver license', error)),
      );
  }

  /**
   * Delete driver license
   * @param driverId Driver ID
   * @returns Observable of deletion result
   */
  deleteDriverLicense(driverId: number): Observable<ApiResponse<string>> {
    const url = `${this.licenseUrl}/by-id/${driverId}`;
    return this.http.delete<ApiResponse<string>>(url, { headers: this.getHeaders() }).pipe(
      tap((res) => {
        this.showToast('Driver license deleted');
        console.log('🗑️ License deleted:', res);
      }),
      catchError((error) => this.handleError('Deleting driver license', error)),
    );
  }

  /**
   * Upload license image
   * @param driverId Driver ID
   * @param file Image file
   * @param field Image field (front or back)
   * @returns Observable of upload result
   */
  uploadLicenseImage(
    driverId: number,
    file: File,
    field: 'licenseFrontImage' | 'licenseBackImage',
  ): Observable<ApiResponse<string>> {
    const formData = new FormData();
    formData.append('file', file);

    const endpoint =
      field === 'licenseFrontImage'
        ? `${this.licenseUrl}/${driverId}/upload-front`
        : `${this.licenseUrl}/${driverId}/upload-back`;

    return this.http
      .post<ApiResponse<string>>(endpoint, formData, {
        headers: this.getUploadHeaders(),
      })
      .pipe(
        tap((res) => {
          this.showToast(`${field === 'licenseFrontImage' ? 'Front' : 'Back'} image uploaded.`);
          console.log(` Upload success [${field}]:`, res);
        }),
        catchError((error) => this.handleError(`Uploading ${field}`, error)),
      );
  }

  /**
   * Get all documents for a driver
   * @param driverId Driver ID
   * @returns Observable of driver documents array
   */
  getDriverDocuments(driverId: number): Observable<ApiResponse<DriverDocument[]>> {
    const url = `${this.apiUrl}/${driverId}/documents`;
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

  /**
   * Upload a document for a driver
   * @param driverId Driver ID
   * @param file Document file to upload
   * @param documentType Type of document
   * @param description Optional document description
   * @returns Observable of upload result
   */
  // Consolidated upload method with overloads for backward compatibility
  uploadDriverDocument(
    driverId: number,
    file: File,
    documentType: string,
    description?: string,
  ): Observable<ApiResponse<DriverDocument>>;
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
  ): Observable<ApiResponse<DriverDocument>>;
  uploadDriverDocument(
    driverId: number,
    file: File,
    third:
      | string
      | {
          documentType?: string;
          name?: string;
          category?: string;
          description?: string;
          expiryDate?: string;
          isRequired?: boolean;
        },
    description?: string,
  ): Observable<ApiResponse<DriverDocument>> {
    return this.uploadDriverDocumentWithProgress(driverId, file, third, description).pipe(
      filter((event) => event.type === HttpEventType.Response),
      map((event) => event.body as ApiResponse<DriverDocument>),
    );
  }

  /**
   * Upload driver document with progress events (used by upload modal)
   */
  uploadDriverDocumentWithProgress(
    driverId: number,
    file: File,
    third:
      | string
      | {
          documentType?: string;
          name?: string;
          category?: string;
          description?: string;
          expiryDate?: string;
          isRequired?: boolean;
        },
    description?: string,
  ): Observable<HttpEvent<ApiResponse<DriverDocument>>> {
    const formData = new FormData();
    formData.append('file', file);

    const opts = typeof third === 'string' ? { documentType: third, description } : third;
    if (opts.documentType) formData.append('documentType', opts.documentType);
    if (opts.name) formData.append('name', opts.name);
    if (opts.category) formData.append('category', opts.category);
    if (opts.description) formData.append('description', opts.description);
    if (opts.expiryDate) formData.append('expiryDate', opts.expiryDate);
    if (opts.isRequired !== undefined) formData.append('isRequired', String(opts.isRequired));

    const url = `${this.apiUrl}/${driverId}/documents/upload`;
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

  // Removed legacy single-parameter delete; now requires driverId + documentId
  deleteDriverDocument(driverId: number, documentId: number): Observable<ApiResponse<string>> {
    const url = `${this.apiUrl}/${driverId}/documents/${documentId}`;
    return this.http.delete<ApiResponse<string>>(url, { headers: this.getHeaders() }).pipe(
      tap(() => this.showToast('Document deleted successfully')),
      catchError((error) => this.handleError('Deleting document', error)),
    );
  } /**
   * Download a driver document
   * @param driverId Driver ID
   * @param documentId Document ID to download
   * @returns Observable of blob for download
   */
  downloadDriverDocument(driverId: number, documentId: number): Observable<Blob> {
    const url = `${this.apiUrl}/${driverId}/documents/${documentId}/download`;
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

  /**
   * Convenience method: download as object URL (maps Blob -> object URL string)
   */
  downloadDriverDocumentUrl(driverId: number, documentId: number): Observable<string> {
    return this.downloadDriverDocument(driverId, documentId).pipe(
      map((blob: Blob) => URL.createObjectURL(blob)),
      tap((objectUrl: string) =>
        console.log(`🔗 Object URL created for document ${documentId}:`, objectUrl),
      ),
      catchError((err) => this.handleError('Creating object URL for document', err)),
    );
  }

  /**
   * Upload document file (legacy method)
   * @param driverId Driver ID
   * @param file Document file
   * @param category Document category
   * @returns Observable of upload result
   */
  uploadDocument(
    driverId: number,
    file: File,
    category: string,
  ): Observable<ApiResponse<DriverDocument>> {
    // DEPRECATED: Prefer using uploadDriverDocument(driverId, file, { category, ... })
    return this.uploadDriverDocument(driverId, file, { category });
  }

  /**
   * Upload document with file and metadata
   * @param driverId Driver ID
   * @param file Document file
   * @param name Document name
   * @param category Document category
   * @param expiryDate Optional expiry date
   * @param description Optional description
   * @param isRequired Whether document is required
   * @returns Observable of upload result
   */
  // Removed old uploadDocumentWithFile in favor of consolidated uploadDriverDocument overload.

  /**
   * Add new document for driver (metadata only)
   * @param document Document data
   * @returns Observable of created document
   */
  addDriverDocument(document: DriverDocument): Observable<ApiResponse<DriverDocument>> {
    const url = `${this.apiUrl}/${document.driverId}/documents`;
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

  /**
   * Update existing driver document
   * @param driverId Driver ID
   * @param documentId Document ID
   * @param updateDto Updated document data (name, category, expiryDate, description, isRequired)
   * @returns Observable of updated document
   */
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
    const url = `${this.apiUrl}/${driverId}/documents/${documentId}`;
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

  /**
   * Update driver document with file replacement (preserves document ID)
   * @param driverId Driver ID
   * @param documentId Document ID to update
   * @param file New file to replace the existing document file
   * @param metadata Updated document metadata
   * @returns Observable of updated document
   */
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

    const url = `${this.apiUrl}/${driverId}/documents/${documentId}/file`;
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

  // ===== VEHICLE MANAGEMENT =====

  /**
   * Get all vehicles
   * @returns Observable of all vehicles
   */
  getAllVehicles(): Observable<ApiResponse<Vehicle[]>> {
    const url = `/api/admin/vehicles/all`;
    return this.http
      .get<ApiResponse<Vehicle[]>>(url, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => console.log(' All Vehicles:', res)),
        catchError((error) => this.handleError('Loading vehicles', error)),
      );
  }

  /**
   * Get vehicles assigned to a specific driver
   * @param driverId Driver ID
   * @returns Observable of driver vehicles
   */
  getVehiclesByDriverId(driverId: number): Observable<ApiResponse<Vehicle[]>> {
    const url = `/api/admin/drivers/by-driver/${driverId}`;
    return this.http
      .get<ApiResponse<Vehicle[]>>(url, {
        headers: this.getHeaders(),
      })
      .pipe(
        tap((res) => console.log(` Vehicles for Driver ${driverId}:`, res)),
        catchError((error) => this.handleError('Loading driver vehicles', error)),
      );
  }

  /**
   * Assign a driver to a vehicle
   * @param driverId Driver ID
   * @param vehicleId Vehicle ID
   * @returns Observable of assignment result
   */
  assignDriverToVehicle(driverId: number, vehicleId: number): Observable<ApiResponse<any>> {
    return this.http
      .post<ApiResponse<any>>(
        this.assignmentApiUrl,
        {
          driverId,
          vehicleId,
          reason: 'Assigned from driver detail/list',
          forceReassignment: true,
        },
        { headers: this.getHeaders() },
      )
      .pipe(
        tap((res) => {
          this.showToast('Driver assigned to vehicle.');
          console.log(' Assignment successful:', res);
        }),
        catchError((error) => this.handleError('Assigning driver to vehicle', error)),
      );
  }

  /**
   * Unassign a driver from their current vehicle
   * @param driverId Driver ID
   * @returns Observable of unassignment result
   */
  unassignDriver(driverId: number, reason?: string): Observable<ApiResponse<any>> {
    let params = new HttpParams();
    if (reason) {
      params = params.set('reason', reason);
    }
    return this.http
      .delete<ApiResponse<any>>(`${this.assignmentApiUrl}/${driverId}`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(
        tap((res) => {
          this.showToast('Driver unassigned successfully.');
          console.log('� Unassigned:', res);
        }),
        catchError((error) => this.handleError('Unassigning driver', error)),
      );
  }

  /**
   * Get attendance records for a driver
   * @param driverId Driver ID
   * @param year Year for attendance records
   * @param month Month for attendance records
   * @returns Observable of attendance records
   */
  getDriverAttendance(
    driverId: number,
    year: number,
    month: number,
  ): Observable<ApiResponse<any[]>> {
    const url = `${this.apiUrl}/${driverId}/attendance?year=${year}&month=${month}`;
    return this.http.get<ApiResponse<any[]>>(url, { headers: this.getHeaders() }).pipe(
      tap((res) => console.log('📅 Driver attendance loaded:', res)),
      catchError((error) => this.handleError('Loading attendance records', error)),
    );
  }

  /**
   * Get attendance summary for a driver
   * @param driverId Driver ID
   * @param year Year for summary
   * @param month Month for summary
   * @returns Observable of attendance summary
   */
  getDriverAttendanceSummary(
    driverId: number,
    year: number,
    month: number,
  ): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/${driverId}/attendance/summary?year=${year}&month=${month}`;
    return this.http.get<ApiResponse<any>>(url, { headers: this.getHeaders() }).pipe(
      tap((res) => console.log('📊 Attendance summary loaded:', res)),
      catchError((error) => this.handleError('Loading attendance summary', error)),
    );
  }

  /**
   * Get attendance record for a specific date
   * @param driverId Driver ID
   * @param date Date string in YYYY-MM-DD format
   * @returns Observable of attendance record or null
   */
  getDriverAttendanceByDate(driverId: number, date: string): Observable<ApiResponse<any | null>> {
    const url = `${this.apiUrl}/${driverId}/attendance/date/${date}`;
    return this.http.get<ApiResponse<any | null>>(url, { headers: this.getHeaders() }).pipe(
      catchError((error) => {
        if (error.status === 404) {
          return of({ data: null } as ApiResponse<any | null>);
        }
        return this.handleError('Loading attendance for date', error);
      }),
    );
  }

  /**
   * Add new attendance record
   * @param record Attendance record data
   * @returns Observable of creation result
   */
  addAttendanceRecord(record: any): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/${record.driverId}/attendance`;
    const { driverId, ...body } = record || {};
    return this.http.post<ApiResponse<any>>(url, body, { headers: this.getHeaders() }).pipe(
      tap((res) => {
        this.showToast('📅 Attendance record added');
        console.log('📅 Attendance added:', res);
      }),
      catchError((error) => this.handleError('Adding attendance record', error)),
    );
  }

  /**
   * Bulk create permission records across a date range (inclusive) for ON_LEAVE / OFF_DUTY.
   * record: { driverId, fromDate, toDate, status, notes }
   */
  addPermissionRange(record: {
    driverId: number;
    fromDate: string;
    toDate: string;
    status: string;
    notes?: string;
  }): Observable<ApiResponse<any[]>> {
    const url = `${this.apiUrl}/${record.driverId}/attendance/permission-range`;
    const { driverId, ...body } = record || {};
    return this.http.post<ApiResponse<any[]>>(url, body, { headers: this.getHeaders() }).pipe(
      tap((res) => {
        this.showToast('📅 Permission range added');
        console.log('📅 Permission range added:', res);
      }),
      catchError((error) => this.handleError('Adding permission range', error)),
    );
  }

  /**
   * Update attendance record
   * @param recordId Attendance record ID
   * @param record Updated attendance data
   * @returns Observable of update result
   */
  updateAttendanceRecord(recordId: number, record: any): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/attendance/${recordId}`;
    const { driverId, id, ...body } = record || {};
    return this.http.put<ApiResponse<any>>(url, body, { headers: this.getHeaders() }).pipe(
      tap((res) => {
        this.showToast('📝 Attendance record updated');
        console.log('📝 Attendance updated:', res);
      }),
      catchError((error) => this.handleError('Updating attendance record', error)),
    );
  }

  /**
   * Delete attendance record
   * @param recordId Attendance record ID
   * @returns Observable of deletion result
   */
  deleteAttendanceRecord(recordId: number): Observable<ApiResponse<string>> {
    const url = `${this.apiUrl}/attendance/${recordId}`;
    return this.http.delete<ApiResponse<string>>(url, { headers: this.getHeaders() }).pipe(
      tap((res) => {
        this.showToast('🗑️ Attendance record deleted');
        console.log('🗑️ Attendance deleted:', res);
      }),
      catchError((error) => this.handleError('Deleting attendance record', error)),
    );
  }

  /**
   * Get attendance records for a month (across all drivers or a specific driver if provided)
   * @param year Year for attendance records
   * @param month Month for attendance records
   * @param options Optional filters (permissionOnly, driverId)
   */
  getAttendanceByMonth(
    year?: number,
    month?: number,
    options?: {
      permissionOnly?: boolean;
      driverId?: number | null;
      page?: number;
      size?: number;
      fromDate?: string;
      toDate?: string;
    },
  ): Observable<ApiResponse<PagedResponse<any>>> {
    const qp: string[] = [
      ...(year ? [`year=${encodeURIComponent(String(year))}`] : []),
      ...(month ? [`month=${encodeURIComponent(String(month))}`] : []),
    ];
    if (options?.driverId) qp.push(`driverId=${encodeURIComponent(String(options.driverId))}`);
    const permissionOnly = options?.permissionOnly ?? true;
    qp.push(`permissionOnly=${permissionOnly}`);
    const page = options?.page ?? 0;
    const size = options?.size ?? 20;
    qp.push(`page=${encodeURIComponent(String(page))}`);
    qp.push(`size=${encodeURIComponent(String(size))}`);
    if (options?.fromDate) qp.push(`fromDate=${encodeURIComponent(options.fromDate)}`);
    if (options?.toDate) qp.push(`toDate=${encodeURIComponent(options.toDate)}`);

    const url = `${this.apiUrl}/attendance?${qp.join('&')}`;
    return this.http.get<ApiResponse<PagedResponse<any>>>(url, { headers: this.getHeaders() }).pipe(
      tap((res) => console.log('📅 Attendance (month-wide, paged) loaded:', res)),
      catchError((error) => this.handleError('Loading month attendance', error)),
    );
  }

  // ===== DRIVER STATISTICS & UTILITIES =====

  /**
   * Get driver statistics for dashboard
   * @returns Observable of driver statistics
   */
  getDriverStats(): Observable<
    ApiResponse<{
      totalDrivers: number;
      activeDrivers: number;
      onDutyDrivers: number;
      pendingDocuments: number;
    }>
  > {
    const url = `${this.apiUrl}/stats`;
    return this.http
      .get<
        ApiResponse<{
          totalDrivers: number;
          activeDrivers: number;
          onDutyDrivers: number;
          pendingDocuments: number;
        }>
      >(url, { headers: this.getHeaders() })
      .pipe(
        tap((res) => console.log('📊 Driver stats loaded:', res)),
        catchError((error) => this.handleError('Loading driver statistics', error)),
      );
  }

  /**
   * Update driver location
   * @param id Driver ID
   * @param latitude Latitude coordinate
   * @param longitude Longitude coordinate
   * @returns Observable of location update result
   */
  updateDriverLocation(
    id: number,
    latitude: number,
    longitude: number,
  ): Observable<ApiResponse<Driver>> {
    const url = `${this.apiUrl}/${id}/update-location?latitude=${latitude}&longitude=${longitude}`;
    return this.http.put<ApiResponse<Driver>>(url, {}, { headers: this.getHeaders() }).pipe(
      tap((res) => {
        this.showToast('Driver location updated!');
        console.log('Location updated:', res);
      }),
      catchError((error) => this.handleError('Updating driver location', error)),
    );
  }

  /**
   * Update device token for push notifications
   * @param driverId Driver ID
   * @param token FCM device token
   * @returns Observable of token update result
   */
  updateDeviceToken(driverId: number, token: string): Observable<void> {
    return this.http
      .post<void>(
        `${this.apiUrl}/update-device-token`,
        { driverId, token },
        {
          headers: this.getHeaders(),
        },
      )
      .pipe(
        tap(() => {
          this.showToast('Device token updated.');
          console.log(' FCM token updated');
        }),
        catchError((error) => this.handleError('Updating device token', error)),
      );
  }
}
