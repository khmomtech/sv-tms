// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { Vehicle } from '../models/vehicle.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

export interface TrailerSearchFilters {
  search?: string;
  status?: string;
  zone?: string;
  assigned?: boolean;
}

@Injectable({
  providedIn: 'root',
})
export class TrailerService {
  private readonly apiUrl = `${environment.baseUrl}/api/admin/trailers`;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  /**
   * Get all trailers with pagination
   */
  getAllTrailers(page: number = 0, size: number = 15): Observable<ApiResponse<any>> {
    const params = new HttpParams().set('page', page.toString()).set('size', size.toString());

    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/list`, {
      headers: this.getHeaders(),
      params,
    });
  }

  /**
   * Get all trailers without pagination
   */
  getAllTrailersNoPage(): Observable<ApiResponse<Vehicle[]>> {
    return this.http.get<ApiResponse<Vehicle[]>>(`${this.apiUrl}/all`, {
      headers: this.getHeaders(),
    });
  }

  /**
   * Get available trailers (not assigned to any truck)
   */
  getAvailableTrailers(): Observable<ApiResponse<Vehicle[]>> {
    return this.http.get<ApiResponse<Vehicle[]>>(`${this.apiUrl}/available`, {
      headers: this.getHeaders(),
    });
  }

  /**
   * Search trailers with filters
   */
  searchTrailers(
    filters: TrailerSearchFilters,
    page: number = 0,
    size: number = 15,
  ): Observable<ApiResponse<any>> {
    let params = new HttpParams().set('page', page.toString()).set('size', size.toString());

    if (filters.search) {
      params = params.set('search', filters.search);
    }
    if (filters.status) {
      params = params.set('status', filters.status);
    }
    if (filters.zone) {
      params = params.set('zone', filters.zone);
    }
    if (filters.assigned !== undefined) {
      params = params.set('assigned', filters.assigned.toString());
    }

    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/search`, {
      headers: this.getHeaders(),
      params,
    });
  }

  /**
   * Get trailers assigned to a specific truck
   */
  getTrailersByTruck(vehicleId: number): Observable<ApiResponse<Vehicle[]>> {
    return this.http.get<ApiResponse<Vehicle[]>>(`${this.apiUrl}/by-truck/${vehicleId}`, {
      headers: this.getHeaders(),
    });
  }

  /**
   * Assign trailer to a truck
   */
  assignTrailerToTruck(trailerId: number, vehicleId: number): Observable<ApiResponse<Vehicle>> {
    return this.http.post<ApiResponse<Vehicle>>(
      `${this.apiUrl}/${trailerId}/assign/${vehicleId}`,
      {},
      { headers: this.getHeaders() },
    );
  }

  /**
   * Unassign trailer from its current truck
   */
  unassignTrailer(trailerId: number): Observable<ApiResponse<Vehicle>> {
    return this.http.post<ApiResponse<Vehicle>>(
      `${this.apiUrl}/${trailerId}/unassign`,
      {},
      { headers: this.getHeaders() },
    );
  }
}
