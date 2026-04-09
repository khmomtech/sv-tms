import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { Vehicle } from '../models/vehicle.model';
import { AuthService } from './auth.service';

export interface DriverCurrentAssignment {
  driverId: number;
  permanentVehicle?: Vehicle | null;
  temporaryVehicle?: Vehicle | null;
  temporaryExpiry?: string | null;
  effectiveType: 'PERMANENT' | 'TEMPORARY';
  effectiveVehicle?: Vehicle | null;
  // Client-side convenience field: minutes until temporaryExpiry
  remainingMinutes?: number | null;
}

export interface TemporaryAssignmentPayload {
  vehicleId: number;
  expiry?: string; // ISO timestamp
  reason?: string;
}

@Injectable({ providedIn: 'root' })
export class DriverAssignmentExtendedService {
  private baseUrl = environment.baseUrl;

  constructor(
    private http: HttpClient,
    private auth: AuthService,
  ) {}

  private wrap<T>(obs: Observable<T>): Observable<ApiResponse<T>> {
    return obs.pipe(
      map((data) => ({
        success: true,
        message: 'OK',
        data,
        totalPages: 0,
        timestamp: new Date().toISOString(),
      })),
    );
  }

  setTemporary(
    driverId: number,
    payload: TemporaryAssignmentPayload,
  ): Observable<ApiResponse<any>> {
    return this.wrap(
      this.http.post(`${this.baseUrl}/api/admin/drivers/${driverId}/temporary-assignment`, payload),
    );
  }

  removeTemporary(driverId: number): Observable<ApiResponse<string>> {
    return this.wrap(
      this.http
        .delete(`${this.baseUrl}/api/admin/drivers/${driverId}/temporary-assignment`)
        .pipe(map(() => 'REMOVED')),
    );
  }

  changePermanent(driverId: number, vehicleId: number): Observable<ApiResponse<any>> {
    return this.wrap(
      this.http.put(
        `${this.baseUrl}/api/admin/drivers/${driverId}/change-permanent`,
        {},
        { params: { vehicleId } },
      ),
    );
  }

  getCurrent(driverId: number): Observable<ApiResponse<DriverCurrentAssignment>> {
    return this.wrap(
      this.http.get<DriverCurrentAssignment>(
        `${this.baseUrl}/api/admin/drivers/${driverId}/current-assignment`,
      ),
    );
  }

  resetIfExpired(driverId: number): Observable<ApiResponse<string>> {
    return this.wrap(
      this.http
        .post(
          `${this.baseUrl}/api/admin/drivers/${driverId}/temporary-assignment/reset-if-expired`,
          {},
        )
        .pipe(map(() => 'TRIGGERED')),
    );
  }
}
