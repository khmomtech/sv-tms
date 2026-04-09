import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { DeviceRegisterDto } from '../models/device-register.dto';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

export interface DeviceApprovalRequest {
  username: string;
  password: string;
  deviceId: string;
  deviceName: string;
  os: string;
  version: string;
  appVersion?: string;
  manufacturer?: string;
  model?: string;
  ipAddress?: string;
  location?: string;
}

@Injectable({
  providedIn: 'root',
})
export class DeviceService {
  // Use apiBaseUrl from environment (canonical in this project)
  private readonly apiUrl = `${environment.apiBaseUrl}/driver/device`;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    const headers: { [header: string]: string } = {
      'Content-Type': 'application/json',
    };
    // Debug: log token presence to help diagnose 403 errors (will appear in browser console)
    try {
      if (!token) {
        console.warn('[DeviceService] No auth token found in localStorage when building headers');
      } else {
        // print only prefix for safety

        console.debug('[DeviceService] Using auth token (prefix):', token.substring(0, 20) + '...');
        headers['Authorization'] = `Bearer ${token}`;
      }
    } catch (err) {
      console.error('[DeviceService] Error reading token for headers', err);
    }
    return new HttpHeaders(headers);
  }

  getAllDevices(): Observable<ApiResponse<DeviceRegisterDto[]>> {
    return this.http
      .get<ApiResponse<DeviceRegisterDto[]>>(`${this.apiUrl}/all`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  getDeviceById(id: number): Observable<ApiResponse<DeviceRegisterDto>> {
    return this.http
      .get<ApiResponse<DeviceRegisterDto>>(`${this.apiUrl}/${id}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  filterDevicesByStatus(status: string): Observable<ApiResponse<DeviceRegisterDto[]>> {
    return this.http
      .get<ApiResponse<DeviceRegisterDto[]>>(`${this.apiUrl}/filter?status=${status}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  registerDevice(device: DeviceRegisterDto): Observable<ApiResponse<string>> {
    return this.http
      .post<ApiResponse<string>>(`${this.apiUrl}/register`, device)
      .pipe(catchError(this.handleError));
  }

  requestDeviceApproval(data: DeviceApprovalRequest): Observable<ApiResponse<any>> {
    return this.http
      .post<ApiResponse<any>>(`${this.apiUrl}/request-approval`, data)
      .pipe(catchError(this.handleError));
  }

  getDeviceStatus(deviceId: string): Observable<ApiResponse<string>> {
    return this.http
      .get<ApiResponse<string>>(`${this.apiUrl}/status/${deviceId}`)
      .pipe(catchError(this.handleError));
  }

  createDevice(data: DeviceRegisterDto): Observable<ApiResponse<DeviceRegisterDto>> {
    return this.http
      .post<ApiResponse<DeviceRegisterDto>>(`${this.apiUrl}/create`, data, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  updateDevice(id: number, data: DeviceRegisterDto): Observable<ApiResponse<DeviceRegisterDto>> {
    return this.http
      .put<ApiResponse<DeviceRegisterDto>>(`${this.apiUrl}/${id}`, data, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  updateDeviceStatus(id: number, status: string): Observable<ApiResponse<void>> {
    return this.http
      .put<ApiResponse<void>>(
        `${this.apiUrl}/${id}/status?status=${status}`,
        {},
        {
          headers: this.getHeaders(),
        },
      )
      .pipe(catchError(this.handleError));
  }

  approveDevice(id: number): Observable<ApiResponse<void>> {
    return this.http
      .put<ApiResponse<void>>(`${this.apiUrl}/approve/${id}`, {}, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  blockDevice(id: number): Observable<ApiResponse<void>> {
    return this.http
      .put<ApiResponse<void>>(`${this.apiUrl}/block/${id}`, {}, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  setPending(id: number): Observable<ApiResponse<void>> {
    return this.http
      .put<ApiResponse<void>>(`${this.apiUrl}/pending/${id}`, {}, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  deleteDevice(id: number): Observable<ApiResponse<void>> {
    return this.http
      .delete<ApiResponse<void>>(`${this.apiUrl}/${id}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  searchDevices(
    page = 0,
    size = 20,
    filters?: { status?: string; driverId?: string; q?: string },
  ): Observable<ApiResponse<any>> {
    const params: string[] = [];
    params.push(`page=${page}`);
    params.push(`size=${size}`);
    if (filters?.status) params.push(`status=${encodeURIComponent(filters.status)}`);
    if (filters?.driverId) params.push(`driverId=${encodeURIComponent(filters.driverId)}`);
    if (filters?.q) params.push(`q=${encodeURIComponent(filters.q)}`);
    const url = `${this.apiUrl}/search?${params.join('&')}`;
    return this.http
      .get<ApiResponse<any>>(url, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  private handleError(error: HttpErrorResponse) {
    console.error('DeviceService Error:', error);
    const message = error.error?.message || error.statusText || 'Unknown error occurred.';
    const status = error.status;
    // Throw a structured object so callers can inspect status and message
    return throwError(() => ({ message, status }));
  }
}
