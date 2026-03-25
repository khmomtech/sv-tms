import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  Case,
  CaseFilter,
  CaseStatistics,
  CaseTask,
  CaseAttachment,
  ApiResponse,
  PagedResponse,
} from '../models/incident.model';

@Injectable({
  providedIn: 'root',
})
export class CaseService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiBaseUrl}/cases`;

  /**
   * List cases with pagination and filtering
   */
  listCases(
    filter?: CaseFilter,
    page: number = 0,
    size: number = 20,
  ): Observable<ApiResponse<PagedResponse<Case>>> {
    let params = new HttpParams().set('page', page.toString()).set('size', size.toString());

    if (filter) {
      if (filter.status) params = params.set('status', filter.status);
      if (filter.severity) params = params.set('severity', filter.severity);
      if (filter.category) params = params.set('category', filter.category);
      if (filter.assignedToUserId)
        params = params.set('assignedToUserId', filter.assignedToUserId.toString());
      if (filter.driverId) params = params.set('driverId', filter.driverId.toString());
      if (filter.vehicleId) params = params.set('vehicleId', filter.vehicleId.toString());
      if (filter.createdAfter) params = params.set('createdAfter', filter.createdAfter);
      if (filter.createdBefore) params = params.set('createdBefore', filter.createdBefore);
    }

    return this.http.get<ApiResponse<PagedResponse<Case>>>(this.baseUrl, { params });
  }

  /**
   * Get case by ID
   */
  getCase(
    id: number,
    includeIncidents: boolean = false,
    includeTasks: boolean = false,
    includeTimeline: boolean = false,
  ): Observable<ApiResponse<Case>> {
    let params = new HttpParams();
    if (includeIncidents) params = params.set('includeIncidents', 'true');
    if (includeTasks) params = params.set('includeTasks', 'true');
    if (includeTimeline) params = params.set('includeTimeline', 'true');

    return this.http.get<ApiResponse<Case>>(`${this.baseUrl}/${id}`, { params });
  }

  /**
   * Create new case
   */
  createCase(caseData: Partial<Case>): Observable<ApiResponse<Case>> {
    return this.http.post<ApiResponse<Case>>(this.baseUrl, caseData);
  }

  /**
   * Update case
   */
  updateCase(id: number, caseData: Partial<Case>): Observable<ApiResponse<Case>> {
    return this.http.put<ApiResponse<Case>>(`${this.baseUrl}/${id}`, caseData);
  }

  /**
   * Update case status
   */
  updateCaseStatus(id: number, status: string): Observable<ApiResponse<Case>> {
    return this.http.patch<ApiResponse<Case>>(`${this.baseUrl}/${id}/status`, { status });
  }

  /**
   * Delete case (soft delete)
   */
  deleteCase(id: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(`${this.baseUrl}/${id}`);
  }

  /**
   * Link incident to case (escalate)
   */
  linkIncident(caseId: number, incidentId: number): Observable<ApiResponse<Case>> {
    return this.http.post<ApiResponse<Case>>(`${this.baseUrl}/${caseId}/incidents`, null, {
      params: new HttpParams().set('incidentId', incidentId.toString()),
    });
  }

  /**
   * Unlink incident from case
   */
  unlinkIncident(caseId: number, incidentId: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(`${this.baseUrl}/${caseId}/incidents/${incidentId}`);
  }

  /**
   * Search cases
   */
  searchCases(
    query: string,
    page: number = 0,
    size: number = 20,
  ): Observable<ApiResponse<PagedResponse<Case>>> {
    const params = new HttpParams()
      .set('q', query)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<PagedResponse<Case>>>(`${this.baseUrl}/search`, { params });
  }

  /**
   * Get case statistics
   */
  getStatistics(): Observable<ApiResponse<CaseStatistics>> {
    return this.http.get<ApiResponse<CaseStatistics>>(`${this.baseUrl}/statistics`);
  }

  /**
   * Get case tasks
   */
  getCaseTasks(caseId: number): Observable<ApiResponse<CaseTask[]>> {
    return this.http.get<ApiResponse<CaseTask[]>>(`${this.baseUrl}/${caseId}/tasks`);
  }

  /**
   * Create case task
   */
  createCaseTask(caseId: number, task: CaseTask): Observable<ApiResponse<CaseTask>> {
    return this.http.post<ApiResponse<CaseTask>>(`${this.baseUrl}/${caseId}/tasks`, task);
  }

  /**
   * Update case task
   */
  updateCaseTask(
    caseId: number,
    taskId: number,
    task: Partial<CaseTask>,
  ): Observable<ApiResponse<CaseTask>> {
    return this.http.put<ApiResponse<CaseTask>>(`${this.baseUrl}/${caseId}/tasks/${taskId}`, task);
  }

  /**
   * Delete case task
   */
  deleteCaseTask(caseId: number, taskId: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(`${this.baseUrl}/${caseId}/tasks/${taskId}`);
  }

  /**
   * Get case attachments
   */
  getCaseAttachments(caseId: number): Observable<ApiResponse<CaseAttachment[]>> {
    return this.http.get<ApiResponse<CaseAttachment[]>>(`${this.baseUrl}/${caseId}/attachments`);
  }

  /**
   * Upload case attachment
   */
  uploadAttachment(
    caseId: number,
    file: File,
    description?: string,
  ): Observable<ApiResponse<CaseAttachment>> {
    const formData = new FormData();
    formData.append('file', file);
    if (description) formData.append('description', description);

    return this.http.post<ApiResponse<CaseAttachment>>(
      `${this.baseUrl}/${caseId}/attachments`,
      formData,
    );
  }

  /**
   * Delete case attachment
   */
  deleteAttachment(caseId: number, attachmentId: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(
      `${this.baseUrl}/${caseId}/attachments/${attachmentId}`,
    );
  }
}
