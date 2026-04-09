// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

const BASE_URL = '/api/khb-so-upload';

@Injectable({
  providedIn: 'root',
})
export class KhbSoUploadService {
  constructor(private http: HttpClient) {}

  /** Upload SO file */
  uploadSOFile(file: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post(`${BASE_URL}/upload`, formData);
  }

  /** Preview data before committing */
  previewUpload(file: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post(`${BASE_URL}/preview`, formData);
  }

  /** Commit uploaded data */
  commitUpload(payload: any): Observable<any> {
    return this.http.post(`${BASE_URL}/commit`, payload);
  }

  /** Plan trips with filters and pagination */
  planTrip(
    uploadDate: string,
    zone?: string,
    distributorCode?: string,
    page: number = 0,
    size: number = 20,
  ): Observable<any> {
    let params = new HttpParams()
      .set('uploadDate', uploadDate)
      .set('page', page.toString())
      .set('size', size.toString());
    if (zone) params = params.set('zone', zone);
    if (distributorCode) params = params.set('distributorCode', distributorCode);
    return this.http.get(`${BASE_URL}/plan-trip`, { params });
  }

  /** Export trip plan to Excel */
  exportTripPlan(uploadDate: string): Observable<Blob> {
    const params = new HttpParams().set('uploadDate', uploadDate);
    return this.http.get(`${BASE_URL}/plan-trip/export`, {
      params,
      responseType: 'blob',
    });
  }

  /** Export final summary report */
  exportFinalSummary(uploadDate: string): Observable<Blob> {
    const params = new HttpParams().set('uploadDate', uploadDate);
    return this.http.get(`${BASE_URL}/report/final-summary`, {
      params,
      responseType: 'blob',
    });
  }

  /** Download final summary Excel by date */
  downloadFinalSummaryExcel(date: string): Observable<Blob> {
    const params = new HttpParams().set('date', date);
    return this.http.get(`${BASE_URL}/khb/final-summary/excel`, {
      params,
      responseType: 'blob',
    });
  }
}
