import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { DriverAssignment } from '../models/driver-assignment.model';
import type { Vehicle } from '../models/vehicle.model';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root',
})
export class DriverAssignmentService {
  private readonly baseUrl = `${environment.apiBaseUrl}/admin/assignments/permanent`;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    });
  }

  private buildParams(params: Record<string, string | number | boolean | undefined>): HttpParams {
    let httpParams = new HttpParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        httpParams = httpParams.set(key, String(value));
      }
    });
    return httpParams;
  }

  getAssignmentsByDriver(driverId: number): Observable<ApiResponse<DriverAssignment[]>> {
    const params = this.buildParams({ driverId });
    return this.http.get<ApiResponse<DriverAssignment[]>>(`${this.baseUrl}/list`, {
      headers: this.getHeaders(),
      params,
    });
  }

  assignDriver(driverId: number, vehicleId: number): Observable<ApiResponse<DriverAssignment>> {
    return this.http.post<ApiResponse<DriverAssignment>>(
      this.baseUrl,
      {
        driverId,
        vehicleId,
        reason: 'Assigned from legacy driver assignment service',
        forceReassignment: true,
      },
      {
        headers: this.getHeaders(),
      },
    );
  }

  unassignDriver(driverId: number, reason?: string): Observable<ApiResponse<string>> {
    const params = this.buildParams({ reason });
    return this.http.delete<ApiResponse<string>>(`${this.baseUrl}/${driverId}`, {
      headers: this.getHeaders(),
      params,
    });
  }

  completeAssignment(id: number): Observable<ApiResponse<DriverAssignment>> {
    return throwError(
      () =>
        new Error(
          `Legacy assignment completion is deprecated (assignmentId=${id}). Use driver-based unassign/reassign actions.`,
        ),
    );
  }

  cancelAssignment(id: number): Observable<ApiResponse<DriverAssignment>> {
    return throwError(
      () =>
        new Error(
          `Legacy assignment cancel is deprecated (assignmentId=${id}). Use driver-based unassign actions.`,
        ),
    );
  }

  updateAssignmentVehicle(
    id: number,
    newVehicleId: number,
  ): Observable<ApiResponse<DriverAssignment>> {
    return throwError(
      () =>
        new Error(
          `Legacy assignment update-by-id is deprecated (assignmentId=${id}, vehicleId=${newVehicleId}). Use driver-based reassign.`,
        ),
    );
  }

  deleteAssignment(id: number): Observable<ApiResponse<void>> {
    return throwError(
      () =>
        new Error(
          `Legacy assignment delete-by-id is deprecated (assignmentId=${id}). Use driver-based unassign.`,
        ),
    );
  }

  getVehiclesByDriverId(driverId: number): Observable<ApiResponse<Vehicle[]>> {
    return throwError(
      () => new Error(`Legacy getVehiclesByDriverId is deprecated (driverId=${driverId}).`),
    );
  }
}
