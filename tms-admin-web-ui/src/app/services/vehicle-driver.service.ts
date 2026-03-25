import { HttpClient, type HttpErrorResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError, timer } from 'rxjs';
import { catchError, map, retry, tap, timeout } from 'rxjs/operators';

import { environment } from '../environments/environment';

export interface AssignmentRequest {
  driverId: number;
  vehicleId: number;
  reason?: string;
  forceReassignment?: boolean;
}

export interface AssignmentResponse {
  id: number;
  driverId: number;
  driverName: string;
  driverFullName?: string;
  driverFirstName?: string;
  driverLastName?: string;
  driverLicenseNumber?: string;
  vehicleId: number;
  truckPlate: string;
  truckModel?: string;
  assignedAt: string;
  assignedBy: string;
  reason?: string;
  active: boolean;
  revokedAt?: string;
  revokedBy?: string;
  revokeReason?: string;
  version?: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message: string;
  timestamp: string;
  requestId?: string;
}

export interface AssignmentStats {
  activeCount: number;
  revokedCount: number;
  totalCount: number;
}

export interface AssignmentError {
  error: string;
  message: string;
  requestId?: string;
  timestamp: string;
}

export interface BulkAssignmentUploadResponse {
  trackingId: string;
  totalRows: number;
  processedRows: number;
  successCount: number;
  failedCount: number;
  results: Array<{
    driverId?: number;
    vehicleId?: number;
    success: boolean;
    message: string;
    requestId?: string;
    statusCode?: number;
  }>;
}

@Injectable({
  providedIn: 'root',
})
export class VehicleDriverService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/assignments/permanent`;
  private readonly REQUEST_TIMEOUT = 30000; // 30 seconds
  private readonly MAX_RETRIES = 2;
  private readonly RETRY_DELAY = 1000; // 1 second
  private readonly enableLogging = !environment.production;

  constructor(private http: HttpClient) {
    if (this.enableLogging) {
      console.log('[VehicleDriverService] Initialized with API URL:', this.apiUrl);
    }
  }

  assignTruckToDriver(request: AssignmentRequest): Observable<ApiResponse<AssignmentResponse>> {
    const requestId = this.generateRequestId();
    const headers = { 'X-Request-ID': requestId };

    if (this.enableLogging) {
      console.log('[VehicleDriverService] Assign request:', { requestId, request });
    }

    return this.http.post<ApiResponse<AssignmentResponse>>(this.apiUrl, request, { headers }).pipe(
      timeout(this.REQUEST_TIMEOUT),
      map((response) => this.normalizeAssignmentResponse(response)),
      tap((response) => {
        if (this.enableLogging) {
          console.log('[VehicleDriverService] Assign success:', response);
        }
      }),
      retry({
        count: this.MAX_RETRIES,
        delay: (error, retryCount) => {
          // Don't retry client errors (4xx)
          if (error.status >= 400 && error.status < 500) {
            throw error;
          }
          if (this.enableLogging) {
            console.log(`[VehicleDriverService] Retry attempt ${retryCount}/${this.MAX_RETRIES}`);
          }
          return timer(this.RETRY_DELAY * retryCount);
        },
      }),
      catchError((err) => this.handleError(err, 'assignTruckToDriver')),
    );
  }

  downloadBatchTemplate(): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/batch/template.csv`, {
      responseType: 'blob',
    });
  }

  uploadBatchCsv(file: File): Observable<ApiResponse<BulkAssignmentUploadResponse>> {
    const requestId = this.generateRequestId('assign-bulk');
    const headers = { 'X-Request-ID': requestId };
    const formData = new FormData();
    formData.append('file', file);

    if (this.enableLogging) {
      console.log('[VehicleDriverService] Upload bulk CSV:', {
        requestId,
        fileName: file.name,
        size: file.size,
      });
    }

    return this.http
      .post<ApiResponse<BulkAssignmentUploadResponse>>(
        `${this.apiUrl}/batch/upload-csv`,
        formData,
        {
          headers,
        },
      )
      .pipe(
        timeout(this.REQUEST_TIMEOUT),
        tap((response) => {
          if (this.enableLogging) {
            console.log('[VehicleDriverService] Bulk CSV upload result:', response);
          }
        }),
        catchError((err) => this.handleError(err, 'uploadBatchCsv')),
      );
  }

  getDriverAssignment(driverId: number): Observable<ApiResponse<AssignmentResponse>> {
    if (this.enableLogging) {
      console.log('[VehicleDriverService] Get driver assignment:', driverId);
    }

    return this.http.get<ApiResponse<AssignmentResponse>>(`${this.apiUrl}/${driverId}`).pipe(
      timeout(this.REQUEST_TIMEOUT),
      map((response) => this.normalizeAssignmentResponse(response)),
      tap((response) => {
        if (this.enableLogging) {
          console.log('[VehicleDriverService] Driver assignment:', response);
        }
      }),
      catchError((err) => this.handleError(err, 'getDriverAssignment')),
    );
  }

  getTruckAssignment(vehicleId: number): Observable<ApiResponse<AssignmentResponse>> {
    if (this.enableLogging) {
      console.log('[VehicleDriverService] Get truck assignment:', vehicleId);
    }

    return this.http.get<ApiResponse<AssignmentResponse>>(`${this.apiUrl}/truck/${vehicleId}`).pipe(
      timeout(this.REQUEST_TIMEOUT),
      map((response) => this.normalizeAssignmentResponse(response)),
      tap((response) => {
        if (this.enableLogging) {
          console.log('[VehicleDriverService] Truck assignment:', response);
        }
      }),
      catchError((err) => this.handleError(err, 'getTruckAssignment')),
    );
  }

  revokeDriverAssignment(driverId: number, reason?: string): Observable<ApiResponse<void>> {
    const requestId = this.generateRequestId('revoke');
    const headers = { 'X-Request-ID': requestId };
    const params: { [key: string]: string } = {};

    if (reason) {
      params['reason'] = reason;
    }

    if (this.enableLogging) {
      console.log('[VehicleDriverService] Revoke assignment:', {
        requestId,
        driverId,
        reason,
      });
    }

    return this.http
      .delete<ApiResponse<void>>(`${this.apiUrl}/${driverId}`, { headers, params })
      .pipe(
        timeout(this.REQUEST_TIMEOUT),
        tap(() => {
          if (this.enableLogging) {
            console.log('[VehicleDriverService] Revoke success:', driverId);
          }
        }),
        catchError((err) => this.handleError(err, 'revokeDriverAssignment')),
      );
  }

  getAssignmentStats(): Observable<ApiResponse<AssignmentStats>> {
    if (this.enableLogging) {
      console.log('[VehicleDriverService] Get stats');
    }

    return this.http.get<ApiResponse<AssignmentStats>>(`${this.apiUrl}/stats`).pipe(
      timeout(this.REQUEST_TIMEOUT),
      tap((response) => {
        if (this.enableLogging) {
          console.log('[VehicleDriverService] Stats:', response);
        }
      }),
      catchError((err) => this.handleError(err, 'getAssignmentStats')),
    );
  }

  /**
   * Get list of all assignments with optional filtering
   * @param filters Optional filter parameters
   * @returns Observable of assignment array
   */
  getAssignments(filters?: {
    driverId?: number;
    vehicleId?: number;
    active?: boolean;
    fromDate?: string;
    toDate?: string;
  }): Observable<ApiResponse<AssignmentResponse[]>> {
    let params: any = {};
    if (filters) {
      if (filters.driverId) params.driverId = filters.driverId.toString();
      if (filters.vehicleId) params.vehicleId = filters.vehicleId.toString();
      if (filters.active !== undefined) params.active = filters.active.toString();
      if (filters.fromDate) params.fromDate = filters.fromDate;
      if (filters.toDate) params.toDate = filters.toDate;
    }

    if (this.enableLogging) {
      console.log('[VehicleDriverService] Get assignments with filters:', filters);
    }

    return this.http.get<ApiResponse<AssignmentResponse[]>>(`${this.apiUrl}/list`, { params }).pipe(
      timeout(this.REQUEST_TIMEOUT),
      map((response) => this.normalizeAssignmentsResponse(response)),
      tap((response) => {
        if (this.enableLogging) {
          console.log('[VehicleDriverService] Assignments:', response);
        }
      }),
      catchError((err) => this.handleError(err, 'getAssignments')),
    );
  }

  private generateRequestId(prefix: string = 'assign'): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 11);
    return `${prefix}-${timestamp}-${random}`;
  }

  private normalizeAssignment(
    assignment: AssignmentResponse | null | undefined,
  ): AssignmentResponse {
    const item = (assignment || {}) as AssignmentResponse;
    return {
      ...item,
      driverName: item.driverName || item.driverFullName || 'Unknown Driver',
    };
  }

  private normalizeAssignmentResponse(
    response: ApiResponse<AssignmentResponse>,
  ): ApiResponse<AssignmentResponse> {
    return {
      ...response,
      data: this.normalizeAssignment(response?.data),
    };
  }

  private normalizeAssignmentsResponse(
    response: ApiResponse<AssignmentResponse[]>,
  ): ApiResponse<AssignmentResponse[]> {
    return {
      ...response,
      data: Array.isArray(response?.data)
        ? response.data.map((item) => this.normalizeAssignment(item))
        : [],
    };
  }

  private handleError(error: HttpErrorResponse, context: string): Observable<never> {
    let errorMessage = 'An unexpected error occurred';
    let errorDetails: any = {};

    if (error.error instanceof ErrorEvent) {
      // Client-side or network error
      errorMessage = `Network error: ${error.error.message}`;
      errorDetails = { type: 'network', message: error.error.message };
    } else {
      // Backend error
      const backendMessage =
        typeof error.error?.message === 'string' ? error.error.message : undefined;
      errorMessage = backendMessage || `Server error: ${error.status} ${error.statusText}`;
      errorDetails = {
        type: 'backend',
        status: error.status,
        statusText: error.statusText,
        backendMessage,
        requestId: error.error?.requestId,
        timestamp: error.error?.timestamp,
      };

      if (!errorDetails.requestId && typeof error.headers?.get === 'function') {
        errorDetails.requestId = error.headers.get('X-Request-ID') || undefined;
      }

      if (!errorDetails.requestId && backendMessage) {
        const match = backendMessage.match(/request ID:\s*([A-Za-z0-9-_]+)/i);
        if (match) {
          errorDetails.requestId = match[1];
        }
      }

      // Special handling for common errors
      if (error.status === 0) {
        errorMessage = 'Cannot connect to server. Please check your internet connection.';
      } else if (error.status === 401) {
        errorMessage = 'Unauthorized. Please login again.';
      } else if (error.status === 403) {
        errorMessage = 'You do not have permission to perform this action.';
      } else if (error.status === 404) {
        errorMessage = error.error?.message || 'Assignment not found.';
      } else if (error.status === 409) {
        errorMessage = error.error?.message || 'Conflict detected. Please refresh and try again.';
      } else if (error.status >= 500) {
        errorMessage =
          backendMessage && backendMessage.trim().length > 0
            ? backendMessage
            : 'Server error. Please try again later.';
        if (errorDetails.requestId && !errorMessage.toLowerCase().includes('request id')) {
          errorMessage += ` (Request ID: ${errorDetails.requestId})`;
        }
      }
    }

    // Log error with context
    console.error(`[VehicleDriverService] Error in ${context}:`, {
      message: errorMessage,
      details: errorDetails,
      error,
    });

    // Return user-friendly error
    return throwError(() => ({
      message: errorMessage,
      ...errorDetails,
      originalError: error,
    }));
  }
}
