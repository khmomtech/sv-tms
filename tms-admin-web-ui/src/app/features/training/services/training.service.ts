import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface TrainingRecord {
  id: number;
  driverId: number;
  driverName: string;
  driverPhone: string;
  trainingName: string;
  description: string;
  expiryDate: string;
  daysUntilExpiry: number | null;
  status: 'ACTIVE' | 'EXPIRING_SOON' | 'EXPIRED';
  isRequired: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface TrainingSummary {
  total: number;
  active: number;
  expiringSoon: number;
  expired: number;
  compliancePercent: number;
}

export interface TrainingPage {
  content: TrainingRecord[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

export interface TrainingApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

export interface TrainingListFilter {
  search?: string;
  status?: string;
  page?: number;
  size?: number;
}

@Injectable({ providedIn: 'root' })
export class TrainingService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiBaseUrl}/admin/training-records`;

  list(filter: TrainingListFilter): Observable<TrainingApiResponse<TrainingPage>> {
    let params = new HttpParams();
    if (filter.search) params = params.set('search', filter.search);
    params = params.set('page', String(filter.page ?? 0));
    params = params.set('size', String(filter.size ?? 20));

    return this.http.get<TrainingApiResponse<TrainingPage>>(this.baseUrl, { params });
  }

  getExpiring(days = 30): Observable<TrainingApiResponse<TrainingRecord[]>> {
    const params = new HttpParams().set('days', String(days));
    return this.http.get<TrainingApiResponse<TrainingRecord[]>>(`${this.baseUrl}/expiring`, {
      params,
    });
  }

  getSummary(): Observable<TrainingApiResponse<TrainingSummary>> {
    return this.http.get<TrainingApiResponse<TrainingSummary>>(`${this.baseUrl}/summary`);
  }
}
