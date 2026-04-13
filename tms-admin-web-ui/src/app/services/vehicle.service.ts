import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { catchError, tap, throwError, of } from 'rxjs';
import { retry, timeout } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { Vehicle } from '../models/vehicle.model';
import type { VehicleSetupRequest } from '../models/vehicle-setup.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';
import { CacheService } from './cache.service';
import { CircuitBreakerService } from './circuit-breaker.service';

@Injectable({
  providedIn: 'root',
})
export class VehicleService {
  private apiUrl = `${environment.baseUrl}/api/admin/vehicles`;
  private defaultErrorMessage = 'Something went wrong. Please try again later.';
  private readonly REQUEST_TIMEOUT_MS = 30000; // 30 seconds
  private readonly CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

  constructor(
    private http: HttpClient,
    private authService: AuthService,
    private cacheService: CacheService,
    private circuitBreaker: CircuitBreakerService,
  ) {
    // Cleanup expired cache entries every 10 minutes and run once immediately
    setInterval(() => this.cacheService.cleanup(), 10 * 60 * 1000);
    this.cacheService.cleanup();
  }

  /** 🔐 Get auth token headers */
  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  // ────────────────────────────────────────────────────────────────────────────────
  //  CRUD METHODS
  // ────────────────────────────────────────────────────────────────────────────────

  /** 📄 Get paginated + filtered vehicle list from server */
  getVehicles(
    page: number = 0,
    size: number = 15,
    filters: {
      search?: string;
      status?: string;
      truckSize?: string;
      zone?: string;
      assigned?: string;
    } = {},
  ): Observable<ApiResponse<{ content: Vehicle[]; totalElements: number; totalPages: number }>> {
    const query = new URLSearchParams();

    if (filters.search) query.append('search', filters.search);
    if (filters.status) query.append('status', filters.status);
    if (filters.truckSize) query.append('truckSize', filters.truckSize);
    if (filters.zone) query.append('zone', filters.zone);
    if (filters.assigned) query.append('assigned', filters.assigned);

    query.append('page', String(page));
    query.append('size', String(size));

    // Include endpoint name to avoid reusing stale cached data from the legacy /filter path.
    const cacheKey = `vehicles:search:${query.toString()}`;
    const url = `${this.apiUrl}/search?${query.toString()}`;

    const request = this.http
      .get<ApiResponse<{ content: Vehicle[]; totalElements: number; totalPages: number }>>(url, {
        headers: this.getHeaders(),
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        tap((res) => console.log('🚛 Paginated Vehicles:', res)),
        catchError((error) => this.handleErrorWithFallback(error, cacheKey)),
      );

    // Use circuit breaker with cache fallback
    return this.circuitBreaker.execute(
      'vehicle-service',
      this.cacheService.getOrFetch(cacheKey, request, this.CACHE_TTL_MS, true),
    );
  }

  /** 🌍 Get all vehicles (non-paginated) */
  getAllVehicles(): Observable<ApiResponse<Vehicle[]>> {
    const cacheKey = 'vehicles:all';
    const request = this.http
      .get<ApiResponse<Vehicle[]>>(`${this.apiUrl}/all`, {
        headers: this.getHeaders(),
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        catchError((error) => this.handleErrorWithFallback(error, cacheKey)),
      );

    return this.circuitBreaker.execute(
      'vehicle-service',
      this.cacheService.getOrFetch(cacheKey, request, this.CACHE_TTL_MS, true),
    );
  }

  /** 🔎 Get single vehicle by ID */
  getVehicleById(id: number): Observable<ApiResponse<Vehicle>> {
    const cacheKey = `vehicle:${id}`;
    const request = this.http
      .get<ApiResponse<Vehicle>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        catchError((error) => this.handleErrorWithFallback(error, cacheKey)),
      );

    return this.circuitBreaker.execute(
      'vehicle-service',
      this.cacheService.getOrFetch(cacheKey, request, this.CACHE_TTL_MS, true),
    );
  }

  /** 👥 Get driver history for a vehicle (paginated) */
  getDriverHistory(
    vehicleId: number,
    page = 0,
    size = 10,
    search?: string,
    activeStatus?: 'all' | 'active' | 'revoked',
  ): Observable<ApiResponse<{ content: any[]; totalElements: number; totalPages: number }>> {
    const query = new URLSearchParams();
    query.append('page', String(page));
    query.append('size', String(size));
    if (search) query.append('search', search);
    if (activeStatus === 'active') {
      query.append('active', 'true');
    } else if (activeStatus === 'revoked') {
      query.append('active', 'false');
    }

    const cacheKey = `vehicle:${vehicleId}:driverHistory:${query.toString()}`;
    const url = `${this.apiUrl}/${vehicleId}/driver-history?${query.toString()}`;

    const request = this.http
      .get<
        ApiResponse<{ content: any[]; totalElements: number }>
      >(url, { headers: this.getHeaders() })
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        catchError((error) => this.handleErrorWithFallback(error, cacheKey)),
      );

    return this.circuitBreaker.execute(
      'vehicle-service',
      this.cacheService.getOrFetch(cacheKey, request, this.CACHE_TTL_MS, true),
    );
  }

  /** ⛽ Get fuel logs for a vehicle (paginated) */
  getFuelLogs(
    vehicleId: number,
    page = 0,
    size = 10,
    search?: string,
  ): Observable<ApiResponse<{ content: any[]; totalElements: number }>> {
    const query = new URLSearchParams();
    query.append('page', String(page));
    query.append('size', String(size));
    if (search) query.append('search', search);

    const cacheKey = `vehicle:${vehicleId}:fuelLogs:${query.toString()}`;
    const url = `${this.apiUrl}/${vehicleId}/fuel-logs?${query.toString()}`;

    const request = this.http
      .get<
        ApiResponse<{ content: any[]; totalElements: number }>
      >(url, { headers: this.getHeaders() })
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        catchError((error) => this.handleErrorWithFallback(error, cacheKey)),
      );

    return this.circuitBreaker.execute(
      'vehicle-service',
      this.cacheService.getOrFetch(cacheKey, request, this.CACHE_TTL_MS, true),
    );
  }

  createFuelLog(vehicleId: number, payload: any): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/${vehicleId}/fuel-logs`;
    return this.http.post<ApiResponse<any>>(url, payload, { headers: this.getHeaders() }).pipe(
      timeout(this.REQUEST_TIMEOUT_MS),
      catchError((error) => this.handleErrorWithFallback(error, 'fuel-log:create')),
    );
  }

  updateFuelLog(vehicleId: number, logId: number, payload: any): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/${vehicleId}/fuel-logs/${logId}`;
    return this.http.put<ApiResponse<any>>(url, payload, { headers: this.getHeaders() }).pipe(
      timeout(this.REQUEST_TIMEOUT_MS),
      catchError((error) => this.handleErrorWithFallback(error, 'fuel-log:update')),
    );
  }

  deleteFuelLog(vehicleId: number, logId: number): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/${vehicleId}/fuel-logs/${logId}`;
    return this.http.delete<ApiResponse<any>>(url, { headers: this.getHeaders() }).pipe(
      timeout(this.REQUEST_TIMEOUT_MS),
      catchError((error) => this.handleErrorWithFallback(error, 'fuel-log:delete')),
    );
  }

  /** 💰 Get cost summary for a vehicle */
  getCostSummary(vehicleId: number): Observable<ApiResponse<any>> {
    const cacheKey = `vehicle:${vehicleId}:costSummary`;
    const url = `${this.apiUrl}/${vehicleId}/cost-summary`;

    const request = this.http.get<ApiResponse<any>>(url, { headers: this.getHeaders() }).pipe(
      timeout(this.REQUEST_TIMEOUT_MS),
      catchError((error) => this.handleErrorWithFallback(error, cacheKey)),
    );

    return this.circuitBreaker.execute(
      'vehicle-service',
      this.cacheService.getOrFetch(cacheKey, request, this.CACHE_TTL_MS, true),
    );
  }

  revokeDriverAssignment(driverId: number, reason?: string): Observable<ApiResponse<any>> {
    if (!driverId) {
      return throwError(() => new Error('Driver ID is required to revoke assignment.'));
    }
    let params = new HttpParams();
    if (reason) {
      params = params.set('reason', reason);
    }
    return this.http
      .delete<ApiResponse<any>>(
        `${environment.apiBaseUrl}/admin/assignments/permanent/${driverId}`,
        {
          headers: this.getHeaders(),
          params,
        },
      )
      .pipe(timeout(this.REQUEST_TIMEOUT_MS), catchError(this.handleError.bind(this)));
  }

  /** ➕ Create new vehicle */
  addVehicle(vehicle: Vehicle): Observable<ApiResponse<Vehicle>> {
    return this.http
      .post<ApiResponse<Vehicle>>(
        this.apiUrl,
        {
          ...vehicle,
          status: vehicle.status,
        },
        {
          headers: this.getHeaders(),
        },
      )
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        tap(() => {
          this.cacheService.invalidatePattern(/^vehicles:/);
        }),
        catchError(this.handleError.bind(this)),
      );
  }

  /** 🛠️ Setup complete vehicle with documents and maintenance */
  setupVehicle(setupRequest: VehicleSetupRequest): Observable<ApiResponse<Vehicle>> {
    return this.http
      .post<ApiResponse<Vehicle>>(`${this.apiUrl}/setup`, setupRequest, {
        headers: this.getHeaders(),
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        tap(() => {
          // Invalidate all vehicle caches
          this.cacheService.invalidatePattern(/^vehicles:/);
        }),
        catchError(this.handleError.bind(this)),
      );
  }

  /** ✏️ Update existing vehicle */
  updateVehicle(vehicle: Vehicle): Observable<ApiResponse<Vehicle>> {
    if (!vehicle.id) {
      return throwError(() => new Error('Vehicle ID is required for update.'));
    }

    return this.http
      .put<ApiResponse<Vehicle>>(`${this.apiUrl}/${vehicle.id}`, vehicle, {
        headers: this.getHeaders(),
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        tap(() => {
          // Invalidate all vehicle caches
          this.cacheService.invalidatePattern(/^vehicles:/);
        }),
        catchError(this.handleError.bind(this)),
      );
  }

  /** ✅ Check if vehicle is ready for operation */
  isVehicleReadyForOperation(vehicleId: number): Observable<ApiResponse<boolean>> {
    return this.http
      .get<ApiResponse<boolean>>(`${this.apiUrl}/${vehicleId}/ready-status`, {
        headers: this.getHeaders(),
      })
      .pipe(timeout(this.REQUEST_TIMEOUT_MS), catchError(this.handleError.bind(this)));
  }

  /** 🗑️ Delete vehicle */
  deleteVehicle(id: number): Observable<ApiResponse<void>> {
    return this.http
      .delete<ApiResponse<void>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        tap(() => {
          // Invalidate all vehicle caches
          this.cacheService.invalidatePattern(/^vehicles:/);
        }),
        catchError(this.handleError.bind(this)),
      );
  }

  // ────────────────────────────────────────────────────────────────────────────────
  // ⚠️ Error Handling
  // ────────────────────────────────────────────────────────────────────────────────

  private handleError(error: HttpErrorResponse): Observable<never> {
    console.error(' API Error:', error);
    let errorMessage = this.defaultErrorMessage;

    if (error.error) {
      if (typeof error.error === 'string') {
        errorMessage = error.error;
      } else if (error.error.message) {
        errorMessage = error.error.message;
      } else if (error.error.errors) {
        errorMessage = Object.values(error.error.errors).join(', ');
      }
    } else {
      switch (error.status) {
        case 0:
          errorMessage = 'Unable to connect to the server. Check your internet connection.';
          break;
        case 400:
          errorMessage = 'Bad request. Please check your input.';
          break;
        case 401:
          errorMessage = 'Unauthorized. Please log in again.';
          break;
        case 403:
          errorMessage = 'Forbidden. You don’t have permission.';
          break;
        case 404:
          errorMessage = 'Not found. The resource does not exist.';
          break;
        case 500:
          errorMessage = 'Server error. Please try again later.';
          break;
      }
    }

    return throwError(() => new Error(errorMessage));
  }

  /**
   * Handle error with cache fallback
   * Returns cached data if available, otherwise throws error
   */
  private handleErrorWithFallback(error: HttpErrorResponse, cacheKey: string): Observable<any> {
    console.error('⚠️ Request failed, attempting cache fallback:', error);

    // Try to get cached data
    const cachedData = this.cacheService.get(cacheKey);

    if (cachedData) {
      console.warn('📦 Returning stale cached data due to error');
      return of(cachedData);
    }

    // No cache available, propagate error
    return this.handleError(error);
  }
}
