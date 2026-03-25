// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

import { environment } from '../environments/environment';
import type { AuditTrail } from '../models/audit-trail.model';

@Injectable({
  providedIn: 'root',
})
export class AuditTrailService {
  private readonly baseUrl = `${environment.baseUrl}/api/admin/audit-trails`;

  constructor(private http: HttpClient) {}

  getAllAuditTrails(): Observable<AuditTrail[]> {
    return this.http.get<AuditTrail[]>(this.baseUrl);
  }

  getAuditTrailsByUser(userId: number): Observable<AuditTrail[]> {
    return this.http.get<AuditTrail[]>(`${this.baseUrl}/user/${userId}`);
  }

  getAuditTrailsByUsername(username: string): Observable<AuditTrail[]> {
    return this.http.get<AuditTrail[]>(`${this.baseUrl}/username/${username}`);
  }

  getAuditTrailsByAction(action: string): Observable<AuditTrail[]> {
    return this.http.get<AuditTrail[]>(`${this.baseUrl}/action/${action}`);
  }

  getAuditTrailsByResourceType(resourceType: string): Observable<AuditTrail[]> {
    return this.http.get<AuditTrail[]>(`${this.baseUrl}/resource/${resourceType}`);
  }

  getAuditTrailsByDateRange(startDate: string, endDate: string): Observable<AuditTrail[]> {
    return this.http.get<AuditTrail[]>(
      `${this.baseUrl}/date-range?startDate=${startDate}&endDate=${endDate}`,
    );
  }

  getAuditTrailsByUsernameAndAction(username: string, action: string): Observable<AuditTrail[]> {
    return this.http.get<AuditTrail[]>(`${this.baseUrl}/user/${username}/action/${action}`);
  }

  createAuditTrail(auditTrail: AuditTrail): Observable<AuditTrail> {
    return this.http.post<AuditTrail>(this.baseUrl, auditTrail);
  }

  deleteAuditTrail(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
