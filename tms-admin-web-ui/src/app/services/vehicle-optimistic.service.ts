import { HttpClient, HttpErrorResponse, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { catchError, map, Observable, of, switchMap, throwError, timeout } from 'rxjs';

import type {
  ConflictData,
  ConflictResolution,
} from '../components/conflict-resolution/conflict-resolution.component';
import { ConflictResolutionComponent } from '../components/conflict-resolution/conflict-resolution.component';
import { environment } from '../environments/environment';
import type { Vehicle } from '../models/vehicle.model';
import { CacheService } from './cache.service';
import { CircuitBreakerService } from './circuit-breaker.service';

interface VehicleWithVersion extends Vehicle {
  version?: number;
  etag?: string;
}

interface PagedResponse<T> {
  success: boolean;
  data?: {
    content: T[];
    page: {
      size: number;
      number: number;
      totalElements: number;
      totalPages: number;
    };
  };
  message?: string;
}

/**
 * Enhanced Vehicle Service with Optimistic Locking Support
 *
 * Features:
 * - ETag-based version tracking
 * - Conflict detection and resolution UI
 * - Resilience patterns (cache, circuit breaker, retry)
 * - User-friendly error messages
 *
 * Optimistic Locking Flow:
 * 1. GET request receives ETag header
 * 2. Store ETag with entity
 * 3. PUT/PATCH includes If-Match header with ETag
 * 4. Server validates version
 * 5. If conflict (412 Precondition Failed), show resolution dialog
 *
 * @example
 * ```typescript
 * // Get vehicle with version
 * this.service.getVehicleById(123).subscribe(vehicle => {
 *   // vehicle.etag is stored automatically
 * });
 *
 * // Update with version check
 * this.service.updateVehicle(vehicle).subscribe({
 *   next: (updated) => console.log('Updated'),
 *   error: (err) => {
 *     // If 412, dialog shown automatically
 *   }
 * });
 * ```
 */
@Injectable({
  providedIn: 'root',
})
export class VehicleOptimisticService {
  private readonly baseUrl = `${environment.baseUrl}/api/admin/vehicles`;
  private readonly REQUEST_TIMEOUT = 30000;

  // Store versions in memory (could use IndexedDB for persistence)
  private versionCache = new Map<number, string>();

  constructor(
    private http: HttpClient,
    private cacheService: CacheService,
    private circuitBreaker: CircuitBreakerService,
    private dialog: MatDialog,
  ) {}

  /**
   * Get paginated vehicles with version tracking
   */
  getVehicles(
    page: number,
    size: number,
    filters?: Record<string, string | undefined>,
  ): Observable<PagedResponse<VehicleWithVersion>> {
    const cacheKey = `vehicles:page:${page}:${size}:${JSON.stringify(filters || {})}`;

    const params: Record<string, string> = {
      page: page.toString(),
      size: size.toString(),
    };

    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value) params[key] = value;
      });
    }

    const request = this.http
      .get<PagedResponse<VehicleWithVersion>>(this.baseUrl, {
        params,
        observe: 'response',
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT),
        map((response) => {
          const body = response.body!;

          // Store ETags for each vehicle
          if (body.data?.content) {
            body.data.content.forEach((vehicle) => {
              const etag = response.headers.get(`ETag-${vehicle.id}`);
              if (etag && vehicle.id) {
                vehicle.etag = etag;
                this.versionCache.set(vehicle.id, etag);
              }
            });
          }

          return body;
        }),
        catchError((error) => this.handleError(error, 'fetching vehicles')),
      );

    return this.circuitBreaker.execute(
      'vehicle-service',
      this.cacheService.getOrFetch(cacheKey, request, 5 * 60 * 1000, true),
    );
  }

  /**
   * Get single vehicle by ID with ETag
   */
  getVehicleById(id: number): Observable<VehicleWithVersion> {
    const cacheKey = `vehicle:${id}`;

    const request = this.http
      .get<{ success: boolean; data: VehicleWithVersion }>(`${this.baseUrl}/${id}`, {
        observe: 'response',
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT),
        map((response) => {
          const vehicle = response.body!.data;
          const etag = response.headers.get('ETag');

          if (etag && vehicle.id) {
            vehicle.etag = etag;
            this.versionCache.set(vehicle.id, etag);
          }

          return vehicle;
        }),
        catchError((error) => this.handleError(error, 'fetching vehicle')),
      );

    return this.circuitBreaker.execute(
      'vehicle-service',
      this.cacheService.getOrFetch(cacheKey, request, 5 * 60 * 1000, true),
    );
  }

  /**
   * Update vehicle with optimistic locking
   * Automatically handles conflicts via dialog
   */
  updateVehicle(vehicle: VehicleWithVersion): Observable<VehicleWithVersion> {
    const etag = vehicle.etag || this.versionCache.get(vehicle.id!);

    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      ...(etag ? { 'If-Match': etag } : {}),
    });

    return this.http
      .put<{
        success: boolean;
        data: VehicleWithVersion;
      }>(`${this.baseUrl}/${vehicle.id}`, vehicle, { headers, observe: 'response' })
      .pipe(
        timeout(this.REQUEST_TIMEOUT),
        map((response) => {
          const updated = response.body!.data;
          const newEtag = response.headers.get('ETag');

          if (newEtag && updated.id) {
            updated.etag = newEtag;
            this.versionCache.set(updated.id, newEtag);
          }

          // Invalidate cache
          this.cacheService.invalidatePattern(/^vehicles:/);
          this.cacheService.invalidate(`vehicle:${vehicle.id}`);

          return updated;
        }),
        catchError((error: HttpErrorResponse) => {
          if (error.status === 412) {
            // Conflict detected - show resolution dialog
            return this.handleConflict(vehicle, error);
          }
          return this.handleError(error, 'updating vehicle');
        }),
      );
  }

  /**
   * Handle version conflict by showing resolution dialog
   */
  private handleConflict(
    localVehicle: VehicleWithVersion,
    error: HttpErrorResponse,
  ): Observable<VehicleWithVersion> {
    // Fetch latest version from server
    return this.getVehicleById(localVehicle.id!).pipe(
      switchMap((serverVehicle) => {
        const conflictFields = this.detectConflicts(localVehicle, serverVehicle);

        const dialogRef = this.dialog.open(ConflictResolutionComponent, {
          data: {
            resourceName: `Vehicle #${localVehicle.id}`,
            currentVersion: serverVehicle,
            serverVersion: serverVehicle,
            localChanges: localVehicle,
            conflictFields,
          } as ConflictData,
          disableClose: true,
          width: '800px',
        });

        return dialogRef.afterClosed().pipe(
          switchMap((resolution: ConflictResolution | null) => {
            if (!resolution) {
              return throwError(() => new Error('Update cancelled by user'));
            }

            if (resolution.action === 'use-server') {
              return of(serverVehicle);
            }

            // Force update with merged or local data
            const updatedVehicle = {
              ...resolution.mergedData,
              etag: serverVehicle.etag,
            };

            return this.updateVehicle(updatedVehicle);
          }),
        );
      }),
    );
  }

  /**
   * Detect which fields have conflicts
   */
  private detectConflicts(local: VehicleWithVersion, server: VehicleWithVersion): string[] {
    const conflicts: string[] = [];
    const fieldsToCheck = [
      'status',
      'licensePlate',
      'assignedZoneId',
      'assignedZoneName',
      'truckSize',
      'assignedDriver',
    ];

    fieldsToCheck.forEach((field) => {
      const localValue = (local as any)[field];
      const serverValue = (server as any)[field];

      if (JSON.stringify(localValue) !== JSON.stringify(serverValue)) {
        conflicts.push(field);
      }
    });

    return conflicts;
  }

  /**
   * Add vehicle (no version needed)
   */
  addVehicle(vehicle: Vehicle): Observable<VehicleWithVersion> {
    return this.http
      .post<{ success: boolean; data: VehicleWithVersion }>(this.baseUrl, vehicle, {
        observe: 'response',
      })
      .pipe(
        timeout(this.REQUEST_TIMEOUT),
        map((response) => {
          const created = response.body!.data;
          const etag = response.headers.get('ETag');

          if (etag && created.id) {
            created.etag = etag;
            this.versionCache.set(created.id, etag);
          }

          this.cacheService.invalidatePattern(/^vehicles:/);
          return created;
        }),
        catchError((error) => this.handleError(error, 'creating vehicle')),
      );
  }

  /**
   * Delete vehicle with version check
   */
  deleteVehicle(id: number, etag?: string): Observable<void> {
    const version = etag || this.versionCache.get(id);
    const headers = new HttpHeaders({
      ...(version ? { 'If-Match': version } : {}),
    });

    return this.http.delete<void>(`${this.baseUrl}/${id}`, { headers }).pipe(
      timeout(this.REQUEST_TIMEOUT),
      map(() => {
        this.versionCache.delete(id);
        this.cacheService.invalidatePattern(/^vehicles:/);
        this.cacheService.invalidate(`vehicle:${id}`);
      }),
      catchError((error) => {
        if (error.status === 412) {
          return throwError(
            () => new Error('Vehicle was modified by someone else. Please refresh and try again.'),
          );
        }
        return this.handleError(error, 'deleting vehicle');
      }),
    );
  }

  /**
   * Handle HTTP errors with user-friendly messages
   */
  private handleError(error: HttpErrorResponse, operation: string): Observable<never> {
    let message = `❌ Error ${operation}`;

    if (error.status === 0) {
      message = '📶 Unable to connect to server. Check your internet connection.';
    } else if (error.status === 401) {
      message = '🔒 Session expired. Please log in again.';
    } else if (error.status === 403) {
      message = '🚫 You don lack permission for this action.';
    } else if (error.status === 404) {
      message = '🔍 Vehicle not found.';
    } else if (error.status === 408) {
      message = '⏱️ Request timeout. Server took too long to respond.';
    } else if (error.status >= 500) {
      message = '💥 Server error. Our team has been notified.';
    }

    console.error(`[VehicleOptimisticService] ${operation}:`, error);

    return throwError(() => ({
      message,
      originalError: error,
      status: error.status,
    }));
  }

  /**
   * Get cache statistics
   */
  getCacheStats() {
    return this.cacheService.getStats();
  }

  /**
   * Get circuit breaker status
   */
  getCircuitStatus() {
    return this.circuitBreaker.getState('vehicle-service');
  }
}
