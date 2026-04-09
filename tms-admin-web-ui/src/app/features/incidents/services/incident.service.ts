import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  Incident,
  IncidentFilter,
  IncidentStatistics,
  ApiResponse,
  PagedResponse,
} from '../models/incident.model';

@Injectable({
  providedIn: 'root',
})
export class IncidentService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiBaseUrl}/incidents`;

  /**
   * List incidents with pagination and filtering
   */
  listIncidents(
    filter?: IncidentFilter,
    page: number = 0,
    size: number = 20,
  ): Observable<ApiResponse<PagedResponse<Incident>>> {
    let params = new HttpParams().set('page', page.toString()).set('size', size.toString());

    if (filter) {
      if (filter.search) params = params.set('search', filter.search);
      if (filter.status) params = params.set('status', filter.status);
      if (filter.group) params = params.set('group', filter.group);
      if (filter.severity) params = params.set('severity', filter.severity);
      if (filter.driverId) params = params.set('driverId', filter.driverId.toString());
      if (filter.vehicleId) params = params.set('vehicleId', filter.vehicleId.toString());
      if (filter.reportedAfter) params = params.set('reportedAfter', filter.reportedAfter);
      if (filter.reportedBefore) params = params.set('reportedBefore', filter.reportedBefore);
    }

    return this.http.get<ApiResponse<PagedResponse<Incident>>>(this.baseUrl, { params });
  }

  /**
   * Get incident by ID
   */
  getIncident(id: number): Observable<ApiResponse<Incident>> {
    return this.http.get<ApiResponse<Incident>>(`${this.baseUrl}/${id}`);
  }

  /**
   * Create new incident
   */
  createIncident(incident: Incident): Observable<ApiResponse<Incident>> {
    return this.http.post<ApiResponse<Incident>>(this.baseUrl, incident);
  }

  /**
   * Update incident
   */
  updateIncident(id: number, incident: Partial<Incident>): Observable<ApiResponse<Incident>> {
    return this.http.put<ApiResponse<Incident>>(`${this.baseUrl}/${id}`, incident);
  }

  /**
   * Delete incident (soft delete)
   */
  deleteIncident(id: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(`${this.baseUrl}/${id}`);
  }

  /**
   * Validate incident (change status to VALIDATED)
   */
  validateIncident(id: number): Observable<ApiResponse<Incident>> {
    return this.http.post<ApiResponse<Incident>>(`${this.baseUrl}/${id}/validate`, {});
  }

  /**
   * Close incident
   */
  closeIncident(id: number, resolutionNotes?: string): Observable<ApiResponse<Incident>> {
    return this.http.post<ApiResponse<Incident>>(`${this.baseUrl}/${id}/close`, {
      resolutionNotes,
    });
  }

  /**
   * Get incident statistics
   */
  getStatistics(filter?: IncidentFilter): Observable<ApiResponse<IncidentStatistics>> {
    let params = new HttpParams();

    if (filter) {
      if (filter.status) params = params.set('status', filter.status);
      if (filter.group) params = params.set('group', filter.group);
      if (filter.severity) params = params.set('severity', filter.severity);
      if (filter.driverId) params = params.set('driverId', filter.driverId.toString());
      if (filter.vehicleId) params = params.set('vehicleId', filter.vehicleId.toString());
      if (filter.reportedAfter) params = params.set('reportedAfter', filter.reportedAfter);
      if (filter.reportedBefore) params = params.set('reportedBefore', filter.reportedBefore);
    }

    return this.http.get<ApiResponse<IncidentStatistics>>(`${this.baseUrl}/statistics`, { params });
  }

  /**
   * Upload photos to incident
   */
  uploadPhotos(id: number, files: File[]): Observable<ApiResponse<Incident>> {
    const formData = new FormData();
    files.forEach((file) => formData.append('files', file));

    return this.http.post<ApiResponse<Incident>>(`${this.baseUrl}/${id}/upload-photos`, formData);
  }
}
