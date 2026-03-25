import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface BookingReportSummary {
  totalBookings: number;
  confirmedBookings: number;
  cancelledBookings: number;
  convertedToOrderBookings: number;
  newBookings: number;
  totalRevenue: number;
  averageCost: number;
  confirmationRate: number;
  cancellationRate: number;
  conversionRate: number;
}

export interface BookingAnalytics {
  name: string;
  count: number;
  revenue: number;
  averageCost: number;
  confirmationRate: number;
  conversionRate: number;
}

@Injectable({
  providedIn: 'root',
})
export class BookingReportService {
  private readonly baseUrl = '/api/admin/bookings/reports';

  constructor(private readonly http: HttpClient) {}

  getSummary(
    startDate?: string,
    endDate?: string,
    status?: string,
  ): Observable<{ data: BookingReportSummary }> {
    let params = new HttpParams();
    if (startDate) params = params.set('startDate', startDate);
    if (endDate) params = params.set('endDate', endDate);
    if (status) params = params.set('status', status);
    return this.http.get<{ data: BookingReportSummary }>(`${this.baseUrl}/summary`, { params });
  }

  getDetailedList(
    page: number = 0,
    size: number = 20,
    startDate?: string,
    endDate?: string,
    status?: string,
    serviceType?: string,
  ): Observable<any> {
    let params = new HttpParams().set('page', page.toString()).set('size', size.toString());
    if (startDate) params = params.set('startDate', startDate);
    if (endDate) params = params.set('endDate', endDate);
    if (status) params = params.set('status', status);
    if (serviceType) params = params.set('serviceType', serviceType);
    return this.http.get<any>(`${this.baseUrl}/detailed`, { params });
  }

  getAnalyticsByCustomer(
    startDate?: string,
    endDate?: string,
  ): Observable<{ data: BookingAnalytics[] }> {
    let params = new HttpParams();
    if (startDate) params = params.set('startDate', startDate);
    if (endDate) params = params.set('endDate', endDate);
    return this.http.get<{ data: BookingAnalytics[] }>(`${this.baseUrl}/analytics/by-customer`, {
      params,
    });
  }

  getAnalyticsByServiceType(
    startDate?: string,
    endDate?: string,
  ): Observable<{ data: BookingAnalytics[] }> {
    let params = new HttpParams();
    if (startDate) params = params.set('startDate', startDate);
    if (endDate) params = params.set('endDate', endDate);
    return this.http.get<{ data: BookingAnalytics[] }>(
      `${this.baseUrl}/analytics/by-service-type`,
      { params },
    );
  }

  getAnalyticsByTruckType(
    startDate?: string,
    endDate?: string,
  ): Observable<{ data: BookingAnalytics[] }> {
    let params = new HttpParams();
    if (startDate) params = params.set('startDate', startDate);
    if (endDate) params = params.set('endDate', endDate);
    return this.http.get<{ data: BookingAnalytics[] }>(`${this.baseUrl}/analytics/by-truck-type`, {
      params,
    });
  }

  exportCsv(
    startDate?: string,
    endDate?: string,
    status?: string,
    serviceType?: string,
  ): Observable<Blob> {
    let params = new HttpParams();
    if (startDate) params = params.set('startDate', startDate);
    if (endDate) params = params.set('endDate', endDate);
    if (status) params = params.set('status', status);
    if (serviceType) params = params.set('serviceType', serviceType);
    return this.http.get<Blob>(`${this.baseUrl}/export/csv`, {
      params,
      responseType: 'blob' as 'json',
    });
  }
}
