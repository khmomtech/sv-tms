import type { HttpErrorResponse } from '@angular/common/http';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { catchError, tap, throwError, of } from 'rxjs';
import { timeout } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { Vehicle } from '../models/vehicle.model';
import { AuthService } from './auth.service';
import { CacheService } from './cache.service';
import { CircuitBreakerService } from './circuit-breaker.service';

/**
 * Production-ready VehicleService with:
 * - Circuit breaker pattern for preventing cascade failures
 * - Intelligent caching with TTL and fallback
 * - Automatic retry with exponential backoff (via interceptor)
 * - Request timeout protection
 * - Enhanced error handling with user-friendly messages
 * - Cache invalidation on mutations
 * - Monitoring hooks for observability
 */
@Injectable({
  providedIn: 'root',
})
export class VehicleResilientService {
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
    // Cleanup expired cache entries every 10 minutes
    setInterval(() => this.cacheService.cleanup(), 10 * 60 * 1000);
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
  //  CRUD METHODS WITH RESILIENCE
  // ────────────────────────────────────────────────────────────────────────────────

  /** 📄 Get paginated + filtered vehicle list from server with caching */
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

    const cacheKey = `vehicles:filter:${query.toString()}`;
    const url = `${this.apiUrl}/filter?${query.toString()}`;

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

  /** 🌍 Get all vehicles (non-paginated) with caching */
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

  /** ➕ Create new vehicle with cache invalidation */
  addVehicle(vehicle: Vehicle): Observable<ApiResponse<Vehicle>> {
    return this.http
      .post<ApiResponse<Vehicle>>(this.apiUrl, vehicle, {
        headers: this.getHeaders(),
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT_MS),
        tap(() => {
          // Invalidate all vehicle caches
          this.cacheService.invalidatePattern(/^vehicles:/);
          console.log('🔄 Vehicle cache invalidated after creation');
        }),
        catchError(this.handleError.bind(this)),
      );
  }

  /** ✏️ Update existing vehicle with cache invalidation */
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
          console.log('🔄 Vehicle cache invalidated after update');
        }),
        catchError(this.handleError.bind(this)),
      );
  }

  /** 🗑️ Delete vehicle with cache invalidation */
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
          console.log('🔄 Vehicle cache invalidated after deletion');
        }),
        catchError(this.handleError.bind(this)),
      );
  }

  // ────────────────────────────────────────────────────────────────────────────────
  // ⚠️ ENHANCED ERROR HANDLING
  // ────────────────────────────────────────────────────────────────────────────────

  /**
   * Enhanced error handler with cache fallback support
   */
  private handleErrorWithFallback(error: HttpErrorResponse, cacheKey?: string): Observable<any> {
    console.error('🔴 Vehicle Service Error:', {
      url: error.url,
      status: error.status,
      message: error.message,
      cacheKey,
    });

    // Try cache fallback for read operations
    if (cacheKey) {
      const cached = this.cacheService.getStale(cacheKey);
      if (cached) {
        console.warn('⚠️ Using stale cache due to error:', cacheKey);
        return of(cached);
      }
    }

    return this.handleError(error);
  }

  /**
   * Standard error handler with user-friendly messages
   */
  private handleError(error: HttpErrorResponse): Observable<never> {
    console.error('🔴 API Error:', error);
    let errorMessage = this.defaultErrorMessage;
    let userMessage = errorMessage;

    // Extract error message from response
    if (error.error) {
      if (typeof error.error === 'string') {
        errorMessage = error.error;
      } else if (error.error.message) {
        errorMessage = error.error.message;
      } else if (error.error.errors) {
        errorMessage = Object.values(error.error.errors).join(', ');
      }
    }

    // Map HTTP status to user-friendly messages
    switch (error.status) {
      case 0:
        userMessage =
          '❌ Unable to connect to the server. Please check your internet connection and try again.';
        break;
      case 400:
        userMessage = `⚠️ Invalid request: ${errorMessage || 'Please check your input and try again.'}`;
        break;
      case 401:
        userMessage = '🔒 Your session has expired. Please log in again.';
        break;
      case 403:
        userMessage = "🚫 You don't have permission to perform this action.";
        break;
      case 404:
        userMessage = '🔍 The requested resource was not found.';
        break;
      case 408:
        userMessage = '⏱️ Request timeout. The server took too long to respond.';
        break;
      case 409:
        userMessage = `⚠️ Conflict: ${errorMessage || 'The resource has been modified by another user.'}`;
        break;
      case 422:
        userMessage = `⚠️ Validation error: ${errorMessage || 'Please check your input.'}`;
        break;
      case 429:
        userMessage = '⏸️ Too many requests. Please wait a moment and try again.';
        break;
      case 500:
        userMessage = '💥 Server error. Our team has been notified. Please try again later.';
        break;
      case 502:
      case 503:
      case 504:
        userMessage = '🔧 Service temporarily unavailable. Please try again in a few moments.';
        break;
      default:
        userMessage = errorMessage || this.defaultErrorMessage;
    }

    // Enhance error with metadata for logging/monitoring
    const enhancedError = new Error(userMessage);
    (enhancedError as any).originalError = error;
    (enhancedError as any).status = error.status;
    (enhancedError as any).timestamp = new Date().toISOString();
    (enhancedError as any).requestId = error.headers?.get('X-Request-ID');

    return throwError(() => enhancedError);
  }

  // ────────────────────────────────────────────────────────────────────────────────
  // 📊 MONITORING & DEBUGGING
  // ────────────────────────────────────────────────────────────────────────────────

  /**
   * Get cache statistics for monitoring dashboard
   */
  getCacheStats() {
    return this.cacheService.getStats();
  }

  /**
   * Get circuit breaker status for health checks
   */
  getCircuitStatus() {
    return this.circuitBreaker.getCircuitState('vehicle-service');
  }

  /**
   * Manually clear cache (for debugging or forced refresh)
   */
  clearCache() {
    this.cacheService.invalidatePattern(/^vehicles:/);
    console.log('🗑️ Vehicle cache cleared');
  }

  /**
   * Force circuit breaker reset (admin function)
   */
  resetCircuitBreaker() {
    this.circuitBreaker.reset('vehicle-service');
    console.log('🔄 Circuit breaker reset');
  }
}
