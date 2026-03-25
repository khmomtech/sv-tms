import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface ComplianceSummary {
  totalDocuments: number;
  expired: number;
  expiringSoon30Days: number;
  active: number;
  overallCompliancePct: number;
}

export interface ExpiringDocument {
  documentId: number;
  driverId: number;
  driverName: string;
  driverPhone: string;
  documentName: string;
  category: string;
  expiryDate: string;
  daysUntilExpiry: number;
  status: 'ACTIVE' | 'EXPIRING_SOON' | 'EXPIRED';
  isRequired: boolean;
}

export interface ComplianceApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

@Injectable({ providedIn: 'root' })
export class ComplianceService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiBaseUrl}/admin/document-compliance`;

  getSummary(): Observable<ComplianceApiResponse<ComplianceSummary>> {
    return this.http.get<ComplianceApiResponse<ComplianceSummary>>(`${this.baseUrl}/summary`);
  }

  getExpiring(days = 30): Observable<ComplianceApiResponse<ExpiringDocument[]>> {
    const params = new HttpParams().set('days', String(days));
    return this.http.get<ComplianceApiResponse<ExpiringDocument[]>>(`${this.baseUrl}/expiring`, {
      params,
    });
  }

  getExpired(): Observable<ComplianceApiResponse<ExpiringDocument[]>> {
    return this.http.get<ComplianceApiResponse<ExpiringDocument[]>>(`${this.baseUrl}/expired`);
  }
}
